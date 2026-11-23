import SwiftUI

// MARK: - Головоломка дня: собрать стих по порядку
// Каждый день один стих, разрезанный на плитки. Человек ставит плитки по порядку: верные закрепляются,
// неверные возвращаются на стол. Шесть попыток; результатом делятся цветными квадратами, без текста стиха.

// MARK: Логика (без интерфейса)
enum VersePuzzleLogic {
    static let maxAttempts = 6
    /// Больше плиток на экране неудобно: длинные стихи режутся на куски по два слова
    static let maxTiles = 8
    static let minWords = 6
    static let maxWords = 18

    private static func gregorian() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }

    /// Номер головоломки: сколько дней прошло с 1 января 2026 (первая головоломка №1). Меняется в полночь по местному времени
    static func dayNumber(for date: Date = Date()) -> Int {
        let calendar = gregorian()
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 1
        parts.day = 1
        guard let start = calendar.date(from: parts) else { return 1 }
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: date)).day ?? 0
        return max(1, days + 1)
    }

    static func words(of text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
    }

    /// Стих годится для головоломки: короче скучно, длиннее не уместится на экране
    static func isEligible(_ text: String) -> Bool {
        let count = words(of: text).count
        return count >= minWords && count <= maxWords
    }

    /// Плитки: каждое слово отдельно, а у длинного стиха слова собраны в куски так, чтобы плиток было не больше восьми
    static func chunks(of text: String) -> [String] {
        let all = words(of: text)
        guard all.count > maxTiles else { return all }
        var result: [String] = []
        var start = 0
        for index in 0..<maxTiles {
            let end = (all.count * (index + 1)) / maxTiles
            if end > start {
                result.append(all[start..<end].joined(separator: " "))
                start = end
            }
        }
        return result
    }

    /// Текст стиха без обращения к базе: для отбора подходящих стихов (полный текст берётся только у выбранного)
    private static func rawText(_ verse: BibleVerse, _ language: AppLanguage) -> String {
        switch language {
        case .armenian: return verse.textHy
        case .russian: return verse.textRu
        case .english: return verse.textEn
        }
    }

    /// Стих дня для головоломки: у каждого дня свой, перебор по кругу с шагом, чтобы соседние дни не шли подряд по теме
    static func verse(forDay day: Int, language: AppLanguage) -> BibleVerse? {
        let pool = BibleVerse.database.filter { isEligible(rawText($0, language)) }
        guard !pool.isEmpty else { return nil }
        let start = (max(1, day) - 1) * 7919 % pool.count
        // Полный текст может отличаться от сырого (издание Нор Арарат), поэтому проверяем его ещё раз
        for step in 0..<min(pool.count, 30) {
            let candidate = pool[(start + step) % pool.count]
            if isEligible(candidate.text(for: language)) { return candidate }
        }
        return nil
    }

    /// Генератор с заданным зерном: порядок плиток одинаков весь день и после перезапуска
    struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed &+ 0x9E37_79B9_7F4A_7C15
        }

        mutating func next() -> UInt64 {
            state = state &+ 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// Порядок плиток на столе: перемешанный, но никогда не равный правильному
    static func shuffled(_ correct: [String], day: Int) -> [String] {
        guard correct.count > 1 else { return correct }
        var generator = SeededGenerator(seed: UInt64(max(1, day)))
        var result = correct
        for _ in 0..<10 {
            result.shuffle(using: &generator)
            if result != correct { return result }
        }
        // Запасной вариант (например, если все плитки одинаковые слова): сдвиг на одну плитку
        return Array(correct.dropFirst()) + [correct[0]]
    }
}

// MARK: Доска
/// Состояние одной головоломки. Номер плитки это её место в `tray`; в ячейке (`slots`) лежит номер плитки или ничего
struct VersePuzzleBoard: Equatable {
    let correct: [String]
    let tray: [String]
    private(set) var slots: [Int?]
    private(set) var locked: Set<Int>
    private(set) var attempts: [[Bool]]

