import Foundation
import SwiftUI

// MARK: - Визуальные стили виджетов и режима StandBy
/// Два вида: «Кадр» (фотография по смыслу стиха, как в карточке стиха дня) и «Святилище» (тёмный тёплый фон без фото,
/// для StandBy и OLED). Раньше стилей было 13 (градиенты и нарисованные «постеры»): они ушли, чтобы виджеты выглядели
/// так же, как всё приложение.
enum WidgetVisualStyle: String, CaseIterable, Identifiable, Codable {
    case posterFrame = "posterFrame"
    case sanctuary = "sanctuary"

    var id: String { self.rawValue }

    /// Стиль из сохранённого значения. Любой из прежних стилей (их уже нет) становится «Кадром»
    static func migrated(from raw: String?) -> WidgetVisualStyle {
        guard let raw else { return .posterFrame }
        return WidgetVisualStyle(rawValue: raw) ?? .posterFrame
    }

    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .posterFrame: return "widget_style_poster_frame".localized(for: language)
        case .sanctuary: return "widget_style_sanctuary".localized(for: language)
        }
    }

    func localizedSubtitle(for language: AppLanguage) -> String {
        switch self {
        case .posterFrame: return "widget_style_poster_frame_desc".localized(for: language)
        case .sanctuary: return "widget_style_sanctuary_desc".localized(for: language)
        }
    }

    var iconName: String {
        switch self {
        case .posterFrame: return "photo.fill"
        case .sanctuary: return "moon.stars.fill"
        }
    }

    var fontDesign: Font.Design { .serif }

    /// Запасной фон контейнера виджета: под фотографией «Кадра» и под рисунком «Святилища»
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .posterFrame:
            return LinearGradient(
                colors: [Color(red: 0.11, green: 0.09, blue: 0.06), Color(red: 0.26, green: 0.18, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sanctuary:
            return LinearGradient(
                colors: [Color(red: 0.07, green: 0.06, blue: 0.05), Color(red: 0.13, green: 0.11, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        posterArt.mainColor
    }

    func secondaryTextColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        posterArt.accentColor
    }

    func quoteIconColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        posterArt.accentColor.opacity(0.85)
    }

    func borderStroke(for colorScheme: ColorScheme) -> LinearGradient {
        let tint = posterArt.accentColor
        return LinearGradient(
            colors: [tint.opacity(0.55), tint.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func buttonBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .posterFrame: return Color.white.opacity(0.18)
        case .sanctuary: return Color(red: 0.78, green: 0.65, blue: 0.42).opacity(0.18)
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
            case .armenian: return "Նարեկացու ոգով"
            case .russian: return "В духе Нарекаци"
            case .english: return "In the spirit of Narekatsi"
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
            case .armenian: return "Նարեկացու ոգով"
            case .russian: return "В духе Нарекаци"
            case .english: return "In the spirit of Narekatsi"
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
    case small = "small"            // 2x2 (Рабочий стол / StandBy)
    case medium = "medium"          // 4x2 (Рабочий стол)
    case large = "large"            // 4x4 (Рабочий стол)
    case lockScreen = "lockScreen"  // Экран блокировки
    
    var id: String { rawValue }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .small:
            switch language {
            case .armenian: return "Գլխավոր 2×2"
            case .russian: return "Рабочий стол 2×2"
            case .english: return "Home Screen 2×2"
            }
        case .medium:
            switch language {
            case .armenian: return "Գլխավոր 4×2"
            case .russian: return "Рабочий стол 4×2"
            case .english: return "Home Screen 4×2"
            }
        case .large:
            switch language {
            case .armenian: return "Գլխավոր 4×4"
            case .russian: return "Рабочий стол 4×4"
            case .english: return "Home Screen 4×4"
            }
        case .lockScreen:
            switch language {
            case .armenian: return "Կողպեքի էկրան"
            case .russian: return "Экран блокировки"
            case .english: return "Lock Screen"
            }
        }
    }
    
    var iconName: String {
        switch self {
        case .small: return "apps.iphone"
        case .medium: return "rectangle.fill"
        case .large: return "square.grid.2x2.fill"
        case .lockScreen: return "lock.fill"
        }
    }
}


