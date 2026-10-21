import Foundation

// MARK: - Куда ведёт подпись цитаты
/// Место цитаты в Писании: книга, глава и первый стих отрывка
struct ScriptureLocation: Equatable {
    let bookId: Int
    let chapter: Int
    let verse: Int?
}

/// По подписи цитаты («Ezekiel 27:27», «Псалом 22:1-2») находит книгу, главу и стих и открывает их в читалке.
/// Подпись цитат «в духе Нарекаци» открывает экран Нарекаци. Молитвы и всё остальное без места в Библии — не ссылки.
enum ScriptureLocator {
    /// Подпись цитат «в духе Нарекаци» (одинаковая у всех строк)
    private static let narekRefEn = "In the spirit of Narekatsi"
    private static let narekRefRu = "В духе Нарекаци"
    private static let narekRefHy = "Նարեկացու ոգով"

    private static var cachedBookIds: [String: Int] = [:]
    private static var cachedChapterCounts: [Int: Int] = [:]
    private static let lock = NSLock()

    private static func normalize(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Названия книг из bible.db (полные и короткие, на трёх языках) → номер книги.
    /// Если база не успела открыться и книг нет, ничего не запоминаем: следующая попытка прочитает их заново.
    private static func loadBooks() -> (ids: [String: Int], chapters: [Int: Int]) {
        lock.lock()
        defer { lock.unlock() }
        if !cachedBookIds.isEmpty { return (cachedBookIds, cachedChapterCounts) }

        var ids: [String: Int] = [:]
        var chapters: [Int: Int] = [:]
        for book in BibleDatabase.shared.getBooks() {
            chapters[book.id] = book.chaptersCount
            for name in [book.nameEn, book.shortNameEn, book.nameRu, book.shortNameRu, book.nameHy, book.shortNameHy] where !name.isEmpty {
                ids[normalize(name)] = book.id
            }
        }
        guard !ids.isEmpty else { return ([:], [:]) }

        // В подборках псалмы названы «Psalm»/«Псалом», а в базе «Psalms»/«Псалтирь»
        for alias in ["psalm", "псалом", "псалмы", "սաղմոս", "սաղմոսներ"] { ids[alias] = 19 }
        for alias in ["songofsongs", "canticles", "песньпесней"] { ids[alias] = 22 }
        for alias in ["առակաց"] { ids[alias] = 20 }

        cachedBookIds = ids
        cachedChapterCounts = chapters
        return (ids, chapters)
    }

    /// Разбор одной подписи: «Книга глава:стих» или «Книга глава:стих-стих» (после них может быть что угодно)
    static func location(inReference reference: String) -> ScriptureLocation? {
        guard let regex = try? NSRegularExpression(pattern: #"^\s*(.+?)\s+(\d+)(?::(\d+))?"#) else { return nil }
        let range = NSRange(reference.startIndex..., in: reference)
        guard let match = regex.firstMatch(in: reference, range: range),
              let nameRange = Range(match.range(at: 1), in: reference),
              let chapterRange = Range(match.range(at: 2), in: reference),
              let chapter = Int(reference[chapterRange]), chapter >= 1 else { return nil }

        let books = loadBooks()
        guard let bookId = books.ids[normalize(String(reference[nameRange]))] else { return nil }
        if let count = books.chapters[bookId], chapter > count { return nil }

        var verse: Int? = nil
        if match.range(at: 3).location != NSNotFound, let verseRange = Range(match.range(at: 3), in: reference) {
            verse = Int(reference[verseRange])
        }
        return ScriptureLocation(bookId: bookId, chapter: chapter, verse: verse)
    }

    static func isNarekatsi(_ verse: BibleVerse) -> Bool {
        verse.refEn == narekRefEn || verse.refRu == narekRefRu || verse.refHy == narekRefHy
    }

    /// Место в Библии, если цитата — стих Писания. Сначала смотрим английскую подпись: в ней названия книг самые однородные.
    static func location(for verse: BibleVerse) -> ScriptureLocation? {
        guard !verse.isPrayer, !isNarekatsi(verse) else { return nil }
        for reference in [verse.refEn, verse.refRu, verse.refHy] {
            if let location = location(inReference: reference) { return location }
        }
        return nil
    }

    /// Можно ли нажать на подпись: это стих Библии или строка «в духе Нарекаци»
    static func canOpen(_ verse: BibleVerse) -> Bool {
        isNarekatsi(verse) || location(for: verse) != nil
    }

    /// Открывает место цитаты: главу Библии на нужном стихе или экран Нарекаци. false — открывать нечего.
    @discardableResult
    static func open(_ verse: BibleVerse) -> Bool {
        let manager = BibleManager.shared
        if isNarekatsi(verse) {
            manager.openNarekatsi()
            return true
        }
        guard let location = location(for: verse) else { return false }
        manager.openBibleReader(bookId: location.bookId, chapter: location.chapter, verse: location.verse)
        return true
    }
}
