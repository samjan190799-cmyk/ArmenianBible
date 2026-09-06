import Foundation
import SwiftUI

// MARK: - Модель библейского текста (стиха или молитвы)
struct BibleVerse: Identifiable, Codable, Hashable {
    let id: UUID
    let textHy: String
    let textRu: String
    let textEn: String
    let refHy: String
    let refRu: String
    let refEn: String
    let isPrayer: Bool
    
    var text: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return textRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return textEn
        } else {
            return textHy
        }
    }
    
    var reference: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
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
        case .armenian: return textHy
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
    
    init(id: UUID = UUID(), textHy: String, textRu: String, textEn: String, refHy: String, refRu: String, refEn: String, isPrayer: Bool = false) {
        self.id = id
        self.textHy = textHy
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
        self.textRu = text
        self.textEn = text
        self.refHy = reference
        self.refRu = reference
        self.refEn = reference
        self.isPrayer = isPrayer
    }
    
    enum CodingKeys: String, CodingKey {
        case id, textHy, textRu, textEn, refHy, refRu, refEn, isPrayer, text, reference
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
            self.textRu = ruText
            self.textEn = enText
            self.refHy = hyRef
            self.refRu = ruRef
            self.refEn = enRef
        } else {
            let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            let reference = try container.decodeIfPresent(String.self, forKey: .reference) ?? ""
            self.textHy = text
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
public enum AIProvider: String, CaseIterable, Identifiable, Codable {
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
    case indigo = "indigo"
    case gold = "gold"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .indigo: return "color_indigo".localized(for: language)
        case .gold: return "color_gold".localized(for: language)
        case .blue: return "color_blue".localized(for: language)
        case .green: return "color_green".localized(for: language)
        case .purple: return "color_purple".localized(for: language)
        }
    }
    
    var colorHex: String {
        switch self {
        case .indigo: return "6366F1"
        case .gold: return "D97706"
        case .blue: return "0EA5E9"
        case .green: return "10B981"
        case .purple: return "8B5CF6"
        }
    }
    
    var secondaryColorHex: String {
        switch self {
        case .indigo: return "818CF8"
        case .gold: return "FBBF24"
        case .blue: return "38BDF8"
        case .green: return "34D399"
        case .purple: return "A78BFA"
        }
    }
}

// MARK: - Визуальные стили виджетов и режима StandBy
enum WidgetVisualStyle: String, CaseIterable, Identifiable, Codable {
    case oledStandby = "oledStandby"
    case modernMinimal = "modernMinimal"
    case sacredParchment = "sacredParchment"
    case royalMonastery = "royalMonastery"
    case monochrome = "monochrome"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .oledStandby: return "widget_style_oled".localized(for: language)
        case .modernMinimal: return "widget_style_glass".localized(for: language)
        case .sacredParchment: return "widget_style_parchment".localized(for: language)
        case .royalMonastery: return "widget_style_royal".localized(for: language)
        case .monochrome: return "widget_style_monochrome".localized(for: language)
        }
    }
    
    func localizedSubtitle(for language: AppLanguage) -> String {
        switch self {
        case .oledStandby: return "widget_style_oled_desc".localized(for: language)
        case .modernMinimal: return "widget_style_glass_desc".localized(for: language)
        case .sacredParchment: return "widget_style_parchment_desc".localized(for: language)
        case .royalMonastery: return "widget_style_royal_desc".localized(for: language)
        case .monochrome: return "widget_style_monochrome_desc".localized(for: language)
        }
    }
    
    var iconName: String {
        switch self {
        case .oledStandby: return "moon.stars.fill"
        case .modernMinimal: return "sparkles"
        case .sacredParchment: return "scroll.fill"
        case .royalMonastery: return "crown.fill"
        case .monochrome: return "circle.lefthalf.filled"
        }
    }
    
    var fontDesign: Font.Design {
        switch self {
        case .oledStandby: return .serif
        case .modernMinimal: return .rounded
        case .sacredParchment: return .serif
        case .royalMonastery: return .serif
        case .monochrome: return .default
        }
    }
    
    var isOled: Bool {
        self == .oledStandby
    }
    
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .oledStandby:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color.black, Color(red: 0.04, green: 0.04, blue: 0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.06), Color(red: 0.09, green: 0.09, blue: 0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .modernMinimal:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.11, green: 0.14, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.97, green: 0.98, blue: 0.99), Color(red: 0.89, green: 0.91, blue: 0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .sacredParchment:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.10, green: 0.07, blue: 0.05), Color(red: 0.15, green: 0.11, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.94, green: 0.89, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .royalMonastery:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.03, green: 0.06, blue: 0.14), Color(red: 0.07, green: 0.12, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.94, green: 0.96, blue: 1.0), Color(red: 0.85, green: 0.91, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .monochrome:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color.black, Color(red: 0.03, green: 0.03, blue: 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color.white, Color(red: 0.95, green: 0.95, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .oledStandby:
            return Color(red: 1.0, green: 0.98, blue: 0.92)
        case .modernMinimal:
            return colorScheme == .dark ? Color.white.opacity(0.96) : Color(red: 0.08, green: 0.11, blue: 0.18)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.99, green: 0.94, blue: 0.82) : Color(red: 0.16, green: 0.10, blue: 0.05)
        case .royalMonastery:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.98, blue: 1.0) : Color(red: 0.05, green: 0.10, blue: 0.20)
        case .monochrome:
            return colorScheme == .dark ? Color.white : Color.black
        }
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        switch self {
        case .oledStandby:
            return Color(red: 0.98, green: 0.75, blue: 0.14)
        case .modernMinimal:
            return colorScheme == .dark ? Color(red: 0.51, green: 0.55, blue: 0.97) : Color(red: 0.31, green: 0.27, blue: 0.90)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.57, green: 0.25, blue: 0.05)
        case .royalMonastery:
            return colorScheme == .dark ? Color(red: 0.22, green: 0.74, blue: 0.97) : Color(red: 0.11, green: 0.31, blue: 0.85)
        case .monochrome:
            return colorScheme == .dark ? Color(red: 0.65, green: 0.68, blue: 0.72) : Color(red: 0.35, green: 0.38, blue: 0.42)
        }
    }
    
    func quoteIconColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        switch self {
        case .oledStandby:
            return Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.85)
        case .modernMinimal:
            return colorScheme == .dark ? Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.40) : Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.20)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.85, green: 0.47, blue: 0.04).opacity(0.60) : Color(red: 0.57, green: 0.25, blue: 0.05).opacity(0.25)
        case .royalMonastery:
            return colorScheme == .dark ? Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.55) : Color(red: 0.11, green: 0.31, blue: 0.85).opacity(0.22)
        case .monochrome:
            return colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.18)
        }
    }
    
    func borderStroke(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .oledStandby:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.45),
                    Color(red: 0.85, green: 0.47, blue: 0.04).opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .modernMinimal:
            let topAlpha: Double = colorScheme == .dark ? 0.20 : 0.10
            let btmAlpha: Double = colorScheme == .dark ? 0.05 : 0.02
            return LinearGradient(
                colors: [Color.white.opacity(topAlpha), Color.white.opacity(btmAlpha)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sacredParchment:
            return LinearGradient(
                colors: [
                    Color(red: 0.71, green: 0.33, blue: 0.04).opacity(0.40),
                    Color(red: 0.45, green: 0.20, blue: 0.02).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .royalMonastery:
            return LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.40),
                    Color(red: 0.07, green: 0.12, blue: 0.25).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .monochrome:
            let alpha: Double = colorScheme == .dark ? 0.22 : 0.12
            return LinearGradient(
                colors: [Color.primary.opacity(alpha), Color.primary.opacity(alpha * 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    func buttonBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .oledStandby:
            return Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.16)
        case .modernMinimal:
            return Color.primary.opacity(0.08)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.14) : Color(red: 0.45, green: 0.20, blue: 0.02).opacity(0.08)
        case .royalMonastery:
            return colorScheme == .dark ? Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.15) : Color(red: 0.11, green: 0.31, blue: 0.85).opacity(0.08)
        case .monochrome:
            return Color.primary.opacity(0.08)
        }
    }
}

// MARK: - Интервал обновления стихов
enum UpdateInterval: String, CaseIterable, Identifiable, Codable {
    case everyHour = "everyHour"
    case every6Hours = "every6Hours"
    case every12Hours = "every12Hours"
    case every24Hours = "every24Hours"
    case onScreenActivation = "onScreenActivation"
    case onTapOnly = "onTapOnly"
    
    var id: String { self.rawValue }
    
    var minutes: Int {
        switch self {
        case .everyHour: return 60
        case .every6Hours: return 360
        case .every12Hours: return 720
        case .every24Hours: return 1440
        case .onScreenActivation: return 60
        case .onTapOnly: return 60
        }
    }
    
    var titleArmenian: String {
        switch self {
        case .everyHour: return "Ամեն ժամ"
        case .every6Hours: return "6 ժամը մեկ"
        case .every12Hours: return "12 ժամը մեկ"
        case .every24Hours: return "Օրական 1 անգամ"
        case .onScreenActivation: return "Ակտիվացումով (հավելվածում)"
        case .onTapOnly: return "Միայն հպումով"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .everyHour: return "interval_every_hour".localized(for: language)
        case .every6Hours: return "interval_every_6_hours".localized(for: language)
        case .every12Hours: return "interval_every_12_hours".localized(for: language)
        case .every24Hours: return "interval_every_24_hours".localized(for: language)
        case .onScreenActivation: return "interval_on_screen_activation".localized(for: language)
        case .onTapOnly: return "interval_on_tap_only".localized(for: language)
        }
    }
}

// MARK: - Категории для Экрана Блокировки и Виджетов (iOS Lock Screen & Widgets)
enum LockScreenCategory: String, CaseIterable, Identifiable, Codable {
    case pearls = "pearls"          // 🕊️ Короткие жемчужины (Бесплатно)
    case narekatsi = "narekatsi"    // 👑 Краткие молитвы Нарекаци (PRO)
    case psalms = "psalms"          // ✝️ Короткие Псалмы Давида (PRO)
    case wisdom = "wisdom"          // 📖 Краткая Мудрость Соломона (PRO)
    case love = "love"              // ❤️ Короткие стихи о Любви (PRO)
    case faith = "faith"            // ⚓ Короткие стихи о Вере (PRO)
    
    var id: String { rawValue }
    
    /// Требуется ли подписка Armenian Bible Premium
    var isPremiumRequired: Bool {
        return self != .pearls
    }
    
    var icon: String {
        switch self {
        case .pearls: return "🕊️"
        case .narekatsi: return "👑"
        case .psalms: return "✝️"
        case .wisdom: return "📖"
        case .love: return "❤️"
        case .faith: return "⚓"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .pearls:
            switch language {
            case .armenian: return "Կարճ գոհարներ"
            case .russian: return "Короткие жемчужины"
            case .english: return "Short Pearls"
            }
        case .narekatsi:
            switch language {
            case .armenian: return "Նարեկացու աղոթքներ"
            case .russian: return "Молитвы Нарекаци"
            case .english: return "Narekatsi Prayers"
            }
        case .psalms:
            switch language {
            case .armenian: return "Սաղմոսներ"
            case .russian: return "Псалмы Давида"
            case .english: return "Psalms"
            }
        case .wisdom:
            switch language {
            case .armenian: return "Իմաստություն և Առակներ"
            case .russian: return "Мудрость и Притчи"
            case .english: return "Wisdom & Proverbs"
            }
        case .love:
            switch language {
            case .armenian: return "Սեր և Խաղաղություն"
            case .russian: return "Любовь и Мир"
            case .english: return "Love & Peace"
            }
        case .faith:
            switch language {
            case .armenian: return "Հավատք և Քաջություն"
            case .russian: return "Вера и Мужество"
            case .english: return "Faith & Courage"
            }
        }
    }
}

// MARK: - Категории контента для Виджетов Домашнего Экрана (Medium 4x2 & Large 4x4)
enum HomeWidgetCategory: String, CaseIterable, Identifiable, Codable {
    case all = "all"                // 📚 Все разделы и темы (Бесплатно)
    case gospels = "gospels"        // 📖 Святое Евангелие (Бесплатно)
    case psalms = "psalms"          // ✝️ Псалмы Давида (PRO)
    case wisdom = "wisdom"          // 💡 Притчи и Мудрость (PRO)
    case narekatsi = "narekatsi"    // 👑 Молитвы Нарекаци (PRO)
    case prayers = "prayers"        // 🤲 Молитвослов (PRO)
    case favorites = "favorites"    // ❤️ Избранные стихи (PRO)
    
    var id: String { rawValue }
    
    var isPremiumRequired: Bool {
        switch self {
        case .all, .gospels: return false
        default: return true
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "books.vertical.fill"
        case .gospels: return "book.closed.fill"
        case .psalms: return "cross.fill"
        case .wisdom: return "lightbulb.fill"
        case .narekatsi: return "crown.fill"
        case .prayers: return "hands.sparkles.fill"
        case .favorites: return "heart.fill"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .all:
            switch language {
            case .armenian: return "Բոլորը"
            case .russian: return "Все разделы"
            case .english: return "All Categories"
            }
        case .gospels:
            switch language {
            case .armenian: return "Ավետարան"
            case .russian: return "Евангелие"
            case .english: return "Gospels"
            }
        case .psalms:
            switch language {
            case .armenian: return "Սաղմոսներ"
            case .russian: return "Псалмы"
            case .english: return "Psalms"
            }
        case .wisdom:
            switch language {
            case .armenian: return "Իմաստություն"
            case .russian: return "Притчи"
            case .english: return "Wisdom"
            }
        case .narekatsi:
            switch language {
            case .armenian: return "Նարեկացի"
            case .russian: return "Нарекаци"
            case .english: return "Narekatsi"
            }
        case .prayers:
            switch language {
            case .armenian: return "Աղոթքներ"
            case .russian: return "Молитвы"
            case .english: return "Prayers"
            }
        case .favorites:
            switch language {
            case .armenian: return "Սիրված"
            case .russian: return "Избранное"
            case .english: return "Favorites"
            }
        }
    }
}

// MARK: - Переключатель размеров превью виджетов в Настройках
enum PreviewWidgetSize: String, CaseIterable, Identifiable {
    case small = "small"            // 2x2 (StandBy / Small)
    case medium = "medium"          // 4x2 (Medium)
    case large = "large"            // 4x4 (Large)
    
    var id: String { rawValue }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .small:
            switch language {
            case .armenian: return "Փոքր 2x2"
            case .russian: return "Малый 2x2"
            case .english: return "Small 2x2"
            }
        case .medium:
            switch language {
            case .armenian: return "Միջին 4x2"
            case .russian: return "Средний 4x2"
            case .english: return "Medium 4x2"
            }
        case .large:
            switch language {
            case .armenian: return "Մեծ 4x4"
            case .russian: return "Большой 4x4"
            case .english: return "Large 4x4"
            }
        }
    }
    
    var iconName: String {
        switch self {
        case .small: return "square"
        case .medium: return "rectangle"
        case .large: return "square.split.2x2"
        }
    }
}


