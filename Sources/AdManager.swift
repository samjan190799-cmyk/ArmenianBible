import SwiftUI
import UIKit
import Combine
import AppTrackingTransparency
import AdSupport

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif

// MARK: - Менеджер Рекламы Meta Audience Network
/// Центральный сервис управления показом баннеров, межстраничных объявлений и видео с наградой.
/// Автоматически учитывает статус подписки (Premium пользователи никогда не видят рекламу).
@MainActor
public final class AdManager: NSObject, ObservableObject {
    public static let shared = AdManager()
    
    // MARK: - Состояние готовности объявлений
    @Published public private(set) var isInterstitialReady: Bool = false
    @Published public private(set) var isRewardedReady: Bool = false
    @Published public private(set) var isTrackingAuthorized: Bool = false
    
    // MARK: - Внутренние свойства
    private var lastInterstitialTime: Date? = nil
    private var actionCounter: Int = 0
    private var onRewardCompletion: (() -> Void)? = nil
    
    #if canImport(FBAudienceNetwork)
    private var currentInterstitial: FBInterstitialAd?
    private var currentRewarded: FBRewardedVideoAd?
    #endif
    
    private override init() {
        super.init()
    }
    
    // MARK: - Инициализация SDK Meta
    public func initialize() {
        #if canImport(FBAudienceNetwork)
        // Настройка тестового режима
        if AdConfig.isTestMode {
            FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
            #if DEBUG
            print("📢 [AdManager] Meta Audience Network Test Device: \(FBAdSettings.testDeviceHash())")
            #endif
        }
        
        // Инициализация движка Meta
        FBAudienceNetworkAds.initialize(with: nil) { result in
            #if DEBUG
            print("📢 [AdManager] Meta SDK Init Result: \(result.isSuccess ? "Success" : "Failed")")
            #endif
        }
        #endif
        
        // Запрос разрешения App Tracking Transparency (ATT) с небольшой задержкой для готовности UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.requestTrackingPermission()
        }
        
