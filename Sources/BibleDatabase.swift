import Foundation
import SQLite3

// MARK: - Модели данных Библии

struct BibleBook: Identifiable, Codable, Hashable {
    let id: Int // Номер книги (1-66)
    let nameHy: String
    let nameRu: String
    let nameEn: String
    let shortNameHy: String
    let shortNameRu: String
    let shortNameEn: String
    let chaptersCount: Int
    
    var name: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return nameRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return nameEn
        } else {
            return nameHy
        }
    }
    
    var shortName: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return shortNameRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return shortNameEn
        } else {
            return shortNameHy
        }
    }
    
    var isNewTestament: Bool {
        return id >= 40 // Книги Нового Завета начинаются с Евангелия от Матфея (40)
    }
}

struct BibleVerseText: Identifiable, Codable, Hashable {
    let id: Int
    let bookId: Int
    let chapter: Int
    let verseNumber: Int
    let textHy: String
    let textRu: String
    let textEn: String
    
    func text(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return textHy
        case .russian: return textRu
        case .english: return textEn
        }
    }
    
    func reference(for language: AppLanguage, bookName: String) -> String {
        switch language {
        case .armenian: return "\(bookName) \(chapter):\(verseNumber)"
        case .russian: return "\(bookName) \(chapter):\(verseNumber)"
        case .english: return "\(bookName) \(chapter):\(verseNumber)"
        }
    }
}

struct BibleChapterText: Identifiable, Codable, Hashable {
    var id: String { "\(book.id)_\(chapterNumber)" }
    let book: BibleBook
    let chapterNumber: Int
    let verses: [BibleVerseText]
}

struct BibleSearchResult: Identifiable, Hashable {
    var id: String { "\(bookId)_\(chapter)_\(verseNumber)" }
    let bookId: Int
    let bookName: String
    let chapter: Int
    let verseNumber: Int
    let text: String
}

// MARK: - Менеджер Базы Данных SQLite

class BibleDatabase {
    static let shared = BibleDatabase()
    
    private var db: OpaquePointer?
    private let dbName = "bible"
    
