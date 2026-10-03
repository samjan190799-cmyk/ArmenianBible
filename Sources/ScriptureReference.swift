import Foundation

// MARK: - Ссылка на место Священного Писания («Մատթեոս 2:1-12»)
/// Одна ссылка из строки чтений праздника. Переход в читалку ведёт на начало отрывка.
struct ScriptureReference: Identifiable, Hashable {
    /// Ссылка в исходной записи: «1 Կորնթացիս 15:12-28»
    let raw: String
    /// Номер книги в bible.db (1…66); nil — книги нет в приложении (например, Книга Премудрости)
    let bookId: Int?
    let chapter: Int
    let verse: Int?
    /// Часть после названия книги: «15:12-28»
    let locator: String

    var id: String { raw }

    /// Можно ли открыть место в читалке
    var canOpen: Bool { bookId != nil }

    /// Название книги на языке интерфейса; если книга неизвестна — исходная запись как есть
    func displayText(for language: AppLanguage) -> String {
        guard let bookId = bookId, let book = ScriptureReferenceParser.book(id: bookId) else { return raw }
        switch language {
        case .armenian: return "\(book.nameHy) \(locator)"
        case .russian: return "\(book.nameRu) \(locator)"
        case .english: return "\(book.nameEn) \(locator)"
        }
    }
}

// MARK: - Разбор строки чтений
enum ScriptureReferenceParser {
    /// Названия книг, как они записаны в чтениях праздников → номер книги в bible.db.
    /// Каждое соответствие сверено с таблицей books в bible.db. «Իմաստութիւն» (Премудрость
    /// Соломона) здесь нет намеренно: в приложении только 66 книг, такая ссылка остаётся текстом.
    private static let bookIds: [String: Int] = [
        "Եսայի": 23,
        "Առակաց": 20,
        "Հովնան": 32,
        "Մատթեոս": 40,
        "Ղուկաս": 42,
        "Հովհաննես": 43,
        "Գործք Առաքելոց": 44,
        "Գործք": 44,
        "Հռոմեացիս": 45,
        "1 Կորնթացիս": 46,
        "2 Կորնթացիս": 47,
        "Գաղատացիս": 48,
        "Եփեսացիս": 49,
        "Կողոսացիս": 51,
        "1 Թեսաղոնիկեցիս": 52,
        "2 Տիմոթեոս": 55,
        "Տիտոս": 56,
        "Եբրայեցիս": 58,
        "1 Հովհաննես": 62,
        "Հայտնություն": 66
    ]

    /// Книги читаем из базы один раз: getBooks() выполняет SQL-запрос при каждом вызове
    private static let booksById: [Int: BibleBook] = {
        Dictionary(BibleDatabase.shared.getBooks().map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    static func book(id: Int) -> BibleBook? {
        booksById[id]
    }

    /// «Ղուկաս 1:26-38, Մատթեոս 2:1-12» → две ссылки. Нераспознанные куски остаются текстом.
    static func parse(_ raw: String) -> [ScriptureReference] {
        raw.split(separator: ",").compactMap { piece -> ScriptureReference? in
            let token = piece.trimmingCharacters(in: .whitespaces)
            guard !token.isEmpty else { return nil }
            guard let spaceIndex = token.lastIndex(of: " ") else {
                return ScriptureReference(raw: token, bookId: nil, chapter: 0, verse: nil, locator: "")
            }

            let bookName = String(token[..<spaceIndex])
            let locator = String(token[token.index(after: spaceIndex)...])
            let chapterAndVerse = locator.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)

            guard let chapterText = chapterAndVerse.first,
                  let chapter = Int(chapterText),
                  let bookId = bookIds[bookName] else {
                return ScriptureReference(raw: token, bookId: nil, chapter: 0, verse: nil, locator: locator)
            }

            var verse: Int? = nil
            if chapterAndVerse.count > 1 {
                verse = Int(chapterAndVerse[1].prefix { $0.isNumber })
            }
            return ScriptureReference(raw: token, bookId: bookId, chapter: chapter, verse: verse, locator: locator)
        }
    }

    /// Открывает место в читалке. Главу и стих записываем раньше номера книги: читалка
    /// забирает все три поля в тот момент, когда приходит deepLinkBookId.
    static func open(_ reference: ScriptureReference) {
        guard let bookId = reference.bookId else { return }
        let manager = BibleManager.shared
        manager.deepLinkChapter = reference.chapter
        manager.deepLinkVerse = reference.verse
        manager.deepLinkBookId = bookId
        manager.openBibleReader()
    }
}
