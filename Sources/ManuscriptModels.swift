import SwiftUI
import UIKit

// MARK: - «Рукопись»: личная страница армянского манускрипта
// Пользователь выбирает стих, и на экране оживает страница рукописи в духе миниатюр Тороса Рослина:
// перо выводит текст, распускаются заставка и буквица, сусальное золото бликует при наклоне телефона,
// а внизу появляется памятная запись (հիշատակարան) с именем и годом по армянскому летоисчислению.

/// Тексты интерфейса «Рукописи» на трёх языках
enum ManuscriptText {
    static func pick(_ language: AppLanguage, hy: String, ru: String, en: String) -> String {
        switch language {
        case .armenian: return hy
        case .russian: return ru
        case .english: return en
        }
    }
}

// MARK: - Стиль миниатюры
enum ManuscriptStyle: String, CaseIterable, Identifiable, Codable {
    /// Ляпис и киноварь, павлины у креста — школа Тороса Рослина (XIII век)
    case roslin
    /// Багряное поле и гранаты — киликийские рукописи
    case cilicia
    /// Глубокая зелень и птицы — в память о Нарекском монастыре
    case narek

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .roslin: return ManuscriptText.pick(language, hy: "Ռոսլին", ru: "Рослин", en: "Roslin")
        case .cilicia: return ManuscriptText.pick(language, hy: "Կիլիկիա", ru: "Киликия", en: "Cilicia")
        case .narek: return ManuscriptText.pick(language, hy: "Նարեկ", ru: "Нарек", en: "Narek")
        }
    }

    var palette: ManuscriptPalette {
        switch self {
        case .roslin: return .roslin
        case .cilicia: return .cilicia
        case .narek: return .narek
        }
    }

    /// Над заставкой: птицы у креста или гранаты
    var hasBirds: Bool { self != .cilicia }
}

// MARK: - Пигменты страницы
/// Страница всегда светлая (это пергамент), поэтому цвета не зависят от тёмной темы.
struct ManuscriptPalette {
    let parchment: UInt32
    let parchmentEdge: UInt32
    let ink: UInt32
    let rubric: UInt32
    let field: UInt32
    let fieldAccent: UInt32
    let leaf: UInt32
    let goldDark: UInt32
    let gold: UInt32
    let goldLight: UInt32
    let goldHighlight: UInt32
    let pearl: UInt32

    static let roslin = ManuscriptPalette(
        parchment: 0xF2E8CF, parchmentEdge: 0xD3BB8E, ink: 0x2A1C12, rubric: 0xA8291F,
        field: 0x1E3F7C, fieldAccent: 0xA8291F, leaf: 0x3C6B4B,
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFAE6A6, pearl: 0xFBF5E6
    )

    static let cilicia = ManuscriptPalette(
        parchment: 0xF3E6CB, parchmentEdge: 0xD6BA88, ink: 0x2B1A12, rubric: 0x9E2420,
        field: 0x7A1A22, fieldAccent: 0x1E3F7C, leaf: 0x2F5E52,
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFAE6A6, pearl: 0xFBF5E6
    )

    static let narek = ManuscriptPalette(
        parchment: 0xEEE3C8, parchmentEdge: 0xC9B286, ink: 0x2C2217, rubric: 0x8E3A22,
        field: 0x24483A, fieldAccent: 0x8A2A22, leaf: 0x5B7A3A,
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFAE6A6, pearl: 0xFBF5E6
    )

    static func color(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        PomegranatePalette.color(hex, alpha)
    }