        // Фоновая предзагрузка объявлений для мгновенного показа
        preloadAds()
    }
    
    // MARK: - Запрос разрешения ATT (iOS 14.5+)
    public func requestTrackingPermission() {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                Task { @MainActor in
                    let authorized = (status == .authorized)
                    self?.isTrackingAuthorized = authorized
                    
                    #if canImport(FBAudienceNetwork)
                    FBAdSettings.setAdvertiserTrackingEnabled(authorized)
                    #if DEBUG
                    print("📢 [AdManager] ATT Status: \(status.rawValue), AdvertiserTrackingEnabled: \(authorized)")
                    #endif
                    #endif
                }
            }
        }
    }
    
    // MARK: - Предзагрузка объявлений
    public func preloadAds() {
        guard !SubscriptionManager.shared.isPremium else {
            #if DEBUG
            print("📢 [AdManager] Premium активен — предзагрузка рекламы отключена")
            #endif
            return
        }
        
        preloadInterstitial()
        preloadRewarded()
    }
    
    public func preloadInterstitial() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium else { return }
        
        let placementID = AdConfig.interstitialPlacementID
        let interstitial = FBInterstitialAd(placementID: placementID)
        interstitial.delegate = self
        self.currentInterstitial = interstitial
        interstitial.load()
        #if DEBUG
        print("📢 [AdManager] Загрузка Interstitial: \(placementID)")
        #endif
        #endif
    }
    
    public func preloadRewarded() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium else { return }
        
        let placementID = AdConfig.rewardedPlacementID
        let rewarded = FBRewardedVideoAd(placementID: placementID)
        rewarded.delegate = self
        self.currentRewarded = rewarded
        rewarded.load()
        #if DEBUG
        print("📢 [AdManager] Загрузка Rewarded: \(placementID)")
        #endif
        #endif
    }
    
    // MARK: - Межстраничная реклама (Interstitial)
    
    /// Проверка возможности показа межстраничного объявления с учетом кулдауна и подписки
    public func canShowInterstitial() -> Bool {
        guard !SubscriptionManager.shared.isPremium else { return false }
        
        if let last = lastInterstitialTime {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < AdConfig.interstitialCooldownSeconds {
                return false
            }
        }
        
        #if canImport(FBAudienceNetwork)
        guard let interstitial = currentInterstitial, interstitial.isAdValid else {
            return false
        }
        return true
        #else
        return false
        #endif
    }
    
    /// Учет действия пользователя (например, сохранение обоев).
    /// При достижении порога интервала пытается показать рекламу.
    public func recordActionAndShowInterstitialIfReady(from viewController: UIViewController? = nil) {
        guard !SubscriptionManager.shared.isPremium else { return }
        
        actionCounter += 1
        if actionCounter >= AdConfig.interstitialActionInterval {
            showInterstitialIfReady(from: viewController)
        }
    }
    
    /// Показ межстраничной рекламы при соблюдении условий
    @discardableResult
    public func showInterstitialIfReady(from viewController: UIViewController? = nil) -> Bool {
        guard canShowInterstitial() else { return false }
        
        #if canImport(FBAudienceNetwork)
        guard let interstitial = currentInterstitial, interstitial.isAdValid else {
            return false
        }
        
        let targetVC = viewController ?? getTopViewController()
        guard let presenter = targetVC else { return false }
        
        interstitial.show(from: presenter)
        lastInterstitialTime = Date()
        actionCounter = 0
        isInterstitialReady = false
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Реклама с вознаграждением (Rewarded Video)
    
    /// Показ видео с наградой (например, для разблокировки дополнительного вопроса к ИИ)
    public func showRewardedAd(from viewController: UIViewController? = nil, onReward: @escaping () -> Void) {
        // Если у пользователя Premium — сразу отдаем награду без рекламы
        if SubscriptionManager.shared.isPremium {
            onReward()
            return
        }
        
        #if canImport(FBAudienceNetwork)
        if let rewarded = currentRewarded, rewarded.isAdValid {
            self.onRewardCompletion = onReward
            let targetVC = viewController ?? getTopViewController()
            if let presenter = targetVC {
                rewarded.show(from: presenter)
                isRewardedReady = false
                return
            }
        }
        #endif
        
        // Фолбек, если реклама не готова — выполняем награду, чтобы не ломать UX
        #if DEBUG
        print("📢 [AdManager] Rewarded видео не готово, предоставляем фолбек-доступ")
        #endif
        onReward()
        preloadRewarded()
    }
    
    // MARK: - Поиск верхнего UIViewController
    private func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = root as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return getTopViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return root
    }
}

// MARK: - Делегаты Meta Audience Network
#if canImport(FBAudienceNetwork)
extension AdManager: FBInterstitialAdDelegate {
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            self.isInterstitialReady = true
            #if DEBUG
            print("✅ [AdManager] Interstitial успешно загружен")
            #endif
        }
    }
    
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        Task { @MainActor in
            self.isInterstitialReady = false
            #if DEBUG
            print("⚠️ [AdManager] Ошибка загрузки Interstitial: \(error.localizedDescription)")
            #endif
        }
    }
    
    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            self.isInterstitialReady = false
            self.preloadInterstitial()
        }
    }
}

extension AdManager: FBRewardedVideoAdDelegate {
    public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            self.isRewardedReady = true
            #if DEBUG
            print("✅ [AdManager] Rewarded Video успешно загружено")
            #endif
        }
    }
    
    public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        Task { @MainActor in
            self.isRewardedReady = false
            #if DEBUG
            print("⚠️ [AdManager] Ошибка загрузки Rewarded Video: \(error.localizedDescription)")
            #endif
        }
    }
    
    public func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            #if DEBUG
            print("🎉 [AdManager] Rewarded Video завершено — выдача награды!")
            #endif
            self.onRewardCompletion?()
            self.onRewardCompletion = nil
        }
    }
    
    public func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            self.isRewardedReady = false
            self.preloadRewarded()
        }
    }
}
#endif
