import Foundation

// MARK: - Прогресс чтения Библии: единая модель
// Чистая логика без UIKit и SwiftUI (тестируется отдельно): что прочитано, где остановились, как это сливается
// между устройствами и как собирается из старых значений. Хранение — в ReadingProgressStore.

/// Место остановки в книге
struct ReadingPosition: Codable, Equatable {
    var chapter: Int
    /// Стих на строке чтения; nil — глава с начала
    var verse: Int?
    /// Время правки (секунды с 1970 г.); 0 — время неизвестно (старые данные), такая запись считается самой старой
    var updatedAt: Double

    /// Порядок «кто новее» для слияния. Равное время разрешается одинаково на всех устройствах (по главе и стиху),
    /// иначе два устройства вечно пересылали бы друг другу «свою» запись.
    func isNewer(than other: ReadingPosition) -> Bool {
        if updatedAt != other.updatedAt { return updatedAt > other.updatedAt }
        if chapter != other.chapter { return chapter > other.chapter }
        return (verse ?? 0) > (other.verse ?? 0)
    }
}

/// Прогресс по одной книге
struct BookReadingProgress: Equatable {
    /// Прочитанные главы: номер главы → время отметки (0 — старые данные без времени)
    var read: [Int: Double] = [:]
    /// Снятые отметки: номер главы → время снятия. Без этого слияние вернуло бы снятую главу из другого устройства
    var cleared: [Int: Double] = [:]
    var position: ReadingPosition? = nil

    var isEmpty: Bool { read.isEmpty && cleared.isEmpty && position == nil }

    static func merged(_ a: BookReadingProgress?, _ b: BookReadingProgress?) -> BookReadingProgress {
        let a = a ?? BookReadingProgress()
        let b = b ?? BookReadingProgress()
        var result = BookReadingProgress()
        let chapters = Set(a.read.keys).union(b.read.keys).union(a.cleared.keys).union(b.cleared.keys)
        for chapter in chapters {
            let readAt = [a.read[chapter], b.read[chapter]].compactMap { $0 }.max()
            let clearedAt = [a.cleared[chapter], b.cleared[chapter]].compactMap { $0 }.max()
            if let readAt = readAt, clearedAt == nil || readAt > clearedAt! {
                result.read[chapter] = readAt
            }
            if let clearedAt = clearedAt {
                result.cleared[chapter] = clearedAt
            }
        }
        switch (a.position, b.position) {
        case (let x?, let y?): result.position = y.isNewer(than: x) ? y : x
        case (let x?, nil): result.position = x
        case (nil, let y?): result.position = y
        case (nil, nil): break
        }
        return result
    }
}

extension BookReadingProgress: Codable {
    private enum CodingKeys: String, CodingKey { case read, cleared, position }

    /// Ключи словарей пишем строками: словарь с Int-ключами Swift кодирует массивом пар, а не объектом
    private static func decodeMap(_ raw: [String: Double]?) -> [Int: Double] {
        var result: [Int: Double] = [:]
        for (key, value) in raw ?? [:] {
            if let chapter = Int(key), chapter > 0, value.isFinite { result[chapter] = value }
        }
        return result
    }

    private static func encodeMap(_ map: [Int: Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        for (chapter, value) in map { result[String(chapter)] = value }
        return result
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        read = Self.decodeMap(try? c.decodeIfPresent([String: Double].self, forKey: .read))
        cleared = Self.decodeMap(try? c.decodeIfPresent([String: Double].self, forKey: .cleared))
        let decoded = try? c.decodeIfPresent(ReadingPosition.self, forKey: .position)
        position = decoded.flatMap { $0 }.flatMap { $0.chapter > 0 ? $0 : nil }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Self.encodeMap(read), forKey: .read)
        try c.encode(Self.encodeMap(cleared), forKey: .cleared)
        try c.encodeIfPresent(position, forKey: .position)
    }
}

/// Прогресс чтения всей Библии. Версия схемы позволяет менять формат, не теряя старых записей.
struct ReadingProgress: Equatable {
    static let currentSchema = 2

    var schema: Int = ReadingProgress.currentSchema
    /// Книга → прогресс по ней
    var books: [Int: BookReadingProgress] = [:]
    /// Книга, которую читали последней, и когда
    var lastBookId: Int? = nil
    var lastUpdatedAt: Double = 0

    var isEmpty: Bool { books.values.allSatisfy { $0.isEmpty } }

    // MARK: Прочитанные главы

    func isRead(bookId: Int, chapter: Int) -> Bool {
        books[bookId]?.read[chapter] != nil
    }

    func readChapters(bookId: Int) -> Set<Int> {
        Set(books[bookId]?.read.keys.map { $0 } ?? [])
    }

    /// Все прочитанные главы по книгам (книги без прочитанных глав не включаются)
    func allReadChapters() -> [Int: Set<Int>] {
        var result: [Int: Set<Int>] = [:]
        for (bookId, book) in books where !book.read.isEmpty {
            result[bookId] = Set(book.read.keys)
        }
        return result
    }