    init(correct: [String], tray: [String], attempts: [[Bool]] = [], locked: Set<Int> = []) {
        self.correct = correct
        self.tray = tray
        self.attempts = attempts
        var filled = [Int?](repeating: nil, count: correct.count)
        var confirmed = Set<Int>()
        var used = Set<Int>()
        // Закреплённые ячейки восстанавливаем плитками с тем же текстом (слова могут повторяться)
        for slot in locked.sorted() where slot >= 0 && slot < correct.count {
            if let tile = tray.indices.first(where: { !used.contains($0) && tray[$0] == correct[slot] }) {
                filled[slot] = tile
                used.insert(tile)
                confirmed.insert(slot)
            }
        }
        self.slots = filled
        self.locked = confirmed
    }

    var maxAttempts: Int { VersePuzzleLogic.maxAttempts }
    var isSolved: Bool { !correct.isEmpty && locked.count == correct.count }
    var isFailed: Bool { !isSolved && attempts.count >= maxAttempts }
    var isFinished: Bool { isSolved || isFailed }
    var isFull: Bool { !slots.contains(where: { $0 == nil }) }

    /// Плитки, которые ещё лежат на столе
    var poolTiles: [Int] {
        tray.indices.filter { tile in !slots.contains(where: { $0 == tile }) }
    }

    /// Плитка встаёт в первую пустую ячейку
    mutating func place(_ tile: Int) {
        guard !isFinished,
              tray.indices.contains(tile),
              !slots.contains(where: { $0 == tile }),
              let slot = slots.firstIndex(where: { $0 == nil }) else { return }
        slots[slot] = tile
    }

    /// Плитка возвращается на стол; закреплённую трогать нельзя
    mutating func remove(slot: Int) {
        guard !isFinished, slots.indices.contains(slot), !locked.contains(slot) else { return }
        slots[slot] = nil
    }

    /// Проверка: верные ячейки закрепляются, неверные освобождаются. Возвращает, что верно в каждой ячейке
    @discardableResult
    mutating func submit() -> [Bool]? {
        guard isFull, !isFinished else { return nil }
        var result: [Bool] = []
        for slot in slots.indices {
            if let tile = slots[slot] {
                result.append(tray[tile] == correct[slot])
            } else {
                result.append(false)
            }
        }
        attempts.append(result)
        for slot in slots.indices {
            if result[slot] {
                locked.insert(slot)
            } else {
                slots[slot] = nil
            }
        }
        return result
    }
}

// MARK: Хранилище
/// Прогресс сегодняшней головоломки и решённые дни (для серии). Всё хранится на телефоне
final class VersePuzzleStore: ObservableObject {
    static let shared = VersePuzzleStore()

    private struct Saved: Codable {
        var key: String
        var count: Int
        var attempts: [[Bool]]
        var locked: [Int]
    }

    private let progressKey = "verse_puzzle_progress_v1"
    private let solvedKey = "verse_puzzle_solved_days_v1"
    private let defaults = UserDefaults.standard

    @Published private(set) var solvedDays: Set<Int> = []

    private init() {
        let stored = defaults.array(forKey: solvedKey) as? [Int] ?? []
        solvedDays = Set(stored)
    }

    var totalSolved: Int { solvedDays.count }

    var isSolvedToday: Bool { solvedDays.contains(VersePuzzleLogic.dayNumber()) }

    /// Сколько дней подряд решена головоломка. Если сегодня ещё не решена, серия считается до вчера
    var streak: Int {
        let today = VersePuzzleLogic.dayNumber()
        var day = solvedDays.contains(today) ? today : today - 1
        var count = 0
        while day > 0 && solvedDays.contains(day) {
            count += 1
            day -= 1
        }
        return count
    }

    func progress(forKey key: String, count: Int) -> (attempts: [[Bool]], locked: [Int]) {
        guard let data = defaults.data(forKey: progressKey),
              let saved = try? JSONDecoder().decode(Saved.self, from: data),
              saved.key == key, saved.count == count else { return ([], []) }
        return (saved.attempts, saved.locked)
    }