    static func uiColor(_ hex: UInt32, _ alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Страница рукописи (то, что рисуется и хранится в «Матенадаране»)
struct ManuscriptPage: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let reference: String
    let language: AppLanguage
    var style: ManuscriptStyle
    /// Основа листа; у страниц, сохранённых до появления основ, поля нет — это пергамент
    var surfaceChoice: ManuscriptSurface?
    var name: String
    let createdAt: Date
    /// Подпись владельца под листом в «Матенадаране»; на самой странице не рисуется
    var note: String?
    /// Место листа в книге; пока не задано, лист стоит по времени создания
    var position: Double?

    init(
        id: UUID = UUID(),
        text: String,
        reference: String,
        language: AppLanguage,
        style: ManuscriptStyle = .roslin,
        surface: ManuscriptSurface = ManuscriptSurface.effective,
        name: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.reference = reference
        self.language = language
        self.style = style
        self.surfaceChoice = surface
        self.name = name
        self.createdAt = createdAt
    }

    var surface: ManuscriptSurface {
        get { surfaceChoice ?? .parchment }
        set { surfaceChoice = newValue }
    }

    /// Ключ порядка в книге: заданное место или время создания (оба числа в одной шкале)
    var sortKey: Double { position ?? createdAt.timeIntervalSince1970 }

    /// Стиль миниатюры и основа вместе: от них зависят все цвета страницы
    var look: ManuscriptLook { ManuscriptLook(style: style, surface: surface) }

    /// Имя для памятной записи берётся из прошлого раза
    static var rememberedName: String {
        UserDefaults.standard.string(forKey: "luys_manuscript_name") ?? ""
    }

    /// Стиль, выбранный в прошлый раз
    static var preferredStyle: ManuscriptStyle {
        ManuscriptStyle(rawValue: UserDefaults.standard.string(forKey: "luys_manuscript_style") ?? "") ?? .roslin
    }

    static func from(verse: BibleVerse, language: AppLanguage) -> ManuscriptPage {
        ManuscriptPage(
            text: verse.text(for: language),
            reference: verse.reference(for: language),
            language: language,
            style: preferredStyle,
            name: rememberedName
        )
    }

    static func from(book: BibleBook, chapter: Int, verse: BibleVerseText, language: AppLanguage) -> ManuscriptPage {
        let bookName: String
        switch language {
        case .armenian: bookName = book.nameHy
        case .russian: bookName = book.nameRu
        case .english: bookName = book.nameEn
        }
        return ManuscriptPage(
            text: verse.text(for: language),
            reference: "\(bookName) \(chapter):\(verse.verseNumber)",
            language: language,
            style: preferredStyle,
            name: rememberedName
        )
    }

    /// Буквица и остальной текст. Ведущие кавычки и пробелы отбрасываются.
    var initialAndBody: (initial: String, body: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = trimmed.firstIndex(where: { $0.isLetter }) else {
            return ("", trimmed)
        }
        let letter = String(trimmed[index])
        let upper = letter.uppercased()
        // «և» в верхнем регистре превращается в две буквы — тогда оставляем как есть
        let initial = upper.count == 1 ? upper : letter
        let body = String(trimmed[trimmed.index(after: index)...])
        return (initial, body)
    }

    /// Стабильное зерно для рисунка пергамента: один и тот же стих — одни и те же волокна
    var seed: UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in (text + reference).utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return hash
    }
}

// MARK: - Армянские буквенные цифры и армянское летоисчисление
enum ArmenianNumerals {
    private static let units = ["", "Ա", "Բ", "Գ", "Դ", "Ե", "Զ", "Է", "Ը", "Թ"]
    private static let tens = ["", "Ժ", "Ի", "Լ", "Խ", "Ծ", "Կ", "Հ", "Ձ", "Ղ"]
    private static let hundreds = ["", "Ճ", "Մ", "Յ", "Ն", "Շ", "Ո", "Չ", "Պ", "Ջ"]
    private static let thousands = ["", "Ռ", "Ս", "Վ", "Տ", "Ր", "Ց", "Ւ", "Փ", "Ք"]

    /// 1475 → «ՌՆՀԵ»
    static func string(_ number: Int) -> String {
        guard number > 0, number < 10_000 else { return String(number) }
        return thousands[number / 1000] + hundreds[(number / 100) % 10] + tens[(number / 10) % 10] + units[number % 10]
    }

    /// Год армянского летоисчисления (эра от 552 года): 2026 → 1475
    static func armenianEraYear(for date: Date) -> Int {
        Calendar(identifier: .gregorian).component(.year, from: date) - 551
    }
}

