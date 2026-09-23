import Foundation
import SwiftUI

// MARK: - Определение выбранного перевода (Арарат или Эчмиадзин)
func isAraratEditionSelected() -> Bool {
    if let savedEdition = AppGroupConstants.sharedDefaults.string(forKey: "armenian_bible_edition") {
        return savedEdition != "echmiadzin"
    }
    let standardEd = UserDefaults.standard.string(forKey: "armenian_bible_edition")
    return standardEd != "echmiadzin"
}

// MARK: - Модель библейского текста (стиха или молитвы)
struct BibleVerse: Identifiable, Codable, Hashable {
    let id: UUID
    let textHy: String
    let textHyArarat: String
    let textRu: String
    let textEn: String
    let refHy: String
    let refRu: String
    let refEn: String
    let isPrayer: Bool
    
    // Провайдер для поиска переводов из SQLite базы (регистрируется основным приложением)
    public static var textLookupProvider: ((_ referenceHy: String) -> (textHy: String, textHyArarat: String)?)? = nil
    
    var text: String {
        let savedLang = AppGroupConstants.sharedDefaults.string(forKey: "app_language") ??
                        UserDefaults.standard.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return textRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return textEn
        } else {
            if isAraratEditionSelected() {
                if !textHyArarat.isEmpty {
                    return textHyArarat
                }
                if let found = Self.textLookupProvider?(refHy), !found.textHyArarat.isEmpty {
                    return found.textHyArarat
                }
            } else {
                if !textHy.isEmpty {
                    return textHy
                }
                if let found = Self.textLookupProvider?(refHy), !found.textHy.isEmpty {
                    return found.textHy
                }
            }
            return textHy
        }
    }
    
    var reference: String {
        let savedLang = AppGroupConstants.sharedDefaults.string(forKey: "app_language") ??
                        UserDefaults.standard.string(forKey: "app_language")
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
            if isAraratEditionSelected() {
                if !textHyArarat.isEmpty {
                    return textHyArarat
                }
                if let found = Self.textLookupProvider?(refHy), !found.textHyArarat.isEmpty {
                    return found.textHyArarat
                }
            } else {
                if !textHy.isEmpty {
                    return textHy
                }
                if let found = Self.textLookupProvider?(refHy), !found.textHy.isEmpty {
                    return found.textHy
                }
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
    
    init(
        id: UUID = UUID(),
        textHy: String,
        textHyArarat: String = "",
        textRu: String,
        textEn: String,
        refHy: String,
        refRu: String,
        refEn: String,
        isPrayer: Bool = false
    ) {
        self.id = id
        self.textHy = textHy
        self.textHyArarat = textHyArarat
        self.textRu = textRu
        self.textEn = textEn
        self.refHy = refHy
        self.refRu = refRu
        self.refEn = refEn
        self.isPrayer = isPrayer
    }
    
    // Для обратной совместимости с UserDefaults (когда сохранены старые стихи)
    init(id: UUID = UUID(), text: String, reference: String, isPrayer: Bool = false) {
        self.id = id
        self.textHy = text
        self.textHyArarat = text
        self.textRu = text
        self.textEn = text
        self.refHy = reference
        self.refRu = reference
        self.refEn = reference
        self.isPrayer = isPrayer
    }
    
    enum CodingKeys: String, CodingKey {
        case id, textHy, textHyArarat, textRu, textEn, refHy, refRu, refEn, isPrayer, text, reference
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.isPrayer = try container.decodeIfPresent(Bool.self, forKey: .isPrayer) ?? false
        
        if let hyText = try container.decodeIfPresent(String.self, forKey: .textHy),
           let ruText = try container.decodeIfPresent(String.self, forKey: .textRu),
           let enText = try container.decodeIfPresent(String.self, forKey: .textEn),
           let hyRef = try container.decodeIfPresent(String.self, forKey: .refHy),
           let ruRef = try container.decodeIfPresent(String.self, forKey: .refRu),
           let enRef = try container.decodeIfPresent(String.self, forKey: .refEn) {
            self.textHy = hyText
            self.textHyArarat = try container.decodeIfPresent(String.self, forKey: .textHyArarat) ?? ""
            self.textRu = ruText
            self.textEn = enText
            self.refHy = hyRef
            self.refRu = ruRef
            self.refEn = enRef
        } else {
            let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            let reference = try container.decodeIfPresent(String.self, forKey: .reference) ?? ""
            self.textHy = text
            self.textHyArarat = ""
            self.textRu = text
            self.textEn = text
            self.refHy = reference
            self.refRu = reference
            self.refEn = reference
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(textHy, forKey: .textHy)
        try container.encode(textHyArarat, forKey: .textHyArarat)
        try container.encode(textRu, forKey: .textRu)
        try container.encode(textEn, forKey: .textEn)
        try container.encode(refHy, forKey: .refHy)
        try container.encode(refRu, forKey: .refRu)
        try container.encode(refEn, forKey: .refEn)
        try container.encode(isPrayer, forKey: .isPrayer)
        // Для совместимости при чтении старым кодом
        try container.encode(text, forKey: .text)
        try container.encode(reference, forKey: .reference)
    }
}