    func save(key: String, board: VersePuzzleBoard) {
        let saved = Saved(key: key, count: board.correct.count, attempts: board.attempts, locked: board.locked.sorted())
        if let data = try? JSONEncoder().encode(saved) {
            defaults.set(data, forKey: progressKey)
        }
    }

    func markSolved(day: Int) {
        guard !solvedDays.contains(day) else { return }
        solvedDays.insert(day)
        defaults.set(solvedDays.sorted(), forKey: solvedKey)
    }
}

// MARK: Карточка на главном экране
struct VersePuzzleBannerCardView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    let onOpen: () -> Void

    @ObservedObject private var store = VersePuzzleStore.shared

    private var subtitle: String {
        let streak = store.streak
        if store.isSolvedToday {
            if streak >= 2 {
                return language.pick(
                    hy: "Այսօր լուծված է · շարք՝ \(streak) օր",
                    ru: "Решено сегодня · серия \(streak) дн.",
                    en: "Solved today · \(streak) day streak"
                )
            }
            return language.pick(hy: "Այսօր լուծված է", ru: "Решено сегодня", en: "Solved today")
        }
        return language.pick(hy: "Նոր համար ամեն օր", ru: "Новый стих каждый день", en: "A new verse every day")
    }

    var body: some View {
        HomeFeatureCard(
            symbol: "puzzlepiece.extension.fill",
            label: language.pick(hy: "ՕՐՎԱ ՀԱՆԵԼՈՒԿ", ru: "ГОЛОВОЛОМКА ДНЯ", en: "PUZZLE OF THE DAY"),
            labelColor: Paper.gold,
            title: language.pick(hy: "Հավաքեք համարը ըստ կարգի", ru: "Соберите стих по порядку", en: "Put the verse in order"),
            subtitle: subtitle,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryAccentColor,
            onOpen: onOpen
        )
    }
}