// MARK: - Памятная запись внизу страницы
extension ManuscriptPage {
    var colophonLines: (opening: String, name: String, date: String) {
        let gregorianYear = Calendar(identifier: .gregorian).component(.year, from: createdAt)
        let eraYear = ArmenianNumerals.armenianEraYear(for: createdAt)
        let letters = ArmenianNumerals.string(eraYear)
        let opening = ManuscriptText.pick(language, hy: "Յիշեցէ՛ք ի Քրիստոս", ru: "Помяните во Христе", en: "Remember in Christ")
        let date = ManuscriptText.pick(
            language,
            hy: "Ի թուին Հայոց \(letters)",
            ru: "В лето армянское \(letters) (\(gregorianYear))",
            en: "In the Armenian year \(letters) (\(gregorianYear))"
        )
        return (opening, name.trimmingCharacters(in: .whitespacesAndNewlines), date)
    }
}

// MARK: - Откуда берутся страницы при листании
enum ManuscriptSource {
    /// Выбранная страница первой, дальше случайные жемчужины Писания (листать можно бесконечно)
    case curated(first: ManuscriptPage)
    /// Все стихи одной главы Библии, открыт выбранный
    case chapter(pages: [ManuscriptPage], startId: UUID)
}

/// Обёртка для fullScreenCover(item:)
struct ManuscriptLaunch: Identifiable {
    let id = UUID()
    let source: ManuscriptSource
}

enum ManuscriptPool {
    /// Короткие стихи из подборок приложения: на странице они выглядят лучше всего
    static func curatedPages(language: AppLanguage, excluding references: Set<String>, count: Int) -> [ManuscriptPage] {
        let verses = BibleVerse.shortPearls + BibleVerse.shortPsalms + BibleVerse.shortLove
            + BibleVerse.shortFaith + BibleVerse.shortWisdom
        var seen = references
        var result: [ManuscriptPage] = []
        let style = ManuscriptPage.preferredStyle
        for verse in verses.shuffled() {
            let text = verse.text(for: language)
            let reference = verse.reference(for: language)
            guard !text.isEmpty, text.count <= 220, !seen.contains(reference) else { continue }
            seen.insert(reference)
            result.append(ManuscriptPage(text: text, reference: reference, language: language, style: style))
            if result.count >= count { break }
        }
        return result
    }

    /// Стихи главы подряд: листание влево и вправо переходит к соседним стихам
    static func chapterSource(book: BibleBook, chapter: Int, startVerse: Int, language: AppLanguage,
                              style: ManuscriptStyle? = nil, surface: ManuscriptSurface? = nil) -> ManuscriptSource? {
        guard let text = BibleDatabase.shared.getChapterText(bookId: book.id, chapter: chapter),
              !text.verses.isEmpty else { return nil }
        var pages: [ManuscriptPage] = []
        var startId: UUID?
        for verse in text.verses {
            var page = ManuscriptPage.from(book: book, chapter: chapter, verse: verse, language: language)
            if let style { page.style = style }
            if let surface { page.surface = surface }
            if verse.verseNumber == startVerse { startId = page.id }
            pages.append(page)
        }
        guard let startId = startId ?? pages.first?.id else { return nil }
        return .chapter(pages: pages, startId: startId)
    }
}

extension AppLanguage {
    /// Текст на трёх языках одной строкой
    func pick(hy: String, ru: String, en: String) -> String {
        ManuscriptText.pick(self, hy: hy, ru: ru, en: en)
    }
}

// MARK: - «Матенадаран»: собрание страниц пользователя
final class ManuscriptLibrary: ObservableObject {
    static let shared = ManuscriptLibrary()
    /// Столько страниц нужно, чтобы переплести кодекс
    static let codexSize = 12

    @Published private(set) var pages: [ManuscriptPage] = []

