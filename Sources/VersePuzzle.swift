import SwiftUI

// MARK: - «Собери стих»: игра с уровнями и головоломка дня
// Стих разрезан на плитки, их нужно поставить по порядку: верные закрепляются, неверные возвращаются на стол.
// Шесть попыток на стих, две подсказки (каждая отнимает звезду), до трёх звёзд за уровень.
// Уровни идут от коротких стихов к длинным. Бесплатная вкладка выдаёт по пять стихов раз в два дня (следующие,
// когда решены прошлые пять), вкладка ИИ и головоломка дня по подписке.

/// Что играем: уровень по номеру или головоломку дня
enum PuzzleMode: Equatable {
    case daily
    case level(Int)
    /// Уровень вкладки «ИИ» (по подписке)
    case ai(Int)

    var key: String {
        switch self {
        case .daily: return "daily"
        case .level(let number): return "level_\(number)"
        case .ai(let number): return "ai_level_\(number)"
        }
    }

    /// Уровень (классический или ИИ), а не головоломка дня
    var isLevel: Bool {
        switch self {
        case .daily: return false
        case .level, .ai: return true
        }
    }
}

/// Вкладки экрана игры: классические уровни из офлайн-базы и уровни от ИИ (по подписке)
private enum PuzzleTab: Hashable {
    case classic
    case ai
}

// MARK: Логика (без интерфейса)
enum VersePuzzleLogic {
    static let maxAttempts = 6
    /// Больше плиток на экране неудобно: длинные стихи режутся на куски по несколько слов
    static let maxTiles = 8
    static let minWords = 6
    static let maxWords = 18
    static let maxHints = 2
    /// Бесплатная вкладка выдаёт стихи пятёрками: следующая приходит, когда решены все выданные и с выдачи прошло два дня
    static let releaseSize = 5
    static let releaseInterval: TimeInterval = 2 * 24 * 60 * 60