    /// Отмечает главу прочитанной. false — уже была отмечена (время не трогаем: запись не должна меняться зря)
    @discardableResult
    mutating func markRead(bookId: Int, chapter: Int, now: Double) -> Bool {
        guard bookId > 0, chapter > 0 else { return false }
        var book = books[bookId] ?? BookReadingProgress()
        guard book.read[chapter] == nil else { return false }
        book.read[chapter] = now
        book.cleared[chapter] = nil
        books[bookId] = book
        return true
    }

    /// Переключает отметку: прочитанная глава снимается (с записью о снятии), непрочитанная отмечается
    mutating func toggleRead(bookId: Int, chapter: Int, now: Double) {
        guard bookId > 0, chapter > 0 else { return }
        var book = books[bookId] ?? BookReadingProgress()
        if book.read[chapter] != nil {
            book.read[chapter] = nil
            book.cleared[chapter] = now
            books[bookId] = book
        } else {
            markRead(bookId: bookId, chapter: chapter, now: now)
        }
    }

    // MARK: Место остановки

    func position(bookId: Int) -> ReadingPosition? {
        books[bookId]?.position
    }

    /// Записывает место остановки. false — ничего не изменилось (глава и стих те же): время не обновляем,
    /// чтобы не гонять в iCloud одно и то же.
    @discardableResult
    mutating func setPosition(bookId: Int, chapter: Int, verse: Int?, now: Double) -> Bool {
        guard bookId > 0, chapter > 0 else { return false }
        let cleanVerse = (verse ?? 0) > 1 ? verse : nil
        var book = books[bookId] ?? BookReadingProgress()
        if let current = book.position, current.chapter == chapter, current.verse == cleanVerse {
            return false
        }
        book.position = ReadingPosition(chapter: chapter, verse: cleanVerse, updatedAt: now)
        books[bookId] = book
        lastBookId = bookId
        lastUpdatedAt = now
        return true
    }

    /// Куда открывать книгу: сохранённое место; нет его (новый телефон, где прогресс пришёл из iCloud, а место нет) —
    /// наибольшая прочитанная глава; нет и её — начало первой главы.
    func resumePoint(bookId: Int) -> (chapter: Int, verse: Int?) {
        if let position = books[bookId]?.position, position.chapter > 0 {
            return (position.chapter, position.verse)
        }
        if let furthest = books[bookId]?.read.keys.max(), furthest > 0 {
            return (furthest, nil)
        }
        return (1, nil)
    }

    /// Последнее место чтения во всей Библии
    var lastLocation: (bookId: Int, chapter: Int, verse: Int?)? {
        guard let bookId = lastBookId, let position = books[bookId]?.position else { return nil }
        return (bookId, position.chapter, position.verse)
    }

    // MARK: Границы

    /// Глава в пределах книги: нулевая, отрицательная или большая номера последней главы приводятся к допустимой
    static func clampedChapter(_ chapter: Int, chaptersCount: Int) -> Int {
        guard chaptersCount > 0 else { return max(1, chapter) }
        return min(max(1, chapter), chaptersCount)
    }

    /// Стих в пределах главы: в другом переводе стихов может быть меньше. За пределами — nil (глава с начала)
    static func clampedVerse(_ verse: Int?, maxVerse: Int) -> Int? {
        guard let verse = verse, verse >= 1, verse <= maxVerse else { return nil }
        return verse
    }

    // MARK: Слияние (iCloud, повторная миграция)

    /// Объединение без потерь: отметки «прочитано» складываются (если главу не снимали позже), место остановки берётся более свежее.
    /// Результат не зависит от порядка аргументов.
    static func merged(_ a: ReadingProgress, _ b: ReadingProgress) -> ReadingProgress {
        var result = ReadingProgress()
        for bookId in Set(a.books.keys).union(b.books.keys) {
            let book = BookReadingProgress.merged(a.books[bookId], b.books[bookId])
            if !book.isEmpty { result.books[bookId] = book }
        }
        let candidates: [(id: Int, at: Double)] = [a, b].compactMap { p in
            p.lastBookId.map { (id: $0, at: p.lastUpdatedAt) }
        }
        if let best = candidates.max(by: { l, r in l.at != r.at ? l.at < r.at : l.id < r.id }) {
            result.lastBookId = best.id
            result.lastUpdatedAt = best.at
        }
        return result
    }

    /// Из старого облачного набора «прочитанные главы» (книга → главы без времени)
    static func fromLegacyReadSets(_ sets: [Int: [Int]]) -> ReadingProgress {
        var result = ReadingProgress()
        for (bookId, chapters) in sets where bookId > 0 {
            for chapter in chapters where chapter > 0 {
                result.books[bookId, default: BookReadingProgress()].read[chapter] = 0
            }
        }
        return result
    }

    /// Прочитанные главы в старом формате облака и ключей (книга → главы по возрастанию)
    func legacyReadSets() -> [Int: [Int]] {
        var result: [Int: [Int]] = [:]
        for (bookId, book) in books where !book.read.isEmpty {
            result[bookId] = book.read.keys.sorted()
        }
        return result
    }
}