extension BibleVerse {
    // MARK: - 1. 🕊️ Короткие жемчужины (Бесплатно / Free) — до 45 символов
    static let shortPearls: [BibleVerse] = [
        BibleVerse(
            textHy: "Մի՛շտ ուրախ եղեք։",
            textRu: "Всегда радуйтесь.",
            textEn: "Rejoice evermore.",
            refHy: "Ա Թեսաղոնիկեցիս 5:16",
            refRu: "1 Фессалоникийцам 5:16",
            refEn: "1 Thessalonians 5:16"
        ),
        BibleVerse(
            textHy: "Անդադա՛ր աղոթեցեք։",
            textRu: "Непрестанно молитесь.",
            textEn: "Pray without ceasing.",
            refHy: "Ա Թեսաղոնիկեցիս 5:17",
            refRu: "1 Фессалоникийцам 5:17",
            refEn: "1 Thessalonians 5:17"
        ),
        BibleVerse(
            textHy: "Ամեն ինչում գոհությո՛ւն հայտնեք։",
            textRu: "За все благодарите.",
            textEn: "In every thing give thanks.",
            refHy: "Ա Թեսաղոնիկեցիս 5:18",
            refRu: "1 Фессалоникийцам 5:18",
            refEn: "1 Thessalonians 5:18"
        ),
        BibleVerse(
            textHy: "Ես եմ աշխարհի լույսը։",
            textRu: "Я свет миру.",
            textEn: "I am the light of the world.",
            refHy: "Հովհաննես 8:12",
            refRu: "Иоанна 8:12",
            refEn: "John 8:12"
        ),
        BibleVerse(
            textHy: "Իմ խաղաղությունն եմ տալիս ձեզ։",
            textRu: "Мир Мой даю вам.",
            textEn: "My peace I give unto you.",
            refHy: "Հովհաննես 14:27",
            refRu: "Иоанна 14:27",
            refEn: "John 14:27"
        ),
        BibleVerse(
            textHy: "Դուք եք աշխարհի լույսը։",
            textRu: "Вы — свет мира.",
            textEn: "Ye are the light of the world.",
            refHy: "Մատթեոս 5:14",
            refRu: "Матфея 5:14",
            refEn: "Matthew 5:14"
        ),
        BibleVerse(
            textHy: "Ձեր ամբողջ հոգսը Նրա՛ վրա գցեք։",
            textRu: "Все заботы ваши возложите на Него.",
            textEn: "Casting all your care upon him.",
            refHy: "Ա Պետրոս 5:7",
            refRu: "1 Петра 5:7",
            refEn: "1 Peter 5:7"
        ),
        BibleVerse(
            textHy: "Ամեն բարի տուրք վերևից է։",
            textRu: "Всякое даяние доброе нисходит свыше.",
            textEn: "Every good gift is from above.",
            refHy: "Հակոբոս 1:17",
            refRu: "Иакова 1:17",
            refEn: "James 1:17"
        ),
        BibleVerse(
            textHy: "Մի՛շտ ուրախ եղեք Տիրոջով։",
            textRu: "Радуйтесь всегда в Господе.",
            textEn: "Rejoice in the Lord alway.",
            refHy: "Փիլիպպեցիներին 4:4",
            refRu: "Филиппийцам 4:4",
            refEn: "Philippians 4:4"
        ),
        BibleVerse(
            textHy: "Նախ խնդրեցե՛ք Աստծո արքայությունը։",
            textRu: "Ищите же прежде Царства Божия.",
            textEn: "Seek ye first the kingdom of God.",
            refHy: "Մատթեոս 6:33",
            refRu: "Матфея 6:33",
            refEn: "Matthew 6:33"
        ),
        BibleVerse(
            textHy: "Աստծո համար անհնարին ոչինչ չկա։",
            textRu: "У Бога не останется бессильным никакое слово.",
            textEn: "For with God nothing shall be impossible.",
            refHy: "Ղուկաս 1:37",
            refRu: "Луки 1:37",
            refEn: "Luke 1:37"
        ),
        BibleVerse(
            textHy: "Երանի՜ խաղաղարարներին։",
            textRu: "Блаженны миротворцы.",
            textEn: "Blessed are the peacemakers.",
            refHy: "Մատթեոս 5:9",
            refRu: "Матфея 5:9",
            refEn: "Matthew 5:9"
        ),
        BibleVerse(
            textHy: "Հիսուս Քրիստոսը նույնն է հավիտյան։",
            textRu: "Иисус Христос Тот же вовеки.",
            textEn: "Jesus Christ the same forever.",
            refHy: "Եբրայեցիս 13:8",
            refRu: "Евреям 13:8",
            refEn: "Hebrews 13:8"
        ),
        BibleVerse(
            textHy: "Խնդրեցե՛ք, և կտրվի ձեզ։",
            textRu: "Просите, и дано будет вам.",
            textEn: "Ask, and it shall be given you.",
            refHy: "Մատթեոս 7:7",
            refRu: "Матфея 7:7",
            refEn: "Matthew 7:7"
        ),
        BibleVerse(
            textHy: "Ես եմ Ալֆան և Օմեգան։",
            textRu: "Я есмь Альфа и Омега.",
            textEn: "I am Alpha and Omega.",
            refHy: "Հայտնություն 22:13",
            refRu: "Откровение 22:13",
            refEn: "Revelation 22:13"
        ),
        BibleVerse(
            textHy: "Երանի՜ նրանց, որ սրտով մաքուր են։",
            textRu: "Блаженны чистые сердцем.",
            textEn: "Blessed are the pure in heart.",
            refHy: "Մատթեոս 5:8",
            refRu: "Матфея 5:8",
            refEn: "Matthew 5:8"
        ),
        BibleVerse(
            textHy: "Աստծո խաղաղությունը թող իշխի ձեր սրտերում։",
            textRu: "Да владычествует в сердцах ваших мир Божий.",
            textEn: "Let the peace of God rule in your hearts.",
            refHy: "Կողոսացիս 3:15",
            refRu: "Колоссянам 3:15",
            refEn: "Colossians 3:15"
        ),
        BibleVerse(
            textHy: "Բարին գործելիս չձանձրանանք։",
            textRu: "Делая добро, да не унываем.",
            textEn: "Let us not be weary in well doing.",
            refHy: "Գաղատացիս 6:9",
            refRu: "Галатам 6:9",
            refEn: "Galatians 6:9"
        ),
        BibleVerse(
            textHy: "Հույսով ուրախացե՛ք, նեղությանը համբերեցե՛ք։",
            textRu: "Утешайтесь надеждой, терпите в скорби.",
            textEn: "Rejoice in hope; patient in tribulation.",
            refHy: "Հռոմեացիս 12:12",
            refRu: "Римлянам 12:12",
            refEn: "Romans 12:12"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ փորձեցե՛ք, բարի՛ն պահեք։",
            textRu: "Все испытывайте, хорошего держитесь.",
            textEn: "Test all things; hold fast what is good.",
            refHy: "Ա Թեսաղոնիկեցիս 5:21",
            refRu: "1 Фессалоникийцам 5:21",
            refEn: "1 Thessalonians 5:21"
        )
    ]

    // MARK: - 2. 👑 Краткие молитвы Нарекаци (PRO) — до 55 символов
    static let shortNarekatsi: [BibleVerse] = [
        BibleVerse(
            textHy: "Ընդո՛ւնիր քաղցրությամբ, Տե՛ր, աղաչանքս։",
            textRu: "Прими с благосклонностью мольбу мою, Господи.",
            textEn: "Lord God, accept with favor my prayer.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Դո՛ւ ես իմ հոգու լույսն ու հույսը։",
            textRu: "Ты — свет и надежда души моей.",
            textEn: "Thou art light and hope of my soul.",
            refHy: "Նարեկացի • Բան ԺԲ",
            refRu: "Нарекаци • Глава 12",
            refEn: "Narekatsi • Prayer 12"
        ),
        BibleVerse(
            textHy: "Ողորմա՛ծ Տեր, խաղաղությո՛ւն տուր իմ սրտին։",
            textRu: "Господи милосердный, даруй мир сердцу моему.",
            textEn: "Merciful Lord, grant peace unto my heart.",
            refHy: "Նարեկացի • Բան ԺԸ",
            refRu: "Нарекаци • Глава 18",
            refEn: "Narekatsi • Prayer 18"
        ),
        BibleVerse(
            textHy: "Քո ձեռքն եմ հանձնում հոգիս, Տե՛ր։",
            textRu: "В Твои руки предаю душу мою, Господи.",
            textEn: "Into Thy hands I commit my soul, Lord.",
            refHy: "Նարեկացի • Բան ԻԳ",
            refRu: "Нарекаци • Глава 23",
            refEn: "Narekatsi • Prayer 23"
        ),
        BibleVerse(
            textHy: "Մաքրի՛ր մեղքերս, Քրիստո՛ս, և նորոգի՛ր հոգիս։",
            textRu: "Очисти грехи мои и обнови дух мой.",
            textEn: "Cleanse my sins, Lord, and renew my spirit.",
            refHy: "Նարեկացի • Բան ԼԳ",
            refRu: "Нарекаци • Глава 33",
            refEn: "Narekatsi • Prayer 33"
        ),
        BibleVerse(
            textHy: "Դո՛ւ ես կյանքը և փրկությունը, Աստվա՛ծ։",
            textRu: "Ты — жизнь и спасение, помилуй, Боже.",
            textEn: "Thou art life and salvation, O God.",
            refHy: "Նարեկացի • Բան ԽԱ",
            refRu: "Нарекаци • Глава 41",
            refEn: "Narekatsi • Prayer 41"
        ),
        BibleVerse(
            textHy: "Թո՛ղ Քո շնորհի լույսը ծագի իմ խավարի մեջ։",
            textRu: "Да воссияет свет благодати Твоей во тьме.",
            textEn: "Let the light of Thy grace shine on me.",
            refHy: "Նարեկացի • Բան ԾԵ",
            refRu: "Нарекаци • Глава 55",
            refEn: "Narekatsi • Prayer 55"
        ),
        BibleVerse(
            textHy: "Եղի՛ր ինձ պաշտպան և անսասան վեմ, Տե՛ր։",
            textRu: "Будь мне защитой и твердыней, Господи.",
            textEn: "Be my defense and rock, O Lord.",
            refHy: "Նարեկացի • Բան ԿԷ",
            refRu: "Нарекаци • Глава 67",
            refEn: "Narekatsi • Prayer 67"
        ),
        BibleVerse(
            textHy: "Մխիթարի՛ր սգավոր հոգիս երկնային ուրախությամբ։",
            textRu: "Утешь скорбящую душу мою небесною радостью.",
            textEn: "Comfort my sorrowful soul with heavenly joy.",
            refHy: "Նարեկացի • Բան ՀԹ",
            refRu: "Нарекаци • Глава 79",
            refEn: "Narekatsi • Prayer 79"
        ),
        BibleVerse(
            textHy: "Տե՛ր, օրհնի՛ր այս օրը Քո խաղաղությամբ։",
            textRu: "Господи, благослови сей день миром Твоим.",
            textEn: "Lord, bless this day with Thy peace.",
            refHy: "Նարեկացի • Բան ՁԸ",
            refRu: "Нарекаци • Глава 88",
            refEn: "Narekatsi • Prayer 88"
        ),
        BibleVerse(
            textHy: "Քե՛զ փառք և գոհություն հավիտյանս, Ամեն։",
            textRu: "Тебе слава и благодарение вовеки, Аминь.",
            textEn: "To Thee be glory and thanks forever, Amen.",
            refHy: "Նարեկացի • Բան ՂԳ",
            refRu: "Нарекаци • Глава 93",
            refEn: "Narekatsi • Prayer 93"
        ),
        BibleVerse(
            textHy: "Նայի՛ր ինձ սիրով և փրկի՛ր, Փրկի՛չ իմ։",
            textRu: "Взгляни с любовью и спаси, Спаситель мой.",
            textEn: "Look with love and save me, my Savior.",
            refHy: "Նարեկացի • Բան ՂԵ",
            refRu: "Нарекаци • Глава 95",
            refEn: "Narekatsi • Prayer 95"
        )
    ]

    // MARK: - 3. ✝️ Короткие Псалмы Давида (PRO) — до 50 символов
    static let shortPsalms: [BibleVerse] = [
        BibleVerse(
            textHy: "Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։",
            textRu: "Господь — Пастырь мой, я не нуждаюсь.",
            textEn: "The Lord is my shepherd; I shall not want.",
            refHy: "Սաղմոսներ 23:1",
            refRu: "Псалом 22:1",
            refEn: "Psalm 23:1"
        ),
        BibleVerse(
            textHy: "Տերն իմ լույսն է ու փրկությունը։",
            textRu: "Господь — свет мой и спасение мое.",
            textEn: "The Lord is my light and my salvation.",
            refHy: "Սաղմոսներ 27:1",
            refRu: "Псалом 26:1",
            refEn: "Psalm 27:1"
        ),
        BibleVerse(
            textHy: "Աստված մեր ապավենն է և զորությունը։",
            textRu: "Бог нам прибежище и сила в бедах.",
            textEn: "God is our refuge and our strength.",
            refHy: "Սաղմոսներ 46:1",
            refRu: "Псалом 45:2",
            refEn: "Psalm 46:1"
        ),
        BibleVerse(
            textHy: "Քո խոսքը ճրագ է իմ ոտքերի համար։",
            textRu: "Слово Твое — светильник ноге моей.",
            textEn: "Thy word is a lamp unto my feet.",
            refHy: "Սաղմոսներ 119:105",
            refRu: "Псалом 118:105",
            refEn: "Psalm 119:105"
        ),
        BibleVerse(
            textHy: "Ճաշակեցե՛ք և տեսե՛ք, թե որքան քաղցր է Տերը։",
            textRu: "Вкусите, и увидите, как благ Господь!",
            textEn: "O taste and see that the Lord is good.",
            refHy: "Սաղմոսներ 34:8",
            refRu: "Псалом 33:9",
            refEn: "Psalm 34:8"
        ),
        BibleVerse(
            textHy: "Սուրբ սի՛րտ ստեղծիր իմ մեջ, Աստվա՛ծ։",
            textRu: "Сердце чистое сотвори во мне, Боже.",
            textEn: "Create in me a clean heart, O God.",
            refHy: "Սաղմոսներ 51:10",
            refRu: "Псалом 50:12",
            refEn: "Psalm 51:10"
        ),
        BibleVerse(
            textHy: "Օրհնի՛ր, ո՛վ իմ անձ, Տիրոջը։",
            textRu: "Благослови, душа моя, Господа!",
            textEn: "Bless the Lord, O my soul.",
            refHy: "Սաղմոսներ 103:1",
            refRu: "Псалом 102:1",
            refEn: "Psalm 103:1"
        ),
        BibleVerse(
            textHy: "Սա այն օրն է, որ Տերն արեց. ցնծա՛նք։",
            textRu: "Сей день сотворил Господь: возрадуемся!",
            textEn: "This is the day which the Lord hath made.",
            refHy: "Սաղմոսներ 118:24",
            refRu: "Псалом 117:24",
            refEn: "Psalm 118:24"
        ),
        BibleVerse(
            textHy: "Տերը մոտ է բոլոր իրեն կանչողներին։",
            textRu: "Близок Господь ко всем зовущим Его.",
            textEn: "The Lord is near to all who call on Him.",
            refHy: "Սաղմոսներ 145:18",
            refRu: "Псалом 144:18",
            refEn: "Psalm 145:18"
        ),
        BibleVerse(
            textHy: "Տիրոջո՛վ ուրախացիր, և Նա կտա քո խնդրանքը։",
            textRu: "Утешайся Господом, и Он исполнит желания.",
            textEn: "Delight in the Lord, and He shall give.",
            refHy: "Սաղմոսներ 37:4",
            refRu: "Псалом 36:4",
            refEn: "Psalm 37:4"
        ),
        BibleVerse(
            textHy: "Իմ օգնությունը Տիրոջից է։",
            textRu: "Помощь моя — от Господа Всевышнего.",
            textEn: "My help cometh from the Lord.",
            refHy: "Սաղմոսներ 121:2",
            refRu: "Псалом 120:2",
            refEn: "Psalm 121:2"
        ),
        BibleVerse(
            textHy: "Միայն Աստծո մեջ է հանգստանում իմ անձը։",
            textRu: "Только в Боге успокаивается душа моя.",
            textEn: "Truly my soul waiteth upon God.",
            refHy: "Սաղմոսներ 62:1",
            refRu: "Псалом 61:2",
            refEn: "Psalm 62:1"
        ),
        BibleVerse(
            textHy: "Իմացե՛ք, որ Տերն է Աստված։",
            textRu: "Знайте, что Господь есть Бог.",
            textEn: "Know ye that the Lord he is God.",
            refHy: "Սաղմոսներ 100:3",
            refRu: "Псалом 99:3",
            refEn: "Psalm 100:3"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ կատարել Քո կամքը։",
            textRu: "Научи меня исполнять волю Твою.",
            textEn: "Teach me to do Thy will, my God.",
            refHy: "Սաղմոսներ 143:10",
            refRu: "Псалом 142:10",
            refEn: "Psalm 143:10"
        )
    ]

    // MARK: - 4. 📖 Краткая Мудрость Соломона (PRO) — до 50 символов
    static let shortWisdom: [BibleVerse] = [
        BibleVerse(
            textHy: "Ամբողջ սրտովդ Տիրո՛ջն ապավինիր։",
            textRu: "Надейся на Господа всем сердцем твоим.",
            textEn: "Trust in the Lord with all thine heart.",
            refHy: "Առակաց 3:5",
            refRu: "Притчи 3:5",
            refEn: "Proverbs 3:5"
        ),
        BibleVerse(
            textHy: "Տիրո՛ջը հանձնիր քո գործերը։",
            textRu: "Предай Господу дела твои.",
            textEn: "Commit thy works unto the Lord.",
            refHy: "Առակաց 16:3",
            refRu: "Притчи 16:3",
            refEn: "Proverbs 16:3"
        ),
        BibleVerse(
            textHy: "Մեղմ պատասխանը հանդարտեցնում է բարկությունը։",
            textRu: "Кроткий ответ отвращает гнев.",
            textEn: "A soft answer turneth away wrath.",
            refHy: "Առակաց 15:1",
            refRu: "Притчи 15:1",
            refEn: "Proverbs 15:1"
        ),
        BibleVerse(
            textHy: "Ամեն զգուշությամբ պահի՛ր քո սիրտը։",
            textRu: "Больше всего хранимого храни сердце твое.",
            textEn: "Keep thy heart with all diligence.",
            refHy: "Առակաց 4:23",
            refRu: "Притчи 4:23",
            refEn: "Proverbs 4:23"
        ),
        BibleVerse(
            textHy: "Տիրոջ անունը ամուր աշտարակ է։",
            textRu: "Имя Господа — крепкая башня праведника.",
            textEn: "The name of the Lord is a strong tower.",
            refHy: "Առակաց 18:10",
            refRu: "Притчи 18:10",
            refEn: "Proverbs 18:10"
        ),
        BibleVerse(
            textHy: "Ուրախ սիրտը բուժիչ դեղ է։",
            textRu: "Веселое сердце благотворно, как врачевство.",
            textEn: "A merry heart doeth good like a medicine.",
            refHy: "Առակաց 17:22",
            refRu: "Притчи 17:22",
            refEn: "Proverbs 17:22"
        ),
        BibleVerse(
            textHy: "Իմաստության սկիզբը Տիրոջ երկյուղն է։",
            textRu: "Начало мудрости — страх Господень.",
            textEn: "The fear of the Lord is wisdom.",
            refHy: "Առակաց 9:10",
            refRu: "Притчи 9:10",
            refEn: "Proverbs 9:10"
        ),
        BibleVerse(
            textHy: "Տերն է ուղղում մարդու քայլերը։",
            textRu: "Господь направляет шаги человека.",
            textEn: "The Lord directeth a man's steps.",
            refHy: "Առակաց 16:9",
            refRu: "Притчи 16:9",
            refEn: "Proverbs 16:9"
        ),
        BibleVerse(
            textHy: "Ինչպես ջուրը՝ այնպես սիրտը մարդու։",
            textRu: "Как в воде лицо, так сердце — к человеку.",
            textEn: "As in water face, so is heart to man.",
            refHy: "Առակաց 27:19",
            refRu: "Притчи 27:19",
            refEn: "Proverbs 27:19"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ իր ժամանակն ունի։",
            textRu: "Всему свое время под небом.",
            textEn: "To everything there is a season.",
            refHy: "Ժողովող 3:1",
            refRu: "Екклесиаст 3:1",
            refEn: "Ecclesiastes 3:1"
        ),
        BibleVerse(
            textHy: "Տիրոջ օրհնությունն է հարստացնում։",
            textRu: "Благословение Господне — оно обогащает.",
            textEn: "The blessing of the Lord, it maketh rich.",
            refHy: "Առակաց 10:22",
            refRu: "Притчи 10:22",
            refEn: "Proverbs 10:22"
        ),
        BibleVerse(
            textHy: "Բարի խոսքը ուրախացնում է սիրտը։",
            textRu: "Доброе слово развеселяет сердце.",
            textEn: "A good word maketh the heart glad.",
            refHy: "Առակաց 12:25",
            refRu: "Притчи 12:25",
            refEn: "Proverbs 12:25"
        )
    ]