    static let storageKey = "luys_manuscripts_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([ManuscriptPage].self, from: data) {
            pages = decoded
        }
    }

    func contains(_ page: ManuscriptPage) -> Bool {
        pages.contains { $0.id == page.id }
    }

    /// Листы в порядке книги: ранние первыми
    var ordered: [ManuscriptPage] {
        pages.sorted { $0.sortKey != $1.sortKey ? $0.sortKey < $1.sortKey : $0.id.uuidString < $1.id.uuidString }
    }

    /// Тома по порядку: каждые codexSize листов — отдельный кодекс
    var volumes: [[ManuscriptPage]] {
        let list = ordered
        return stride(from: 0, to: list.count, by: Self.codexSize).map {
            Array(list[$0..<min($0 + Self.codexSize, list.count)])
        }
    }

    /// Листов в томе, который сейчас собирается (0 — прошлый том только что переплетён, новый ещё пуст)
    var currentVolumeFill: Int { pages.count % Self.codexSize }

    /// Сколько листов показывать в счётчиках: после переплёта том полный
    var volumeProgress: Int { isCodexBound ? Self.codexSize : currentVolumeFill }

    /// Номер тома, о котором говорят счётчики
    var activeVolume: Int {
        pages.isEmpty ? 1 : (isCodexBound ? pages.count / Self.codexSize : pages.count / Self.codexSize + 1)
    }

    /// Для CI: -manuscript_seed_library N кладёт в пустое собрание N листов (каждый третий с подписью),
    /// чтобы снять «Матенадаран», читалку и PDF
    func seedForTestsIfNeeded() {
        let count = UserDefaults.standard.integer(forKey: "manuscript_seed_library")
        guard count > 0, pages.isEmpty else { return }
        let language = BibleManager.shared.appLanguage
        let notes = [
            ManuscriptText.pick(language, hy: "Մայրիկի համար", ru: "Для мамы", en: "For Mom"),
            ManuscriptText.pick(language, hy: "Օրհնության օրը", ru: "На день благословения", en: "For a day of blessing")
        ]
        for (index, var page) in ManuscriptPool.curatedPages(language: language, excluding: [], count: count).enumerated() {
            page.position = Double(index)
            if index % 3 == 0 { page.note = notes[(index / 3) % notes.count] }
            save(page)
        }
    }

    /// Листы пришли из iCloud: перечитываем собрание из хранилища
    func reloadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([ManuscriptPage].self, from: data) else { return }
        pages = decoded
    }

    /// Новая страница встаёт первой; уже сохранённая обновляется на месте (стиль, имя)
    func save(_ page: ManuscriptPage) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            // Подпись и место в книге меняются только здесь, из «Матенадарана»; студия о них не знает
            var updated = page
            updated.note = pages[index].note
            updated.position = pages[index].position
            pages[index] = updated
        } else {
            pages.insert(page, at: 0)
        }
        persist()
    }

    func delete(_ page: ManuscriptPage) {
        pages.removeAll { $0.id == page.id }
        persist()
    }

    /// Последний том полон и переплетён
    var isCodexBound: Bool { !pages.isEmpty && currentVolumeFill == 0 }

    static let noteLimit = 80

    func setNote(_ note: String, for page: ManuscriptPage) {
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let trimmed = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.noteLimit))
        pages[index].note = trimmed.isEmpty ? nil : trimmed
        persist()
    }

    func canMove(_ page: ManuscriptPage, by step: Int) -> Bool {
        let list = ordered
        guard let index = list.firstIndex(where: { $0.id == page.id }) else { return false }
        return list.indices.contains(index + step)
    }

    /// Сдвигает лист на одно место раньше (-1) или позже (+1): новое место берётся между новыми соседями
    func move(_ page: ManuscriptPage, by step: Int) {
        let list = ordered
        guard let index = list.firstIndex(where: { $0.id == page.id }), list.indices.contains(index + step),
              let stored = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let target = index + step
        let neighbour = list[target].sortKey
        if step < 0 {
            let before = target > 0 ? list[target - 1].sortKey : neighbour - 60
            pages[stored].position = (before + neighbour) / 2
        } else {
            let after = target + 1 < list.count ? list[target + 1].sortKey : neighbour + 60
            pages[stored].position = (neighbour + after) / 2
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
