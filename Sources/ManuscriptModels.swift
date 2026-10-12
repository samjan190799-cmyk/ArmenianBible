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
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFFF7DA, pearl: 0xFBF5E6
    )

    static let cilicia = ManuscriptPalette(
        parchment: 0xF3E6CB, parchmentEdge: 0xD6BA88, ink: 0x2B1A12, rubric: 0x9E2420,
        field: 0x7A1A22, fieldAccent: 0x1E3F7C, leaf: 0x2F5E52,
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFFF7DA, pearl: 0xFBF5E6
    )

    static let narek = ManuscriptPalette(
        parchment: 0xEEE3C8, parchmentEdge: 0xC9B286, ink: 0x2C2217, rubric: 0x8E3A22,
        field: 0x24483A, fieldAccent: 0x8A2A22, leaf: 0x5B7A3A,
        goldDark: 0x7A5616, gold: 0xC1902F, goldLight: 0xEDD17F, goldHighlight: 0xFFF7DA, pearl: 0xFBF5E6
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
    var name: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        reference: String,
        language: AppLanguage,
        style: ManuscriptStyle = .roslin,
        name: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.reference = reference
        self.language = language
        self.style = style
        self.name = name
        self.createdAt = createdAt
    }

    /// Имя для памятной записи берётся из прошлого раза
    static var rememberedName: String {
        UserDefaults.standard.string(forKey: "luys_manuscript_name") ?? ""
    }

    static func from(verse: BibleVerse, language: AppLanguage) -> ManuscriptPage {
        ManuscriptPage(
            text: verse.text(for: language),
            reference: verse.reference(for: language),
            language: language,
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

// MARK: - «Матенадаран»: собрание страниц пользователя
final class ManuscriptLibrary: ObservableObject {
    static let shared = ManuscriptLibrary()
    /// Столько страниц нужно, чтобы переплести кодекс
    static let codexSize = 12

    @Published private(set) var pages: [ManuscriptPage] = []

    private let storageKey = "luys_manuscripts_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ManuscriptPage].self, from: data) {
            pages = decoded
        }
    }

    func contains(_ page: ManuscriptPage) -> Bool {
        pages.contains { $0.id == page.id }
    }

    /// Новая страница встаёт первой; уже сохранённая обновляется на месте (стиль, имя)
    func save(_ page: ManuscriptPage) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages[index] = page
        } else {
            pages.insert(page, at: 0)
        }
        persist()
    }

    func delete(_ page: ManuscriptPage) {
        pages.removeAll { $0.id == page.id }
        persist()
    }

    var isCodexBound: Bool { pages.count >= Self.codexSize }

    private func persist() {
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