    // MARK: - 5. ❤️ Короткие стихи о Любви и Мире (PRO) — до 45 символов
    static let shortLove: [BibleVerse] = [
        BibleVerse(
            textHy: "Թո՛ղ ձեր ամեն գործ սիրով լինի։",
            textRu: "Все у вас да будет с любовью.",
            textEn: "Let all that you do be done in love.",
            refHy: "Ա Կորնթացիս 16:14",
            refRu: "1 Коринфянам 16:14",
            refEn: "1 Corinthians 16:14"
        ),
        BibleVerse(
            textHy: "Աստված սեր է։",
            textRu: "Бог есть любовь, пребывайте в любви.",
            textEn: "God is love; dwell in His love.",
            refHy: "Ա Հովհաննես 4:16",
            refRu: "1 Иоанна 4:16",
            refEn: "1 John 4:16"
        ),
        BibleVerse(
            textHy: "Սերը երբեք չի դադարում։",
            textRu: "Любовь никогда не перестает.",
            textEn: "Charity never faileth.",
            refHy: "Ա Կորնթացիս 13:8",
            refRu: "1 Коринфянам 13:8",
            refEn: "1 Corinthians 13:8"
        ),
        BibleVerse(
            textHy: "Սրանցից մեծագույնը սերն է։",
            textRu: "Вера, надежда, любовь; но больше — любовь.",
            textEn: "Faith, hope, love; greatest of these is love.",
            refHy: "Ա Կորնթացիս 13:13",
            refRu: "1 Коринфянам 13:13",
            refEn: "1 Corinthians 13:13"
        ),
        BibleVerse(
            textHy: "Հագե՛ք սերը, որ կատարելության կապն է։",
            textRu: "Облекитесь в любовь, союз совершенства.",
            textEn: "Put on love, the bond of perfection.",
            refHy: "Կողոսացիս 3:14",
            refRu: "Колоссянам 3:14",
            refEn: "Colossians 3:14"
        ),
        BibleVerse(
            textHy: "Սիրեցե՛ք միմյանց։",
            textRu: "Заповедь новую даю вам: да любите друг друга.",
            textEn: "A new commandment I give: love one another.",
            refHy: "Հովհաննես 13:34",
            refRu: "Иоанна 13:34",
            refEn: "John 13:34"
        ),
        BibleVerse(
            textHy: "Մենք սիրում ենք, քանի որ Նա նախ սիրեց մեզ։",
            textRu: "Будем любить, ибо Он первый возлюбил нас.",
            textEn: "We love him, because he first loved us.",
            refHy: "Ա Հովհաննես 4:19",
            refRu: "1 Иоанна 4:19",
            refEn: "1 John 4:19"
        ),
        BibleVerse(
            textHy: "Մնացե՛ք իմ սիրո մեջ։",
            textRu: "Пребудьте в любви Моей, говорит Господь.",
            textEn: "Continue ye in my love, saith the Lord.",
            refHy: "Հովհաննես 15:9",
            refRu: "Иоанна 15:9",
            refEn: "John 15:9"
        ),
        BibleVerse(
            textHy: "Սիրենք գործով և ճշմարտությամբ։",
            textRu: "Будем любить делом и истиною.",
            textEn: "Let us love in deed and in truth.",
            refHy: "Ա Հովհաննես 3:18",
            refRu: "1 Иоанна 3:18",
            refEn: "1 John 3:18"
        ),
        BibleVerse(
            textHy: "Սերը օրենքի լրումն է։",
            textRu: "Любовь есть исполнение закона.",
            textEn: "Love is the fulfilling of the law.",
            refHy: "Հռոմեացիս 13:10",
            refRu: "Римлянам 13:10",
            refEn: "Romans 13:10"
        ),
        BibleVerse(
            textHy: "Սերը ծածկում է մեղքերի բազմությունը։",
            textRu: "Любовь покрывает множество грехов.",
            textEn: "Charity shall cover the multitude of sins.",
            refHy: "Ա Պետրոս 4:8",
            refRu: "1 Петра 4:8",
            refEn: "1 Peter 4:8"
        )
    ]

    // MARK: - 6. ⚓ Короткие стихи о Вере и Мужестве (PRO) — до 45 символов
    static let shortFaith: [BibleVerse] = [
        BibleVerse(
            textHy: "Հավատքո՛վ ենք ընթանում։",
            textRu: "Мы ходим верою, а не видением.",
            textEn: "For we walk by faith, not by sight.",
            refHy: "Բ Կորնթացիս 5:7",
            refRu: "2 Коринфянам 5:7",
            refEn: "2 Corinthians 5:7"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, միայն հավատա՛։",
            textRu: "Не бойся, только веруй.",
            textEn: "Be not afraid, only believe.",
            refHy: "Մարկոս 5:36",
            refRu: "Марка 5:36",
            refEn: "Mark 5:36"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ հնարավոր է հավատացողին։",
            textRu: "Все возможно верующему.",
            textEn: "All things are possible to him that believeth.",
            refHy: "Մարկոս 9:23",
            refRu: "Марка 9:23",
            refEn: "Mark 9:23"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսով։",
            textRu: "Все могу в укрепляющем меня Христе.",
            textEn: "I can do all things through Christ.",
            refHy: "Փիլիպպեցիներին 4:13",
            refRu: "Филиппийцам 4:13",
            refEn: "Philippians 4:13"
        ),
        BibleVerse(
            textHy: "Հավատը հուսացված բաների հաստատումն է։",
            textRu: "Вера есть уверенность в невидимом.",
            textEn: "Faith is the substance of things hoped for.",
            refHy: "Եբրայեցիս 11:1",
            refRu: "Евреям 11:1",
            refEn: "Hebrews 11:1"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, քանզի ես քեզ հետ եմ։",
            textRu: "Не бойся, ибо Я с тобою; Я Бог твой.",
            textEn: "Fear thou not; for I am with thee.",
            refHy: "Եսայի 41:10",
            refRu: "Исаия 41:10",
            refEn: "Isaiah 41:10"
        ),
        BibleVerse(
            textHy: "Տիրոջն ապավինողները կնորոգվեն ուժով։",
            textRu: "Надеющиеся на Господа обновятся в силе.",
            textEn: "They that wait upon the Lord renew strength.",
            refHy: "Եսայի 40:31",
            refRu: "Исаия 40:31",
            refEn: "Isaiah 40:31"
        ),
        BibleVerse(
            textHy: "Զորացե՛ք Տիրոջով և Նրա զորության կարողությամբ։",
            textRu: "Укрепляйтесь Господом и силою Его.",
            textEn: "Be strong in the Lord and in His power.",
            refHy: "Եփեսացիս 6:10",
            refRu: "Ефесянам 6:10",
            refEn: "Ephesians 6:10"
        ),
        BibleVerse(
            textHy: "Զորացի՛ր և քա՛ջ եղիր, Տերը քեզ հետ է։",
            textRu: "Будь тверд и мужествен, Господь с тобою.",
            textEn: "Be strong and courageous; God is with thee.",
            refHy: "Հեսու 1:9",
            refRu: "Иисус Навин 1:9",
            refEn: "Joshua 1:9"
        ),
        BibleVerse(
            textHy: "Հավատարիմ է Խոստացողը։",
            textRu: "Будем держаться веры, ибо верен Обещавший.",
            textEn: "Hold fast our faith, for He is faithful.",
            refHy: "Եբրայեցիս 10:23",
            refRu: "Евреям 10:23",
            refEn: "Hebrews 10:23"
        ),
        BibleVerse(
            textHy: "Եթե Աստված մեր կողմն է, ո՞վ է մեզ հակառակ։",
            textRu: "Если Бог за нас, кто против нас?",
            textEn: "If God be for us, who can be against us?",
            refHy: "Հռոմեացիս 8:31",
            refRu: "Римлянам 8:31",
            refEn: "Romans 8:31"
        ),
        BibleVerse(
            textHy: "Աստված մեզ զորության և սիրո ոգի տվեց։",
            textRu: "Дал нам Бог духа силы, любви и целомудрия.",
            textEn: "God gave us the spirit of power and of love.",
            refHy: "Բ Տիմոթեոս 1:7",
            refRu: "2 Тимофею 1:7",
            refEn: "2 Timothy 1:7"
        )
    ]

    /// Обратная совместимость для виджетов и представлений
    static var lockScreenPearls: [BibleVerse] {
        return shortPearls
    }

    /// Получение строго уникального массива коротких стихов для выбранной категории экрана блокировки
    static func lockScreenVerses(for category: LockScreenCategory) -> [BibleVerse] {
        switch category {
        case .pearls:
            return shortPearls
        case .narekatsi:
            return shortNarekatsi
        case .psalms:
            return shortPsalms
        case .wisdom:
            return shortWisdom
        case .love:
            return shortLove
        case .faith:
            return shortFaith
        }
    }

