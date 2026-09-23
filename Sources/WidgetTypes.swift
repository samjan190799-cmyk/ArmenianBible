import Foundation
import SwiftUI

// MARK: - Визуальные стили виджетов и режима StandBy
enum WidgetVisualStyle: String, CaseIterable, Identifiable, Codable {
    case oledStandby = "oledStandby"
    case modernMinimal = "modernMinimal"
    case sacredParchment = "sacredParchment"
    case royalMonastery = "royalMonastery"
    case monochrome = "monochrome"
    case celestialEmerald = "celestialEmerald"
    case crimsonGospel = "crimsonGospel"
    case auroraSunset = "auroraSunset"
    case monasticStone = "monasticStone"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .oledStandby: return "widget_style_oled".localized(for: language)
        case .modernMinimal: return "widget_style_glass".localized(for: language)
        case .sacredParchment: return "widget_style_parchment".localized(for: language)
        case .royalMonastery: return "widget_style_royal".localized(for: language)
        case .monochrome: return "widget_style_monochrome".localized(for: language)
        case .celestialEmerald: return "widget_style_emerald".localized(for: language)
        case .crimsonGospel: return "widget_style_crimson".localized(for: language)
        case .auroraSunset: return "widget_style_sunset".localized(for: language)
        case .monasticStone: return "widget_style_stone".localized(for: language)
        }
    }
    
    func localizedSubtitle(for language: AppLanguage) -> String {
        switch self {
        case .oledStandby: return "widget_style_oled_desc".localized(for: language)
        case .modernMinimal: return "widget_style_glass_desc".localized(for: language)
        case .sacredParchment: return "widget_style_parchment_desc".localized(for: language)
        case .royalMonastery: return "widget_style_royal_desc".localized(for: language)
        case .monochrome: return "widget_style_monochrome_desc".localized(for: language)
        case .celestialEmerald: return "widget_style_emerald_desc".localized(for: language)
        case .crimsonGospel: return "widget_style_crimson_desc".localized(for: language)
        case .auroraSunset: return "widget_style_sunset_desc".localized(for: language)
        case .monasticStone: return "widget_style_stone_desc".localized(for: language)
        }
    }
    
    var iconName: String {
        switch self {
        case .oledStandby: return "moon.stars.fill"
        case .modernMinimal: return "sparkles"
        case .sacredParchment: return "scroll.fill"
        case .royalMonastery: return "crown.fill"
        case .monochrome: return "circle.lefthalf.filled"
        case .celestialEmerald: return "leaf.fill"
        case .crimsonGospel: return "drop.fill"
        case .auroraSunset: return "sun.horizon.fill"
        case .monasticStone: return "mountain.2.fill"
        }
    }
    
    var fontDesign: Font.Design {
        switch self {
        case .oledStandby: return .serif
        case .modernMinimal: return .rounded
        case .sacredParchment: return .serif
        case .royalMonastery: return .serif
        case .monochrome: return .default
        case .celestialEmerald: return .serif
        case .crimsonGospel: return .serif
        case .auroraSunset: return .rounded
        case .monasticStone: return .serif
        }
    }
    
    var isOled: Bool {
        self == .oledStandby
    }
    
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .oledStandby:
            // Чистейший OLED черный в обоих режимах для энергосбережения и StandBy
            return LinearGradient(
                colors: [Color.black, Color(red: 0.04, green: 0.04, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .modernMinimal:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.11, blue: 0.19), Color(red: 0.13, green: 0.17, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.94, green: 0.96, blue: 1.0), Color(red: 0.86, green: 0.90, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .sacredParchment:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.16, green: 0.11, blue: 0.08), Color(red: 0.24, green: 0.17, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.94, blue: 0.86), Color(red: 0.91, green: 0.85, blue: 0.73)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .royalMonastery:
            // Настоящий величественный королевский сапфирово-синий (Royal Blue) в обоих режимах!
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.06, green: 0.12, blue: 0.32), Color(red: 0.10, green: 0.20, blue: 0.50)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.10, green: 0.22, blue: 0.58), Color(red: 0.16, green: 0.34, blue: 0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .monochrome:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.14, green: 0.14, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color.white, Color(red: 0.93, green: 0.93, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .celestialEmerald:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.04, green: 0.16, blue: 0.11), Color(red: 0.07, green: 0.25, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.92, green: 0.97, blue: 0.93), Color(red: 0.81, green: 0.92, blue: 0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .crimsonGospel:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.18, green: 0.05, blue: 0.09), Color(red: 0.28, green: 0.08, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.99, green: 0.92, blue: 0.94), Color(red: 0.96, green: 0.82, blue: 0.86)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .auroraSunset:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [
                        Color(red: 0.14, green: 0.08, blue: 0.22),
                        Color(red: 0.26, green: 0.12, blue: 0.22),
                        Color(red: 0.38, green: 0.15, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.93, blue: 0.88),
                        Color(red: 1.0, green: 0.84, blue: 0.82),
                        Color(red: 0.95, green: 0.76, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .monasticStone:
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [Color(red: 0.09, green: 0.10, blue: 0.12), Color(red: 0.14, green: 0.15, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.93, green: 0.94, blue: 0.95), Color(red: 0.85, green: 0.86, blue: 0.88)],
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
            return colorScheme == .dark ? Color.white : Color(red: 0.08, green: 0.11, blue: 0.18)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.99, green: 0.95, blue: 0.85) : Color(red: 0.20, green: 0.12, blue: 0.06)
        case .royalMonastery:
            // Белый текст на насыщенном королевском синем фоне
            return Color(red: 0.98, green: 0.99, blue: 1.0)
        case .monochrome:
            return colorScheme == .dark ? Color.white : Color.black
        case .celestialEmerald:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.99, blue: 0.97) : Color(red: 0.06, green: 0.22, blue: 0.15)
        case .crimsonGospel:
            return colorScheme == .dark ? Color(red: 0.99, green: 0.95, blue: 0.96) : Color(red: 0.30, green: 0.06, blue: 0.12)
        case .auroraSunset:
            return colorScheme == .dark ? Color(red: 1.0, green: 0.97, blue: 0.94) : Color(red: 0.22, green: 0.08, blue: 0.20)
        case .monasticStone:
            return colorScheme == .dark ? Color(red: 0.95, green: 0.96, blue: 0.98) : Color(red: 0.12, green: 0.13, blue: 0.15)
        }
    }
    
    private func parseAccentColor(_ hex: String) -> Color? {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6 || clean.count == 8 || clean.count == 3 else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&int) else { return nil }
        let a, r, g, b: UInt64
        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        let dynamicAccent = parseAccentColor(accentHex)
        switch self {
        case .oledStandby:
            if accentHex.uppercased() != "6366F1", let customAccent = dynamicAccent {
                return customAccent
            }
            return Color(red: 0.98, green: 0.75, blue: 0.14)
        case .modernMinimal:
            if let customAccent = dynamicAccent {
                return customAccent
            }
            return colorScheme == .dark ? Color(red: 0.60, green: 0.68, blue: 0.98) : Color(red: 0.28, green: 0.35, blue: 0.85)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.72, blue: 0.25) : Color(red: 0.58, green: 0.32, blue: 0.08)
        case .royalMonastery:
            // Светло-небесный / золотистый для ссылок на королевском синем
            return Color(red: 0.72, green: 0.86, blue: 1.0)
        case .monochrome:
            return colorScheme == .dark ? Color(red: 0.75, green: 0.75, blue: 0.78) : Color(red: 0.35, green: 0.35, blue: 0.38)
        case .celestialEmerald:
            return colorScheme == .dark ? Color(red: 0.40, green: 0.88, blue: 0.65) : Color(red: 0.10, green: 0.45, blue: 0.30)
        case .crimsonGospel:
            return colorScheme == .dark ? Color(red: 0.98, green: 0.75, blue: 0.55) : Color(red: 0.65, green: 0.15, blue: 0.25)
        case .auroraSunset:
            return colorScheme == .dark ? Color(red: 1.0, green: 0.70, blue: 0.40) : Color(red: 0.78, green: 0.28, blue: 0.22)
        case .monasticStone:
            return colorScheme == .dark ? Color(red: 0.85, green: 0.70, blue: 0.45) : Color(red: 0.45, green: 0.35, blue: 0.20)
        }
    }
    
    func quoteIconColor(for colorScheme: ColorScheme, accentHex: String = "6366F1") -> Color {
        let dynamicAccent = parseAccentColor(accentHex)
        switch self {
        case .oledStandby:
            if accentHex.uppercased() != "6366F1", let customAccent = dynamicAccent {
                return customAccent.opacity(0.90)
            }
            return Color(red: 0.96, green: 0.68, blue: 0.12).opacity(0.90)
        case .modernMinimal:
            if let customAccent = dynamicAccent {
                return customAccent.opacity(colorScheme == .dark ? 0.75 : 0.60)
            }
            return colorScheme == .dark ? Color(red: 0.50, green: 0.58, blue: 0.98).opacity(0.70) : Color(red: 0.31, green: 0.38, blue: 0.90).opacity(0.50)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.68, blue: 0.18).opacity(0.85) : Color(red: 0.68, green: 0.35, blue: 0.08).opacity(0.65)
        case .royalMonastery:
            return Color(red: 0.60, green: 0.84, blue: 1.0).opacity(0.85)
        case .monochrome:
            return colorScheme == .dark ? Color.white.opacity(0.40) : Color.black.opacity(0.35)
        case .celestialEmerald:
            return colorScheme == .dark ? Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.85) : Color(red: 0.12, green: 0.50, blue: 0.35).opacity(0.70)
        case .crimsonGospel:
            return colorScheme == .dark ? Color(red: 0.98, green: 0.70, blue: 0.50).opacity(0.85) : Color(red: 0.70, green: 0.18, blue: 0.28).opacity(0.70)
        case .auroraSunset:
            return colorScheme == .dark ? Color(red: 1.0, green: 0.55, blue: 0.45).opacity(0.85) : Color(red: 0.82, green: 0.30, blue: 0.25).opacity(0.70)
        case .monasticStone:
            return colorScheme == .dark ? Color(red: 0.80, green: 0.65, blue: 0.40).opacity(0.85) : Color(red: 0.48, green: 0.38, blue: 0.22).opacity(0.70)
        }
    }
    
    func borderStroke(for colorScheme: ColorScheme) -> LinearGradient {
        switch self {
        case .oledStandby:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.68, blue: 0.12).opacity(0.55),
                    Color(red: 0.85, green: 0.47, blue: 0.04).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .modernMinimal:
            let topAlpha: Double = colorScheme == .dark ? 0.35 : 0.25
            let btmAlpha: Double = colorScheme == .dark ? 0.10 : 0.08
            return LinearGradient(
                colors: [Color.white.opacity(topAlpha), Color.white.opacity(btmAlpha)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sacredParchment:
            return LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.50, blue: 0.15).opacity(0.55),
                    Color(red: 0.45, green: 0.25, blue: 0.05).opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .royalMonastery:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.55),
                    Color(red: 0.15, green: 0.30, blue: 0.75).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .monochrome:
            let alpha: Double = colorScheme == .dark ? 0.30 : 0.20
            return LinearGradient(
                colors: [Color.primary.opacity(alpha), Color.primary.opacity(alpha * 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .celestialEmerald:
            return LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.85, blue: 0.55).opacity(0.45),
                    Color(red: 0.10, green: 0.40, blue: 0.25).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .crimsonGospel:
            return LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.40, blue: 0.50).opacity(0.45),
                    Color(red: 0.45, green: 0.10, blue: 0.20).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .auroraSunset:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.60, blue: 0.40).opacity(0.50),
                    Color(red: 0.80, green: 0.25, blue: 0.45).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .monasticStone:
            return LinearGradient(
                colors: [
                    Color(red: 0.70, green: 0.72, blue: 0.78).opacity(0.40),
                    Color(red: 0.40, green: 0.42, blue: 0.48).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    func buttonBackground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .oledStandby:
            return Color(red: 0.96, green: 0.68, blue: 0.12).opacity(0.20)
        case .modernMinimal:
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
        case .sacredParchment:
            return colorScheme == .dark ? Color(red: 0.96, green: 0.72, blue: 0.25).opacity(0.18) : Color(red: 0.58, green: 0.32, blue: 0.08).opacity(0.10)
        case .royalMonastery:
            return Color.white.opacity(0.18)
        case .monochrome:
            return colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
        case .celestialEmerald:
            return Color(red: 0.30, green: 0.85, blue: 0.55).opacity(colorScheme == .dark ? 0.20 : 0.12)
        case .crimsonGospel:
            return Color(red: 0.90, green: 0.40, blue: 0.50).opacity(colorScheme == .dark ? 0.20 : 0.12)
        case .auroraSunset:
            return Color(red: 1.0, green: 0.60, blue: 0.40).opacity(colorScheme == .dark ? 0.22 : 0.12)
        case .monasticStone:
            return Color(red: 0.80, green: 0.65, blue: 0.40).opacity(colorScheme == .dark ? 0.18 : 0.10)
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


