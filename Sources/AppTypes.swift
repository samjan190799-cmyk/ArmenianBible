import Foundation
import SwiftUI

// MARK: - Языки приложения
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case armenian = "armenian"
    case russian = "russian"
    case english = "english"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .armenian: return "Հայերեն"
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
    
    var localeCode: String {
        switch self {
        case .armenian: return "hy"
        case .russian: return "ru"
        case .english: return "en"
        }
    }
}

// MARK: - Язык виджета
enum WidgetLanguage: String, CaseIterable, Identifiable, Codable {
    case followApp = "followApp"
    case armenian = "armenian"
    case russian = "russian"
    case english = "english"
    
    var id: String { self.rawValue }
    
    var appLanguage: AppLanguage? {
        switch self {
        case .followApp: return nil
        case .armenian: return .armenian
        case .russian: return .russian
        case .english: return .english
        }
    }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .followApp:
            switch language {
            case .armenian: return "Ինչպես հավելվածում"
            case .russian: return "Как в приложении"
            case .english: return "Same as App"
            }
        case .armenian: return "Հայերեն"
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

// MARK: - Провайдеры искусственного интеллекта
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case gemini = "gemini"
    case chatgpt = "chatgpt"
    case claude = "claude"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .chatgpt: return "ChatGPT"
        case .claude: return "Claude"
        }
    }
    
    var accentColorHex: String {
        switch self {
        case .gemini: return "4E80EE"
        case .chatgpt: return "10A37F"
        case .claude: return "E07A5F"
        }
    }
    
    var iconName: String {
        switch self {
        case .gemini: return "sparkles"
        case .chatgpt: return "bubble.left.and.text.bubble.right.fill"
        case .claude: return "cpu.fill"
        }
    }
}

// MARK: - Категория отображаемого текста
enum TextCategory: String, CaseIterable, Identifiable, Codable {
    case verses = "verses"
    case prayers = "prayers"
    case favorites = "favorites"
    case both = "both"
    
    var id: String { self.rawValue }
    
    var titleArmenian: String {
        switch self {
        case .verses: return "Աստվածաշունչ"
        case .prayers: return "Աղոթքներ"
        case .favorites: return "Ընտրյալներ"
        case .both: return "Խառը"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .verses: return "category_verses".localized(for: language)
        case .prayers: return "category_prayers".localized(for: language)
        case .favorites: return "category_favorites".localized(for: language)
        case .both: return "category_both".localized(for: language)
        }
    }
}

// MARK: - Режимы темы оформления (Системная / Светлая / Темная)
enum AppAppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .system: return "appearance_system".localized(for: language)
        case .light: return "appearance_light".localized(for: language)
        case .dark: return "appearance_dark".localized(for: language)
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Цветовые темы оформления
enum AccentColorTheme: String, CaseIterable, Identifiable, Codable {
    case cinnabar = "cinnabar"
    case indigo = "indigo"
    case gold = "gold"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .cinnabar: return "color_cinnabar".localized(for: language)
        case .indigo: return "color_indigo".localized(for: language)
        case .gold: return "color_gold".localized(for: language)
        case .blue: return "color_blue".localized(for: language)
        case .green: return "color_green".localized(for: language)
        case .purple: return "color_purple".localized(for: language)
        }
    }
    
    var colorHex: String {
        switch self {
        case .cinnabar: return "B03F2F"
        case .indigo: return "4B4F8F"
        case .gold: return "8F6B2A"
        case .blue: return "3D5A8C"
        case .green: return "4F6B45"
        case .purple: return "6E4B73"
        }
    }
    
    var secondaryColorHex: String {
        switch self {
        case .cinnabar: return "C96A55"
        case .indigo: return "7A7FC4"
        case .gold: return "B8893A"
        case .blue: return "5F7FB5"
        case .green: return "6F9060"
        case .purple: return "93709A"
        }
    }
}