    static let database: [BibleVerse] = [
        BibleVerse(
            textHy: "Որովհետև Աստված այնքան սիրեց աշխարհը, որ իր միածին Որդուն տվեց, որպեսզի ամեն նրան հավատացողը չկորչի, այլ հավիտենական կյանք ունենա։",
            textRu: "Ибо так возлюбил Бог мир, что отдал Сына Своего Единородного, дабы всякий верующий в Него не погиб, но имел жизнь вечную.",
            textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            refHy: "Հովհաննես 3:16",
            refRu: "Иоанна 3:16",
            refEn: "John 3:16"
        ),
        BibleVerse(
            textHy: "Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ Կանաչ մարգագետիններում նա ինձ պառկեցնում է և հանդարտ ջрերի մոտ է տանում ինձ։",
            textRu: "Господь — Пастырь мой; я ни в чем не буду нуждаться. Он покоит меня на злачных пажитях и водит меня к водам тихим.",
            textEn: "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.",
            refHy: "Սաղմոսներ 23:1-2",
            refRu: "Псалом 22:1-2",
            refEn: "Psalm 23:1-2"
        ),
        BibleVerse(
            textHy: "Չէ՞ որ ես քեզ պատվիրեցի. զորացի՛ր և քա՛ջ եղիր, մի՛ վախեցիր և մի՛ զարհուրիր, որովհետև քո Տեր Աստվածը քեզ հետ է ամեն տեղ, ուր էլ որ գնաս։",
            textRu: "Вот Я повелеваю тебе: будь тверд и мужествен, не страшись и не ужасаяся; ибо с тобою Господь Бог твой везде, куда ни пойдешь.",
            textEn: "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee whithersoever thou goest.",
            refHy: "Հեսու 1:9",
            refRu: "Иисус Навин 1:9",
            refEn: "Joshua 1:9"
        ),
        BibleVerse(
            textHy: "Ամբողջ սրտովդ Տիրոջն ապավինիր և քո սեփական հասկացողությանը մի՛ վստահիր: Քո բոլոր ճանապարհներին ճանաչի՛ր նրան, և նա կուղղի քո շավիղները:",
            textRu: "Надейся на Господа всем сердцем твоим, и не полагайся на разум твой. Во всех путях твоих познавай Его, и Он направит стези твои.",
            textEn: "Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.",
            refHy: "Առակաց 3:5-6",
            refRu: "Притчи 3:5-6",
            refEn: "Proverbs 3:5-6"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսի միջոցով։",
            textRu: "Все могу в укрепляющем меня Иисусе Христе.",
            textEn: "I can do all things through Christ which strengtheneth me.",
            refHy: "Փիլիպպեցիներին 4:13",
            refRu: "Филиппийцам 4:13",
            refEn: "Philippians 4:13"
        ),
        BibleVerse(
            textHy: "Գիտենք նաև, որ Աստծուն սիրողներին ամեն ինչ գործակից է լինում բարու համար, նրանց, որ կանչվեցին նրա նախասահմանումով։",
            textRu: "Притом знаем, что любящим Бога, призванным по Его изволению, все содействует ко благу.",
            textEn: "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
            refHy: "Հռոմեացիներին 8:28",
            refRu: "Римлянам 8:28",
            refEn: "Romans 8:28"
        ),
        BibleVerse(
            textHy: "Որովհետև ես գիտեմ այն խորհուրդները, որ խորհում եմ ձեր մասին,- ասում է Տերը,- խաղաղության խորհուրդներ և ոչ թե չարիքի, որպեսզի ձեզ ապագա և հույս տամ։",
            textRu: "Ибо только Я знаю намерения, какие имею о вас, говорит Господь, намерения во благо, а не на зло, чтобы дать вам будущность и надежду.",
            textEn: "For I know the thoughts that I think toward you, saith the Lord, thoughts of peace, and not of evil, to give you an expected end.",
            refHy: "Երեմիա 29:11",
            refRu: "Иеремия 29:11",
            refEn: "Jeremiah 29:11"
        ),
        BibleVerse(
            textHy: "Եվ մի՛ կերպարանվեք այս աշխարհի կերպարանքով, այլ նորոգվե՛ք ձեր մտքի նորոգությամբ, որպեսզի քննեք, թե ի՛նչ է Աստծու կամքը՝ բարին, հաճելին և կատարյալը։",
            textRu: "И не сообразуйтесь с веком сим, но преобразуйтесь обновлением ума вашего, чтобы вам познавать, что есть воля Божия, благая, угодная и совершенная.",
            textEn: "And be not conformed to this world: but be ye transformed by the renewing of your mind, that ye may prove what is that good, and acceptable, and perfect, will of God.",
            refHy: "Հռոմեացիներին 12:2",
            refRu: "Римлянам 12:2",
            refEn: "Romans 12:2"
        ),
        BibleVerse(
            textHy: "Իսկ Հոգու պտուղն է՝ սեր, ուրախություն, խաղաղություն, երկայնամտություն, քաղցրություն, բարություն, հավատարմություն, հեզություն, ժուժկալություն։",
            textRu: "Плод же духа: любовь, радость, мир, долготерпение, благость, милосердие, вера, кротость, воздержание.",
            textEn: "But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance.",
            refHy: "Գաղատացիներին 5:22-23",
            refRu: "Галатам 5:22-23",
            refEn: "Galatians 5:22-23"
        ),
        BibleVerse(
            textHy: "Քո խոսքը ճրագ է իմ ոտքերի համար և լույս՝ իմ ճանապարհին:",
            textRu: "Слово Твое — светильник ноге моей и свет стезе моей.",
            textEn: "Thy word is a lamp unto my feet, and a light unto my path.",
            refHy: "Սաղմոսներ 119:105",
            refRu: "Псалом 118:105",
            refEn: "Psalm 119:105"
        ),
        BibleVerse(
            textHy: "Եկե՛ք ինձ մոտ, բոլոր հոգնածնե՛րդ և բեռնավորվածնե՛րդ, և ես ձեզ հանգիստ կտամ:",
            textRu: "Придите ко Мне все труждающиеся и обремененные, и Я успокою вас.",
            textEn: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
            refHy: "Մատթեոս 11:28",
            refRu: "Матфея 11:28",
            refEn: "Matthew 11:28"
        ),
        BibleVerse(
            textHy: "Հիսուսը նրան ասաց. «Ես եմ ճանապարհը, ճշմարտությունը և կյանքը. ոչ ոք չի գալիս Հոր մոտ, եթե ոչ իմ միջոցով»։",
            textRu: "Иисус сказал ему: Я есмь путь и истина и жизнь; никто не приходит к Отцу, как только через Меня.",
            textEn: "Jesus saith unto him, I am the way, the truth, and the life: no man cometh unto the Father, but by me.",
            refHy: "Հովհաննես 14:6",
            refRu: "Иоанна 14:6",
            refEn: "John 14:6"
        ),
        BibleVerse(
            textHy: "Սերը համբերող է, քաղցրաբարո է. սերը չի նախանձում, սերը չի գոռոզանում, չի հպարտանում, անվայել վարմունք չի ունենում, իրենը չի փնտրում, բարկությամբ չի գրգռվում, չար բան չի խորհում։",
            textRu: "Любовь долготерпит, милосердствует, любовь не завидует, любовь не превозносится, не гордится, не бесчинствует, не ищет своего, не раздражается, не умышляет зла.",
            textEn: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up, Doth not behave itself unseemly, seeketh not her own, is not easily provoked, thinketh no evil.",
            refHy: "Ա Կորնթացիներին 13:4-5",
            refRu: "1 Коринфянам 13:4-5",
            refEn: "1 Cor 13:4-5"
        ),
        BibleVerse(
            textHy: "Որովհետև Աստված մեզ երկչոտության հոգի չտվեց, այլ՝ զորության, սիրո և ողջախոհության:",
            textRu: "Ибо дал нам Бог духа не боязни, но силы и любви и целомудрия.",
            textEn: "For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.",
            refHy: "Բ Տիմոթեոս 1:7",
            refRu: "2 Тимофею 1:7",
            refEn: "2 Timothy 1:7"
        ),
        BibleVerse(
            textHy: "Իսկ Տիրոջն սպասողները նոր ուժ կստանան, արծիվների պես թևերով վեր կսլանան, կվազեն ու չեն հոգնի, կքայլեն ու չեն նվաղի։",
            textRu: "А надеющиеся на Господа обновятся в силе: поднимут крылья, как орлы, потекут — и не устанут, пойдут — и не утомятся.",
            textEn: "But they that wait upon the Lord shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.",
            refHy: "Եսայիա 40:31",
            refRu: "Исаия 40:31",
            refEn: "Isaiah 40:31"
        ),
        BibleVerse(
            textHy: "Հավատն այն բաների հաստատումն է, որոնց հույսն ունենք, և ապացույցն այն բաների, որոնք չեն երևում։",
            textRu: "Вера же есть осуществление ожидаемого и уверенность в невидимом.",
            textEn: "Now faith is the substance of things hoped for, the evidence of things not seen.",
            refHy: "Եբրայեցիներին 11:1",
            refRu: "Евреям 11:1",
            refEn: "Hebrews 11:1"
        ),
        BibleVerse(
            textHy: "Աստված մեր ապավենն է և զորությունը, մեծ օգնական՝ նեղությունների մեջ:",
            textRu: "Бог нам прибежище и сила, скорый помощник в бедах.",
            textEn: "God is our refuge and strength, a very present help in trouble.",
            refHy: "Սաղմոսներ 46:1",
            refRu: "Псалом 45:2",
            refEn: "Psalm 46:1"
        ),
        BibleVerse(
            textHy: "Սիրո մեջ վախ չկա, այլ կատարյալ սերն արտաքսում է վախը:",
            textRu: "В любви нет страха, но совершенная любовь изгоняет страх.",
            textEn: "There is no fear in love; but perfect love casteth out fear.",
            refHy: "Ա Հովհաննես 4:18",
            refRu: "1 Иоанна 4:18",
            refEn: "1 John 4:18"
        ),
        BibleVerse(
            textHy: "Տիրոջո՛վ ուրախացիր, և նա կտա քեզ քո սրտի փափագները:",
            textRu: "Утешайся Господом, и Он исполнит желания сердца твоего.",
            textEn: "Delight thyself also in the Lord; and he shall give thee the desires of thine heart.",
            refHy: "Սաղմոսներ 37:4",
            refRu: "Псалом 36:4",
            refEn: "Psalm 37:4"
        ),
        BibleVerse(
            textHy: "Նախ խնդրեցե՛ք Աստծո արքայությունը և նրա արդարությունը, և այդ ամենը ավելիով կտրվի ձեզ:",
            textRu: "Ищите же прежде Царства Божия и правды Его, и это все приложится вам.",
            textEn: "But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.",
            refHy: "Մատթեոս 6:33",
            refRu: "Матфея 6:33",
            refEn: "Matthew 6:33"
        ),
        BibleVerse(
            textHy: "Ավելի մեծ սեր ոչ ոք ունի, քան այն, որ մեկն իր կյանքը դնի իր բարեկամների համար։",
            textRu: "Нет больше той любви, как если кто положит душу свою за друзей своих.",
            textEn: "Greater love hath no man than this, that a man lay down his life for his friends.",
            refHy: "Հովհաննես 15:13",
            refRu: "Иоанна 15:13",
            refEn: "John 15:13"
        ),
        BibleVerse(
            textHy: "Այսուհետև զորացե՛ք Տիրոջով և նրա ուժի կարողությամբ։",
            textRu: "Наконец, братия мои, укрепляйтесь Господом и могуществом силы Его.",
            textEn: "Finally, my brethren, be strong in the Lord, and in the power of his might.",
            refHy: "Եֆեսացիներին 6:10",
            refRu: "Ефесянам 6:10",
            refEn: "Ephesians 6:10"
        ),
        BibleVerse(
            textHy: "Եվ հույսի Աստվածը թող ձեզ լցնի ամենայն ուրախությամբ և խաղաղությամբ՝ հավատալու մեջ, որպեսզի հույսով առատանաք Սուրբ Հոգու զորությամբ։",
            textRu: "Бог же надежды да исполнит вас всякого радости и мира во вере, дабы вы изобиловали надеждою, силою Духа Святаго.",
            textEn: "Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.",
            refHy: "Հռոմեացիներին 15:13",
            refRu: "Римлянам 15:13",
            refEn: "Romans 15:13"
        ),
        BibleVerse(
            textHy: "Եթե ձեզնից որևէ մեկն իմաստության պակաս ունի, թող խնդրի Աստծուց, որ բոլորին տալիս է առատությամբ և չի նախատում, և նրան կտրվի։",
            textRu: "Если же у кого из вас недостает мудрости, да просит у Бога, дающего всем просто и без упреков, — и дастся ему.",
            textEn: "If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.",
            refHy: "Հակոբոս 1:5",
            refRu: "Иакова 1:5",
            refEn: "James 1:5"
        ),
        BibleVerse(
            textHy: "Ձեր ամբողջ հոգսը նրա վրա՛ գցեք, որովհետև նա հոգ է տանում ձեր մասին։",
            textRu: "Все заботы ваши возложите на Него, ибо Он печется о вас.",
            textEn: "Casting all your care upon him; for he careth for you.",
            refHy: "Ա Պետրоս 5:7",
            refRu: "1 Петра 5:7",
            refEn: "1 Peter 5:7"
        ),
        BibleVerse(
            textHy: "Տերն իմ լույսն է և իմ փրկությունը, ումի՞ց վախենամ. Տերն իմ կյանքի ապավենն է:",
            textRu: "Господь — свет мой и спасение мое: кого мне бояться? Господь крепость жизни моей: кого мне страшиться?",
            textEn: "The Lord is my light and my salvation; whom shall I fear? the Lord is the strength of my life; of whom shall I be afraid?",
            refHy: "Սաղմոսներ 27:1",
            refRu: "Псалом 26:1",
            refEn: "Psalm 27:1"
        ),
        BibleVerse(
            textHy: "Երանի՜ նրանց, որ սրտով մաքուր են, որովհետև նրանք Աստծուն պիտի տեսնեն։",
            textRu: "Блаженны чистые сердцем, ибо они Бога узрят.",
            textEn: "Blessed are the pure in heart: for they shall see God.",
            refHy: "Մատթեոս 5:8",
            refRu: "Матфея 5:8",
            refEn: "Matthew 5:8"
        ),
        BibleVerse(
            textHy: "Երանի՜ խաղաղարարներին, որովհետև նրանք Աստծու որդիներ պիտի կոչվեն։",
            textRu: "Блаженны миротворцы, ибо они сынами Божиими нарекутся.",
            textEn: "Blessed are the peacemakers: for they shall be called the children of God.",
            refHy: "Մատթեոս 5:9",
            refRu: "Матфея 5:9",
            refEn: "Matthew 5:9"
        ),
        BibleVerse(
            textHy: "Այդպես թող փայլի ձեր լույսը մարդկանց առաջ, որպեսզի տեսնեն ձեր բարի գործերը և փառավորեն ձեր Երկնավոր Հորը:",
            textRu: "Так да светит свет ваш пред людьми, чтобы они видели ваши добрые дела и прославляли Отца вашего Небесного.",
            textEn: "Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.",
            refHy: "Մատթեոս 5:16",
            refRu: "Матфея 5:16",
            refEn: "Matthew 5:16"
        ),
        BibleVerse(
            textHy: "Խնդրեցե՛ք, և կտրվի ձեզ, փնտրեցե՛ք և կգտնեք, բախեցե՛ք, և կբացվի ձեզ։",
            textRu: "Просите, и дано будет вам; ищите, и найдете; стучите, и отворят вам.",
            textEn: "Ask, and it shall be given you; seek, and ye shall find; knock, and it shall be opened unto you.",
            refHy: "Մատթեոս 7:7",
            refRu: "Матфея 7:7",
            refEn: "Matthew 7:7"
        ),
        BibleVerse(
            textHy: "Հիսուսը նայեց նրանց և ասաց. «Մարդկանց համար դա անհնար է, բայց Աստծու համար ամեն ինչ հնարավոր է»։",
            textRu: "А Иисус, воззрев, сказал им: человекам это невозможно, Богу же все возможно.",
            textEn: "But Jesus beheld them, and said unto them, With men this is impossible; but with God all things are possible.",
            refHy: "Մատթեոս 19:26",
            refRu: "Матфея 19:26",
            refEn: "Matthew 19:26"
        ),
        BibleVerse(
            textHy: "Հիսուսը նրան ասաց. «Սիրի՛ր քо Տեր Աստծուն քո ամբողջ սրտով, քո ամբողջ հոգով և քո ամբողջ մտքով»։",
            textRu: "Иисус сказал ему: возлюби Господа Бога твоего всем сердцем твоим и всею душею твоею и всем разумением твоим.",
            textEn: "Jesus said unto him, Thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind.",
            refHy: "Մատթեոս 22:37",
            refRu: "Матфея 22:37",
            refEn: "Matthew 22:37"
        ),
        BibleVerse(
            textHy: "Եվ ահա ես ձեզ հետ եմ ամեն օր՝ մինչև աշխարհի վախճանը։",
            textRu: "И се, Я с вами во все дни до скончания века. Аминь.",
            textEn: "And, lo, I am with you alway, even unto the end of the world. Amen.",
            refHy: "Մատթեոս 28:20",
            refRu: "Матфея 28:20",
            refEn: "Matthew 28:20"
        ),
        BibleVerse(
            textHy: "Սկզբում էր Խոսքը, և Խոսքը Աստծու մոտ էր, և Խոսքը Աստված էր։",
            textRu: "В начале было Слово, и Слово было у Бога, и Слово было Бог.",
            textEn: "In the beginning was the Word, and the Word was with God, and the Word was God.",
            refHy: "Հովհաննես 1:1",
            refRu: "Иоанна 1:1",
            refEn: "John 1:1"
        ),
        BibleVerse(
            textHy: "Ես եմ աշխարհի լույսը. ով իմ հետևից է գալիս, խավարի մեջ չի քայլի, այլ կունենա կյանքի լույսը:",
            textRu: "Я свет миру; кто последует за Мною, тот не будет ходить во тьме, но будет иметь свет жизни.",
            textEn: "I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.",
            refHy: "Հովհաննես 8:12",
            refRu: "Иоанна 8:12",
            refEn: "John 8:12"
        ),
        BibleVerse(
            textHy: "Եվ կճանաչեք ճշմարտությունը, և ճշմարտությունը կազատի ձեզ։",
            textRu: "И познаете истину, и истина сделает вас свободными.",
            textEn: "And ye shall know the truth, and the truth shall make you free.",
            refHy: "Հովհաննես 8:32",
            refRu: "Иоанна 8:32",
            refEn: "John 8:32"
        ),
        BibleVerse(
            textHy: "Խաղաղություն եմ թողնում ձեզ, իմ խաղաղությունն եմ տալիս ձեզ. ոչ ինչպես աշխարհն է տալիս, ես եմ տալիս ձեզ: Ձեր սիրտը թող չխռովվի և չվախենա:",
            textRu: "Мир оставляю вам, мир Мой даю вам; не так, как мир дает, Я даю вам. Да не смущается сердце ваше и да не устрашается.",
            textEn: "Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you. Let not your heart be troubled, neither let it be afraid.",
            refHy: "Հովհաննես 14:27",
            refRu: "Иоанна 14:27",
            refEn: "John 14:27"
        ),
        BibleVerse(
            textHy: "Աշխարհում նեղություն պիտի ունենաք, բայց քաջալերվեցե՛ք, ես հաղթել եմ աշխարհին։",
            textRu: "В мире будете иметь скорбь; но мужайтесь: Я победил мир.",
            textEn: "In the world ye shall have tribulation: but be of good cheer; I have overcome the world.",
            refHy: "Հովհաննես 16:33",
            refRu: "Иоанна 16:33",
            refEn: "John 16:33"
        ),
        BibleVerse(
            textHy: "Իսկ արդ, ի՞նչ ասենք այս բաների մասին։ Եթե Աստված մեր կողմն է, ո՞վ կլինի մեզ հակառակ։",
            textRu: "Что же сказать на это? Если Бог за нас, кто против нас?",
            textEn: "What shall we then say to these things? If God be for us, who can be against us?",
            refHy: "Հռոմեացիներին 8:31",
            refRu: "Римлянам 8:31",
            refEn: "Romans 8:31"
        ),
        BibleVerse(
            textHy: "Մի՛ հաղթվիր չարից, այլ բարիո՛վ հաղթիր չարին։",
            textRu: "Не будь побежден злом, но побеждай зло добром.",
            textEn: "Be not overcome of evil, but overcome evil with good.",
            refHy: "Հռոմեացիներին 12:21",
            refRu: "Римлянам 12:21",
            refEn: "Romans 12:21"
        ),
        BibleVerse(
            textHy: "Ձեր ամեն գործ սիրո՛վ թող լինի։",
            textRu: "Все у вас да будет с любовью.",
            textEn: "Let all your things be done with charity.",
            refHy: "Ա Կորնթացիներին 16:14",
            refRu: "1 Коринфянам 16:14",
            refEn: "1 Corinthians 16:14"
        ),
        BibleVerse(
            textHy: "Ուստի եթե մեկը Քրիստոսի մեջ է, նա նոր արարած է. հինն անցավ, և ահա ամեն ինչ նոր եղավ։",
            textRu: "Итак, кто во Христе, тот новая тварь; древнее прошло, теперь все новое.",
            textEn: "Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.",
            refHy: "Բ Կորնթացիներին 5:17",
            refRu: "2 Коринфянам 5:17",
            refEn: "2 Corinthians 5:17"
        ),
        BibleVerse(
            textHy: "Որովհետև շնորհով եք փրկված հավատի միջոցով, և սա ոչ թե ձեզնից է, այլ Աստծու պարգևն է։",
            textRu: "Ибо благодатью вы спасены через веру, и сие не от вас, Божий дар.",
            textEn: "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God.",
            refHy: "Եփեսացիներին 2:8",
            refRu: "Ефесянам 2:8",
            refEn: "Ephesians 2:8"
        ),
        BibleVerse(
            textHy: "Ոչ մի բանի համար հոգս մի՛ արեք, այլ ամեն ինչում աղոթքով և աղաչանքով, գոհությամբ հանդերձ, ձեր խնդրանքները թող հայտնի լինեն Աստծուն։",
            textRu: "Не заботьтесь ни о чем, но всегда в молитве и прошении с благодарением открывайте свои желания пред Богом.",
            textEn: "Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.",
            refHy: "Փիլիպպեցիներին 4:6",
            refRu: "Филиппийцам 4:6",
            refEn: "Philippians 4:6"
        ),
        BibleVerse(
            textHy: "Ամեն ժամ ուրա՛խ եղեք։ Անդադա՛ր աղոթեցեք։ Ամեն ինչի համար գոհությո՛ւն հայտնեցեք, որովհետև սա է Աստծու կամքը ձեր հանդեպ Քրիստոս Հիսուսով։",
            textRu: "Всегда радуйтесь. Непрестанно молитесь. За все благодарите: ибо такова о вас воля Божия во Христе Иисусе.",
            textEn: "Rejoice evermore. Pray without ceasing. In every thing give thanks: for this is the will of God in Christ Jesus concerning you.",
            refHy: "Ա Թեսաղոնիկեցիներին 5:16-18",
            refRu: "1 Фессалоникийцам 5:16-18",
            refEn: "1 Thess 5:16-18"
        ),
        BibleVerse(
            textHy: "Հիսուս Քրիստոսը նույնն է երեկ, այսօր և հավիտյան։",
            textRu: "Иисус Христос вчера и сегодня и вовеки Тот же.",
            textEn: "Jesus Christ the same yesterday, and to day, and for ever.",
            refHy: "Եբրայեցիներին 13:8",
            refRu: "Евреям 13:8",
            refEn: "Hebrews 13:8"
        ),
        BibleVerse(
            textHy: "Ով չի սիրում, նա չի ճանաչում Աստծուն, որովհետև Աստված սեր է։",
            textRu: "Кто не любит, тот не познал Boga, потому что Бог есть любовь.",
            textEn: "He that loveth not knoweth not God; for God is love.",
            refHy: "Ա Հովհաննես 4:8",
            refRu: "1 Иоанна 4:8",
            refEn: "1 John 4:8"
        ),
        BibleVerse(
            textHy: "Բերանիս խոսքերն ու սրտիս խորհուրդները հաճելի թող լինեն քո առաջ, Տե՛ր, իմ Վե՛մ և իմ Փրկի՛չ։",
            textRu: "Да будут слова уст моих и помышление сердца моего благоугодны пред Тобою, Господи, твердыня моя и Избавитель мой!",
            textEn: "Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O Lord, my strength, and my redeemer.",
            refHy: "Սաղմոսներ 19:14",
            refRu: "Псалом 18:15",
            refEn: "Psalm 19:14"
        ),
        BibleVerse(
            textHy: "Քո ճանապարհը Տիրո՛ջը հանձնիր և նրա՛ն հուսա. նա կկատարի այն։",
            textRu: "Предай Господу путь твой и уповай на Него, и Он совершит.",
            textEn: "Commit thy way unto the Lord; trust also in him; and he shall bring it to pass.",
            refHy: "Սաղմոսներ 37:5",
            refRu: "Псалом 36:5",
            refEn: "Psalm 37:5"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, որովհետև ես քեզ հետ եմ. մի՛ զարհուրիր, որովհետև ես քո Աստվածն եմ. ես կզորացնեմ քեզ և կօգնեմ քեզ...",
            textRu: "Не бойся, ибо Я с тобою; не смущайся, ибо Я Бог твой; Я укреплю тебя, и помогу тебе...",
            textEn: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee...",
            refHy: "Եսայիա 41:10",
            refRu: "Исаия 41:10",
            refEn: "Isaiah 41:10"
        ),
        BibleVerse(
            textHy: "Տերը մոտ է սրտով կոտրվածներին և փրկում է հոգով խոնարհներին։",
            textRu: "Близко Господь к сокрушенным сердцем и смиренных духом спасет.",
            textEn: "The Lord is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.",
            refHy: "Սաղմոսներ 34:18",
            refRu: "Псалом 33:19",
            refEn: "Psalm 34:18"
        ),
        BibleVerse(
            textHy: "Համբերությամբ սպասեցի Տիրոջը, և նա հակվեց դեպի ինձ ու լսեց իմ աղաղակը։",
            textRu: "Твердо уповал я на Господа, и Он приклонился ко мне и услышал вопль мой.",
            textEn: "I waited patiently for the Lord; and he inclined unto me, and heard my cry.",
            refHy: "Սաղմոսներ 40:1",
            refRu: "Псалом 39:2",
            refEn: "Psalm 40:1"
        ),
        BibleVerse(
            textHy: "Քո հոգսը Տիրո՛ջ վրա գցիր, և նա կհոգա քեզ. նա երբեք թույլ չի տա, որ արդարը սասանվի։",
            textRu: "Возложи на Господа заботы твои, и Он поддержит тебя. Никогда не даст Он поколебаться праведнику.",
            textEn: "Cast thy burden upon the Lord, and he shall sustain thee: he shall never suffer the righteous to be moved.",
            refHy: "Սաղմոսներ 55:22",
            refRu: "Псалом 54:23",
            refEn: "Psalm 55:22"
        ),
        BibleVerse(
            textHy: "Միայն Աստծով է հանդարտվում իմ անձը, նրանից է իմ փրկությունը։",
            textRu: "Только в Боге успокаивается душа моя: от Него спасение мое.",
            textEn: "Truly my soul waiteth upon God: from him cometh my salvation.",
            refHy: "Սաղմոսներ 62:1",
            refRu: "Псалом 61:2",
            refEn: "Psalm 62:1"
        ),
        BibleVerse(
            textHy: "Որովհետև Տեր Աստվածը արև է և վահան. Տերը շնորհ և փառք է տալիս, ոչ մի բարիք չի զլանում ուղղությամբ ընթացողներից։",
            textRu: "Ибо Господь Бог есть солнце и щит, Господь дает благодать и славу; ходящих в непорочности Он не лишает благ.",
            textEn: "For the Lord God is a sun and shield: the Lord will give grace and glory: no good thing will he withhold from them that walk uprightly.",
            refHy: "Սաղմոսներ 84:11",
            refRu: "Псалом 83:12",
            refEn: "Psalm 84:11"
        ),
        BibleVerse(
            textHy: "Բայց Դու, Տե՛ր, գթած և ողորմած Աստված ես, երկայնամիտ և բազումողորմ ու ճշմարիտ։",
            textRu: "Но Ты, Господи, Бог щедрый и благосердный, долготерпеливый и многомилостивый и истинный.",
            textEn: "But thou, O Lord, art a God full of compassion, and gracious, longsuffering, and plenteous in mercy and truth.",
            refHy: "Սաղմոսներ 86:15",
            refRu: "Псалом 85:15",
            refEn: "Psalm 86:15"
        ),
        BibleVerse(
            textHy: "Բարձրյալի ծածկոցի տակ բնակվողը Ամենակարողի հովանու տակ է հանգստանում: Ես Տիրոջն ասում եմ. «Իմ ապավենն ու իմ ամրոցն ես»:",
            textRu: "Живущий под кровом Всевышнего под сенью Всемогущего покоится, говорит Господу: «прибежище мое и защита моя, Бог мой, на Которого я уповаю!»",
            textEn: "He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty. I will say of the Lord, He is my refuge and my fortress.",
            refHy: "Սաղմոսներ 91:1-2",
            refRu: "Псалом 90:1-2",
            refEn: "Psalm 91:1-2"
        ),
        BibleVerse(
            textHy: "Որովհետև Տերը բարի է, նրա ողորմությունը հավիտենական է, և նրա հավատարմությունը՝ ազգից մինչև ազգ։",
            textRu: "Ибо благ Господь: милость Его вовек, и истина Его в род и род.",
            textEn: "For the Lord is good; his mercy is everlasting; and his truth endureth to all generations.",
            refHy: "Սաղմոսներ 100:5",
            refRu: "Псалом 99:5",
            refEn: "Psalm 100:5"
        ),
        BibleVerse(
            textHy: "Գոհացե՛ք Տիրոջից, որովհետև բարի է, որովհետև հավիտենական է նրա ողորմությունը։",
            textRu: "Славьте Господа, ибо Он благ, ибо вовек милость Его.",
            textEn: "O give thanks unto the Lord; for he is good: for his mercy endureth for ever.",
            refHy: "Սաղմոսներ 107:1",
            refRu: "Псалом 106:1",
            refEn: "Psalm 107:1"
        ),
        BibleVerse(
            textHy: "Փառաբանեցե՛ք Տիրոջը, որովհետև բարի է, որովհետև հավիտենական է նրա ողորմությունը։",
            textRu: "Славьте Господа, ибо Он благ, ибо вовек милость Его.",
            textEn: "O give thanks unto the Lord; for he is good: because his mercy endureth for ever.",
            refHy: "Սաղմոսներ 118:1",
            refRu: "Псалом 117:1",
            refEn: "Psalm 118:1"
        ),
        BibleVerse(
            textHy: "Ինչո՞վ կմաքրի երիտասարդն իր ճանապարհը. Քո խոսքի համեմատ զգուշանալով։",
            textRu: "Как юноше содержать в чистоте путь свой? — Хранением себя по слову Твоему.",
            textEn: "Wherewithal shall a young man cleanse his way? by taking heed thereto according to thy word.",
            refHy: "Սաղմոսներ 119:9",
            refRu: "Псалом 118:9",
            refEn: "Psalm 119:9"
        ),
        BibleVerse(
            textHy: "Փառաբանում եմ Քեզ, որ ահավոր և զարմանալի կերպով ստեղծվեցի։",
            textRu: "Славлю Тебя, потому что я дивно устроен.",
            textEn: "I will praise thee; for I am fearfully and wonderfully made.",
            refHy: "Սաղմոսներ 139:14",
            refRu: "Псалом 138:14",
            refEn: "Psalm 139:14"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ կատարել Քո կամքը, որովհետև Դու ես իմ Աստվածը. Քո բարի Հոգին թող ինձ առաջնորդի դեպի ուղիղ երկիր։",
            textRu: "Научи меня исполнять волю Твою, потому что Ты Бог мой; Дух Твой благий да ведет меня в землю правды.",
            textEn: "Teach me to do thy will; for thou art my God: thy spirit is good; lead me into the land of uprightness.",
            refHy: "Սաղմոսներ 143:10",
            refRu: "Псалом 142:10",
            refEn: "Psalm 143:10"
        ),
        BibleVerse(
            textHy: "Տիրո՛ջը հանձնիր քո գործերը, և քո ծրագրերը կհաստատվեն:",
            textRu: "Предай Господу дела твои, и предприятия твои совершатся.",
            textEn: "Commit thy works unto the Lord, and thy thoughts shall be established.",
            refHy: "Առակաց 16:3",
            refRu: "Притчи 16:3",
            refEn: "Proverbs 16:3"
        ),
        BibleVerse(
            textHy: "Տիրոջ անունը ամուր աշտարակ է. արդարը փախչում է դեպի այն և ապահով լինում։",
            textRu: "Имя Господа — крепкая башня: убегает в нее праведник, и безопасен.",
            textEn: "The name of the Lord is a strong tower: the righteous runneth into it, and is safe.",
            refHy: "Առակաց 18:10",
            refRu: "Притчи 18:10",
            refEn: "Proverbs 18:10"
        ),
        BibleVerse(
            textHy: "Ահա Աստված է իմ փրկությունը. ես կվստահեմ և չեմ վախենա, որովհետև Տեր Եհովան է իմ զորությունը և իմ օրհնությունը, և նա եղավ իմ փրկությունը։",
            textRu: "Вот, Бог — спасение мое: уповаю на Него и не боюсь; ибо Господь Бог — сила моя и пение мое; и Он был мне во спасение.",
            textEn: "Behold, God is my salvation; I will trust, and not be afraid: for the Lord JEHOVAH is my strength and my song; he also is become my salvation.",
            refHy: "Եսայիա 12:2",
            refRu: "Исаия 12:2",
            refEn: "Isaiah 12:2"
        ),
        BibleVerse(
            textHy: "Նա հոգնածին ուժ է տալիս և թույլին՝ մեծ կարողություն։",
            textRu: "Он дает утомленному силу, и изнемогшему дарует крепость.",
            textEn: "He giveth power to the faint; and to them that have no might he increaseth strength.",
            refHy: "Եսայիա 40:29",
            refRu: "Исаия 40:29",
            refEn: "Isaiah 40:29"
        ),
        BibleVerse(
            textHy: "Երբ ջրերի միջով անցնես, ես քեզ հետ կլինեմ, և գետերը քեզ չեն խեղդի. երբ կրակի միջով քայլես, չես այրվի, և բոցը քեզ չի կիզի։",
            textRu: "Будешь ли переходить через воды, Я с тобою, — через реки ли, они не потопят тебя; пойдешь ли через огонь, не обожжешься, и пламя не опалит тебя.",
            textEn: "When thou passest through the waters, I will be with thee; and through the rivers, they shall not overflow thee: when thou walkest through the fire, thou shalt not be burned; neither shall the flame kindle upon thee.",
            refHy: "Եսայիա 43:2",
            refRu: "Исаия 43:2",
            refEn: "Isaiah 43:2"
        ),
        BibleVerse(
            textHy: "Երանի՜ ողորմածներին, որովհետև նրանք ողորմություն պիտի գտնեն։",
            textRu: "Блаженны милостивые, ибо они помилованы будут.",
            textEn: "Blessed are the merciful: for they shall obtain mercy.",
            refHy: "Մատթեոս 5:7",
            refRu: "Матфея 5:7",
            refEn: "Matthew 5:7"
        ),
        BibleVerse(
            textHy: "Որովհետև ուր որ երկու կամ երեք հոգի հավաքված լինեն իմ անունով, այնտեղ եմ ես՝ նրանց մեջ։",
            textRu: "Ибо, где двое или трое собраны во имя Мое, там Я посреди них.",
            textEn: "For where two or three are gathered together in my name, there am I in the midst of them.",
            refHy: "Մատթեոս 18:20",
            refRu: "Матфея 18:20",
            refEn: "Matthew 18:20"
        ),
        BibleVerse(
            textHy: "Երկինքն ու երկիրը կանցնեն, բայց իմ խոսքերը երբեք չեն անցնի։",
            textRu: "Небо и земля прейдут, но слова Мои не прейдут.",
            textEn: "Heaven and earth shall pass away, but my words shall not pass away.",
            refHy: "Մատթեոս 24:35",
            refRu: "Матфея 24:35",
            refEn: "Matthew 24:35"
        ),
        BibleVerse(
            textHy: "Որովհետև Աստծո համար անհնարին ոչինչ չկա:",
            textRu: "Ибо у Бога не останется бессильным никакое слово.",
            textEn: "For with God nothing shall be impossible.",
            refHy: "Ղուկաս 1:37",
            refRu: "Луки 1:37",
            refEn: "Luke 1:37"
        ),
        BibleVerse(
            textHy: "Գողը գալիս է միայն գողանալու, սպանելու և կորստյան մատնելու համար։ Ես եկա, որ կյանք ունենան և ավելիով ունենան։",
            textRu: "Вор приходит только для того, чтобы украсть, убить и погубить. Я пришел для того, чтобы имели жизнь и имели с избытком.",
            textEn: "The thief cometh not, but for to steal, and to kill, and to destroy: I am come that they might have life, and that they might have it more abundantly.",
            refHy: "Հովհաննես 10:10",
            refRu: "Иоанна 10:10",
            refEn: "John 10:10"
        ),
        BibleVerse(
            textHy: "Բայց Աստված իր սերն է հայտնում մեր հանդեպ նրանով, որ դեռ մեղավոր էինք, երբ Քրիստոսը մեռավ մեզ համար։",
            textRu: "Но Бог Свою любовь к нам доказывает тем, что Христос умер за нас, когда мы были еще грешниками.",
            textEn: "But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us.",
            refHy: "Հռոմեացիներին 5:8",
            refRu: "Римлянам 5:8",
            refEn: "Romans 5:8"
        ),
        BibleVerse(
            textHy: "Հույսով ուրախացե՛ք, նեղության մեջ համբերեցե՛ք, աղոթքի մեջ հարատևեցե՛ք։",
            textRu: "Утешайтесь надеждою; в скорби будьте терпеливы, в молитве постоянны.",
            textEn: "Rejoicing in hope; patient in tribulation; continuing instant in prayer.",
            refHy: "Հռոմեացիներին 12:12",
            refRu: "Римлянам 12:12",
            refEn: "Romans 12:12"
        ),
        BibleVerse(
            textHy: "Հա՛յր մեր, որ երկնքում ես, սուրբ թող լինի Քո անունը. Քո արքայությունը թող գա, Քո կամքը թող լինի երկրի վրա, ինչպես երկնքում։ Մեր հանապազօրյա հացը տո՛ւր մեզ այսօր։ Եվ ներե՛ր մեզ мեր պարտքերը, ինչպես և մենք ենք ներում մեր պարտապաններին։ Եվ մի՛ տանիր մեզ փորձության, այլ փրկի՛ր մեզ չարից։ Որովհետև Քոնն է արքայությունը և զորությունը և փառքը հավիտյանս։ Ամեն։",
            textRu: "Отче наш, сущий на небесах! да святится имя Твое; да приидет Царствие Твое; да будет воля Твоя и на земле, как на небе; хлеб наш насущный дай нам на сей день; и прости нам долги наши, как и мы прощаем должникам нашим; и не введи нас в искушение, но избавь нас от лукавого. Ибо Твое есть Царство и сила и слава вовеки. Аминь.",
            textEn: "Our Father which art in heaven, Hallowed be thy name. Thy kingdom come. Thy will be done in earth, as it is in heaven. Give us this day our daily bread. And forgive us our debts, as we forgive our debtors. And lead us not into temptation, but deliver us from evil: For thine is the kingdom, and the power, and the glory, for ever. Amen.",
            refHy: "Տերունական աղոթք",
            refRu: "Молитва Господня",
            refEn: "The Lord's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Պահապա՛ն ամենայնի Քրիստոս, աջ Քո հովանի լիցի ի վերայ իմ, ի տուէ և ի գիշերի, ի նստիլ ի տան, ի գնալ ի ճանապարհ, ի ննջել և ի յառնել, զի մի՛ երբեք սասանեցայց. և ողորմեա՛ Քո արարածոց և ինձ՝ բազմամեղիս։",
            textRu: "Хранитель всех, Христос! Да будет десница Твоя сенью надо мною днем и ночью, дома и в пути, во время сна и бодрствования, чтобы никогда не поколебался я. И помилуй Творения Твои и меня, многогрешного.",
            textEn: "O Christ, guardian of all, let Thy right hand be a shadow over me day and night, at home and on the way, in sleep and in waking, that I may never stumble. And have mercy upon Thy creations, and upon me, a manifold sinner.",
            refHy: "Սուրբ Ներսես Շնորհալի",
            refRu: "Св. Нерсес Шнорали",
            refEn: "St. Nerses the Gracious",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր իմ և Աստվա՛ծ իմ, Քո սիրո և ողորմության համար ներիր իմ բոլոր մեղքերը, որոնք գործել եմ Քո սուրբ կամքի դեմ։ Լվա՛ ինձ իմ անօրենությունից և մաքրիր ինձ իմ մեղքերից։ Ամեն։",
            textRu: "Господи мой и Бог мой! Ради Твоей любви и милосердия прости все грехи мои, содеянные против Твоей святой воли. Омой меня от беззакония моего и очисти меня от грехов моих. Аминь.",
            textEn: "My Lord and my God, for the sake of Thy love and mercy, forgive all my sins which I have committed against Thy holy will. Wash me thoroughly from my iniquity, and cleanse me from my sins. Amen.",
            refHy: "Աղոթագիրք (Զղջման)",
            refRu: "Молитвослов (Покаянная)",
            refEn: "Prayer Book (Repentance)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Փա՛ռք Քեզ, Տե՛ր Աստված իմ, որ արժանացրիր ինձ այս առավոտյան լույսին։ Տո՛ւր ինձ այսօր խաղաղությամբ և առանց փորձության անցկացնել օրը, պահպանիր իմ մտքերը և գործերը Քո սիրո մեջ։ Ամեն։",
            textRu: "Слава Тебе, Господи Боже мой, сподобившему меня сего утреннего света! Даруй мне провести этот день в мире и без искушений, сохрани помыслы мои и дела в любви Твоей. Аминь.",
            textEn: "Glory to Thee, my Lord and God, Who hast made me worthy of this morning light! Grant me to pass this day in peace and without temptation, keep my thoughts and deeds in Thy love. Amen.",
            refHy: "Սուրբ Հովհաննես Գառնեցի",
            refRu: "Св. Иоанн Гарнеци",
            refEn: "St. John of Garni",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տերը կպահպանի քեզ ամեն չարից, Տերը կպահպանի քո անձը։ Տերը կպահպանի քո մուտքն ու ելքը այսուհետև մինչև հավիտյան։ Ամեն։",
            textRu: "Господь сохранит тебя от всякого зла; сохранит душу твою Господь. Господь будет охранять выхождение твое и вхождение твое отныне и вовек. Аминь.",
            textEn: "The Lord shall preserve thee from all evil: he shall preserve thy soul. The Lord shall preserve thy going out and thy coming in from this time forth, and even for evermore. Amen.",
            refHy: "Ճանապարհորդի Աղոթք",
            refRu: "Молитва путешественника",
            refEn: "Traveler's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր մեզ Քո խաղաղությունը, Տե՛ր, որը վեր է ամեն մտքից։ Խաղաղեցրու մեր սրտերը, հեռացրու մեր վախերը և տուր մեզ Քո ներկայության ապահովությունը։ Ամեն։",
            textRu: "Даруй нам мир Твой, Господи, который превыше всякого ума. Умиротвори сердца наши, отгони страхи наши и даруй нам уверенность в Твоем присутствии. Аминь.",
            textEn: "Grant us Thy peace, O Lord, which passeth all understanding. Pacify our hearts, take away our fears, and grant us the security of Thy presence. Amen.",
            refHy: "Աղոթագիրք (Խաղաղության)",
            refRu: "Молитвослов (О мире)",
            refEn: "Prayer Book (For Peace)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Ընկա՛լ քաղցրությամբ, Տեր Աստված հզոր, զդառնացողիս աղաչանս, մատի՛ր գթությամբ առ պատկառեալս դիմոք։ Փարատեա՛, ամենապարգև, զամոթական տխրութիւնս, բա՛րձ յինէն զծանր հեծութիւնս։ Ամեն։",
            textRu: "Прими с благоволением, Господи Боже Вседержитель, горькие моления мои, обрати милостивый взор на кающегося. Рассей, Всеблагой, постыдную скорбь мою, сними с меня тяжелое бремя уныния. Аминь.",
            textEn: "Receive with sweetness, Lord God Almighty, my bitter prayers, look with compassion upon my contrite face. Dispel, O All-Giver, my shameful sadness, lift from me this heavy sighing. Amen.",
            refHy: "Սուրբ Գրիգոր Նարեկացի",
            refRu: "Св. Григор Нарекаци",
            refEn: "St. Gregory of Narek",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Շնորհակալ եմ Քեզնից, Տե՛ր իմ և Աստվա՛ծ իմ, Քո բոլոր բարիքների, կյանքի, առողջության և Քո անսահման սիրո համար, որով շրջապատում ես ինձ ամեն օր։ Ամեն։",
            textRu: "Благодарю Тебя, Господи мой и Бог мой, за все Твои благодеяния, за жизнь, здоровье и за безграничную Твою любовь, которой Ты окружаешь меня каждый день. Аминь.",
            textEn: "Thank Thee, my Lord and God, for all Thy blessings, for life, health, and for Thy boundless love with which Thou surroundest me every day. Amen.",
            refHy: "Շնորհակալական Աղոթք",
            refRu: "Благодарственная молитва",
            refEn: "Prayer of Thanksgiving",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Բժշկի՛ր ինձ, Տե՛ր, և ես կբժշկվեմ. փրկի՛ր ինձ, և ես կփրկվեմ, որովհետև Դու ես իմ փառքը։ Տո՛ւր առողջություն մարմնիս և խաղաղություն հոգուս։ Ամեն։",
            textRu: "Исцели меня, Господи, и исцелен буду; спаси меня, и спасен буду; ибо Ты хвала моя. Даруй здравие телу моему и мир душе моей. Аминь.",
            textEn: "Heal me, O Lord, and I shall be healed; save me, and I shall be saved: for thou art my praise. Grant health to my body and peace to my soul. Amen.",
            refHy: "Բժշկության Աղոթք",
            refRu: "Молитва об исцелении",
            refEn: "Prayer for Healing",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Որովհետև Աստված իր Որդուն չուղարկեց աշխարհ, որ դատապարտի աշխարհը, այլ որպեսզի աշխարհը նրանով փրկվի։",
            textRu: "Ибо не послал Бог Сына Своего в мир, чтобы судить мир, но чтобы мир спасен был чрез Него.",
            textEn: "For God sent not his Son into the world to condemn the world; but that the world through him might be saved.",
            refHy: "Հովհաննես 3:17",
            refRu: "Иоанна 3:17",
            refEn: "John 3:17"
        ),
        BibleVerse(
            textHy: "Իմ լուծը ձեզ վրա՛ վերցրեք և սովորեցե՛ք ինձնից, որովհետև հեզ եմ և սրտով խոնարհ, և ձեր անձերի համար հանգիստ կգտնեք։",
            textRu: "Возьмите иго Мое на себя и научитесь от Меня, ибо Я кроток и смирен сердцем, и найдете покой душам вашим;",
            textEn: "Take my yoke upon you, and learn of me; for I am meek and lowly in heart: and ye shall find rest unto your souls.",
            refHy: "Մատթեոս 11:29",
            refRu: "Матфея 11:29",
            refEn: "Matthew 11:29"
        ),
        BibleVerse(
            textHy: "Որովհետև հաստատ գիտեմ, որ ո՛չ մահը, ո՛չ կյանքը, ո՛չ հրեշտակները... չեն կարող մեզ բաժանել Աստծու սիրուց, որ մեր Տեր Քրիստոս Հիսուսի մեջ է։",
            textRu: "Ибо я уверен, что ни смерть, ни жизнь, ни Ангелы... не может отлучить нас от любви Божией во Христе Иисусе, Господе нашем.",
            textEn: "For I am persuaded, that neither death, nor life, nor angels... shall be able to separate us from the love of God, which is in Christ Jesus our Lord.",
            refHy: "Հռոմեացիներին 8:38-39",
            refRu: "Римлянам 8:38-39",
            refEn: "Romans 8:38-39"
        ),
        BibleVerse(
            textHy: "Արթո՛ւն կացեք, հաստա՛տ մնացեք հավատի մեջ, տղամա՛րդ եղեք, զորացե՛ք։ Ձեր ամեն գործ թող սիրով լինի։",
            textRu: "Бодрствуйте, стойте в вере, будьте мужественны, тверды. Все у вас да будет с любовью.",
            textEn: "Watch ye, stand fast in the faith, quit you like men, be strong. Let all your things be done with charity.",
            refHy: "Ա Կորնթացիներին 16:13-14",
            refRu: "1 Коринфянам 16:13-14",
            refEn: "1 Cor 16:13-14"
        ),
        BibleVerse(
            textHy: "Եվ նա ինձ ասաց. «Իմ շնորհը բավական է քեզ, որովհետև իմ զորությունը տկարության մեջ է կատարյալ դառնում»։",
            textRu: "Но Господь сказал мне: «довольно для тебя благодати Моей, ибо сила Моя совершается в немощи».",
            textEn: "And he said unto me, My grace is sufficient for thee: for my strength is made perfect in weakness.",
            refHy: "Բ Կորնթացիներին 12:9",
            refRu: "2 Коринфянам 12:9",
            refEn: "2 Corinthians 12:9"
        ),
        BibleVerse(
            textHy: "Եվ բարիք գործելուց չձանձրանա՛նք, որովհետև իր ժամանակին կհնձենք, եթե չթուլանանք։",
            textRu: "Делая добро, да не унываем, ибо в свое время пожнем, если не ослабеем.",
            textEn: "And let us not be weary in well doing: for in due season we shall reap, if we faint not.",
            refHy: "Գաղատացիներին 6:9",
            refRu: "Галатам 6:9",
            refEn: "Galatians 6:9"
        ),
        BibleVerse(
            textHy: "Եվ Աստծու խաղաղությունը, որ վեր է ամեն մտքից, կպահպանի ձեր սրտերն ու մտքերը Քրիստոս Հիսուսով։",
            textRu: "И мир Божий, который превыше всякого ума, соблюдет сердца ваши и помышления ваши во Христе Иисусе.",
            textEn: "And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.",
            refHy: "Փիլիպպեցիներին 4:7",
            refRu: "Филиппийцам 4:7",
            refEn: "Philippians 4:7"
        ),
        BibleVerse(
            textHy: "Եվ իմ Աստվածը թող լրացնի ձեր ամեն կարիքը իր հարստության համեմատ՝ փառքով Քրիստոս Հիսուսի միջոցով։",
            textRu: "Бог мой да восполнит всякую нужду вашу, по богатству Своему в славе, Христом Иисусом.",
            textEn: "But my God shall supply all your need according to his riches in glory by Christ Jesus.",
            refHy: "Փիլիպպեցիներին 4:19",
            refRu: "Филиппийцам 4:19",
            refEn: "Philippians 4:19"
        ),
        BibleVerse(
            textHy: "Եվ ամենայն շնորհների Աստվածը... ձեզ՝ մի փոքր ժամանակ չարչարվածներիս, թող կատարյալ դարձնի, հաստատի, զորացնի և հիմնավորի։",
            textRu: "Бог же всякой благодати... по кратковременном страдании вашем, да совершит вас, да утвердит, да укрепит, да соделает непоколебимыми.",
            textEn: "But the God of all grace... after that ye have suffered a while, make you perfect, stablish, strengthen, settle you.",
            refHy: "Ա Պետրոս 5:10",
            refRu: "1 Петра 5:10",
            refEn: "1 Peter 5:10"
        ),
        BibleVerse(
            textHy: "Եթե մեր մեղքերը խոստովանենք, հավատարիմ է նա և արդար՝ մեր մեղքերը մեզ ներելու և մեզ մաքրելու ամեն անիրավությունից:",
            textRu: "Если исповедуем грехи наши, то Он, будучи верен и праведен, простит нам грехи наши и очистит нас от всякой неправды.",
            textEn: "If we confess our sins, he is faithful and just to forgive us our sins, and to cleanse us from all unrighteousness.",
            refHy: "Ա Հովհաննես 1:9",
            refRu: "1 Иоанна 1:9",
            refEn: "1 John 1:9"
        ),
        BibleVerse(
            textHy: "Պահի՛ր ինձ աչքի բիբի պես, Քո թևերի հովանու տակ թաքցրո՛ւ ինձ։",
            textRu: "Храни меня, как зеницу ока; в тени крыл Твоих укрой меня.",
            textEn: "Keep me as the apple of the eye, hide me under the shadow of thy wings.",
            refHy: "Սաղմոսներ 17:8",
            refRu: "Псалом 16:8",
            refEn: "Psalm 17:8"
        ),
        BibleVerse(
            textHy: "Ո՞վ վեր կելնի Տիրոջ լեռը, կամ ո՞վ կկանգնի նրա սուրբ տեղում։ Նա, ով մաքուր ձեռքեր ունի և անարատ սիրտ։",
            textRu: "Кто взойдет на гору Господню, или кто станет на святом месте Его? Тот, у которого руки неповинны и сердце чисто.",
            textEn: "Who shall ascend into the hill of the Lord? or who shall stand in his holy place? He that hath clean hands, and a pure heart.",
            refHy: "Սաղմոսներ 24:3-4",
            refRu: "Псалом 23:3-4",
            refEn: "Psalm 24:3-4"
        ),
        BibleVerse(
            textHy: "Սպասի՛ր Տիրոջը, զորացի՛ր, և թող քո սիրտը պնդանա. այո՛, սպասի՛ր Տիրոջը։",
            textRu: "Надейся на Господа, мужайся, и да укрепляется сердце твое, и надейся на Господа.",
            textEn: "Wait on the Lord: be of good courage, and he shall strengthen thine heart: wait, I say, on the Lord.",
            refHy: "Սաղմոսներ 27:14",
            refRu: "Псалом 26:14",
            refEn: "Psalm 27:14"
        ),
        BibleVerse(
            textHy: "Ճաշակեցե՛ք և տեսե՛ք, որ քաղցր է Տերը. երանի՜ այն մարդուն, որ ապավինում է նրան:",
            textRu: "Вкусите, и увидите, как благ Господь! Блажен человек, который уповает на Него!",
            textEn: "O taste and see that the Lord is good: blessed is the man that trusteth in him.",
            refHy: "Սաղմոսներ 34:8",
            refRu: "Псалом 33:9",
            refEn: "Psalm 34:8"
        ),
        BibleVerse(
            textHy: "Տիրոջից են հաստատվում մարդու քայլերը, և նա հավանում է նրա ճանապարհը։ Թեև նա վայր ընկնի, չի կործանվի, որովհետև Տերը բռնում է նրա ձեռքը։",
            textRu: "Господом утверждаются шаги человека, и Он благоволит к пути его: когда он будет падать, не упадет, ибо Господь держит его за руку.",
            textEn: "The steps of a good man are ordered by the Lord: and he delighteth in his way. Though he fall, he shall not be utterly cast down: for the Lord upholdeth him with his hand.",
            refHy: "Սաղմոսներ 37:23-24",
            refRu: "Псалом 36:23-24",
            refEn: "Psalm 37:23-24"
        ),
        BibleVerse(
            textHy: "Տե՛ր Յիսուս Քրիստոս, աճեցրո՛ւ իմ հաւատքը, զօրացրո՛ւ իմ յոյսը և կատարելագործի՛ր իմ սէրը։ Տո՛ւր ինձ սիրտ, որ լսի Քո ձայնը, և կամք՝ որ հնազանդուի Քո սուրբ կամքին։ Ամեն։",
            textRu: "Господи Иисусе Христе, умножь мою веру, укрепи мою надежду и усовершенствуй мою любовь! Даруй мне сердце, внемлющее Твоему голосу, и волю, покорную Твоей святой воле. Аминь.",
            textEn: "Lord Jesus Christ, increase my faith, strengthen my hope, and perfect my love! Grant me a heart that listens to Thy voice, and a will obedient to Thy holy will. Amen.",
            refHy: "Աղոթագիրք (Հավատքի)",
            refRu: "Молитвослов (О вере)",
            refEn: "Prayer Book (Of Faith)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Աստուա՛ծ երկնաւոր, օրհնի՛ր իմ ընտանիքը։ Տո՛ւր մեզ խաղաղութիւն, սէր և համերաշխութիւն։ Պահպանի՛ր մեզ ամեն չարից և փորձանքից, եղի՛ր մեր տան Պահապանն ու Ապաւէնը։ Ամեն։",
            textRu: "Отец Небесный, благослови мою семью! Даруй нам мир, любовь и единомыслие. Сохрани нас от всякого зла и невзгод, будь Хранителем и Защитником нашего дома. Аминь.",
            textEn: "Heavenly Father, bless my family! Grant us peace, love, and unity. Keep us from all evil and adversity, and be the Guardian and Protector of our home. Amen.",
            refHy: "Ընտանեկան Աղոթք",
            refRu: "Семейная молитва",
            refEn: "Family Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր և արարիչ կյանքիս, ծուլության, տխրության, արծաթասիրության և դատարկախոսության հոգին մի՛ տուր ինձ։ Իսկ ողջախոհության, խոնարհության, համբերության և սիրո հոգին շնորհի՛ր Քո ծառային։ Ամեն։",
            textRu: "Господи и Владыка живота моего, дух праздности, уныния, любоначалия и празднословия не даждь ми. Дух же целомудрия, смиренномудрия, терпения и любви даруй ми, рабу Твоему. Аминь.",
            textEn: "O Lord and Master of my life, take from me the spirit of sloth, despair, lust of power, and idle talk. But give rather the spirit of chastity, humility, patience, and love to Thy servant. Amen.",
            refHy: "Սուրբ Եփրեմ Ասորի",
            refRu: "Св. Ефрем Сирин",
            refEn: "St. Ephrem the Syrian",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տէր Աստուած մեր, զոր ինչ մեղայ այսօր բանիւ, գործով կամ խորհրդով, որպէս բարերար և մարդասէր Աստուած՝ ներեա՛ ինձ։ Տո՛ւր ինձ խաղաղ քուն և անխռով ննջում, պահպանիր զիս չարի փորձանքից։ Ամեն։",
            textRu: "Господи Боже наш, если согрешил я в сей день словом, делом или помышлением, как благой и человеколюбивый Бог, прости мне. Даруй мне мирный и безмятежный сон, сохрани меня от всякого зла. Аминь.",
            textEn: "O Lord our God, if I have sinned this day in word, deed, or thought, as a good and loving God, forgive me. Grant me peaceful and undisturbed sleep, and keep me safe from all evil. Amen.",
            refHy: "Երեկոյան Աղոթք",
            refRu: "Вечерняя молитва",
            refEn: "Evening Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, որովհետև ես քեզ հետ եմ. մի՛ զարհուրիր, որովհետև ես քո Աստվածն եմ. ես քեզ կզորացնեմ և քեզ օգնություն կհասնեմ։",
            textRu: "Не бойся, ибо Я с тобою; не смущайся, ибо Я Бог твой; Я укреплю тебя, и помогу тебе, и поддержу тебя десницею правды Моей.",
            textEn: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.",
            refHy: "Եսայի 41:10",
            refRu: "Исаия 41:10",
            refEn: "Isaiah 41:10"
        ),
        BibleVerse(
            textHy: "Հանդարտվեցե՛ք և ճանաչեցե՛ք, որ ես եմ Աստված. ես բարձր կլինեմ ազգերի մեջ, բարձր կլինեմ երկրի վրա։",
            textRu: "Остановитесь и познайте, что Я — Бог: буду превознесен в народах, превознесен на земле.",
            textEn: "Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.",
            refHy: "Սաղմոսներ 46:10",
            refRu: "Псалом 45:11",
            refEn: "Psalm 46:10"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսով։",
            textRu: "Все могу в укрепляющем меня Иисусе Христе.",
            textEn: "I can do all things through Christ which strengtheneth me.",
            refHy: "Փիլիպեցիս 4:13",
            refRu: "Филиппийцам 4:13",
            refEn: "Philippians 4:13"
        ),
        BibleVerse(
            textHy: "Եվ գիտենք, որ Աստծուն սիրողներին ամեն ինչ գործակից է լինում բարու համար։",
            textRu: "Притом знаем, что любящим Бога, призванным по Его изволению, все содействует ко благу.",
            textEn: "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
            refHy: "Հռոմեացիս 8:28",
            refRu: "Римлянам 8:28",
            refEn: "Romans 8:28"
        ),
        BibleVerse(
            textHy: "Ամենայն զգուշությամբ պահպանի՛ր սիրտդ, որովհետև նրանից են բխում կյանքի աղբյուրները:",
            textRu: "Больше всего хранимого храни сердце твое, потому что из него источники жизни.",
            textEn: "Keep thy heart with all diligence; for out of it are the issues of life.",
            refHy: "Առակաց 4:23",
            refRu: "Притчи 4:23",
            refEn: "Proverbs 4:23"
        ),
        BibleVerse(
            textHy: "Իսկ Հոգու պտուղն է՝ սեր, ուրախություն, խաղաղություն, համբերատարություն, քաղցրություն, բարություն, հավատարմություն, հեզություն, ժուժկալություն։",
            textRu: "Плод же духа: любовь, радость, мир, долготерпение, благость, милосердие, вера, кротость, воздержание.",
            textEn: "But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance.",
            refHy: "Գաղատացիս 5:22-23",
            refRu: "Галатам 5:22-23",
            refEn: "Galatians 5:22-23"
        ),
        BibleVerse(
            textHy: "Միշտ ուրա՛խ եղեք, անդադա՛ր աղոթեք, ամեն ինչում գոհությո՛ւն հայտնեք, որովհետև սա է Աստծո կամքը ձեր հանդեպ:",
            textRu: "Всегда радуйтесь. Непрестанно молитесь. За все благодарите: ибо такова о вас воля Божия во Христе Иисусе.",
            textEn: "Rejoice evermore. Pray without ceasing. In every thing give thanks: for this is the will of God in Christ Jesus.",
            refHy: "Ա Թեսաղոնիկեցիս 5:16-18",
            refRu: "1 Фессалоникийцам 5:16-18",
            refEn: "1 Thessalonians 5:16-18"
        ),
        BibleVerse(
            textHy: "Ձեր ամեն գործ սիրո՛վ թող կատարվի:",
            textRu: "Все у вас да будет с любовью.",
            textEn: "Let all that you do be done in love.",
            refHy: "Ա Կորնթացիս 16:14",
            refRu: "1 Коринфянам 16:14",
            refEn: "1 Corinthians 16:14"
        ),
        BibleVerse(
            textHy: "Ամեն բարի տուրք և ամեն կատարյալ պարգև վերևից է՝ Լույսերի Հորից:",
            textRu: "Всякое даяние доброе и всякий дар совершенный нисходит свыше, от Отца светов.",
            textEn: "Every good gift and every perfect gift is from above, and cometh down from the Father of lights.",
            refHy: "Հակոբոս 1:17",
            refRu: "Иакова 1:17",
            refEn: "James 1:17"
        ),
        BibleVerse(
            textHy: "Հավատը հուսացած բաների հաստատությունն է և չերևացող բաների ապացույցը:",
            textRu: "Вера же есть осуществление ожидаемого и уверенность в невидимом.",
            textEn: "Now faith is the substance of things hoped for, the evidence of things not seen.",
            refHy: "Եբրայեցիս 11:1",
            refRu: "Евреям 11:1",
            refEn: "Hebrews 11:1"
        ),
        BibleVerse(
            textHy: "Չարից մի՛ հաղթվիր, այլ չարին բարիո՛վ հաղթիր:",
            textRu: "Не будь побежден злом, но побеждай зло добром.",
            textEn: "Be not overcome of evil, but overcome evil with good.",
            refHy: "Հռոմեացիս 12:21",
            refRu: "Римлянам 12:21",
            refEn: "Romans 12:21"
        ),
        BibleVerse(
            textHy: "Եվ այս ամենի վրա հագե՛ք սերը, որ կատարելության կապն է:",
            textRu: "Более же всего облекитесь в любовь, которая есть совокупность совершенства.",
            textEn: "And above all these things put on charity, which is the bond of perfectness.",
            refHy: "Կողոսացիս 3:14",
            refRu: "Колоссянам 3:14",
            refEn: "Colossians 3:14"
        ),
        BibleVerse(
            textHy: "Բարի է Տերը, ապավեն՝ նեղության օրը, և ճանաչում է նրանց, ովքեր հուսացել են իրեն:",
            textRu: "Благ Господь, убежище в день скорби, и знает надеющихся на Него.",
            textEn: "The Lord is good, a strong hold in the day of trouble; and he knoweth them that trust in him.",
            refHy: "Նաում 1:7",
            refRu: "Наум 1:7",
            refEn: "Nahum 1:7"
        ),
        BibleVerse(
            textHy: "Դուք եք աշխարհի լույսը. մի քաղաք, որ լեռան վրա է կառուցված, չի կարող թաքնվել:",
            textRu: "Вы — свет мира. Не может укрыться город, стоящий на верху горы.",
            textEn: "Ye are the light of the world. A city that is set on an hill cannot be hid.",
            refHy: "Մատթեոս 5:14",
            refRu: "Матфея 5:14",
            refEn: "Matthew 5:14"
        ),
        BibleVerse(
            textHy: "Բայց Տիրոջն ապավինողները նորոգվում են ուժով, թևերով վեր են բարձրանում արծիվների պես, վազում են և չեն հոգնում:",
            textRu: "А надеющиеся на Господа обновятся в силе: поднимут крылья, как орлы, потекут — и не устанут, пойдут — и не утомятся.",
            textEn: "But they that wait upon the Lord shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary.",
            refHy: "Եսայի 40:31",
            refRu: "Исаия 40:31",
            refEn: "Isaiah 40:31"
        ),
        BibleVerse(
            textHy: "Հիսուսն ասաց. «Եթե կարող ես հավատալ, ամեն ինչ հնարավոր է նրան, ով հավատում է»:",
            textRu: "Иисус сказал ему: если сколько-нибудь можешь веровать, все возможно верующему.",
            textEn: "Jesus said unto him, If thou canst believe, all things are possible to him that believeth.",
            refHy: "Մարկոս 9:23",
            refRu: "Марка 9:23",
            refEn: "Mark 9:23"
        ),
        BibleVerse(
            textHy: "Որովհետև հավատո՛վ ենք ընթանում և ոչ թե տեսանելիքով:",
            textRu: "Ибо мы ходим верою, а не видением.",
            textEn: "For we walk by faith, not by sight.",
            refHy: "Բ Կորնթացիս 5:7",
            refRu: "2 Коринфянам 5:7",
            refEn: "2 Corinthians 5:7"
        ),
        BibleVerse(
            textHy: "Հիսուս Քրիստոսը նույնն է երեկ, այսօր և հավիտյան:",
            textRu: "Иисус Христос вчера и сегодня и вовеки Тот же.",
            textEn: "Jesus Christ the same yesterday, and to day, and for ever.",
            refHy: "Եբրայեցիս 13:8",
            refRu: "Евреям 13:8",
            refEn: "Hebrews 13:8"
        ),
        BibleVerse(
            textHy: "Օրհնի՛ր Տիրոջը, ո՛վ իմ անձ, և իմ ամբողջ էությունը՝ նրա սուրբ անունը: Օրհնի՛ր Տիրոջը և մի՛ մոռացիր նրա բոլոր բարիքները:",
            textRu: "Благослови, душа моя, Господа, и вся внутренность моя — святое имя Его. Благослови, душа моя, Господа и не забывай всех благодеяний Его.",
            textEn: "Bless the Lord, O my soul: and all that is within me, bless his holy name. Bless the Lord, O my soul, and forget not all his benefits.",
            refHy: "Սաղմոսներ 103:1-2",
            refRu: "Псалом 102:1-2",
            refEn: "Psalm 103:1-2"
        ),
        BibleVerse(
            textHy: "Գոհացե՛ք Տիրոջից, որովհետև բարի է, որովհետև հավիտյան է նրա ողորմությունը:",
            textRu: "Славьте Господа, ибо Он благ, ибо вовек милость Его.",
            textEn: "O give thanks unto the Lord; for he is good: for his mercy endureth for ever.",
            refHy: "Սաղմոսներ 136:1",
            refRu: "Псалом 135:1",
            refEn: "Psalm 136:1"
        ),
        BibleVerse(
            textHy: "Զորացե՛ք և քա՛ջ եղեք, մի՛ վախեցեք. քանզի քո Տեր Աստվածն Ինքն է գնում քեզ հետ, Նա քեզ չի թողնի և չի լքի:",
            textRu: "Будьте тверды и мужественны, не бойтесь и не страшитесь их: ибо Господь Бог твой Сам пойдет с тобою и не оставит тебя.",
            textEn: "Be strong and of a good courage, fear not, nor be afraid: for the Lord thy God, he it is that doth go with thee; he will not fail thee, nor forsake thee.",
            refHy: "Երկրորդ Օրենք 31:6",
            refRu: "Второзаконие 31:6",
            refEn: "Deuteronomy 31:6"
        ),
        BibleVerse(
            textHy: "Բարի՛ եղեք միմյանց հանդեպ, գթառատ, ներելով միմյանց, ինչպես Աստված Քրիստոսով ներեց ձեզ:",
            textRu: "Будьте друг ко другу добры, сострадательны, прощайте друг друга, как и Бог во Христе простил вас.",
            textEn: "And be ye kind one to another, tenderhearted, forgiving one another, even as God for Christ's sake hath forgiven you.",
            refHy: "Եփեսացիս 4:32",
            refRu: "Ефесянам 4:32",
            refEn: "Ephesians 4:32"
        ),
        BibleVerse(
            textHy: "Քեզ ասվեց, ո՛վ մարդ, ինչն է բարին. միայն արդարությո՛ւն գործել, սիրե՛լ ողորմությունը և խոնարհությա՛մբ քայլել քո Աստծո հետ:",
            textRu: "Сказано тебе, человек, что — добро и чего требует от тебя Господь: действовать справедливо, любить дела милосердия и смиренномудренно ходить пред Богом твоим.",
            textEn: "He hath shewed thee, O man, what is good; and what doth the Lord require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?",
            refHy: "Միքիա 6:8",
            refRu: "Михей 6:8",
            refEn: "Micah 6:8"
        ),
        BibleVerse(
            textHy: "Հաստատուն միտք ունեցողին պահում ես կատարյալ խաղաղության մեջ, որովհետև նա հույսը դրել է Քեզ վրա:",
            textRu: "Твердого духом Ты хранишь в совершенном мире, ибо на Тебя уповает он.",
            textEn: "Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee.",
            refHy: "Եսայի 26:3",
            refRu: "Исаия 26:3",
            refEn: "Isaiah 26:3"
        ),
        BibleVerse(
            textHy: "Ձեր ամբողջ հոգսը նրա՛ վրա գցեք, որովհետև նա հոգ է տանում ձեր մասին:",
            textRu: "Все заботы ваши возложите на Него, ибо Он печется о вас.",
            textEn: "Casting all your care upon him; for he careth for you.",
            refHy: "Ա Պետրոս 5:7",
            refRu: "1 Петра 5:7",
            refEn: "1 Peter 5:7"
        ),
        BibleVerse(
            textHy: "Քո Տեր Աստվածը քո մեջ է, մի զորավոր Փրկիչ. Նա ուրախությամբ կցնծա քեզ վրա և կհանգստացնի Իր սիրո մեջ:",
            textRu: "Господь Бог твой среди тебя, Он силен спасти тебя; возвеселится о тебе радостью, обновит тебя любовью Своею.",
            textEn: "The Lord thy God in the midst of thee is mighty; he will save, he will rejoice over thee with joy; he will rest in his love.",
            refHy: "Սոփոնիա 3:17",
            refRu: "Софония 3:17",
            refEn: "Zephaniah 3:17"
        ),
        BibleVerse(
            textHy: "Աչքերս դեպի լեռներն եմ բարձրացնում, որտեղի՞ց պիտի գա իմ օգնությունը: Իմ օգնությունը Տիրոջից է, որ ստեղծեց երկինքն ու երկիրը:",
            textRu: "Возвожу очи мои к горам, откуда придет помощь моя. Помощь моя от Господа, сотворившего небо и землю.",
            textEn: "I will lift up mine eyes unto the hills, from whence cometh my help. My help cometh from the Lord, which made heaven and earth.",
            refHy: "Սաղմոսներ 121:1-2",
            refRu: "Псалом 120:1-2",
            refEn: "Psalm 121:1-2"
        ),
        BibleVerse(
            textHy: "Եթե Աստված մեր կողմն է, ո՞վ կարող է մեզ հակառակ լինել:",
            textRu: "Если Бог за нас, кто против нас?",
            textEn: "If God be for us, who can be against us?",
            refHy: "Հռոմեացիս 8:31",
            refRu: "Римлянам 8:31",
            refEn: "Romans 8:31"
        ),
        BibleVerse(
            textHy: "Որդյակնե՛րս, չսիրենք խոսքով և լեզվով, այլ՝ գործով և ճշմարտությամբ:",
            textRu: "Дети мои! станем любить не словом или языком, но делом и истиною.",
            textEn: "My little children, let us not love in word, neither in tongue; but in deed and in truth.",
            refHy: "Ա Հովհաննես 3:18",
            refRu: "1 Иоанна 3:18",
            refEn: "1 John 3:18"
        ),
        BibleVerse(
            textHy: "Քո խոսքը ծածկեցի իմ սրտում, որպեսզի քո դեմ մեղք չգործեմ:",
            textRu: "В сердце моем сокрыл я слово Твое, чтобы не грешить пред Тобою.",
            textEn: "Thy word have I hid in mine heart, that I might not sin against thee.",
            refHy: "Սաղմոսներ 119:11",
            refRu: "Псалом 118:11",
            refEn: "Psalm 119:11"
        ),
        BibleVerse(
            textHy: "Ոչ մի բանի համար հոգս մի՛ արեք, այլ ամեն բանում աղոթքով և աղաչանքով, գոհությամբ հանդերձ, ձեր խնդրանքները թող հայտնի լինեն Աստծուն: Եվ Աստծո խաղաղությունը կպահպանի ձեր սրտերը:",
            textRu: "Не заботьтесь ни о чем, но всегда в молитве и прошении с благодарением открывайте свои желания пред Богом, и мир Божий соблюдет сердца ваши.",
            textEn: "Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God. And the peace of God shall keep your hearts.",
            refHy: "Փիլիպպեցիներին 4:6-7",
            refRu: "Филиппийцам 4:6-7",
            refEn: "Philippians 4:6-7"
        ),
        BibleVerse(
            textHy: "Տիրոջը միշտ իմ առաջ եմ դրել. քանի որ նա իմ աջ կողմում է, ես չեմ սասանվի:",
            textRu: "Всегда видел я пред собою Господа, ибо Он одесную меня; не поколеблюсь.",
            textEn: "I have set the Lord always before me: because he is at my right hand, I shall not be moved.",
            refHy: "Սաղմոսներ 16:8",
            refRu: "Псалом 15:8",
            refEn: "Psalm 16:8"
        ),
        BibleVerse(
            textHy: "Արդ, մնում են հավատը, հույսը, սերը՝ այս երեքը. բայց սրանցից մեծագույնը սերն է:",
            textRu: "А теперь пребывают сии три: вера, надежда, любовь; но любовь из них больше.",
            textEn: "And now abideth faith, hope, charity, these three; but the greatest of these is charity.",
            refHy: "Ա Կորնթացիս 13:13",
            refRu: "1 Коринфянам 13:13",
            refEn: "1 Corinthians 13:13"
        ),
        BibleVerse(
            textHy: "Ես եմ որթատունկը, դուք՝ ճյուղերը: Ով մնում է իմ մեջ, և ես՝ նրա մեջ, նա շատ պտուղ է բերում, որովհետև առանց ինձ ոչինչ չեք կարող անել:",
            textRu: "Я есмь лоза, а вы ветви; кто пребывает во Мне, и Я в нем, тот приносит много плода; ибо без Меня не можете делать ничего.",
            textEn: "I am the vine, ye are the branches: He that abideth in me, and I in him, the same bringeth forth much fruit: for without me ye can do nothing.",
            refHy: "Հովհաննես 15:5",
            refRu: "Иоанна 15:5",
            refEn: "John 15:5"
        ),
        BibleVerse(
            textHy: "Իմացե՛ք, որ Տերն է Աստված. Նա ստեղծեց մեզ, և ոչ թե մենք: Մենք նրա ժողովուրդն ենք և նրա արոտի ոչխարները:",
            textRu: "Знайте, что Господь есть Бог, что Он сотворил нас, и мы — Его, Его народ и овцы паствы Его.",
            textEn: "Know ye that the Lord he is God: it is he that hath made us, and not we ourselves; we are his people, and the sheep of his pasture.",
            refHy: "Սաղմոսներ 100:3",
            refRu: "Псалом 99:3",
            refEn: "Psalm 100:3"
        ),
        BibleVerse(
            textHy: "Տերը մոտ է բոլոր նրանց, ովքեր կանչում են իրեն, բոլոր նրանց, ովքեր կանչում են իրեն ճշմարտությամբ:",
            textRu: "Близок Господь ко всем призывающим Его, ко всем призывающим Его в истине.",
            textEn: "The Lord is nigh unto all them that call upon him, to all that call upon him in truth.",
            refHy: "Սաղմոսներ 145:18",
            refRu: "Псалом 144:18",
            refEn: "Psalm 145:18"
        ),
        BibleVerse(
            textHy: "Կանչի՛ր ինձ, և ես քեզ պատասխան կտամ և քեզ կհայտնեմ մեծ ու անիմանալի բաներ, որոնք դու չգիտես:",
            textRu: "Воззови ко Мне — и Я отвечу тебе, покажу тебе великое и недоступное, чего ты не знаешь.",
            textEn: "Call unto me, and I will answer thee, and shew thee great and mighty things, which thou knowest not.",
            refHy: "Երեմիա 33:3",
            refRu: "Иеремия 33:3",
            refEn: "Jeremiah 33:3"
        ),
        BibleVerse(
            textHy: "Միայն Աստծո մեջ է հանգստանում իմ անձը, նրանից է իմ փրկությունը: Միայն նա է իմ վեմն ու իմ փրկությունը, իմ ամրոցը. ես շատ չեմ սասանվի:",
            textRu: "Только в Боге успокаивается душа моя: от Него спасение мое. Только Он — твердыня моя и спасение мое, убежище мое: не поколеблюсь более.",
            textEn: "Truly my soul waiteth upon God: from him cometh my salvation. He only is my rock and my salvation; he is my defence; I shall not be greatly moved.",
            refHy: "Սաղմոսներ 62:1-2",
            refRu: "Псалом 61:2-3",
            refEn: "Psalm 62:1-2"
        ),
        BibleVerse(
            textHy: "Սերը համբերատար է, սերը քաղցրաբարո է, չի նախանձում, չի գոռոզանում, չի հպարտանում, անվայել վարմունք չի ունենում, իրենը չի փնտրում, չի գրգռվում, չարը չի խորհում: Ամեն բանի դիմանում է, ամեն բանի հավատում է, միշտ հույս ունի, ամեն բանի համբերում: Սերը երբեք չի դադարում:",
            textRu: "Любовь долготерпит, милосердствует, любовь не завидует, любовь не превозносится, не гордится, не бесчинствует, не ищет своего, не раздражается, не мыслит зла, не радуется неправде, а сорадуется истине; все покрывает, всему верит, всего надеется, все переносит. Любовь никогда не перестает.",
            textEn: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up, doth not behave itself unseemly, seeketh not her own, is not easily provoked, thinketh no evil; beareth all things, believeth all things, hopeth all things, endureth all things. Charity never faileth.",
            refHy: "Ա Կորնթացիս 13:4-8",
            refRu: "1 Коринфянам 13:4-8",
            refEn: "1 Corinthians 13:4-8"
        ),
        BibleVerse(
            textHy: "Որովհետև ես համոզված եմ, որ ո՛չ մահը, ո՛չ կյանքը, ո՛չ հրեշտակները, ո՛չ իշխանությունները, ո՛չ ներկա և ո՛չ էլ գալիք բաները, ո՛չ բարձրությունը, ո՛չ խորությունը և ո՛չ էլ որևէ այլ արարած չեն կարող մեզ բաժանել Աստծո սիրուց, որ մեր Տեր Քրիստոս Հիսուսի մեջ է:",
            textRu: "Ибо я уверен, что ни смерть, ни жизнь, ни Ангелы, ни Начала, ни Силы, ни настоящее, ни будущее, ни высота, ни глубина, ни другая какая тварь не может отлучить нас от любви Божией во Христе Иисусе, Господе нашем.",
            textEn: "For I am persuaded, that neither death, nor life, nor angels, nor principalities, nor powers, nor things present, nor things to come, nor height, nor depth, nor any other creature, shall be able to separate us from the love of God, which is in Christ Jesus our Lord.",
            refHy: "Հռոմեացիս 8:38-39",
            refRu: "Римлянам 8:38-39",
            refEn: "Romans 8:38-39"
        ),
        BibleVerse(
            textHy: "Սկզբում էր Խոսքը, և Խոսքը Աստծո մոտ էր, և Խոսքը Աստված էր: Ամեն ինչ նրանով եղավ, և առանց նրա չեղավ ոչինչ, որ եղել է: Նրանում էր կյանքը, և այդ կյանքը մարդկանց լույսն էր: Եվ լույսը խավարի մեջ լուսավորում է, և խավարը նրան չհաղթահարեց:",
            textRu: "В начале было Слово, и Слово было у Бога, и Слово было Бог. Оно было в начале у Бога. Все чрез Него начало быть, и без Него ничто не начало быть, что начало быть. В Нем была жизнь, и жизнь была свет человеков. И свет во тьме светит, и тьма не объяла его.",
            textEn: "In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made by him; and without him was not any thing made that was made. In him was life; and the life was the light of men. And the light shineth in darkness; and the darkness comprehended it not.",
            refHy: "Հովհաննես 1:1-5",
            refRu: "Иоанна 1:1-5",
            refEn: "John 1:1-5"
        ),
        BibleVerse(
            textHy: "Երանի՜ հոգով աղքատներին, որովհետև նրանցն է երկնքի արքայությունը: Երանի՜ սգավորներին, որովհետև նրանք պիտի մխիթարվեն: Երանի՜ հեզերին, որովհետև նրանք երկիրը պիտի ժառանգեն: Երանի՜ նրանց, որ քաղցն ու ծարավն ունեն արդարության, որովհետև նրանք պիտի հագենան: Երանի՜ ողորմածներին, որովհետև նրանք ողորմություն պիտի գտնեն: Երանի՜ նրանց, որ սրտով մաքուր են, որովհետև նրանք Աստծուն պիտի տեսնեն: Երանի՜ խաղաղարարներին, որովհետև նրանք Աստծո որդիներ պիտի կոչվեն:",
            textRu: "Блаженны нищие духом, ибо их есть Царство Небесное. Блаженны плачущие, ибо они утешатся. Блаженны кроткие, ибо они наследуют землю. Блаженны алчущие и жаждущие правды, ибо они насытятся. Блаженны милостивые, ибо они помилованы будут. Блаженны чистые сердцем, ибо они Бога узрят. Блаженны миротворцы, ибо они будут наречены сынами Божиими.",
            textEn: "Blessed are the poor in spirit: for theirs is the kingdom of heaven. Blessed are they that mourn: for they shall be comforted. Blessed are the meek: for they shall inherit the earth. Blessed are they which do hunger and thirst after righteousness: for they shall be filled. Blessed are the merciful: for they shall obtain mercy. Blessed are the pure in heart: for they shall see God. Blessed are the peacemakers: for they shall be called the children of God.",
            refHy: "Մատթեոս 5:3-9",
            refRu: "Матфея 5:3-9",
            refEn: "Matthew 5:3-9"
        ),
        BibleVerse(
            textHy: "Արդ, որպես Աստծո ընտրյալներ, սրբեր և սիրելիներ, հագե՛ք գութ, ողորմություն, քաղցրություն, խոնարհություն, հեզություն, համբերատարություն՝ ներելով միմյանց: Եվ այս ամենի վրա հագե՛ք սերը, որ կատարելության կապն է: Եվ ձեր սրտերում թող տիրի Քրիստոսի խաղաղությունը:",
            textRu: "Итак облекитесь, как избранные Божии, святые и возлюбленные, в милосердие, благость, смиренномудрие, кротость, долготерпение, снисходя друг другу и прощая взаимно. Более же всего облекитесь в любовь, которая есть совокупность совершенства. И да владычествует в сердцах ваших мир Божий.",
            textEn: "Put on therefore, as the elect of God, holy and beloved, bowels of mercies, kindness, humbleness of mind, meekness, longsuffering; forbearing one another, and forgiving one another. And above all these things put on charity, which is the bond of perfectness. And let the peace of God rule in your hearts.",
            refHy: "Կողոսացիս 3:12-15",
            refRu: "Колоссянам 3:12-15",
            refEn: "Colossians 3:12-15"
        ),
        BibleVerse(
            textHy: "Տերն իմ հովիվն է, և ես կարիք չեմ ունենա: Կանաչ մարգագետիններում Նա ինձ պառկեցնում է և հանդարտ ջրերի մոտ է տանում ինձ: Նա վերանորոգում է իմ հոգին: Եթե նույնիսկ անցնեմ մահվան շվաքի ձորով, չարից չեմ վախենա, որովհետև Դու ինձ հետ ես. Քո գավազանն ու ցուպը՝ նրանք են ինձ մխիթարում: Արդարև, բարությունն ու ողորմությունը պիտի ինձ հետևեն իմ կյանքի բոլոր օրերում:",
            textRu: "Господь — Пастырь мой; я ни в чем не буду нуждаться: Он покоит меня на злачных пажитях и водит меня к водам тихим, подкрепляет душу мою, направляет меня на стези правды ради имени Своего. Если я пойду и долиною смертной тени, не убоюсь зла, потому что Ты со мной; Твой жезл и Твой посох — они успокаивают меня. Так, благость и милость да сопровождают меня во все дни жизни моей.",
            textEn: "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters. He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake. Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me. Surely goodness and mercy shall follow me all the days of my life.",
            refHy: "Սաղմոսներ 23:1-4,6",
            refRu: "Псалом 22:1-4,6",
            refEn: "Psalm 23:1-4,6"
        ),
        BibleVerse(
            textHy: "Ի վերջո, եղբայրնե՛րս, զորացե՛ք Տիրոջով և նրա զորության կարողությամբ: Հագե՛ք Աստծո սպառազինությունը, որպեսզի կարողանաք դեմ կանգնել սատանայի հնարքներին: Ուրեմն ամո՛ւր կանգնեք՝ ձեր մեջքը գոտևորած ճշմարտությամբ և հագած արդարության զրահը:",
            textRu: "Наконец, братия мои, укрепляйтесь Господом и могуществом силы Его. Облекитесь во всеоружие Божие, чтобы вам можно было стать против козней диавольских. Итак станьте, препоясав чресла ваши истиною и облекшись в броню праведности.",
            textEn: "Finally, my brethren, be strong in the Lord, and in the power of his might. Put on the whole armour of God, that ye may be able to stand against the wiles of the devil. Stand therefore, having your loins girt about with truth, and having on the breastplate of righteousness.",
            refHy: "Եփեսացիս 6:10-14",
            refRu: "Ефесянам 6:10-14",
            refEn: "Ephesians 6:10-14"
        ),
        BibleVerse(
            textHy: "Փնտրեցե՛ք Տիրոջը, քանի դեռ նա կարող է գտնվել. կանչեցե՛ք նրան, քանի դեռ նա մոտ է: Ամբարիշտը թող թողնի իր ճանապարհը և անօրեն մարդը՝ իր խորհուրդները, և թող դառնա դեպի Տերը, և նա կողորմի նրան: «Որովհետև իմ խորհուրդները ձեր խորհուրդները չեն, և ձեր ճանապարհները իմ ճանապարհները չեն»,- ասում է Տերը:",
            textRu: "Ищите Господа, когда можно найти Его; призывайте Его, когда Он близко. Да оставит нечестивый путь свой и беззаконник — помыслы свои, и да обратится к Господу, и Он помилует его, и к Богу нашему, ибо Он многомилостив. Мои мысли — не ваши мысли, ни ваши пути — пути Мои, говорит Господь.",
            textEn: "Seek ye the Lord while he may be found, call ye upon him while he is near: Let the wicked forsake his way, and the unrighteous man his thoughts: and let him return unto the Lord, and he will have mercy upon him. For my thoughts are not your thoughts, neither are your ways my ways, saith the Lord.",
            refHy: "Եսայի 55:6-9",
            refRu: "Исаия 55:6-9",
            refEn: "Isaiah 55:6-9"
        )
    ]

