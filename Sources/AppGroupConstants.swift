import Foundation
import SwiftUI

// MARK: - Централизованное управление App Group хранилищем
enum AppGroupConstants {
    static let activeSuiteName = "group.com.rileytestut.AltStore.V7J345DY58"
    static let legacySuiteName = "group.com.samvel.ArmenianBible"
    
    static var allSuites: [String] {
        [activeSuiteName, legacySuiteName]
    }
    
    static var sharedDefaults: UserDefaults {
        if let d = UserDefaults(suiteName: activeSuiteName) {
            return d
        }
        if let d = UserDefaults(suiteName: legacySuiteName) {
            return d
        }
        return UserDefaults.standard
    }
    
    /// Отказоустойчивое чтение строки из всех доступных хранилищ песочницы
    static func sharedString(forKey key: String) -> String? {
        for suite in allSuites {
            if let d = UserDefaults(suiteName: suite), let val = d.string(forKey: key), !val.isEmpty {
                return val
            }
        }
        if let stdVal = UserDefaults.standard.string(forKey: key), !stdVal.isEmpty {
            return stdVal
        }
        return nil
    }
    
    /// Отказоустойчивое чтение булевого флага из всех доступных хранилищ песочницы
    static func sharedBool(forKey key: String) -> Bool {
        for suite in allSuites {
            if let d = UserDefaults(suiteName: suite), d.bool(forKey: key) {
                return true
            }
        }
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Отказоустойчивое чтение выбранного стиля виджета
    static func sharedVisualStyle() -> WidgetVisualStyle {
        let keys = ["widget_visual_style", "widgetVisualStyle"]
        for key in keys {
            if let raw = sharedString(forKey: key), let style = WidgetVisualStyle(rawValue: raw) {
                return style
            }
        }
        return .oledStandby
    }
    
    static func syncToAll(_ update: (UserDefaults) -> Void) {
        for suite in allSuites {
            if let defs = UserDefaults(suiteName: suite) {
                update(defs)
                defs.synchronize()
            }
        }
        update(UserDefaults.standard)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Шрифт виджета экрана блокировки
/// Четыре варианта начертания для виджета Lock Screen.
/// Хранится в App Group по ключу "lock_screen_font_design".
enum LockScreenFontDesign: String, CaseIterable, Identifiable {
    case serif     = "serif"      // Классический (Georgia/Times) — по умолчанию
    case rounded   = "rounded"    // Мягкий закруглённый
    case monospaced = "monospaced" // Моноширинный (технический)
    case standard  = "standard"   // Системный (San Francisco)
    
    var id: String { rawValue }
    
    var fontDesign: Font.Design {
        switch self {
        case .serif:      return .serif
        case .rounded:    return .rounded
        case .monospaced: return .monospaced
        case .standard:   return .default
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .serif:
            switch language {
            case .armenian: return "Դասական (Serif)"
            case .russian:  return "Классический (Serif)"
            case .english:  return "Classic (Serif)"
            }
        case .rounded:
            switch language {
            case .armenian: return "Կլոր (Rounded)"
            case .russian:  return "Округлый (Rounded)"
            case .english:  return "Rounded"
            }
        case .monospaced:
            switch language {
            case .armenian: return "Մոնո (Monospaced)"
            case .russian:  return "Моно (Monospaced)"
            case .english:  return "Monospaced"
            }
        case .standard:
            switch language {
            case .armenian: return "Համակարգ (Default)"
            case .russian:  return "Системный (Default)"
            case .english:  return "System (Default)"
            }
        }
    }
    
    var previewText: String { "Ա • А • A" }
}

extension AppGroupConstants {
    /// Считывает выбранный шрифт виджета блокировки из App Group
    static func sharedLockScreenFontDesign() -> LockScreenFontDesign {
        if let raw = sharedString(forKey: "lock_screen_font_design"),
           let design = LockScreenFontDesign(rawValue: raw) {
            return design
        }
        return .serif
    }
}
