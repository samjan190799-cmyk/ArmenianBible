import Foundation
import SwiftUI

// MARK: - Нормализация строк для сравнения без учета регистра и знаков препинания
extension String {
    var normalizedForComparison: String {
        self.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

// MARK: - Элемент Избранного (Объединенная модель для стихов дня и стихов из Библии)
struct FavoriteItem: Identifiable, Codable, Hashable {
    let id: UUID
    let isDailyVerse: Bool            // True — если это стих дня/виджета, False — если стих из Библии
    let bookId: Int?                  // ID книги в SQLite (для стихов из Библии)
    let chapter: Int?                 // Номер главы (для стихов из Библии)
    let verseNumber: Int?             // Номер стиха (для стихов из Библии)
    
    let textHy: String
    let textHyArarat: String
    let textRu: String
    let textEn: String
    let refHy: String
    let refRu: String
    let refEn: String
    
    init(
        id: UUID,
        isDailyVerse: Bool,
        bookId: Int? = nil,
        chapter: Int? = nil,
        verseNumber: Int? = nil,
        textHy: String,
        textHyArarat: String = "",
        textRu: String,
        textEn: String,
        refHy: String,
        refRu: String,
        refEn: String
    ) {
        self.id = id
        self.isDailyVerse = isDailyVerse
        self.bookId = bookId
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.textHy = textHy
        self.textHyArarat = textHyArarat
        self.textRu = textRu
        self.textEn = textEn
        self.refHy = refHy
        self.refRu = refRu
        self.refEn = refEn
    }
    
    enum CodingKeys: String, CodingKey {
        case id, isDailyVerse, bookId, chapter, verseNumber
        case textHy, textHyArarat, textRu, textEn
        case refHy, refRu, refEn
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        isDailyVerse = try container.decode(Bool.self, forKey: .isDailyVerse)
        bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
        chapter = try container.decodeIfPresent(Int.self, forKey: .chapter)
        verseNumber = try container.decodeIfPresent(Int.self, forKey: .verseNumber)
        textHy = try container.decode(String.self, forKey: .textHy)
        textHyArarat = try container.decodeIfPresent(String.self, forKey: .textHyArarat) ?? ""
        textRu = try container.decode(String.self, forKey: .textRu)
        textEn = try container.decode(String.self, forKey: .textEn)
        refHy = try container.decode(String.self, forKey: .refHy)
        refRu = try container.decode(String.self, forKey: .refRu)
        refEn = try container.decode(String.self, forKey: .refEn)
    }
    
    var text: String {
        let savedLang = AppGroupConstants.sharedDefaults.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return textRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return textEn
        } else {
            if isAraratEditionSelected() && !textHyArarat.isEmpty {
                return textHyArarat
            }
            return textHy
        }
    }
    
    var reference: String {
        let savedLang = AppGroupConstants.sharedDefaults.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return refRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return refEn
        } else {
            return refHy
        }
    }
    
    func text(for language: AppLanguage) -> String {
        switch language {
        case .armenian:
            if isAraratEditionSelected() && !textHyArarat.isEmpty {
                return textHyArarat
            }
            return textHy
        case .russian: return textRu
        case .english: return textEn
        }
    }
    
    func reference(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return refHy
        case .russian: return refRu
        case .english: return refEn
        }
    }
}