    // MARK: - Выборка стихов по категории домашнего виджета (HomeWidgetCategory)
    static func verses(for category: HomeWidgetCategory, isPremium: Bool = true) -> [BibleVerse] {
        let activeCat = (isPremium || !category.isPremiumRequired) ? category : .all
        switch activeCat {
        case .all:
            return BibleVerse.database
            
        case .gospels:
            let gospels = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("մատթեոս") || r.contains("մարկոս") || r.contains("ղուկաս") || r.contains("հովհաննես") ||
                       r.contains("матфе") || r.contains("марк") || r.contains("луки") || r.contains("иоанн") ||
                       r.contains("matthew") || r.contains("mark") || r.contains("luke") || r.contains("john")
            }
            return !gospels.isEmpty ? gospels : BibleVerse.database
            
        case .psalms:
            let p = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("սաղմոս") || r.contains("псалом") || r.contains("psalm")
            }
            let list = p + BibleVerse.shortPsalms
            return !list.isEmpty ? list : BibleVerse.database
            
        case .wisdom:
            let w = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("առակ") || r.contains("ժողովող") || r.contains("իմաստութ") ||
                       r.contains("притч") || r.contains("екклесиаст") || r.contains("премудрост") ||
                       r.contains("proverbs") || r.contains("ecclesiastes") || r.contains("wisdom")
            }
            let list = w + BibleVerse.shortWisdom
            return !list.isEmpty ? list : BibleVerse.database
            
        case .narekatsi:
            let n = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("նարեկ") || r.contains("нарекаци") || r.contains("narek")
            }
            let list = n + BibleVerse.shortNarekatsi
            return !list.isEmpty ? list : BibleVerse.shortNarekatsi
            
        case .prayers:
            let prayers = BibleVerse.database.filter { $0.isPrayer }
            return !prayers.isEmpty ? prayers : BibleVerse.database
            
        case .favorites:
            if let defaults = UserDefaults(suiteName: "group.com.samvel.ArmenianBible"),
               let savedFavoritesData = defaults.data(forKey: "favorite_verses"),
               let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData),
               !decoded.isEmpty {
                return decoded.map { item in
                    BibleVerse(
                        id: item.id,
                        textHy: item.textHy,
                        textRu: item.textRu,
                        textEn: item.textEn,
                        refHy: item.refHy,
                        refRu: item.refRu,
                        refEn: item.refEn,
                        isPrayer: false
                    )
                }
            }
            return BibleVerse.database
        }
    }
}

// MARK: - Нормализация строк для сравнения без учета регистра и знаков препинания
extension String {
    var normalizedForComparison: String {
        self.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

private func isAraratEditionSelected() -> Bool {
    let savedEdition = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "armenian_bible_edition")
    return savedEdition != "echmiadzin"
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
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
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
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
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


