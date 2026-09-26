import Foundation
import SwiftUI

// MARK: - Централизованное управление App Group хранилищем
enum AppGroupConstants {
    // Основная официальная группа Apple Developer Portal (TestFlight / App Store)
    static let appleAppGroupSuiteName = "group.com.samvel.ArmenianBible"
    static let altStoreSuiteName = "group.com.rileytestut.AltStore.V7J345DY58"
    
    // Для обратной совместимости
    static var activeSuiteName: String { appleAppGroupSuiteName }
    static var legacySuiteName: String { altStoreSuiteName }
    
    static var allSuites: [String] {
        [appleAppGroupSuiteName, altStoreSuiteName]
    }
    
    static var sharedDefaults: UserDefaults {
        if let d = UserDefaults(suiteName: appleAppGroupSuiteName) {
            return d
        }
        if let d = UserDefaults(suiteName: altStoreSuiteName) {
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
    
    /// Отказоустойчивое чтение двоичных данных (Data) из файлового моста и UserDefaults
    static func sharedData(forKey key: String) -> Data? {
        // 1. Проверяем файл в общем контейнере App Group на диске (самый надежный способ синхронизации процесса приложения и виджета)
        for suite in allSuites {
            if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) {
                let fileURL = container.appendingPathComponent("\(key).json")
                if let data = try? Data(contentsOf: fileURL), !data.isEmpty {
                    return data
                }
            }
        }
        // 2. Проверяем UserDefaults всех доступных App Group
        for suite in allSuites {
            if let d = UserDefaults(suiteName: suite), let data = d.data(forKey: key), !data.isEmpty {
                return data
            }
        }
        // 3. Локальный UserDefaults
        if let stdData = UserDefaults.standard.data(forKey: key), !stdData.isEmpty {
            return stdData
        }
        return nil
    }
    
    /// Сохранение двоичных данных (Data) во все доступные хранилища и общий дисковый контейнер
    static func syncDataToAll(_ data: Data, forKey key: String) {
        for suite in allSuites {
            if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) {
                let fileURL = container.appendingPathComponent("\(key).json")
                try? data.write(to: fileURL, options: .atomic)
            }
            if let defs = UserDefaults(suiteName: suite) {
                defs.set(data, forKey: key)
                defs.synchronize()
            }
        }
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.synchronize()
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