// MARK: - Тематические Теги (Verse Tags)
enum VerseTag: String, CaseIterable, Identifiable, Codable, Hashable {
    case faith = "faith"
    case hope = "hope"
    case love = "love"
    case grief = "grief"
    case gratitude = "gratitude"
    case wisdom = "wisdom"
    case prayer = "prayer"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .faith: return "🕊️"
        case .hope: return "⚓"
        case .love: return "❤️"
        case .grief: return "🕯️"
        case .gratitude: return "🙏"
        case .wisdom: return "📜"
        case .prayer: return "✝️"
        }
    }
    
    var colorHex: String {
        switch self {
        case .faith: return "38BDF8"       // Sky blue
        case .hope: return "10B981"        // Emerald
        case .love: return "F43F5E"        // Rose
        case .grief: return "8B5CF6"       // Violet
        case .gratitude: return "F59E0B"   // Amber
        case .wisdom: return "0EA5E9"      // Ocean
        case .prayer: return "6366F1"      // Indigo
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .faith:
            switch language {
            case .armenian: return "Հավատք"
            case .russian: return "Вера"
            case .english: return "Faith"
            }
        case .hope:
            switch language {
            case .armenian: return "Հույս"
            case .russian: return "Надежда"
            case .english: return "Hope"
            }
        case .love:
            switch language {
            case .armenian: return "Սեր"
            case .russian: return "Любовь"
            case .english: return "Love"
            }
        case .grief:
            switch language {
            case .armenian: return "Սուգ և մխիթարություն"
            case .russian: return "Скорбь и утешение"
            case .english: return "Grief & Comfort"
            }
        case .gratitude:
            switch language {
            case .armenian: return "Գոհություն"
            case .russian: return "Благодарность"
            case .english: return "Gratitude"
            }
        case .wisdom:
            switch language {
            case .armenian: return "Իմաստություն"
            case .russian: return "Мудрость"
            case .english: return "Wisdom"
            }
        case .prayer:
            switch language {
            case .armenian: return "Աղոթք"
            case .russian: return "Молитва"
            case .english: return "Prayer"
            }
        }
    }
}

// MARK: - Аннотация стиха (Цветной маркер, Заметка, Тематические теги)
struct VerseAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let verseNumber: Int
    let bookNameHy: String
    let bookNameRu: String
    let bookNameEn: String
    let textHy: String
    let textHyArarat: String
    let textRu: String
    let textEn: String
    var colorHex: String?              // Выделение маркером (например, "FACC15", "4ADE80", etc.)
    var note: String                   // Текст личной мысли / размышления
    var tags: [VerseTag]               // Список назначенных тегов
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        bookId: Int,
        chapter: Int,
        verseNumber: Int,
        bookNameHy: String = "",
        bookNameRu: String = "",
        bookNameEn: String = "",
        textHy: String,
        textHyArarat: String = "",
        textRu: String,
        textEn: String,
        colorHex: String? = nil,
        note: String = "",
        tags: [VerseTag] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.bookNameHy = bookNameHy
        self.bookNameRu = bookNameRu
        self.bookNameEn = bookNameEn
        self.textHy = textHy
        self.textHyArarat = textHyArarat
        self.textRu = textRu
        self.textEn = textEn
        self.colorHex = colorHex
        self.note = note
        self.tags = tags
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bookId, chapter, verseNumber
        case bookNameHy, bookNameRu, bookNameEn
        case textHy, textHyArarat, textRu, textEn
        case colorHex, note, tags, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        bookId = try container.decode(Int.self, forKey: .bookId)
        chapter = try container.decode(Int.self, forKey: .chapter)
        verseNumber = try container.decode(Int.self, forKey: .verseNumber)
        bookNameHy = try container.decodeIfPresent(String.self, forKey: .bookNameHy) ?? ""
        bookNameRu = try container.decodeIfPresent(String.self, forKey: .bookNameRu) ?? ""
        bookNameEn = try container.decodeIfPresent(String.self, forKey: .bookNameEn) ?? ""
        textHy = try container.decode(String.self, forKey: .textHy)
        textHyArarat = try container.decodeIfPresent(String.self, forKey: .textHyArarat) ?? ""
        textRu = try container.decode(String.self, forKey: .textRu)
        textEn = try container.decode(String.self, forKey: .textEn)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        tags = try container.decodeIfPresent([VerseTag].self, forKey: .tags) ?? []
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    var key: String {
        "\(bookId)_\(chapter)_\(verseNumber)"
    }
    
    func text(for language: AppLanguage) -> String {
        switch language {
        case .armenian:
            if isAraratEditionSelected() && !textHyArarat.isEmpty {
                return textHyArarat
            }
            return textHy
        case .russian: return textRu
        case .english: return textEn
        }
    }
    
    func bookName(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return bookNameHy.isEmpty ? "\(bookId)" : bookNameHy
        case .russian: return bookNameRu.isEmpty ? "\(bookId)" : bookNameRu
        case .english: return bookNameEn.isEmpty ? "\(bookId)" : bookNameEn
        }
    }
    
    func reference(for language: AppLanguage) -> String {
        "\(bookName(for: language)) \(chapter):\(verseNumber)"
    }
    
    var hasContent: Bool {
        (colorHex != nil && !colorHex!.isEmpty) || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !tags.isEmpty
    }
}


