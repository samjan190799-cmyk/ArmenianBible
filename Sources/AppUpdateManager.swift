import SwiftUI
import UIKit

// MARK: - Модель конфигурации версии приложения
struct AppVersionConfig: Codable, Sendable {
    let minVersion: String
    let latestVersion: String
    let forceUpdate: Bool
    let updateUrl: String?
    let titleHy: String?
    let titleRu: String?
    let titleEn: String?
    let messageHy: String?
    let messageRu: String?
    let messageEn: String?
    
    enum CodingKeys: String, CodingKey {
        case minVersion = "min_version"
        case latestVersion = "latest_version"
        case forceUpdate = "force_update"
        case updateUrl = "update_url"
        case titleHy = "title_hy"
        case titleRu = "title_ru"
        case titleEn = "title_en"
        case messageHy = "message_hy"
        case messageRu = "message_ru"
        case messageEn = "message_en"
    }
}

// MARK: - Менеджер Принудительного Обновления (Force Update Manager)
/// Управляет проверкой наличия критических обновлений в App Store
/// и удаленным управлением блокировкой устаревших версий.
@MainActor
final class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()
    
    /// Ссылка на приложение в App Store
    let appStoreURL: URL = URL(string: "https://apps.apple.com/app/id6790569890")!
    
    /// URL удаленного конфигуратора версий на GitHub Pages
    private let remoteConfigURL = URL(string: "https://samjan190799-cmyk.github.io/armenianbible-version.json")!
    
    /// Флаг обязательного блокирующего обновления
    @Published var isForceUpdateRequired: Bool = false
    
    /// Доступная версия в App Store
    @Published var availableVersion: String = ""
    
    /// Определяет, запущено ли приложение в среде TestFlight, на симуляторе или в отладочной сборке.
    /// В TestFlight и при разработке принудительное обновление никогда не блокирует пользователя.
    var isTestFlightOrDebug: Bool {
        Bundle.isTestFlightOrDebug
    }
    
    /// Текущая установленная версия
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.7"
    }
    
    /// Заголовок окна обновления в зависимости от языка
    @Published var updateTitle: String = ""
    
    /// Текст сообщения обновления
    @Published var updateMessage: String = ""
    
    private var isChecking: Bool = false
    
    private init() {}
    
    // MARK: - Проверка обновлений
    func checkForUpdates(language: AppLanguage = .armenian) {
        // В TestFlight, на симуляторе или при локальной отладке блокирующий экран никогда не показывается
        if isTestFlightOrDebug {
            isForceUpdateRequired = false
            return
        }
        
        guard !isChecking else { return }
        isChecking = true
        
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.isChecking = false }
            
            // 1. Попытка получить удаленный конфиг с GitHub Pages
            let remoteConfig = await self.fetchRemoteConfig()
            
            if let config = remoteConfig {
                let isOlderThanMin = AppUpdateManager.isVersion(self.currentVersion, olderThan: config.minVersion)
                let isOlderThanLatest = AppUpdateManager.isVersion(self.currentVersion, olderThan: config.latestVersion)
                let isForce = config.forceUpdate && isOlderThanLatest
                
                if isOlderThanMin || isForce {
                    self.availableVersion = config.latestVersion
                    self.configureLocalizedTexts(config: config, language: language)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.isForceUpdateRequired = true
                    }
                    return
                }
            }
            
            // 2. Фолбек: проверка через официальный iTunes Lookup API
            if let storeVersion = await self.fetchAppStoreVersion() {
                if AppUpdateManager.isVersion(self.currentVersion, olderThan: storeVersion) {
                    self.availableVersion = storeVersion
                    self.configureDefaultTexts(newVersion: storeVersion, language: language)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.isForceUpdateRequired = true
                    }
                }
            }
        }
    }
    
    // MARK: - Загрузка удаленного конфига
    private func fetchRemoteConfig() async -> AppVersionConfig? {
        do {
            var request = URLRequest(url: remoteConfigURL)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 6.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(AppVersionConfig.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Запрос версии в iTunes Lookup API
    private func fetchAppStoreVersion() async -> String? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=com.samvel.armenianbible") else {
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 6.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first,
               let version = first["version"] as? String {
                return version
            }
        } catch {
            return nil
        }
        return nil
    }
    
    // MARK: - Локализация текстов
    private func configureLocalizedTexts(config: AppVersionConfig, language: AppLanguage) {
        switch language {
        case .armenian:
            self.updateTitle = config.titleHy ?? "Պարտադիր թարմացում"
            self.updateMessage = config.messageHy ?? "Հավելվածի նոր տարբերակը հասանելի է App Store-ում: Խնդրում ենք թարմացնել՝ շարունակելու համար:"
        case .russian:
            self.updateTitle = config.titleRu ?? "Требуется обновление"
            self.updateMessage = config.messageRu ?? "Доступна новая версия приложения Luys в App Store. Пожалуйста, обновите приложение, чтобы продолжить использование."
        case .english:
            self.updateTitle = config.titleEn ?? "Update Required"
            self.updateMessage = config.messageEn ?? "A new version of Luys is available on the App Store. Please update to continue using the app."
        }
    }
    
    private func configureDefaultTexts(newVersion: String, language: AppLanguage) {
        switch language {
        case .armenian:
            self.updateTitle = "Պարտադիր թարմացում"
            self.updateMessage = "Հասանելի է Luys հավելվածի նոր \(newVersion) տարբերակը: Խնդրում ենք թարմացնել App Store-ից:"
        case .russian:
            self.updateTitle = "Требуется обновление"
            self.updateMessage = "Вышла новая версия Luys \(newVersion) с важными исправлениями. Обновите приложение в App Store, чтобы продолжить."
        case .english:
            self.updateTitle = "Update Required"
            self.updateMessage = "A new version \(newVersion) of Luys is available with important updates. Please update on the App Store to continue."
        }
    }
    
    // MARK: - Переход в App Store для обновления
    func openAppStore() {
        Haptics.notify(.success)
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Семантическое сравнение версий
    /// Возвращает true если v1 строго меньше v2 (например, "2.3" < "2.4")
    static func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 < p2 { return true }
            if p1 > p2 { return false }
        }
        return false
    }
}

