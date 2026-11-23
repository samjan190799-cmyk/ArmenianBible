import Foundation

// MARK: - Хранение прогресса чтения и перенос со старых ключей
// Единственный источник правды — один JSON в defaults (`reading_progress_v2`). Старые ключи не удаляются
// и продолжают обновляться (зеркало): так прежние версии приложения при откате и на других устройствах ничего не теряют.

enum ReadingProgressStore {
    /// Модель целиком (JSON)
    static let modelKey = "reading_progress_v2"
    /// Копия всех старых значений, снятая перед первым переносом
    static let backupKey = "reading_progress_backup_v1"
    /// Версия схемы, до которой перенос уже сделан
    static let migratedKey = "reading_progress_migrated_schema"

    // Старые ключи (те же, что читали прежние версии)
    static let legacyReadChaptersKey = "bible_read_chapters_by_book"
    static let legacyLastBookKey = "last_read_book_id"
    static let legacyLastChapterKey = "last_read_chapter"
    static let legacyChapterPrefix = "last_read_chapter_for_book_"
    static let legacyVersePrefix = "last_read_verse_for_book_"
    static let legacyUpdatedPrefix = "last_read_updated_for_book_"

    // MARK: Чтение и запись модели

    static func encode(_ progress: ReadingProgress) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(progress)
    }

    static func decode(_ data: Data) -> ReadingProgress? {
        try? JSONDecoder().decode(ReadingProgress.self, from: data)
    }

    /// Сохранённая модель; nil, если её нет или данные повреждены
    static func load(from defaults: UserDefaults) -> ReadingProgress? {
        guard let data = defaults.data(forKey: modelKey) else { return nil }
        return decode(data)
    }

    /// Записывает модель и зеркалит нужное в старые ключи
    static func save(_ progress: ReadingProgress, to defaults: UserDefaults) {
        if let data = encode(progress) {
            defaults.set(data, forKey: modelKey)
        }
        mirrorLegacyKeys(progress, to: defaults)
    }

    // MARK: Старые ключи

    /// Целое из значения defaults любого числового вида (Int, NSNumber, Double, строка); остальное — nil
    static func intValue(_ any: Any?) -> Int? {
        switch any {
        case let value as Int: return value
        case let value as Double: return value.isFinite ? Int(exactly: value.rounded()) : nil
        case let value as NSNumber: return value.intValue
        case let value as String: return Int(value)
        default: return nil
        }
    }

    /// Читает старые значения из defaults (в порядке приоритета): мусор пропускается, ничего не падает
    static func snapshotLegacy(from sources: [UserDefaults]) -> LegacyReadingSnapshot {
        var snapshot = LegacyReadingSnapshot()
        for defaults in sources {
            let all = defaults.dictionaryRepresentation()

            if let raw = all[legacyReadChaptersKey] as? [String: Any] {
                for (key, value) in raw where Int(key) != nil {
                    guard let list = value as? [Any] else { continue }
                    let chapters = list.compactMap { intValue($0) }.filter { $0 > 0 }
                    snapshot.readChapters[key] = Array(Set(snapshot.readChapters[key] ?? []).union(chapters)).sorted()
                }
            }

            for (key, value) in all where key.hasPrefix(legacyChapterPrefix) {
                let bookKey = String(key.dropFirst(legacyChapterPrefix.count))
                guard Int(bookKey) != nil, snapshot.positions[bookKey] == nil,
                      let chapter = intValue(value), chapter > 0 else { continue }
                let verse = intValue(all[legacyVersePrefix + bookKey])
                var updated = all[legacyUpdatedPrefix + bookKey] as? Double
                if updated == nil, let whole = intValue(all[legacyUpdatedPrefix + bookKey]) { updated = Double(whole) }
                snapshot.positions[bookKey] = LegacyReadingSnapshot.BookPosition(chapter: chapter, verse: verse, updatedAt: updated)
            }

            if snapshot.lastBookId == nil, let book = intValue(all[legacyLastBookKey]), book > 0 {
                snapshot.lastBookId = book
                snapshot.lastChapter = intValue(all[legacyLastChapterKey])
            }
        }
        return snapshot
    }

    /// Зеркало в старые ключи: прежние версии приложения читают только их
    static func mirrorLegacyKeys(_ progress: ReadingProgress, to defaults: UserDefaults) {
        var readSets: [String: [Int]] = [:]
        for (bookId, chapters) in progress.legacyReadSets() { readSets[String(bookId)] = chapters }
        defaults.set(readSets, forKey: legacyReadChaptersKey)

        for (bookId, book) in progress.books {
            guard let position = book.position else { continue }
            defaults.set(position.chapter, forKey: legacyChapterPrefix + String(bookId))
            if let verse = position.verse {
                defaults.set(verse, forKey: legacyVersePrefix + String(bookId))
            } else {
                defaults.removeObject(forKey: legacyVersePrefix + String(bookId))
            }
        }
        if let last = progress.lastLocation {
            defaults.set(last.bookId, forKey: legacyLastBookKey)
            defaults.set(last.chapter, forKey: legacyLastChapterKey)
        }
    }

    // MARK: Перенос

    /// Возвращает модель, при необходимости собрав её из старых значений. Безопасно вызывать сколько угодно раз.
    ///
    /// Порядок записи такой, чтобы обрыв в любой точке ничего не терял: сначала копия старых значений, затем модель,
    /// и только потом пометка «перенос сделан». Если пометки нет, перенос повторится и сольётся с уже записанной моделью.
    /// Старые ключи не удаляются.
    static func loadOrMigrate(primary: UserDefaults, extraSources: [UserDefaults] = [], persist write: (ReadingProgress) -> Void) -> ReadingProgress {
        let existing = load(from: primary)
        let migratedSchema = intValue(primary.object(forKey: migratedKey)) ?? 0
        if let existing = existing, migratedSchema >= ReadingProgress.currentSchema {
            return existing
        }

        let snapshot = snapshotLegacy(from: [primary] + extraSources)
        if primary.data(forKey: backupKey) == nil, !snapshot.isEmpty,
           let backup = try? JSONEncoder().encode(snapshot) {
            primary.set(backup, forKey: backupKey)
        }

        var progress = ReadingProgressMigration.migrate(snapshot)
        if let existing = existing {
            progress = ReadingProgress.merged(existing, progress)
        }
        write(progress)
        primary.set(ReadingProgress.currentSchema, forKey: migratedKey)
        return progress
    }
}