// MARK: Экран головоломки
struct VersePuzzleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var store = VersePuzzleStore.shared

    @State private var board: VersePuzzleBoard? = nil
    @State private var verse: BibleVerse? = nil
    @State private var day = VersePuzzleLogic.dayNumber()
    @State private var didLoad = false

    private var language: AppLanguage { manager.appLanguage }
    private var storageKey: String { "\(day)_\(language.rawValue)" }

    private enum ChipStyle {
        case tray
        case placed
        case locked
    }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if let current = board {
                            content(for: current)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            load()
            Funnel.track("feature_used", ["feature": "puzzle_opened"])
        }
    }

    // MARK: Верх экрана
    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Paper.ink.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Text(language.pick(
                hy: "Օրվա հանելուկ №\(day)",
                ru: "Головоломка дня №\(day)",
                en: "Puzzle of the day #\(day)"
            ))
            .font(PaperFont.font(size: 18, weight: .semibold))
            .foregroundColor(Paper.ink)

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        Text(language.pick(
            hy: "Այսօր հանելուկ չկա։ Վաղը նորից եկեք։",
            ru: "Сегодня головоломки нет. Загляните завтра.",
            en: "No puzzle today. Come back tomorrow."
        ))
        .font(PaperFont.font(size: 15))
        .foregroundColor(Paper.inkSecondary)
        .multilineTextAlignment(.center)
        .padding(.top, 40)
    }

    // MARK: Содержимое
    @ViewBuilder
    private func content(for current: VersePuzzleBoard) -> some View {
        statusLine(for: current)
        answerArea(for: current)
        if !current.attempts.isEmpty {
            attemptsHistory(current.attempts)
        }
        if current.isFinished {
            finishCard(for: current)
        } else {
            trayArea(for: current)
            checkButton(for: current)
        }
    }

    private func statusLine(for current: VersePuzzleBoard) -> some View {
        HStack {
            if !current.isFinished {
                Text(language.pick(
                    hy: "Փորձ \(current.attempts.count + 1) / \(current.maxAttempts)",
                    ru: "Попытка \(current.attempts.count + 1) из \(current.maxAttempts)",
                    en: "Attempt \(current.attempts.count + 1) of \(current.maxAttempts)"
                ))
                .font(PaperFont.font(size: 13, weight: .semibold))
                .foregroundColor(Paper.inkSecondary)
            }

            Spacer()

            if store.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Paper.gold)
                    Text(language.pick(
                        hy: "Շարք՝ \(store.streak) օր",
                        ru: "Серия: \(store.streak) дн.",
                        en: "Streak: \(store.streak) days"
                    ))
                    .font(PaperFont.font(size: 13, weight: .semibold))
                    .foregroundColor(Paper.gold)
                }
            }
        }
    }

    private func answerArea(for current: VersePuzzleBoard) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(current.slots.indices, id: \.self) { slot in
                slotView(slot, in: current)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSheet(cornerRadius: 18)
    }

    @ViewBuilder
    private func slotView(_ slot: Int, in current: VersePuzzleBoard) -> some View {
        if let tile = current.slots[slot] {
            let isLocked = current.locked.contains(slot)
            Button {
                guard !isLocked, !current.isFinished else { return }
                Haptics.impact(.light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    removeTile(at: slot)
                }
            } label: {
                chip(current.tray[tile], style: isLocked ? .locked : .placed)
            }
            .buttonStyle(.plain)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Paper.inkTertiary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(width: 40, height: 36)
        }
    }

    private func chip(_ text: String, style: ChipStyle) -> some View {
        let fill: Color
        let border: Color
        let textColor: Color
        switch style {
        case .tray:
            fill = Paper.gold.opacity(0.10)
            border = Paper.gold.opacity(0.45)
            textColor = Paper.ink
        case .placed:
            fill = Paper.gold.opacity(0.24)
            border = Paper.gold
            textColor = Paper.ink
        case .locked:
            fill = Paper.moss
            border = Paper.moss
            textColor = Paper.onAccent
        }
        return Text(text)
            .font(PaperFont.font(size: 15, weight: .medium))
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(border, lineWidth: 1))
    }

    private func attemptsHistory(_ attempts: [[Bool]]) -> some View {
        VStack(spacing: 6) {
            ForEach(attempts.indices, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(attempts[row].indices, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(attempts[row][column] ? Paper.moss : Paper.inkTertiary.opacity(0.35))
                            .frame(width: 18, height: 18)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func trayArea(for current: VersePuzzleBoard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.pick(
                hy: "Սեղմեք բառերը այն կարգով, որով դրանք գրված են համարում",
                ru: "Нажимайте слова в том порядке, в каком они стоят в стихе",
                en: "Tap the words in the order they appear in the verse"
            ))
            .font(PaperFont.font(size: 12, weight: .medium))
            .foregroundColor(Paper.inkSecondary)

            FlowLayout(spacing: 8) {
                ForEach(current.poolTiles, id: \.self) { tile in
                    Button {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            placeTile(tile)
                        }
                    } label: {
                        chip(current.tray[tile], style: .tray)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checkButton(for current: VersePuzzleBoard) -> some View {
        Button {
            submit()
        } label: {
            Text(language.pick(hy: "Ստուգել", ru: "Проверить", en: "Check"))
                .font(PaperFont.font(size: 16, weight: .semibold))
                .foregroundColor(Paper.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Paper.accentFill)
                .cornerRadius(16)
                .opacity(current.isFull ? 1 : 0.4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!current.isFull)
    }

    // MARK: Итог
    private func finishCard(for current: VersePuzzleBoard) -> some View {
        VStack(spacing: 14) {
            Image(systemName: current.isSolved ? "checkmark.seal.fill" : "book.closed.fill")
                .font(.system(size: 34))
                .foregroundColor(current.isSolved ? Paper.moss : Paper.gold)

            Text(finishTitle(for: current))
                .font(PaperFont.font(size: 17, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)

            if let verse {
                VStack(spacing: 6) {
                    Text("«\(verse.text(for: language))»")
                        .font(PaperFont.font(size: 16))
                        .foregroundColor(Paper.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Text(verse.reference(for: language))
                        .font(PaperFont.font(size: 13, weight: .semibold))
                        .foregroundColor(Paper.gold)
                }
            }

            ShareLink(item: shareText(for: current)) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(Paper.gold)
                    Text(language.pick(hy: "Կիսվել արդյունքով", ru: "Поделиться результатом", en: "Share result"))
                        .font(PaperFont.font(size: 15, weight: .semibold))
                        .foregroundColor(Paper.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .paperField(cornerRadius: 16)
            }
            .buttonStyle(ScaleButtonStyle())

            Text(language.pick(hy: "Նոր հանելուկը՝ վաղը", ru: "Новая головоломка завтра", en: "A new puzzle tomorrow"))
                .font(PaperFont.font(size: 12, weight: .medium))
                .foregroundColor(Paper.inkSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
    }

    private func finishTitle(for current: VersePuzzleBoard) -> String {
        if current.isSolved {
            let used = current.attempts.count
            let total = current.maxAttempts
            return language.pick(
                hy: "Ճիշտ է։ Փորձ՝ \(used)/\(total)",
                ru: "Верно! Решено с попытки \(used) из \(total)",
                en: "Correct! Solved on attempt \(used) of \(total)"
            )
        }
        return language.pick(
            hy: "Այսօր չստացվեց։ Ահա այդ համարը՝",
            ru: "Сегодня не вышло. Вот этот стих:",
            en: "Not this time. Here is the verse:"
        )
    }

    /// Текст для отправки: только квадраты и ссылка на приложение, сам стих не раскрывается
    private func shareText(for current: VersePuzzleBoard) -> String {
        let header = language.pick(
            hy: "Luys · Օրվա հանելուկ №\(day)",
            ru: "Luys · Головоломка дня №\(day)",
            en: "Luys · Puzzle of the day #\(day)"
        )
        let rows = current.attempts
            .map { row in row.map { $0 ? "🟩" : "⬜" }.joined() }
            .joined(separator: "\n")
        let score = current.isSolved ? "\(current.attempts.count)/\(current.maxAttempts)" : "X/\(current.maxAttempts)"
        let link = "https://apps.apple.com/app/id\(ReviewManager.shared.appStoreID)"
        return "\(header) \(score)\n\(rows)\n\(link)"
    }

    // MARK: Действия
    private func placeTile(_ tile: Int) {
        board?.place(tile)
    }

    private func removeTile(at slot: Int) {
        board?.remove(slot: slot)
    }

    private func load() {
        day = VersePuzzleLogic.dayNumber()
        guard let chosen = VersePuzzleLogic.verse(forDay: day, language: language) else { return }
        let correct = VersePuzzleLogic.chunks(of: chosen.text(for: language))
        guard correct.count >= 3 else { return }
        let saved = store.progress(forKey: storageKey, count: correct.count)
        verse = chosen
        board = VersePuzzleBoard(
            correct: correct,
            tray: VersePuzzleLogic.shuffled(correct, day: day),
            attempts: saved.attempts,
            locked: Set(saved.locked)
        )
    }

    private func submit() {
        guard var updated = board else { return }
        guard let result = updated.submit() else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            board = updated
        }
        store.save(key: storageKey, board: updated)

        if updated.isSolved {
            Haptics.notify(.success)
            store.markSolved(day: day)
            PomegranateTreeManager.shared.record(.plan)
            Funnel.track("feature_used", ["feature": "puzzle_solved"])
        } else if updated.isFailed {
            Haptics.notify(.error)
            Funnel.track("feature_used", ["feature": "puzzle_failed"])
        } else {
            Haptics.notify(result.contains(true) ? .success : .warning)
        }
    }
}