    private static func gregorian() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }

    /// Номер головоломки дня: сколько дней прошло с 1 января 2026 (первая №1). Меняется в полночь по местному времени
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

    /// Слово для плитки: без знаков препинания и заглавных букв, чтобы они не подсказывали порядок
    /// (запятая в конце плитки или заглавная буква в начале сразу выдают начало и конец стиха). Дефис внутри слова остаётся
    static func tileWord(_ word: String) -> String {
        var kept = String.UnicodeScalarView()
        for scalar in word.unicodeScalars {
            if CharacterSet.punctuationCharacters.contains(scalar) && scalar != "-" { continue }
            kept.append(scalar)
        }
        return String(kept).trimmingCharacters(in: CharacterSet(charactersIn: "-")).lowercased()
    }

    /// Слова стиха в виде плиток: знаки препинания сняты, слова из одних знаков (тире) отброшены
    static func tileWords(of text: String) -> [String] {
        words(of: text).map { tileWord($0) }.filter { !$0.isEmpty }
    }

    /// Плитки: каждое слово отдельно, а у длинного стиха слова собраны в куски так, чтобы плиток было не больше `maxTiles`
    static func chunks(of text: String, maxTiles: Int = VersePuzzleLogic.maxTiles) -> [String] {
        let all = tileWords(of: text)
        let limit = max(2, maxTiles)
        guard all.count > limit else { return all }
        var result: [String] = []
        var start = 0
        for index in 0..<limit {
            let end = (all.count * (index + 1)) / limit
            if end > start {
                result.append(all[start..<end].joined(separator: " "))
                start = end
            }
        }
        return result
    }

    /// Сколько плиток на уровне: сначала четыре, к тринадцатому уровню восемь
    static func tileCount(forLevel level: Int) -> Int {
        min(maxTiles, 4 + (max(1, level) - 1) / 3)
    }

    /// Звёзды за пройденный уровень: чем меньше попыток, тем больше; каждая подсказка отнимает одну (но не меньше одной)
    static func stars(attempts: Int, hints: Int) -> Int {
        let base = attempts <= 2 ? 3 : (attempts <= 4 ? 2 : 1)
        return max(1, base - max(0, hints))
    }

    /// Текст стиха без обращения к базе: для отбора подходящих стихов (полный текст берётся только у выбранного)
    private static func rawText(_ verse: BibleVerse, _ language: AppLanguage) -> String {
        switch language {
        case .armenian: return verse.textHy
        case .russian: return verse.textRu
        case .english: return verse.textEn
        }
    }

    /// Стих головоломки дня: у каждого дня свой, перебор по кругу с шагом, чтобы соседние дни не шли подряд по теме
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

    /// Стихи для уровней: без повторов, от коротких к длинным (при равной длине порядок базы). Номер уровня это место в списке
    static func levelPool(language: AppLanguage) -> [BibleVerse] {
        var seen = Set<String>()
        var items: [(verse: BibleVerse, words: Int, index: Int)] = []
        for (index, verse) in BibleVerse.database.enumerated() {
            let raw = rawText(verse, language)
            let count = words(of: raw).count
            guard count >= minWords && count <= maxWords else { continue }
            guard seen.insert(raw.lowercased()).inserted else { continue }
            items.append((verse, count, index))
        }
        items.sort { left, right in
            left.words != right.words ? left.words < right.words : left.index < right.index
        }
        return items.map { $0.verse }
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
    static func shuffled(_ correct: [String], seed: Int) -> [String] {
        guard correct.count > 1 else { return correct }
        var generator = SeededGenerator(seed: UInt64(max(1, seed)))
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
    /// Сколько попыток и подсказок у партии: у классических уровней и головоломки дня обычные, у ИИ-уровней их задаёт ступень
    let attemptLimit: Int
    let hintLimit: Int
    private(set) var slots: [Int?]
    private(set) var locked: Set<Int>
    private(set) var attempts: [[Bool]]
    private(set) var hintsUsed: Int

    init(correct: [String], tray: [String], attempts: [[Bool]] = [], locked: Set<Int> = [], hintsUsed: Int = 0,
         attemptLimit: Int = VersePuzzleLogic.maxAttempts, hintLimit: Int = VersePuzzleLogic.maxHints) {
        self.correct = correct
        self.tray = tray
        self.attemptLimit = max(1, attemptLimit)
        self.hintLimit = max(0, hintLimit)
        self.attempts = attempts
        self.hintsUsed = max(0, hintsUsed)
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

    var maxAttempts: Int { attemptLimit }
    var hintsLeft: Int { max(0, hintLimit - hintsUsed) }
    var isSolved: Bool { !correct.isEmpty && locked.count == correct.count }
    var isFailed: Bool { !isSolved && attempts.count >= maxAttempts }
    var isFinished: Bool { isSolved || isFailed }
    var isFull: Bool { !slots.contains(where: { $0 == nil }) }

    /// Звёзды за решённую головоломку (для неразрешённой 0)
    var stars: Int {
        isSolved ? VersePuzzleLogic.stars(attempts: max(1, attempts.count), hints: hintsUsed) : 0
    }

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

    /// Подсказка: первая ещё не закреплённая ячейка получает верную плитку и закрепляется. Попытку не тратит
    @discardableResult
    mutating func useHint() -> Bool {
        guard !isFinished, hintsLeft > 0,
              let slot = correct.indices.first(where: { !locked.contains($0) }) else { return false }
        let needed = correct[slot]
        // Сначала плитка со стола, потом такая же из чужой незакреплённой ячейки
        var tile: Int? = poolTiles.first(where: { tray[$0] == needed })
        if tile == nil {
            tile = slots.indices.compactMap { index -> Int? in
                guard !locked.contains(index), let placed = slots[index], tray[placed] == needed else { return nil }
                return placed
            }.first
        }
        guard let found = tile else { return false }
        for index in slots.indices where !locked.contains(index) && slots[index] == found {
            slots[index] = nil
        }
        slots[slot] = found
        locked.insert(slot)
        hintsUsed += 1
        return true
    }
}

// MARK: Хранилище
/// Прогресс головоломок: решённые дни (серия), звёзды по уровням и незаконченные партии. Всё хранится на телефоне
final class VersePuzzleStore: ObservableObject {
    static let shared = VersePuzzleStore()

    /// Незаконченная или законченная партия одного уровня или дня
    struct Saved: Codable {
        var count: Int
        var attempts: [[Bool]]
        var locked: [Int]
        var hints: Int
        /// Сколько раз уровень начинали заново: от этого зависит порядок плиток
        var retry: Int
    }

    private let solvedKey = "verse_puzzle_solved_days_v1"
    private let starsKey = "verse_puzzle_level_stars_v1"
    private let releasedKey = "verse_puzzle_released_levels_v1"
    private let releasedAtKey = "verse_puzzle_released_at_v1"
    private let defaults = UserDefaults.standard

    @Published private(set) var solvedDays: Set<Int> = []
    /// Лучший результат по уровню: номер уровня → звёзды (1…3)
    @Published private(set) var levelStars: [Int: Int] = [:]
    /// Сколько первых уровней уже выдано бесплатной вкладке (пятёрками)
    @Published private(set) var releasedLevels: Int = 0
    /// Когда выдана последняя пятёрка
    @Published private(set) var releasedAt: Date? = nil

    private init() {
        let stored = defaults.array(forKey: solvedKey) as? [Int] ?? []
        solvedDays = Set(stored)
        releasedLevels = defaults.integer(forKey: releasedKey)
        releasedAt = defaults.object(forKey: releasedAtKey) as? Date
        let rawStars = defaults.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        for (key, value) in rawStars {
            if let level = Int(key), level > 0, value > 0 { levelStars[level] = min(3, value) }
        }
    }

    // MARK: Головоломка дня
    var totalSolved: Int { solvedDays.count }

    var isSolvedToday: Bool { solvedDays.contains(VersePuzzleLogic.dayNumber()) }

    /// Сколько дней подряд решена головоломка дня. Если сегодня ещё не решена, серия считается до вчера
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

    func markSolved(day: Int) {
        guard !solvedDays.contains(day) else { return }
        solvedDays.insert(day)
        defaults.set(solvedDays.sorted(), forKey: solvedKey)
    }

    // MARK: Уровни
    var completedLevels: Int { levelStars.count }

    var totalStars: Int { levelStars.values.reduce(0, +) }

    /// Первый ещё не пройденный уровень
    var nextLevel: Int {
        var level = 1
        while levelStars[level] != nil { level += 1 }
        return level
    }

    func stars(for level: Int) -> Int { levelStars[level] ?? 0 }

    /// Записывает результат уровня (остаётся лучший). Возвращает true, если уровень пройден впервые
    @discardableResult
    func recordStars(level: Int, stars: Int) -> Bool {
        guard level > 0, stars > 0 else { return false }
        let first = levelStars[level] == nil
        levelStars[level] = max(levelStars[level] ?? 0, min(3, stars))
        var raw: [String: Int] = [:]
        for (key, value) in levelStars { raw[String(key)] = value }
        defaults.set(raw, forKey: starsKey)
        return first
    }

    // MARK: Пятёрки бесплатной вкладки
    /// Самый дальний решённый уровень
    var highestSolvedLevel: Int { levelStars.keys.max() ?? 0 }

    /// Решены ли все выданные уровни
    private var allReleasedSolved: Bool {
        releasedLevels > 0 && (1...releasedLevels).allSatisfy { levelStars[$0] != nil }
    }

    private func setReleased(_ levels: Int, at date: Date) {
        releasedLevels = levels
        releasedAt = date
        defaults.set(levels, forKey: releasedKey)
        defaults.set(date, forKey: releasedAtKey)
    }

    /// Выдаёт следующую пятёрку, если решены все выданные и прошло два дня. Первый запуск: выдаётся первая пятёрка,
    /// а у тех, кто уже решал уровни, выданными остаются все решённые. Возвращает true, если выдана новая пятёрка
    @discardableResult
    func refreshReleases(poolCount: Int, now: Date = Date()) -> Bool {
        let size = VersePuzzleLogic.releaseSize
        guard poolCount > 0 else { return false }
        if releasedLevels == 0 {
            let rounded = ((highestSolvedLevel + size - 1) / size) * size
            setReleased(min(poolCount, max(size, rounded)), at: now)
            return false
        }
        guard releasedLevels < poolCount, allReleasedSolved else { return false }
        let since = releasedAt ?? Date.distantPast
        guard now.timeIntervalSince(since) >= VersePuzzleLogic.releaseInterval else { return false }
        setReleased(min(poolCount, releasedLevels + size), at: now)
        return true
    }

    /// Сколько осталось ждать следующую пятёрку; nil, если ждать нечего (не всё решено или всё уже выдано)
    func waitForNextRelease(poolCount: Int, now: Date = Date()) -> TimeInterval? {
        guard releasedLevels > 0, releasedLevels < poolCount, allReleasedSolved else { return nil }
        let since = releasedAt ?? Date.distantPast
        let left = VersePuzzleLogic.releaseInterval - now.timeIntervalSince(since)
        return left > 0 ? left : nil
    }

    /// Решено уровней в последней выданной пятёрке
    func solvedInCurrentRelease() -> Int {
        guard releasedLevels > 0 else { return 0 }
        let start = max(1, releasedLevels - VersePuzzleLogic.releaseSize + 1)
        return (start...releasedLevels).filter { levelStars[$0] != nil }.count
    }

    // MARK: Партии
    private func progressKey(_ id: String) -> String { "verse_puzzle_prog_v2_" + id }

    /// Сохранённая партия; если плиток стало другое число (сменилось издание текста), партия начинается заново, но счётчик повторов остаётся
    func progress(id: String, count: Int) -> Saved {
        let fresh = Saved(count: count, attempts: [], locked: [], hints: 0, retry: 0)
        guard let data = defaults.data(forKey: progressKey(id)),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return fresh }
        if saved.count == count { return saved }
        var reset = fresh
        reset.retry = saved.retry
        return reset
    }

    func save(id: String, _ saved: Saved) {
        if let data = try? JSONEncoder().encode(saved) {
            defaults.set(data, forKey: progressKey(id))
        }
    }
}

// MARK: Карточка на главном экране
struct VersePuzzleBannerCardView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    let onOpen: () -> Void

    @ObservedObject private var store = VersePuzzleStore.shared
    @ObservedObject private var subscription = SubscriptionManager.shared

    private var subtitle: String {
        let done = store.completedLevels
        if done > 0 {
            let stars = store.totalStars
            return language.pick(
                hy: "Անցած՝ \(done) · ★ \(stars)",
                ru: "Пройдено: \(done) · ★ \(stars)",
                en: "Completed: \(done) · ★ \(stars)"
            )
        }
        if subscription.isPremium {
            return language.pick(
                hy: "Հարյուրավոր համարներ՝ պարզից բարդ",
                ru: "Сотни стихов, от простых к сложным",
                en: "Hundreds of verses, from easy to hard"
            )
        }
        return language.pick(
            hy: "\(VersePuzzleLogic.releaseSize) համար ամեն 2 օրը՝ անվճար",
            ru: "\(VersePuzzleLogic.releaseSize) стихов каждые 2 дня бесплатно",
            en: "\(VersePuzzleLogic.releaseSize) free verses every 2 days"
        )
    }

    var body: some View {
        HomeFeatureCard(
            symbol: "puzzlepiece.extension.fill",
            label: language.pick(hy: "ԽԱՂ՝ ՀԱՎԱՔԵՔ ՀԱՄԱՐԸ", ru: "ИГРА: СОБЕРИ СТИХ", en: "GAME: VERSE PUZZLE"),
            labelColor: Paper.gold,
            title: language.pick(hy: "Հավաքեք համարը ըստ կարգի", ru: "Соберите стих по порядку", en: "Put the verse in order"),
            subtitle: subtitle,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryAccentColor,
            onOpen: onOpen
        )
    }
}

