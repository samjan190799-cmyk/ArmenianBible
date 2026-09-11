import SwiftUI
import UIKit

// MARK: - Варианты иконок приложения
enum AppIconOption: String, CaseIterable, Identifiable {
    case classic = "classic"
    case pitchBlack = "pitchBlack"
    case snowWhite = "snowWhite"
    case goldenGlow = "goldenGlow"
    case royalIndigo = "royalIndigo"
    case royalPomegranate = "royalPomegranate"
    case sacredEmerald = "sacredEmerald"
    
    var id: String { rawValue }
    
    /// Имя иконки для передачи в UIApplication.shared.setAlternateIconName (nil = первичная)
    var iconName: String? {
        switch self {
        case .classic:
            return nil
        case .pitchBlack:
            return "AppIcon-PitchBlack"
        case .snowWhite:
            return "AppIcon-SnowWhite"
        case .goldenGlow:
            return "AppIcon-GoldenGlow"
        case .royalIndigo:
            return "AppIcon-RoyalIndigo"
        case .royalPomegranate:
            return "AppIcon-RoyalPomegranate"
        case .sacredEmerald:
            return "AppIcon-SacredEmerald"
        }
    }
    
    /// Имя ассета превью в Assets.xcassets
    var assetPreviewName: String {
        switch self {
        case .classic:
            return "AppIcon-Classic"
        case .pitchBlack:
            return "AppIcon-PitchBlack"
        case .snowWhite:
            return "AppIcon-SnowWhite"
        case .goldenGlow:
            return "AppIcon-GoldenGlow"
        case .royalIndigo:
            return "AppIcon-RoyalIndigo"
        case .royalPomegranate:
            return "AppIcon-RoyalPomegranate"
        case .sacredEmerald:
            return "AppIcon-SacredEmerald"
        }
    }
    
    /// Является ли эксклюзивной Premium функцией
    var isPremium: Bool {
        switch self {
        case .classic, .pitchBlack, .snowWhite:
            return false
        case .goldenGlow, .royalIndigo, .royalPomegranate, .sacredEmerald:
            return true
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .classic:
            switch language {
            case .armenian: return "Դասական"
            case .russian: return "Классическая"
            case .english: return "Classic"
            }
        case .pitchBlack:
            switch language {
            case .armenian: return "Խորը Սև"
            case .russian: return "Черно-белая"
            case .english: return "Pitch Black"
            }
        case .snowWhite:
            switch language {
            case .armenian: return "Ձյունաճերմակ"
            case .russian: return "Белоснежная"
            case .english: return "Snow White"
            }
        case .goldenGlow:
            switch language {
            case .armenian: return "Ոսկեգույն Փայլ"
            case .russian: return "Золотое сияние"
            case .english: return "Golden Glow"
            }
        case .royalIndigo:
            switch language {
            case .armenian: return "Արքայական Ինդիգո"
            case .russian: return "Королевский Индиго"
            case .english: return "Royal Indigo"
            }
        case .royalPomegranate:
            switch language {
            case .armenian: return "Արքայական Նուռ"
            case .russian: return "Королевский Гранат"
            case .english: return "Royal Pomegranate"
            }
        case .sacredEmerald:
            switch language {
            case .armenian: return "Սրբազան Զմրուխտ"
            case .russian: return "Священный Изумруд"
            case .english: return "Sacred Emerald"
            }
        }
    }
    
    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .classic:
            switch language {
            case .armenian: return "Ավանդական քարե խաչքար"
            case .russian: return "Традиционный каменный хачкар"
            case .english: return "Traditional stone cross"
            }
        case .pitchBlack:
            switch language {
            case .armenian: return "Սև ֆոն և սպիտակ խաչքար"
            case .russian: return "Глубокий черный фон и белый хачкар"
            case .english: return "Pitch black & pure white cross"
            }
        case .snowWhite:
            switch language {
            case .armenian: return "Մաքուր սպիտակ ֆոն և մուգ խաչքար"
            case .russian: return "Чистый белый фон и темный хачкар"
            case .english: return "Pure white canvas & bold dark cross"
            }
        case .goldenGlow:
            switch language {
            case .armenian: return "Պայծառ ճառագայթող ոսկեգույն լույս"
            case .russian: return "Яркий теплый золотой свет"
            case .english: return "Radiant warm golden light"
            }
        case .royalIndigo:
            switch language {
            case .armenian: return "Գիշերային շափյուղա և աստվածային շունչ"
            case .russian: return "Ночной сапфир и золотое благословение"
            case .english: return "Celestial sapphire night & gold"
            }
        case .royalPomegranate:
            switch language {
            case .armenian: return "Հայկական նռան երանգ և ոսկեզօծ խաչ"
            case .russian: return "Благородный гранатовый тон и золотой хачкар"
            case .english: return "Noble pomegranate crimson & radiant gold"
            }
        case .sacredEmerald:
            switch language {
            case .armenian: return "Խորը զմրուխտյա հանգստություն և ոսկի"
            case .russian: return "Глубокий изумрудный цвет и золотой свет"
            case .english: return "Deep mystical emerald & celestial gold"
            }
        }
    }
}

// MARK: - Менеджер выбора альтернативной иконки приложения
@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    private let storageKey = "selected_app_icon_option_v1"
    
    @Published private(set) var currentOption: AppIconOption = .classic
    @Published var errorMessage: String? = nil
    
    private init() {
        syncWithSystem()
    }
    
    /// Синхронизация текущей выбранной иконки с системой и UserDefaults
    func syncWithSystem() {
        if let savedRaw = UserDefaults.standard.string(forKey: storageKey),
           let savedOption = AppIconOption(rawValue: savedRaw) {
            self.currentOption = savedOption
        } else {
            // Проверяем системную установку
            let systemIconName = UIApplication.shared.alternateIconName
            if let matched = AppIconOption.allCases.first(where: { $0.iconName == systemIconName }) {
                self.currentOption = matched
            } else {
                self.currentOption = .classic
            }
        }
    }
    
    /// Сброс ошибки
    func clearError() {
        errorMessage = nil
    }
    
    /// Попытка выбрать иконку
    /// - Returns: true, если иконка успешно установлена; false, если заблокирована (требуется Paywall)
    @discardableResult
    func selectIcon(_ option: AppIconOption, onRequirePaywall: () -> Void) -> Bool {
        // Проверка Premium прав
        if option.isPremium && !SubscriptionManager.shared.isPremium {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.warning)
            onRequirePaywall()
            return false
        }
        
        // Если иконка уже выбрана
        if currentOption == option {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            return true
        }
        
        guard UIApplication.shared.supportsAlternateIcons else {
            print("⚠️ Device does not support alternate app icons")
            self.errorMessage = "Alternate icons not supported on this device"
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.error)
            return false
        }
        
        let targetIconName = option.iconName
        
        UIApplication.shared.setAlternateIconName(targetIconName) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Error setting alternate app icon: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.error)
                } else {
                    self?.currentOption = option
                    UserDefaults.standard.set(option.rawValue, forKey: self?.storageKey ?? "selected_app_icon_option_v1")
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                }
            }
        }
        
        return true
    }
}
