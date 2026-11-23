import XCTest
@testable import ArmenianBible

// Тесты чистой логики прогресса чтения (ReadingProgress.swift, ReadingProgressStore.swift).
// Те же фикстуры проверяет Node-порт: scripts/reading_progress_check.js.
// ВАЖНО: в project.yml тестовой цели пока нет, файл лежит вне Sources и в сборку приложения не попадает.
// Чтобы запускать, нужна цель типа bundle.unit-test с sources: [Tests] и зависимостью от ArmenianBible.

final class ReadingProgressTests: XCTestCase {
    private let matthew = 40, mark = 41, luke = 42, john = 43

    /// Данные с телефона пользователя: Матфей 7/28, Марк 2/16, Лука 1/24, Иоанн 5/21; сохранена глава Матфея 1 без стиха
    private func phoneSnapshot() -> LegacyReadingSnapshot {
        var s = LegacyReadingSnapshot()
        s.readChapters = ["40": Array(1...7), "41": [1, 2], "42": [1], "43": Array(1...5)]
        s.positions = ["40": .init(chapter: 1, verse: nil, updatedAt: nil)]
        s.lastBookId = 40
        s.lastChapter = 1
        return s
    }

    private func freshDefaults() -> UserDefaults {
        let name = "reading-progress-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testPhoneFixtureMatthewResumesAtChapterSeven() {
        let p = ReadingProgressMigration.migrate(phoneSnapshot())
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 7)
        XCTAssertNil(p.resumePoint(bookId: matthew).verse)
        XCTAssertEqual(p.readChapters(bookId: matthew), Set(1...7))
        XCTAssertEqual(p.readChapters(bookId: mark), [1, 2])
        XCTAssertEqual(p.readChapters(bookId: luke), [1])
        XCTAssertEqual(p.readChapters(bookId: john), Set(1...5))
        XCTAssertEqual(p.resumePoint(bookId: mark).chapter, 2)
        XCTAssertEqual(p.resumePoint(bookId: john).chapter, 5)
    }

    func testEmptyFixture() {
        let p = ReadingProgressMigration.migrate(LegacyReadingSnapshot())
        XCTAssertTrue(p.isEmpty)
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 1)
        XCTAssertNil(p.resumePoint(bookId: matthew).verse)
    }

    func testSavedChapterTwelveVerseNineStays() {
        var s = LegacyReadingSnapshot()
        s.readChapters = ["40": Array(1...12)]
        s.positions = ["40": .init(chapter: 12, verse: 9, updatedAt: nil)]
        let p = ReadingProgressMigration.migrate(s)
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 12)
        XCTAssertEqual(p.resumePoint(bookId: matthew).verse, 9)
    }

    func testChapterOneWithVerseStaysAndNoSavedChapterUsesFurthestRead() {
        var s = LegacyReadingSnapshot()
        s.readChapters = ["40": Array(1...7), "41": [2, 9, 4]]
        s.positions = ["40": .init(chapter: 1, verse: 5, updatedAt: nil)]
        let p = ReadingProgressMigration.migrate(s)
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 1)
        XCTAssertEqual(p.resumePoint(bookId: matthew).verse, 5)
        XCTAssertEqual(p.resumePoint(bookId: mark).chapter, 9)
    }

    func testGarbageInDefaultsDoesNotBreakMigration() {
        let d = freshDefaults()
        d.set(["abc": [1, 2], "40": [1, 2, 5], "41": "oops"] as [String: Any], forKey: ReadingProgressStore.legacyReadChaptersKey)
        d.set(4, forKey: ReadingProgressStore.legacyChapterPrefix + "zzz")
        d.set(-2, forKey: ReadingProgressStore.legacyChapterPrefix + "40")
        d.set("семь", forKey: ReadingProgressStore.legacyChapterPrefix + "41")
        d.set(Data([0x7b]), forKey: ReadingProgressStore.modelKey)
        var persisted: ReadingProgress?
        let p = ReadingProgressStore.loadOrMigrate(primary: d, persist: { persisted = $0 })
        XCTAssertEqual(p.readChapters(bookId: matthew), [1, 2, 5])
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 5)
        XCTAssertNotNil(persisted)
    }

    func testMigrationKeepsBackupAndOldKeysAndIsIdempotent() {
        let d = freshDefaults()
        d.set(["40": Array(1...7)], forKey: ReadingProgressStore.legacyReadChaptersKey)
        d.set(1, forKey: ReadingProgressStore.legacyChapterPrefix + "40")
        var stored: ReadingProgress?
        let first = ReadingProgressStore.loadOrMigrate(primary: d, persist: { stored = $0; ReadingProgressStore.save($0, to: d) })
        XCTAssertNotNil(d.data(forKey: ReadingProgressStore.backupKey))
        XCTAssertNotNil(d.object(forKey: ReadingProgressStore.legacyReadChaptersKey))
        let second = ReadingProgressStore.loadOrMigrate(primary: d, persist: { _ in XCTFail("повторный перенос не должен писать") })
        XCTAssertEqual(first, second)
        XCTAssertNotNil(stored)
    }

    func testOpeningDoesNotMovePositionButReadingDoes() {
        var p = ReadingProgress()
        p.markRead(bookId: matthew, chapter: 7, now: 10)
        XCTAssertNil(p.position(bookId: matthew), "отметка прочитанной место остановки не пишет")
        XCTAssertTrue(p.setPosition(bookId: matthew, chapter: 7, verse: nil, now: 11))
        XCTAssertFalse(p.setPosition(bookId: matthew, chapter: 7, verse: nil, now: 12))
        XCTAssertEqual(p.position(bookId: matthew)?.updatedAt, 11)
        XCTAssertFalse(p.setPosition(bookId: matthew, chapter: 7, verse: 1, now: 13))
        XCTAssertTrue(p.setPosition(bookId: matthew, chapter: 7, verse: 12, now: 14))
        XCTAssertEqual(p.resumePoint(bookId: matthew).verse, 12)
        p.markRead(bookId: matthew, chapter: 1, now: 20)
        XCTAssertEqual(p.resumePoint(bookId: matthew).chapter, 7, "случайное открытие главы 1 не затирает место")
    }

    func testBounds() {
        XCTAssertNil(ReadingProgress.clampedVerse(30, maxVerse: 25))
        XCTAssertEqual(ReadingProgress.clampedVerse(25, maxVerse: 25), 25)
        XCTAssertNil(ReadingProgress.clampedVerse(0, maxVerse: 25))
        XCTAssertNil(ReadingProgress.clampedVerse(nil, maxVerse: 25))
        XCTAssertEqual(ReadingProgress.clampedChapter(0, chaptersCount: 28), 1)
        XCTAssertEqual(ReadingProgress.clampedChapter(-4, chaptersCount: 28), 1)
        XCTAssertEqual(ReadingProgress.clampedChapter(99, chaptersCount: 28), 28)
        XCTAssertEqual(ReadingProgress.clampedChapter(7, chaptersCount: 28), 7)
        var p = ReadingProgress()
        XCTAssertFalse(p.setPosition(bookId: matthew, chapter: 0, verse: 3, now: 1))
        XCTAssertFalse(p.setPosition(bookId: 0, chapter: 3, verse: 3, now: 1))
        XCTAssertFalse(p.markRead(bookId: matthew, chapter: 0, now: 1))
    }

    func testMergeUnionsReadAndTakesNewerPosition() {
        var a = ReadingProgress(), b = ReadingProgress()
        a.markRead(bookId: matthew, chapter: 1, now: 10); a.markRead(bookId: matthew, chapter: 2, now: 10)
        a.setPosition(bookId: matthew, chapter: 2, verse: 5, now: 50)
        b.markRead(bookId: matthew, chapter: 2, now: 20); b.markRead(bookId: matthew, chapter: 3, now: 20)
        b.setPosition(bookId: matthew, chapter: 3, verse: nil, now: 60)
        b.markRead(bookId: mark, chapter: 1, now: 5)
        let m = ReadingProgress.merged(a, b)
        XCTAssertEqual(m.readChapters(bookId: matthew), [1, 2, 3])
        XCTAssertEqual(m.readChapters(bookId: mark), [1])
        XCTAssertEqual(m.resumePoint(bookId: matthew).chapter, 3)
        // запись без времени проигрывает при любом порядке
        let legacy = ReadingProgressMigration.migrate({
            var s = LegacyReadingSnapshot()
            s.readChapters = ["40": [1]]
            s.positions = ["40": .init(chapter: 9, verse: 2, updatedAt: nil)]
            return s
        }())
        XCTAssertEqual(ReadingProgress.merged(legacy, a).resumePoint(bookId: matthew).chapter, 2)
        XCTAssertEqual(ReadingProgress.merged(a, legacy).resumePoint(bookId: matthew).chapter, 2)
    }

    func testMergeIsCommutativeAndIdempotent() {
        var a = ReadingProgress(), b = ReadingProgress()
        a.markRead(bookId: matthew, chapter: 1, now: 10); a.setPosition(bookId: matthew, chapter: 4, verse: 2, now: 70)
        a.toggleRead(bookId: matthew, chapter: 1, now: 80)
        b.markRead(bookId: matthew, chapter: 1, now: 30); b.markRead(bookId: matthew, chapter: 5, now: 30)
        b.setPosition(bookId: matthew, chapter: 6, verse: nil, now: 70)
        XCTAssertEqual(ReadingProgress.merged(a, b), ReadingProgress.merged(b, a))
        XCTAssertEqual(ReadingProgress.merged(a, a), a)
    }

    func testClearedChapterDoesNotComeBackFromOldCopyOrLegacyFormat() {
        var a = ReadingProgress()
        a.markRead(bookId: matthew, chapter: 3, now: 10)
        let b = ReadingProgress.merged(ReadingProgress(), a)
        a.toggleRead(bookId: matthew, chapter: 3, now: 20)
        let m = ReadingProgress.merged(a, b)
        XCTAssertFalse(m.isRead(bookId: matthew, chapter: 3))
        var c = ReadingProgress.merged(ReadingProgress(), m)
        c.markRead(bookId: matthew, chapter: 3, now: 30)
        XCTAssertTrue(ReadingProgress.merged(m, c).isRead(bookId: matthew, chapter: 3))
        let legacy = ReadingProgress.fromLegacyReadSets([matthew: [3]])
        XCTAssertFalse(ReadingProgress.merged(m, legacy).isRead(bookId: matthew, chapter: 3))
    }

    func testJSONRoundTripAndJunkIsDropped() throws {
        let p = ReadingProgressMigration.migrate(phoneSnapshot())
        let data = try XCTUnwrap(ReadingProgressStore.encode(p))
        XCTAssertEqual(ReadingProgressStore.decode(data), p)
        XCTAssertEqual(ReadingProgressStore.encode(try XCTUnwrap(ReadingProgressStore.decode(data))), data)
        let dirty = #"{"schema":2,"books":{"40":{"read":{"1":0,"x":5,"-2":1},"position":{"chapter":0,"updatedAt":0}},"abc":{"read":{"1":1}}},"lastBookId":"z"}"#
        let q = try XCTUnwrap(ReadingProgressStore.decode(Data(dirty.utf8)))
        XCTAssertEqual(q.readChapters(bookId: matthew), [1])
        XCTAssertNil(q.position(bookId: matthew))
        XCTAssertEqual(q.books.count, 1)
        XCTAssertNil(ReadingProgressStore.decode(Data("[]".utf8)))
    }

    func testLegacyKeysAreMirrored() {
        let d = freshDefaults()
        var p = ReadingProgress()
        p.markRead(bookId: matthew, chapter: 7, now: 1)
        p.setPosition(bookId: matthew, chapter: 7, verse: 12, now: 2)
        ReadingProgressStore.save(p, to: d)
        XCTAssertEqual(d.integer(forKey: ReadingProgressStore.legacyChapterPrefix + "40"), 7)
        XCTAssertEqual(d.integer(forKey: ReadingProgressStore.legacyVersePrefix + "40"), 12)
        XCTAssertEqual(d.integer(forKey: ReadingProgressStore.legacyLastBookKey), 40)
        XCTAssertEqual(d.dictionary(forKey: ReadingProgressStore.legacyReadChaptersKey) as? [String: [Int]], ["40": [7]])
    }
}