// MARK: - Полноэкранный Экран Блокировки Обновления (Force Update Overlay)
/// Блокирует использование приложения до обновления до актуальной версии
struct ForceUpdateOverlayView: View {
    @ObservedObject private var updateManager = AppUpdateManager.shared
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing: Bool = false
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [manager.accentTheme.color, manager.accentTheme.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // Размытый полноэкранный затемняющий фон
            Paper.scrim
                .ignoresSafeArea()
            
            // Центральная карточка блокировки
            VStack(spacing: 24) {
                // Анимированная иконка обновления
                ZStack {
                    Circle()
                        .fill(manager.accentTheme.color.opacity(0.18))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isPulsing ? 1.15 : 0.95)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [manager.accentTheme.color, manager.accentTheme.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: Paper.shadow, radius: 16, y: 6)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(Paper.onAccent)
                        .rotationEffect(.degrees(isPulsing ? 360 : 0))
                }
                .padding(.top, 8)
                
                // Бейдж версии
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text(versionBadgeText)
                        .font(PaperFont.font(size: 12, weight: .semibold))
                }
                .foregroundColor(manager.accentTheme.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(manager.accentTheme.color.opacity(0.15))
                .clipShape(Capsule())
                
                // Заголовок и описание
                VStack(spacing: 10) {
                    Text(updateManager.updateTitle.isEmpty ? defaultTitle : updateManager.updateTitle)
                        .font(PaperFont.font(size: 22, weight: .semibold))
                        .foregroundColor(Paper.ink)
                        .multilineTextAlignment(.center)
                    
                    Text(updateManager.updateMessage.isEmpty ? defaultMessage : updateManager.updateMessage)
                        .font(PaperFont.font(size: 14.5))
                        .foregroundColor(Paper.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                
                // Сравнение версий
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text(currentVersionLabel)
                            .font(PaperFont.font(size: 11, weight: .medium))
                            .foregroundColor(Paper.inkSecondary)
                        Text(updateManager.currentVersion)
                            .font(PaperFont.font(size: 14, weight: .semibold))
                            .foregroundColor(Paper.ink)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(manager.accentTheme.color)
                    
                    VStack(spacing: 2) {
                        Text(newVersionLabel)
                            .font(PaperFont.font(size: 11, weight: .medium))
                            .foregroundColor(manager.accentTheme.color)
                        Text(updateManager.availableVersion.isEmpty ? "2.4+" : updateManager.availableVersion)
                            .font(PaperFont.font(size: 14, weight: .semibold))
                            .foregroundColor(manager.accentTheme.color)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Paper.fillSubtle)
                .cornerRadius(12)
                
                // Главная обязательная кнопка «Обновить в App Store»
                Button {
                    updateManager.openAppStore()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text(updateButtonText)
                            .font(PaperFont.font(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Paper.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [manager.accentTheme.color, manager.accentTheme.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Paper.shadow, radius: 12, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Paper.page)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Paper.fillMuted, Paper.fillMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Paper.shadow, radius: 30, y: 15)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).loops(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    // MARK: - Локализованные надписи
    private var versionBadgeText: String {
        switch manager.appLanguage {
        case .armenian: return "ՆՈՐ ԹԱՐՄԱՑՈՒՄ"
        case .russian:  return "НОВАЯ ВЕРСИЯ"
        case .english:  return "NEW UPDATE"
        }
    }
    
    private var defaultTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Պարտադիր թարմացում"
        case .russian:  return "Требуется обновление"
        case .english:  return "Update Required"
        }
    }
    
    private var defaultMessage: String {
        switch manager.appLanguage {
        case .armenian: return "Շարունակելու համար անհրաժեշտ է թարմացնել Luys հավելվածը App Store-ում:"
        case .russian:  return "Для продолжения использования необходимо обновить приложение Luys в App Store."
        case .english:  return "Please update Luys to the latest version on the App Store to continue."
        }
    }
    
    private var currentVersionLabel: String {
        switch manager.appLanguage {
        case .armenian: return "Ընթացիկ"
        case .russian:  return "Текущая"
        case .english:  return "Current"
        }
    }
    
    private var newVersionLabel: String {
        switch manager.appLanguage {
        case .armenian: return "Նոր տարբերակ"
        case .russian:  return "Новая"
        case .english:  return "New"
        }
    }
    
    private var updateButtonText: String {
        switch manager.appLanguage {
        case .armenian: return "Թարմացնել App Store-ում"
        case .russian:  return "Обновить в App Store"
        case .english:  return "Update on App Store"
        }
    }
}