    private init() {
        openDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        guard let dbPath = Bundle.main.path(forResource: dbName, ofType: "db") else {
            print("Bible database file '\(dbName).db' not found in bundle resources.")
            return
        }
        
        // Открываем базу данных в режиме Read-Only, так как она лежит в Bundle приложения
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("Error opening Bible database at path: \(dbPath)")
            if let errorMsg = sqlite3_errmsg(db) {
                print("SQLite Error: \(String(cString: errorMsg))")
            }
            db = nil
        } else {
            print("Successfully opened Bible database.")
        }
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            print("Closed Bible database connection.")
        }
    }
    
    // MARK: - Получение списка книг
    
    func getBooks() -> [BibleBook] {
        var books: [BibleBook] = []
        let query = "SELECT id, name_hy, name_ru, name_en, short_name_hy, short_name_ru, short_name_en, chapters_count FROM books ORDER BY id ASC;"
        var statement: OpaquePointer?
        
        guard db != nil else { return [] }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let nameHy = String(cString: sqlite3_column_text(statement, 1))
                let nameRu = String(cString: sqlite3_column_text(statement, 2))
                let nameEn = String(cString: sqlite3_column_text(statement, 3))
                
                let shortNameHy = sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : ""
                let shortNameRu = sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : ""
                let shortNameEn = sqlite3_column_text(statement, 6) != nil ? String(cString: sqlite3_column_text(statement, 6)) : ""
                
                let chaptersCount = Int(sqlite3_column_int(statement, 7))
                
                let book = BibleBook(
                    id: id,
                    nameHy: nameHy,
                    nameRu: nameRu,
                    nameEn: nameEn,
                    shortNameHy: shortNameHy,
                    shortNameRu: shortNameRu,
                    shortNameEn: shortNameEn,
                    chaptersCount: chaptersCount
                )
                books.append(book)
            }
        } else {
            print("Error preparing getBooks query.")
        }
        
        sqlite3_finalize(statement)
        return books
    }
    
    // MARK: - Получение книги по ID
    
    func getBook(id: Int) -> BibleBook? {
        let query = "SELECT id, name_hy, name_ru, name_en, short_name_hy, short_name_ru, short_name_en, chapters_count FROM books WHERE id = ? LIMIT 1;"
        var statement: OpaquePointer?
        var book: BibleBook? = nil
        
        guard db != nil else { return nil }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let nameHy = String(cString: sqlite3_column_text(statement, 1))
                let nameRu = String(cString: sqlite3_column_text(statement, 2))
                let nameEn = String(cString: sqlite3_column_text(statement, 3))
                
                let shortNameHy = sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : ""
                let shortNameRu = sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : ""
                let shortNameEn = sqlite3_column_text(statement, 6) != nil ? String(cString: sqlite3_column_text(statement, 6)) : ""
                
                let chaptersCount = Int(sqlite3_column_int(statement, 7))
                
                book = BibleBook(
                    id: id,
                    nameHy: nameHy,
                    nameRu: nameRu,
                    nameEn: nameEn,
                    shortNameHy: shortNameHy,
                    shortNameRu: shortNameRu,
                    shortNameEn: shortNameEn,
                    chaptersCount: chaptersCount
                )
            }
        }
        
        sqlite3_finalize(statement)
        return book
    }
    
    // MARK: - Получение текста главы
    
    func getChapterText(bookId: Int, chapter: Int) -> BibleChapterText? {
        guard let book = getBook(id: bookId) else { return nil }
        
        var verses: [BibleVerseText] = []
        let query = "SELECT id, verse, text_hy, text_ru, text_en FROM verses WHERE book_id = ? AND chapter = ? ORDER BY verse ASC;"
        var statement: OpaquePointer?
        
        guard db != nil else { return nil }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(bookId))
            sqlite3_bind_int(statement, 2, Int32(chapter))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let verseNum = Int(sqlite3_column_int(statement, 1))
                let textHy = String(cString: sqlite3_column_text(statement, 2))
                let textRu = String(cString: sqlite3_column_text(statement, 3))
                let textEn = String(cString: sqlite3_column_text(statement, 4))
                
                let verse = BibleVerseText(
                    id: id,
                    bookId: bookId,
                    chapter: chapter,
                    verseNumber: verseNum,
                    textHy: textHy,
                    textRu: textRu,
                    textEn: textEn
                )
                verses.append(verse)
            }
        }
        
        sqlite3_finalize(statement)
        
        guard !verses.isEmpty else { return nil }
        return BibleChapterText(book: book, chapterNumber: chapter, verses: verses)
    }
    
    // MARK: - Получение конкретного стиха
    
    func getVerseText(bookId: Int, chapter: Int, verse: Int) -> BibleVerseText? {
        let query = "SELECT id, text_hy, text_ru, text_en FROM verses WHERE book_id = ? AND chapter = ? AND verse = ? LIMIT 1;"
        var statement: OpaquePointer?
        var verseText: BibleVerseText? = nil
        
        guard db != nil else { return nil }
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(bookId))
            sqlite3_bind_int(statement, 2, Int32(chapter))
            sqlite3_bind_int(statement, 3, Int32(verse))
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let textHy = String(cString: sqlite3_column_text(statement, 1))
                let textRu = String(cString: sqlite3_column_text(statement, 2))
                let textEn = String(cString: sqlite3_column_text(statement, 3))
                
                verseText = BibleVerseText(
                    id: id,
                    bookId: bookId,
                    chapter: chapter,
                    verseNumber: verse,
                    textHy: textHy,
                    textRu: textRu,
                    textEn: textEn
                )
            }
        }
        
        sqlite3_finalize(statement)
        return verseText
    }
    
    // MARK: - Полнотекстовый поиск FTS5
    
    func search(query: String, language: AppLanguage) -> [BibleSearchResult] {
        var results: [BibleSearchResult] = []
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.count >= 2 else { return [] }
        
        let searchColumn: String
        switch language {
        case .armenian:
            searchColumn = "text_hy"
        case .russian:
            searchColumn = "text_ru"
        case .english:
            searchColumn = "text_en"
        }
        
        let sql = """
        SELECT v.book_id, b.name_hy, b.name_ru, b.name_en, v.chapter, v.verse, v.text_hy, v.text_ru, v.text_en
        FROM verses_fts f
        JOIN verses v ON v.id = f.rowid
        JOIN books b ON b.id = v.book_id
        WHERE f.\(searchColumn) MATCH ?
        LIMIT 100;
        """
        
        var statement: OpaquePointer?
        guard db != nil else { return [] }
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            let escapedQuery = cleanQuery
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")
            let ftsQuery = "\"\(escapedQuery)\" OR \(escapedQuery)*"
            
            sqlite3_bind_text(statement, 1, (ftsQuery as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let bookId = Int(sqlite3_column_int(statement, 0))
                
                let bNameHy = String(cString: sqlite3_column_text(statement, 1))
                let bNameRu = String(cString: sqlite3_column_text(statement, 2))
                let bNameEn = String(cString: sqlite3_column_text(statement, 3))
                
                let chapter = Int(sqlite3_column_int(statement, 4))
                let verseNum = Int(sqlite3_column_int(statement, 5))
                
                let textHy = String(cString: sqlite3_column_text(statement, 6))
                let textRu = String(cString: sqlite3_column_text(statement, 7))
                let textEn = String(cString: sqlite3_column_text(statement, 8))
                
                let bookName: String
                let displayedText: String
                switch language {
                case .armenian:
                    bookName = bNameHy
                    displayedText = textHy
                case .russian:
                    bookName = bNameRu
                    displayedText = textRu
                case .english:
                    bookName = bNameEn
                    displayedText = textEn
                }
                
                let result = BibleSearchResult(
                    bookId: bookId,
                    bookName: bookName,
                    chapter: chapter,
                    verseNumber: verseNum,
                    text: displayedText
                )
                results.append(result)
            }
        } else {
            print("Error preparing FTS5 search query.")
            if let errorMsg = sqlite3_errmsg(db) {
                print("SQLite FTS5 Error: \(String(cString: errorMsg))")
            }
        }
        
        sqlite3_finalize(statement)
        return results
    }
}