extension ReadingProgress: Codable {
    private enum CodingKeys: String, CodingKey { case schema, books, lastBookId, lastUpdatedAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = (try? c.decodeIfPresent(Int.self, forKey: .schema)) ?? ReadingProgress.currentSchema
        let raw = (try? c.decodeIfPresent([String: BookReadingProgress].self, forKey: .books)) ?? [:]
        books = [:]
        for (key, value) in raw {
            if let bookId = Int(key), bookId > 0, !value.isEmpty { books[bookId] = value }
        }
        lastBookId = (try? c.decodeIfPresent(Int.self, forKey: .lastBookId)) ?? nil
        let at = (try? c.decodeIfPresent(Double.self, forKey: .lastUpdatedAt)) ?? 0
        lastUpdatedAt = at.isFinite ? at : 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schema, forKey: .schema)
        var raw: [String: BookReadingProgress] = [:]
        for (bookId, book) in books where !book.isEmpty { raw[String(bookId)] = book }
        try c.encode(raw, forKey: .books)
        try c.encodeIfPresent(lastBookId, forKey: .lastBookId)
        try c.encode(lastUpdatedAt, forKey: .lastUpdatedAt)
    }
}

// MARK: - Миграция из старых значений

/// Всё, что хранили до новой модели: отдельные ключи в UserDefaults. Копия снимка кладётся в резерв перед миграцией.
struct LegacyReadingSnapshot: Codable, Equatable {
    struct BookPosition: Codable, Equatable {
        var chapter: Int
        var verse: Int?
        var updatedAt: Double?
    }

    /// bible_read_chapters_by_book: книга → прочитанные главы
    var readChapters: [String: [Int]] = [:]
    /// last_read_chapter_for_book_<id> (+ стих и время): книга → место остановки
    var positions: [String: BookPosition] = [:]
    /// last_read_book_id и last_read_chapter
    var lastBookId: Int? = nil
    var lastChapter: Int? = nil

    var isEmpty: Bool {
        readChapters.values.allSatisfy { $0.isEmpty } && positions.isEmpty && lastBookId == nil
    }
}

enum ReadingProgressMigration {
    /// Собирает новую модель из старых значений. Ни одна прочитанная глава не теряется.
    ///
    /// Место остановки по книге: сохранённое, кроме одного случая. Старая ошибка записывала место остановки сразу при открытии
    /// главы, поэтому случайное открытие главы 1 затирало настоящее место. Признак: сохранена глава 1 без стиха, а среди прочитанных
    /// есть глава больше первой. Тогда берём наибольшую прочитанную главу (в остальных случаях сохранённое место не трогаем:
    /// глава 1 со стихом или глава 12 со стихом 9 остаются как есть). Сохранённой главы нет вовсе — тоже наибольшая прочитанная.
    static func migrate(_ snapshot: LegacyReadingSnapshot) -> ReadingProgress {
        var readByBook: [Int: [Int]] = [:]
        for (key, chapters) in snapshot.readChapters {
            guard let bookId = Int(key), bookId > 0 else { continue }
            let valid = chapters.filter { $0 > 0 }
            if !valid.isEmpty { readByBook[bookId] = valid }
        }
        var result = ReadingProgress.fromLegacyReadSets(readByBook)

        var positions: [Int: ReadingPosition] = [:]
        for (key, saved) in snapshot.positions {
            guard let bookId = Int(key), bookId > 0, saved.chapter > 0 else { continue }
            let cleanVerse = (saved.verse ?? 0) > 1 ? saved.verse : nil
            var chapter = saved.chapter
            var verse = cleanVerse
            if chapter <= 1, cleanVerse == nil, let furthest = readByBook[bookId]?.max(), furthest > 1 {
                chapter = furthest
                verse = nil
            }
            let at = (saved.updatedAt ?? 0)
            positions[bookId] = ReadingPosition(chapter: chapter, verse: verse, updatedAt: at.isFinite ? at : 0)
        }
        // Книги, где прочитанное есть, а места остановки нет
        for (bookId, chapters) in readByBook where positions[bookId] == nil {
            if let furthest = chapters.max() {
                positions[bookId] = ReadingPosition(chapter: furthest, verse: nil, updatedAt: 0)
            }
        }
        for (bookId, position) in positions {
            result.books[bookId, default: BookReadingProgress()].position = position
        }

        // Последняя книга: как записано в старом глобальном месте, если по ней есть позиция; иначе самая свежая
        if let last = snapshot.lastBookId, last > 0, positions[last] != nil {
            result.lastBookId = last
            result.lastUpdatedAt = positions[last]?.updatedAt ?? 0
        } else if let best = positions.max(by: { l, r in
            l.value.updatedAt != r.value.updatedAt ? l.value.updatedAt < r.value.updatedAt : l.key < r.key
        }) {
            result.lastBookId = best.key
            result.lastUpdatedAt = best.value.updatedAt
        }
        return result
    }
}