// MARK: Экран игры: уровни и головоломка дня
struct VersePuzzleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var store = VersePuzzleStore.shared
    @ObservedObject private var subscription = SubscriptionManager.shared

    @State private var pool: [BibleVerse] = []
    @State private var mode: PuzzleMode? = nil
    @State private var isShowingPaywall = false
    @State private var paywallSource = "puzzle"
    @State private var tab: PuzzleTab = .classic
    @State private var aiLoading = false
    @State private var aiUsedFallback = false
    @ObservedObject private var aiStore = AIPuzzleStore.shared
    @State private var didLoad = false
    @Environment(\.scenePhase) private var scenePhase

    private var language: AppLanguage { manager.appLanguage }
    private let packSize = 10

    var body: some View {
        ZStack {
            PaperBackground()

            if let current = mode {
                VersePuzzlePlayView(
                    mode: current,
                    pool: pool,
                    onExit: {
                        withAnimation(.easeInOut(duration: 0.2)) { mode = nil }
                    },
                    onNextLevel: { next in
                        if case .ai = current { openAILevel(next) } else { openLevel(next) }
                    },
                    canOpenLevel: { isOpen($0) }
                )
                .id(current.key)
            } else {
                hub
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(source: paywallSource)
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            pool = VersePuzzleLogic.levelPool(language: language)
            refreshReleases()
            Funnel.track("feature_used", ["feature": "puzzle_opened"])
            #if DEBUG || targetEnvironment(simulator)
            applyDebugLaunch()
            #endif
        }
        .onChange(of: manager.appLanguage) { newLanguage in
            pool = VersePuzzleLogic.levelPool(language: newLanguage)
            refreshReleases()
            mode = nil
        }
        .onChange(of: mode) { _ in
            refreshReleases()
            if tab == .ai { refillAILevelsIfNeeded() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { refreshReleases() }
        }
        .onChange(of: tab) { newTab in
            if newTab == .ai {
                Funnel.track("feature_used", ["feature": "puzzle_tab_ai"])
                refillAILevelsIfNeeded()
            }
        }
    }

    // MARK: Вход в уровень или в головоломку дня (с проверкой подписки)
    private func openLevel(_ level: Int) {
        guard level >= 1, level <= pool.count else { return }
        if !isOpen(level) {
            // Следующая пятёрка ещё не выдана: возвращаемся к списку, где написано, когда она откроется
            Haptics.notify(.warning)
            withAnimation(.easeInOut(duration: 0.2)) { mode = nil }
            return
        }
        Haptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.2)) { mode = .level(level) }
    }

    private func openDaily() {
        if !subscription.isPremium {
            lockedTapped()
            return
        }
        Haptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.2)) { mode = .daily }
    }

    private func lockedTapped() {
        Haptics.notify(.warning)
        Funnel.track("feature_used", ["feature": "puzzle_locked"])
        paywallSource = "puzzle"
        isShowingPaywall = true
    }

    /// Открыт ли уровень: подписчику все, остальным выданные пятёрки и уже решённые
    private func isOpen(_ level: Int) -> Bool {
        subscription.isPremium || level <= store.releasedLevels || store.stars(for: level) > 0
    }

    /// Сколько уровней показывать в списке: подписчику все, остальным выданные и уже решённые
    private var visibleCount: Int {
        if subscription.isPremium { return pool.count }
        return min(pool.count, max(store.releasedLevels, store.highestSolvedLevel))
    }

    /// Если пришло время, выдаёт следующую пятёрку
    private func refreshReleases() {
        guard !pool.isEmpty else { return }
        if store.refreshReleases(poolCount: pool.count) {
            Funnel.track("feature_used", ["feature": "puzzle_pack_next"])
        }
    }

    #if DEBUG || targetEnvironment(simulator)
    /// Для съёмки в CI (только симулятор и отладочная сборка): -puzzle_seed YES засевает четыре решённых уровня со звёздами,
    /// -puzzle_open daily|level|ai открывает головоломку дня, уровень (-puzzle_level N) или вкладку ИИ
    private func applyDebugLaunch() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "puzzle_seed") {
            for (index, value) in [3, 2, 3, 1].enumerated() {
                store.recordStars(level: index + 1, stars: value)
            }
            refreshReleases()
        }
        switch defaults.string(forKey: "puzzle_open") {
        case "daily": mode = .daily
        case "level": mode = .level(max(1, defaults.integer(forKey: "puzzle_level")))
        case "ai": tab = .ai
        default: break
        }
    }
    #endif

    /// Сколько ждать, по-человечески: «1 д 14 ч», «5 ч 20 мин», «12 мин»
    private func waitText(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(seconds / 60))
        let days = minutes / (24 * 60)
        let hours = (minutes % (24 * 60)) / 60
        let mins = minutes % 60
        if days > 0 {
            return language.pick(hy: "\(days) օր \(hours) ժ", ru: "\(days) д \(hours) ч", en: "\(days) d \(hours) h")
        }
        if hours > 0 {
            return language.pick(hy: "\(hours) ժ \(mins) ր", ru: "\(hours) ч \(mins) мин", en: "\(hours) h \(mins) min")
        }
        return language.pick(hy: "\(mins) ր", ru: "\(mins) мин", en: "\(mins) min")
    }

    // MARK: ИИ-уровни: открыть и догрузить
    private func openAILevel(_ level: Int) {
        guard subscription.isPremium else { return }
        guard aiStore.reference(forLevel: level) != nil else {
            // Уровень ещё не загружен: возвращаемся к списку, пока подбирается следующая пачка
            withAnimation(.easeInOut(duration: 0.2)) { mode = nil }
            refillAILevelsIfNeeded()
            return
        }
        Haptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.2)) { mode = .ai(level) }
        // Пока человек играет, следующая пачка догружается в фоне
        refillAILevelsIfNeeded()
    }

    /// Догружает пачку ИИ-уровней, если впереди осталось мало; один запрос за раз
    private func refillAILevelsIfNeeded() {
        guard subscription.isPremium, !aiLoading, aiStore.needsRefill else { return }
        aiLoading = true
        let requestLanguage = language
        Task { @MainActor in
            let result = await AIPuzzleService.loadNextBatch(language: requestLanguage)
            aiLoading = false
            aiUsedFallback = !result.usedAI
        }
    }

    // MARK: Главная страница игры
    private var hub: some View {
        VStack(spacing: 0) {
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

                Text(language.pick(hy: "Հավաքեք համարը", ru: "Собери стих", en: "Verse Puzzle"))
                    .font(PaperFont.font(size: 18, weight: .semibold))
                    .foregroundColor(Paper.ink)

                Spacer()

                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Picker("", selection: $tab) {
                Text(language.pick(hy: "Դասական", ru: "Классика", en: "Classic")).tag(PuzzleTab.classic)
                Text(language.pick(hy: "ԱԲ", ru: "ИИ", en: "AI")).tag(PuzzleTab.ai)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if tab == .classic {
                        summaryCard
                        if !subscription.isPremium {
                            releaseCard
                        }
                        continueButton
                        dailyCard
                        levelsSection
                    } else if subscription.isPremium {
                        aiPremiumView
                    } else {
                        aiTab
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(
                value: "★ \(store.totalStars)",
                caption: language.pick(hy: "աստղ", ru: "звёзд", en: "stars")
            )
            Divider().frame(height: 34).opacity(0.5)
            summaryItem(
                value: "\(store.completedLevels) / \(visibleCount)",
                caption: language.pick(hy: "մակարդակ անցած", ru: "уровней пройдено", en: "levels completed")
            )
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 18)
    }

    private func summaryItem(value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PaperFont.font(size: 22, weight: .semibold).monospacedDigit())
                .foregroundColor(Paper.gold)
            Text(caption)
                .font(PaperFont.font(size: 12, weight: .medium))
                .foregroundColor(Paper.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
        let next = store.nextLevel
        let allDone = !pool.isEmpty && next > pool.count
        // Следующая пятёрка ещё не выдана: кнопка показывает, сколько осталось ждать
        let waiting = !allDone && !pool.isEmpty && !isOpen(next)
        let wait = store.waitForNextRelease(poolCount: pool.count) ?? 60
        let label: String
        if allDone {
            label = language.pick(hy: "Բոլոր մակարդակներն անցած են", ru: "Все уровни пройдены", en: "All levels completed")
        } else if waiting {
            label = language.pick(hy: "Հաջորդ հնգյակը՝ \(waitText(wait)) հետո", ru: "Следующая пятёрка через \(waitText(wait))", en: "Next set in \(waitText(wait))")
        } else {
            label = language.pick(hy: "Շարունակել · մակարդակ \(next)", ru: "Продолжить · уровень \(next)", en: "Continue · level \(next)")
        }
        return Button {
            if allDone || waiting { return }
            openLevel(next)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: allDone ? "checkmark.seal.fill" : (waiting ? "clock.fill" : "play.fill"))
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(PaperFont.font(size: 16, weight: .semibold))
            }
            .foregroundColor(Paper.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Paper.accentFill)
            .cornerRadius(16)
            .opacity(pool.isEmpty ? 0.4 : (waiting ? 0.6 : 1))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(pool.isEmpty || waiting)
    }

    private var dailyCard: some View {
        let day = VersePuzzleLogic.dayNumber()
        let streak = store.streak
        let subtitle: String
        if store.isSolvedToday {
            subtitle = streak >= 2
                ? language.pick(hy: "Այսօր լուծված է · շարք՝ \(streak) օր", ru: "Решено сегодня · серия \(streak) дн.", en: "Solved today · \(streak) day streak")
                : language.pick(hy: "Այսօր լուծված է", ru: "Решено сегодня", en: "Solved today")
        } else {
            subtitle = language.pick(hy: "Նոր համար ամեն օր", ru: "Новый стих каждый день", en: "A new verse every day")
        }
        return Button {
            openDaily()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Paper.gold)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.pick(hy: "Օրվա հանելուկ №\(day)", ru: "Головоломка дня №\(day)", en: "Puzzle of the day #\(day)"))
                        .font(PaperFont.font(size: 15, weight: .semibold))
                        .foregroundColor(Paper.ink)
                    Text(subtitle)
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                }

                Spacer(minLength: 8)

                if subscription.isPremium {
                    Image(systemName: store.isSolvedToday ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(store.isSolvedToday ? Paper.moss : Paper.inkTertiary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Paper.gold)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .paperSheet(cornerRadius: 18)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Пятёрка бесплатной вкладки: сколько решено и когда придёт следующая
    private var releaseCard: some View {
        let size = VersePuzzleLogic.releaseSize
        let solved = store.solvedInCurrentRelease()
        let number = max(1, (store.releasedLevels + size - 1) / size)
        let wait = store.waitForNextRelease(poolCount: pool.count)
        let allReleased = !pool.isEmpty && store.releasedLevels >= pool.count
        let status: String
        if allReleased {
            status = language.pick(hy: "Բոլոր համարներն արդեն բացված են", ru: "Все стихи уже открыты", en: "All verses are unlocked")
        } else if let wait = wait {
            status = language.pick(
                hy: "Հաջորդ \(size) համարը կբացվի \(waitText(wait)) հետո",
                ru: "Следующие \(size) стихов откроются через \(waitText(wait))",
                en: "The next \(size) verses unlock in \(waitText(wait))"
            )
        } else {
            status = language.pick(
                hy: "Լուծված է \(solved)՝ \(size)-ից։ Լուծեք բոլորը՝ հաջորդը ստանալու համար",
                ru: "Решено \(solved) из \(size). Решите все, чтобы получить следующие",
                en: "\(solved) of \(size) solved. Solve them all to unlock the next set"
            )
        }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(language.pick(hy: "Հնգյակ №\(number)", ru: "Пятёрка №\(number)", en: "Set #\(number)"))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(Paper.ink)

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    ForEach(0..<size, id: \.self) { index in
                        Circle()
                            .fill(index < solved ? Paper.gold : Paper.hairline)
                            .frame(width: 10, height: 10)
                    }
                }
            }

            Text(status)
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Paper.gold.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Paper.gold.opacity(0.3), lineWidth: 1.2))
    }

    // MARK: Вкладка «ИИ» без подписки: что это и кнопка Premium
    private var aiTab: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Paper.gold)
                    Text(language.pick(hy: "ԱԲ մակարդակներ", ru: "ИИ-уровни", en: "AI levels"))
                        .font(PaperFont.font(size: 18, weight: .semibold))
                        .foregroundColor(Paper.ink)
                }

                aiPoint(language.pick(
                    hy: "ԱԲ-ն ինքն է ընտրում համարները ողջ Աստվածաշնչից",
                    ru: "ИИ сам подбирает стихи по всей Библии",
                    en: "AI picks verses from the whole Bible"
                ))
                aiPoint(language.pick(
                    hy: "Որքան առաջ, այնքան դժվար մակարդակներ",
                    ru: "Чем дальше, тем сложнее уровни",
                    en: "The further you go, the harder the levels"
                ))
                aiPoint(language.pick(
                    hy: "Մտնում է Luys Premium բաժանորդագրության մեջ",
                    ru: "Входит в подписку Luys Premium",
                    en: "Included with Luys Premium"
                ))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperSheet(cornerRadius: 18)

            Button {
                Haptics.impact(.light)
                paywallSource = "puzzle_ai"
                isShowingPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(language.pick(hy: "Բացել Premium-ը", ru: "Открыть Premium", en: "Unlock Premium"))
                        .font(PaperFont.font(size: 16, weight: .semibold))
                }
                .foregroundColor(Paper.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Paper.accentFill)
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func aiPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Paper.moss)
                .padding(.top, 2)
            Text(text)
                .font(PaperFont.font(size: 14))
                .foregroundColor(Paper.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Вкладка «ИИ» у подписчика: уровни по ступеням, загрузка пачек
    private var aiPremiumView: some View {
        VStack(spacing: 16) {
            aiSummaryCard
            aiContinueButton
            if aiUsedFallback {
                Text(language.pick(
                    hy: "ԱԲ-ն այժմ հասանելի չէ. համարներն ընտրվել են առանց դրա",
                    ru: "ИИ сейчас недоступен: стихи подобраны без него",
                    en: "AI is unavailable right now: the verses were picked without it"
                ))
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            aiLevelsSection
        }
    }

    private var aiSummaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(
                value: "★ \(aiStore.totalStars)",
                caption: language.pick(hy: "աստղ", ru: "звёзд", en: "stars")
            )
            Divider().frame(height: 34).opacity(0.5)
            summaryItem(
                value: "\(aiStore.completedLevels) / \(aiStore.loadedLevels)",
                caption: language.pick(hy: "մակարդակ անցած", ru: "уровней пройдено", en: "levels completed")
            )
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 18)
    }

    private var aiContinueButton: some View {
        let next = aiStore.nextLevel
        let ready = aiStore.reference(forLevel: next) != nil
        let label: String
        if aiLoading {
            label = language.pick(hy: "Ընտրվում են համարներ…", ru: "Подбираю стихи…", en: "Picking verses…")
        } else if ready {
            label = language.pick(hy: "Շարունակել · մակարդակ \(next)", ru: "Продолжить · уровень \(next)", en: "Continue · level \(next)")
        } else {
            label = language.pick(hy: "Բեռնել մակարդակները", ru: "Загрузить уровни", en: "Load levels")
        }
        return Button {
            if ready {
                openAILevel(next)
            } else {
                refillAILevelsIfNeeded()
            }
        } label: {
            HStack(spacing: 8) {
                if aiLoading {
                    ProgressView()
                        .tint(Paper.onAccent)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(label)
                    .font(PaperFont.font(size: 16, weight: .semibold))
            }
            .foregroundColor(Paper.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Paper.accentFill)
            .cornerRadius(16)
            .opacity(aiLoading ? 0.6 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(aiLoading)
    }

    private var aiLevelsSection: some View {
        let tierCount = (aiStore.loadedLevels + AIPuzzleLogic.levelsPerTier - 1) / AIPuzzleLogic.levelsPerTier
        return VStack(alignment: .leading, spacing: 14) {
            Text(language.pick(hy: "ՄԱԿԱՐԴԱԿՆԵՐ", ru: "УРОВНИ", en: "LEVELS"))
                .font(PaperFont.font(size: 11, weight: .semibold))
                .foregroundColor(Paper.inkSecondary)
                .tracking(1.0)

            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(0..<tierCount, id: \.self) { index in
                    aiTierView(index)
                }
            }
        }
    }

    private func aiTierView(_ index: Int) -> some View {
        let size = AIPuzzleLogic.levelsPerTier
        let start = index * size + 1
        let end = min(aiStore.loadedLevels, start + size - 1)
        let tier = AIPuzzleLogic.tier(forLevel: start)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        return VStack(alignment: .leading, spacing: 8) {
            Text(language.pick(
                hy: "Աստիճան \(tier.number) · \(tier.minWords)–\(tier.maxWords) բառ",
                ru: "Ступень \(tier.number) · \(tier.minWords)–\(tier.maxWords) слов",
                en: "Step \(tier.number) · \(tier.minWords)–\(tier.maxWords) words"
            ))
            .font(PaperFont.font(size: 12, weight: .semibold))
            .foregroundColor(Paper.inkSecondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(start...end, id: \.self) { level in
                    aiLevelCell(level)
                }
            }
        }
    }

    private func aiLevelCell(_ level: Int) -> some View {
        let stars = aiStore.stars(for: level)
        let isNext = level == aiStore.nextLevel
        return Button {
            openAILevel(level)
        } label: {
            VStack(spacing: 4) {
                Text("\(level)")
                    .font(PaperFont.font(size: 17, weight: .semibold).monospacedDigit())
                    .foregroundColor(Paper.ink)

                HStack(spacing: 1) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= stars ? "star.fill" : "star")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(index <= stars ? Paper.gold : Paper.inkTertiary.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stars > 0 ? Paper.gold.opacity(0.16) : Paper.sheet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isNext ? Paper.gold : Paper.hairline, lineWidth: isNext ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Уровни пачками по десять
    private var levelsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.pick(hy: "ՄԱԿԱՐԴԱԿՆԵՐ", ru: "УРОВНИ", en: "LEVELS"))
                .font(PaperFont.font(size: 11, weight: .semibold))
                .foregroundColor(Paper.inkSecondary)
                .tracking(1.0)

            if pool.isEmpty {
                Text(language.pick(
                    hy: "Մակարդակները հասանելի չեն",
                    ru: "Уровни сейчас недоступны",
                    en: "Levels are not available right now"
                ))
                .font(PaperFont.font(size: 13))
                .foregroundColor(Paper.inkSecondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<packCount, id: \.self) { pack in
                        packView(pack)
                    }
                }
            }
        }
    }

    private var packCount: Int {
        (visibleCount + packSize - 1) / packSize
    }

    private func packView(_ pack: Int) -> some View {
        let start = pack * packSize + 1
        let end = min(visibleCount, start + packSize - 1)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        return VStack(alignment: .leading, spacing: 8) {
            Text(language.pick(
                hy: "Մակարդակներ \(start)–\(end)",
                ru: "Уровни \(start)–\(end)",
                en: "Levels \(start)–\(end)"
            ))
            .font(PaperFont.font(size: 12, weight: .semibold))
            .foregroundColor(Paper.inkSecondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(start...end, id: \.self) { level in
                    levelCell(level)
                }
            }
        }
    }

    private func levelCell(_ level: Int) -> some View {
        let stars = store.stars(for: level)
        let isLocked = !isOpen(level)
        let isNext = level == store.nextLevel
        return Button {
            openLevel(level)
        } label: {
            VStack(spacing: 4) {
                Text("\(level)")
                    .font(PaperFont.font(size: 17, weight: .semibold).monospacedDigit())
                    .foregroundColor(Paper.ink)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Paper.gold)
                } else {
                    HStack(spacing: 1) {
                        ForEach(1...3, id: \.self) { index in
                            Image(systemName: index <= stars ? "star.fill" : "star")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(index <= stars ? Paper.gold : Paper.inkTertiary.opacity(0.6))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stars > 0 ? Paper.gold.opacity(0.16) : Paper.sheet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isNext && !isLocked ? Paper.gold : Paper.hairline, lineWidth: isNext && !isLocked ? 1.5 : 1)
            )
            .opacity(isLocked ? 0.6 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: Экран одного уровня или головоломки дня
struct VersePuzzlePlayView: View {
    let mode: PuzzleMode
    let pool: [BibleVerse]
    let onExit: () -> Void
    let onNextLevel: (Int) -> Void
    /// Открыт ли уровень: бесплатному игроку после последнего уровня пятёрки кнопки «Следующий уровень» нет
    let canOpenLevel: (Int) -> Bool

    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var store = VersePuzzleStore.shared

    @ObservedObject private var aiStore = AIPuzzleStore.shared
    @State private var board: VersePuzzleBoard? = nil
    @State private var verse: BibleVerse? = nil
    @State private var day = VersePuzzleLogic.dayNumber()
    @State private var retry = 0
    @State private var didLoad = false

    private var language: AppLanguage { manager.appLanguage }

    private var progressId: String {
        switch mode {
        case .daily: return "daily_\(day)_\(language.rawValue)"
        case .level(let number): return "level_\(number)_\(language.rawValue)"
        case .ai(let number): return "ai_level_\(number)_\(language.rawValue)"
        }
    }

    private enum ChipStyle {
        case tray
        case placed
        case locked
    }

    var body: some View {
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
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            load()
        }
    }

    // MARK: Верх экрана
    private var title: String {
        switch mode {
        case .daily:
            return language.pick(hy: "Օրվա հանելուկ №\(day)", ru: "Головоломка дня №\(day)", en: "Puzzle of the day #\(day)")
        case .level(let number):
            return language.pick(hy: "Մակարդակ \(number)", ru: "Уровень \(number)", en: "Level \(number)")
        case .ai(let number):
            return language.pick(hy: "ԱԲ մակարդակ \(number)", ru: "ИИ-уровень \(number)", en: "AI level \(number)")
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                onExit()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Paper.ink.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Text(title)
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
            hy: "Այս հանելուկը հասանելի չէ։",
            ru: "Эта головоломка сейчас недоступна.",
            en: "This puzzle is not available right now."
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
        HStack(spacing: 10) {
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

            if !current.isFinished && current.hintLimit > 0 {
                hintButton(for: current)
            }

            if case .daily = mode, store.streak > 0 {
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

    private func hintButton(for current: VersePuzzleBoard) -> some View {
        let enabled = current.hintsLeft > 0
        return Button {
            useHint()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(language.pick(
                    hy: "Հուշում · \(current.hintsLeft)",
                    ru: "Подсказка · \(current.hintsLeft)",
                    en: "Hint · \(current.hintsLeft)"
                ))
                .font(PaperFont.font(size: 13, weight: .semibold))
            }
            .foregroundColor(enabled ? Paper.gold : Paper.inkTertiary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Paper.gold.opacity(enabled ? 0.12 : 0.04)))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!enabled)
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

            if mode.isLevel && current.hintLimit > 0 {
                Text(language.pick(
                    hy: "Յուրաքանչյուր հուշում հանում է մեկ աստղ",
                    ru: "Каждая подсказка отнимает одну звезду",
                    en: "Each hint costs one star"
                ))
                .font(PaperFont.font(size: 11, weight: .medium))
                .foregroundColor(Paper.inkTertiary)
            }

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
    @ViewBuilder
    private func finishCard(for current: VersePuzzleBoard) -> some View {
        switch mode {
        case .daily:
            dailyFinishCard(for: current)
        case .level(let number):
            levelFinishCard(for: current, level: number)
        case .ai(let number):
            levelFinishCard(for: current, level: number)
        }
    }

    private var verseBlock: some View {
        Group {
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
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PaperFont.font(size: 16, weight: .semibold))
                .foregroundColor(Paper.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Paper.accentFill)
                .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PaperFont.font(size: 15, weight: .semibold))
                .foregroundColor(Paper.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .paperField(cornerRadius: 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func levelFinishCard(for current: VersePuzzleBoard, level: Int) -> some View {
        let stars = current.stars
        return VStack(spacing: 14) {
            if current.isSolved {
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= stars ? "star.fill" : "star")
                            .font(.system(size: 30))
                            .foregroundColor(index <= stars ? Paper.gold : Paper.inkTertiary.opacity(0.5))
                    }
                }
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Paper.gold)
            }

            Text(current.isSolved
                 ? language.pick(
                    hy: "Մակարդակն անցած է։ Փորձ՝ \(max(1, current.attempts.count))",
                    ru: "Уровень пройден! Попыток: \(max(1, current.attempts.count))",
                    en: "Level complete! Attempts: \(max(1, current.attempts.count))")
                 : language.pick(
                    hy: "Այս անգամ չստացվեց։ Ահա այդ համարը՝",
                    ru: "Не вышло. Вот этот стих:",
                    en: "Not this time. Here is the verse:"))
                .font(PaperFont.font(size: 17, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)

            verseBlock

            if current.isSolved {
                if hasNextLevel(after: level) {
                    primaryButton(language.pick(hy: "Հաջորդ մակարդակ", ru: "Следующий уровень", en: "Next level")) {
                        onNextLevel(level + 1)
                    }
                }
                secondaryButton(language.pick(hy: "Նորից խաղալ", ru: "Играть заново", en: "Play again")) {
                    restart()
                }
            } else {
                primaryButton(language.pick(hy: "Փորձել նորից", ru: "Попробовать снова", en: "Try again")) {
                    restart()
                }
            }

            secondaryButton(language.pick(hy: "Մակարդակներին", ru: "К уровням", en: "All levels")) {
                onExit()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
    }

    private func dailyFinishCard(for current: VersePuzzleBoard) -> some View {
        VStack(spacing: 14) {
            Image(systemName: current.isSolved ? "checkmark.seal.fill" : "book.closed.fill")
                .font(.system(size: 34))
                .foregroundColor(current.isSolved ? Paper.moss : Paper.gold)

            Text(dailyFinishTitle(for: current))
                .font(PaperFont.font(size: 17, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)

            verseBlock

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

            secondaryButton(language.pick(hy: "Մակարդակներին", ru: "К уровням", en: "All levels")) {
                onExit()
            }

            Text(language.pick(hy: "Նոր հանելուկը՝ վաղը", ru: "Новая головоломка завтра", en: "A new puzzle tomorrow"))
                .font(PaperFont.font(size: 12, weight: .medium))
                .foregroundColor(Paper.inkSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
    }

    private func dailyFinishTitle(for current: VersePuzzleBoard) -> String {
        if current.isSolved {
            let used = max(1, current.attempts.count)
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
        let score = current.isSolved ? "\(max(1, current.attempts.count))/\(current.maxAttempts)" : "X/\(current.maxAttempts)"
        let link = "https://apps.apple.com/app/id\(ReviewManager.shared.appStoreID)"
        return "\(header) \(score)\n\(rows)\n\(link)"
    }

    /// Есть ли куда идти дальше: у классики пока не кончился список и следующий уровень открыт, у ИИ уровни догружаются сами
    private func hasNextLevel(after level: Int) -> Bool {
        if case .ai = mode { return true }
        return level < pool.count && canOpenLevel(level + 1)
    }

    /// Попытки и подсказки партии: у ИИ-уровня их задаёт ступень, у остальных обычные
    private var limits: (attempts: Int, hints: Int) {
        if case .ai(let number) = mode {
            let tier = AIPuzzleLogic.tier(forLevel: number)
            return (tier.attempts, tier.hints)
        }
        return (VersePuzzleLogic.maxAttempts, VersePuzzleLogic.maxHints)
    }

    // MARK: Действия
    private func placeTile(_ tile: Int) {
        board?.place(tile)
    }

    private func removeTile(at slot: Int) {
        board?.remove(slot: slot)
    }

    /// Стих и число плиток для текущей партии: у дня своё правило, у уровня своё
    private func makeSetup() -> (verse: BibleVerse, tiles: Int, seedBase: Int)? {
        switch mode {
        case .daily:
            guard let chosen = VersePuzzleLogic.verse(forDay: day, language: language) else { return nil }
            return (chosen, VersePuzzleLogic.maxTiles, day)
        case .level(let number):
            guard pool.indices.contains(number - 1) else { return nil }
            return (pool[number - 1], VersePuzzleLogic.tileCount(forLevel: number), number * 100)
        case .ai(let number):
            guard let reference = aiStore.reference(forLevel: number),
                  let chosen = AIPuzzleLogic.verse(for: reference) else { return nil }
            return (chosen, AIPuzzleLogic.tier(forLevel: number).tiles, 1_000_000 + number * 100)
        }
    }

    private func load() {
        day = VersePuzzleLogic.dayNumber()
        guard let chosen = makeSetup() else { return }
        let correct = VersePuzzleLogic.chunks(of: chosen.verse.text(for: language), maxTiles: chosen.tiles)
        guard correct.count >= 3 else { return }
        let saved = store.progress(id: progressId, count: correct.count)
        retry = saved.retry
        verse = chosen.verse
        board = VersePuzzleBoard(
            correct: correct,
            tray: VersePuzzleLogic.shuffled(correct, seed: chosen.seedBase + saved.retry),
            attempts: saved.attempts,
            locked: Set(saved.locked),
            hintsUsed: saved.hints,
            attemptLimit: limits.attempts,
            hintLimit: limits.hints
        )
        #if DEBUG || targetEnvironment(simulator)
        applyDebugDemo()
        #endif
    }

    #if DEBUG || targetEnvironment(simulator)
    /// Для съёмки в CI (только симулятор и отладочная сборка): -puzzle_hints N закрепляет N первых слов,
    /// -puzzle_place M кладёт на стол ещё M верных плиток, чтобы партия выглядела начатой (с большим M кладутся все),
    /// -puzzle_submit YES после этого нажимает «Проверить»
    private func applyDebugDemo() {
        guard var current = board else { return }
        let defaults = UserDefaults.standard
        for _ in 0..<max(0, defaults.integer(forKey: "puzzle_hints")) {
            _ = current.useHint()
        }
        for _ in 0..<max(0, defaults.integer(forKey: "puzzle_place")) {
            guard let slot = current.slots.firstIndex(where: { $0 == nil }),
                  let tile = current.poolTiles.first(where: { current.tray[$0] == current.correct[slot] }) else { break }
            current.place(tile)
        }
        // -puzzle_submit YES проверяет расстановку: верные слова закрепляются, и если все на месте, головоломка решена
        if defaults.bool(forKey: "puzzle_submit") {
            _ = current.submit()
        }
        board = current
    }
    #endif

    /// Уровень начинается заново: другой порядок плиток, попытки и подсказки с нуля (лучшие звёзды остаются)
    private func restart() {
        guard let current = board else { return }
        Haptics.impact(.light)
        store.save(id: progressId, VersePuzzleStore.Saved(count: current.correct.count, attempts: [], locked: [], hints: 0, retry: retry + 1))
        withAnimation(.easeInOut(duration: 0.2)) {
            load()
        }
    }

    private func persist(_ updated: VersePuzzleBoard) {
        store.save(
            id: progressId,
            VersePuzzleStore.Saved(
                count: updated.correct.count,
                attempts: updated.attempts,
                locked: updated.locked.sorted(),
                hints: updated.hintsUsed,
                retry: retry
            )
        )
    }

    private func useHint() {
        guard var updated = board else { return }
        guard updated.useHint() else { return }
        Haptics.impact(.medium)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            board = updated
        }
        persist(updated)
        if updated.isSolved {
            finished(updated)
        }
    }

    private func submit() {
        guard var updated = board else { return }
        guard let result = updated.submit() else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            board = updated
        }
        persist(updated)

        if updated.isSolved {
            finished(updated)
        } else if updated.isFailed {
            Haptics.notify(.error)
            Funnel.track("feature_used", ["feature": "puzzle_failed"])
        } else {
            Haptics.notify(result.contains(true) ? .success : .warning)
        }
    }

    /// Головоломка решена: запоминаем результат и кормим Гранатовое древо (за уровень только при первом прохождении)
    private func finished(_ solved: VersePuzzleBoard) {
        Haptics.notify(.success)
        switch mode {
        case .daily:
            store.markSolved(day: day)
            PomegranateTreeManager.shared.record(.plan)
            Funnel.track("feature_used", ["feature": "puzzle_solved"])
        case .level(let number):
            let isFirst = store.recordStars(level: number, stars: solved.stars)
            if isFirst {
                PomegranateTreeManager.shared.record(.plan)
            }
            Funnel.track("feature_used", ["feature": "puzzle_level_won"])
        case .ai(let number):
            let isFirst = aiStore.recordStars(level: number, stars: solved.stars)
            if isFirst {
                PomegranateTreeManager.shared.record(.plan)
            }
            Funnel.track("feature_used", ["feature": "puzzle_ai_level_won"])
        }
    }
}
