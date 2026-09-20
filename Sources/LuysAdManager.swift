import SwiftUI
import UIKit
import Combine
import AppTrackingTransparency
import AdSupport

#if canImport(MyTargetSDK)
import MyTargetSDK
#endif

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif

// MARK: - Плейсменты баннерных блоков Luys
public enum LuysBannerPlacement: String, CaseIterable, Identifiable, Sendable {
    case home = "home"
    case reader = "reader"
    case favorites = "favorites"
    case narekatsi = "narekatsi"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .home: return "Главная"
        case .reader: return "Библия"
        case .favorites: return "Избранное"
        case .narekatsi: return "Нарекаци"
        case .settings: return "Настройки"
        }
    }
}

// MARK: - Доступные рекламные провайдеры
public enum LuysAdNetworkType: String, CaseIterable, Identifiable, Sendable {
    case vk = "VK Реклама"
    case meta = "Meta Audience Network"
    case houseAd = "Luys House Ad"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .vk: return "v.circle.fill"
        case .meta: return "m.circle.fill"
        case .houseAd: return "cross.fill"
        }
    }
}

// MARK: - Центральный менеджер рекламы Luys (VK Ads / MyTargetSDK + Meta Fallback)
/// Построен строго по архитектурным стандартам 2026 года: Swift 6 Strict Concurrency,
/// изоляция `@MainActor`, гео-роутинг и безопасное управление жизненным циклом памяти.
@MainActor
public final class LuysAdManager: NSObject, ObservableObject {
    public static let shared = LuysAdManager()
    
    // MARK: - Включение / Отключение показа рекламы
    @AppStorage("luys_ads_enabled") public var isAdsEnabled: Bool = true
    @AppStorage("luys_ad_test_mode") public var isTestMode: Bool = false
    
    // MARK: - Идентификаторы VK Рекламы / myTarget Slot ID для раздельных экранов
    @AppStorage("vk_rewarded_slot_id") public var vkRewardedSlotId: Int = Int(AdConfig.vkDefaultRewardedSlotId)
    @AppStorage("vk_banner_home_slot_id") public var vkBannerHomeSlotId: Int = Int(AdConfig.vkBannerHomeSlotId)
    @AppStorage("vk_banner_reader_slot_id") public var vkBannerReaderSlotId: Int = Int(AdConfig.vkBannerReaderSlotId)
    @AppStorage("vk_banner_favorites_slot_id") public var vkBannerFavoritesSlotId: Int = Int(AdConfig.vkBannerFavoritesSlotId)
    @AppStorage("vk_banner_narekatsi_slot_id") public var vkBannerNarekatsiSlotId: Int = Int(AdConfig.vkBannerNarekatsiSlotId)
    @AppStorage("vk_banner_settings_slot_id") public var vkBannerSettingsSlotId: Int = Int(AdConfig.vkBannerSettingsSlotId)
    
    // MARK: - Аналитика показов, кликов и наград
    @AppStorage("luys_ad_impressions") public var totalImpressions: Int = 0
    @AppStorage("luys_ad_clicks") public var totalClicks: Int = 0
    @AppStorage("luys_rewarded_bonuses_earned") public var totalRewardedBonusesEarned: Int = 0
    
    // MARK: - Состояния рекламы
    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var isRewardedReady: Bool = false
    @Published public private(set) var isInterstitialReady: Bool = false
    @Published public private(set) var isTrackingAuthorized: Bool = false
    @Published public private(set) var activeProviderType: LuysAdNetworkType = .vk
    @Published public private(set) var detectedRegionCode: String = "AM"
    
    // MARK: - Внутренние свойства
    private var lastInterstitialTime: Date? = nil
    private var actionCounter: Int = 0
    private var onRewardCompletion: (() -> Void)? = nil
    
    #if canImport(MyTargetSDK)
    private var vkRewardedAd: MTRGRewardedAd?
    /// КРИТИЧЕСКИЙ SWIFT 6 БАГФИКС: Сохраняем сильную ссылку на показываемое объявление,
    /// иначе ARC очищает объект из памяти до завершения воспроизведения и коллбэка награды.
    private var currentlyShowingRewardedAd: MTRGRewardedAd?
    #endif
    
    #if canImport(FBAudienceNetwork)
    private var currentInterstitial: FBInterstitialAd?
    private var currentRewarded: FBRewardedVideoAd?
    #endif
    
    private override init() {
        super.init()
        determineActiveNetworkByGeo()
    }
    
    // MARK: - Гео-маршрутизация (Geo-Routing)
    /// Для стран СНГ (Армения, Россия, Беларусь, Казахстан и др.) приоритетно используется VK Реклама.
    public func determineActiveNetworkByGeo() {
        let region = Locale.current.region?.identifier.uppercased() ?? "AM"
        self.detectedRegionCode = region
        
        #if canImport(FBAudienceNetwork)
        let cisRegions: Set<String> = ["AM", "RU", "BY", "KZ", "UZ", "KG", "TJ", "AZ", "MD", "GE"]
        if cisRegions.contains(region) {
            self.activeProviderType = .vk
        } else {
            self.activeProviderType = .meta
        }
        #else
        // В проекте подключен прямой SDK VK Рекламы (myTarget)
        self.activeProviderType = .vk
        #endif
    }
    
    /// Получение индивидуального Slot ID для экрана для избежания No-Fill при параллельных запросах
    public func bannerSlotId(for placement: LuysBannerPlacement) -> UInt {
        if isTestMode {
            return AdConfig.vkDemoBannerSlotId
        }
        switch placement {
        case .home:
            return vkBannerHomeSlotId > 0 ? UInt(vkBannerHomeSlotId) : AdConfig.vkBannerHomeSlotId
        case .reader:
            return vkBannerReaderSlotId > 0 ? UInt(vkBannerReaderSlotId) : AdConfig.vkBannerReaderSlotId
        case .favorites:
            return vkBannerFavoritesSlotId > 0 ? UInt(vkBannerFavoritesSlotId) : AdConfig.vkBannerFavoritesSlotId
        case .narekatsi:
            return vkBannerNarekatsiSlotId > 0 ? UInt(vkBannerNarekatsiSlotId) : AdConfig.vkBannerNarekatsiSlotId
        case .settings:
            return vkBannerSettingsSlotId > 0 ? UInt(vkBannerSettingsSlotId) : AdConfig.vkBannerSettingsSlotId
        }
    }
    
    // MARK: - Инициализация рекламных SDK
    @MainActor
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        determineActiveNetworkByGeo()
        
        #if canImport(MyTargetSDK)
        preloadVkRewarded()
        startPeriodicAdCheck()
        #endif
        
        #if !targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.requestTrackingPermission()
        }
        #endif
    }
    
    // MARK: - Запрос разрешения Apple ATT (iOS 14.5+)
    public func requestTrackingPermission() {
        #if !targetEnvironment(simulator)
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                Task { @MainActor in
                    let authorized = (status == .authorized)
                    self?.isTrackingAuthorized = authorized
                    
                    #if canImport(FBAudienceNetwork)
                    FBAdSettings.setAdvertiserTrackingEnabled(authorized)
                    #endif
                }
            }
        }
        #endif
    }
    
    // MARK: - Периодический цикл автообновления и проверки рекламы (каждые 45 секунд)
    private var adRefreshTimer: Timer?
    
    public func startPeriodicAdCheck() {
        guard adRefreshTimer == nil else { return }
        let interval = AdConfig.bannerAutoRefreshInterval > 0 ? AdConfig.bannerAutoRefreshInterval : 45.0
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                guard !SubscriptionManager.shared.isPremium, self.isAdsEnabled else { return }
                
                #if canImport(MyTargetSDK)
                if !self.isRewardedReady {
                    #if DEBUG
                    print("🔄 [LuysAds] Периодический цикл (каждые \(interval)с): Запрос новой VK RewardedAd")
                    #endif
                    self.preloadVkRewarded()
                }
                #endif
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.adRefreshTimer = timer
    }
    
    public func stopPeriodicAdCheck() {
        adRefreshTimer?.invalidate()
        adRefreshTimer = nil
    }
    
    // MARK: - Предзагрузка объявлений
    public func preloadAds() {
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        
        #if canImport(MyTargetSDK)
        preloadVkRewarded()
        startPeriodicAdCheck()
        #endif
        
        #if canImport(FBAudienceNetwork)
        preloadInterstitial()
        preloadMetaRewarded()
        #endif
    }
    
    public func preloadVkRewarded() {
        #if canImport(MyTargetSDK)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        guard !isRewardedReady else { return }
        
        let slotId = isTestMode ? AdConfig.vkDemoRewardedSlotId : UInt(max(0, vkRewardedSlotId))
        guard slotId > 0 else { return }
        
        let rewarded = MTRGRewardedAd(slotId: slotId)
        rewarded.delegate = self
        self.vkRewardedAd = rewarded
        rewarded.load()
        #endif
    }
    
    public func preloadInterstitial() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        let placementID = AdConfig.interstitialPlacementID
        let interstitial = FBInterstitialAd(placementID: placementID)
        interstitial.delegate = self
        self.currentInterstitial = interstitial
        interstitial.load()
        #endif
    }
    
    public func preloadMetaRewarded() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        let placementID = AdConfig.rewardedPlacementID
        let rewarded = FBRewardedVideoAd(placementID: placementID)
        rewarded.delegate = self
        self.currentRewarded = rewarded
        rewarded.load()
        #endif
    }
    
    // MARK: - Межстраничная реклама (Interstitial)
    public func canShowInterstitial() -> Bool {
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return false }
        
        if let last = lastInterstitialTime {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < AdConfig.interstitialCooldownSeconds {
                return false
            }
        }
        
        actionCounter += 1
        return actionCounter >= AdConfig.interstitialActionInterval
    }
    
    public func showInterstitialIfAllowed(from viewController: UIViewController? = nil) -> Bool {
        guard canShowInterstitial() else { return false }
        
        let rootVC = viewController ?? getTopViewController()
        guard let presenter = rootVC else { return false }
        
        #if canImport(FBAudienceNetwork)
        if let interstitial = currentInterstitial, interstitial.isAdValid {
            interstitial.show(fromRootViewController: presenter)
            lastInterstitialTime = Date()
            actionCounter = 0
            isInterstitialReady = false
            return true
        }
        #endif
        
        return false
    }
    
    // MARK: - Реклама с вознаграждением (Rewarded Video)
    public func showRewardedAd(from viewController: UIViewController? = nil, onReward: @escaping () -> Void) {
        // Если у пользователя Premium — сразу начисляем бонус без рекламы
        if SubscriptionManager.shared.isPremium || !isAdsEnabled {
            onReward()
            return
        }
        
        let rootVC = viewController ?? getTopViewController()
        
        // 1. Приоритетный показ VK Рекламы (myTarget)
        #if canImport(MyTargetSDK)
        if let vkAd = self.vkRewardedAd, let presenter = rootVC {
            self.onRewardCompletion = onReward
            // Фиксируем сильную ссылку для защиты от ARC
            self.currentlyShowingRewardedAd = vkAd
            self.vkRewardedAd = nil
            self.isRewardedReady = false
            vkAd.show(with: presenter)
            return
        }
        #endif
        
        // 2. Резервный показ Meta Audience Network
        #if canImport(FBAudienceNetwork)
        if let metaRewarded = self.currentRewarded, metaRewarded.isAdValid, let presenter = rootVC {
            self.onRewardCompletion = onReward
            metaRewarded.show(fromRootViewController: presenter)
            self.isRewardedReady = false
            return
        }
        #endif
        
        // 3. Graceful UX Fallback: если ни одна сеть не готова — даем награду пользователю
        onReward()
        preloadVkRewarded()
    }
    
    // MARK: - Начисление награды
    public func completeRewardedAdAndGrantReward() {
        SubscriptionManager.shared.grantBonusAiQuestionFromAd()
        totalRewardedBonusesEarned += 1
        
        let callback = onRewardCompletion
        onRewardCompletion = nil
        callback?()
        
        preloadVkRewarded()
    }
    
    // MARK: - Аналитика
    public func logImpression() {
        totalImpressions += 1
    }
    
    public func logClick() {
        totalClicks += 1
    }
    
    // MARK: - Поиск верхнего UIViewController
    public func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
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

// MARK: - Делегаты VK Рекламы / myTarget (Rewarded Video)
#if canImport(MyTargetSDK)
extension LuysAdManager: MTRGRewardedAdDelegate {
    nonisolated public func onLoad(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.isRewardedReady = true
        }
    }
    
    nonisolated public func onLoadFailed(error: any Error, rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.isRewardedReady = false
        }
    }
    
    nonisolated public func onReward(_ reward: MTRGReward, rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.completeRewardedAdAndGrantReward()
        }
    }
    
    nonisolated public func onDisplay(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }
    
    nonisolated public func onClick(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.logClick()
        }
    }
    
    nonisolated public func onClose(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.currentlyShowingRewardedAd = nil
            LuysAdManager.shared.preloadVkRewarded()
        }
    }
}
#endif

// MARK: - Делегаты Meta Audience Network
#if canImport(FBAudienceNetwork)
extension LuysAdManager: FBInterstitialAdDelegate {
    nonisolated public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.isInterstitialReady = true
        }
    }
    
    nonisolated public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        Task { @MainActor in
            LuysAdManager.shared.isInterstitialReady = false
        }
    }
    
    nonisolated public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.isInterstitialReady = false
            LuysAdManager.shared.preloadInterstitial()
        }
    }
}

extension LuysAdManager: FBRewardedVideoAdDelegate {
    nonisolated public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            LuysAdManager.shared.isRewardedReady = true
        }
    }
    
    nonisolated public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        Task { @MainActor in
            LuysAdManager.shared.isRewardedReady = false
        }
    }
    
    nonisolated public func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            LuysAdManager.shared.completeRewardedAdAndGrantReward()
        }
    }
    
    nonisolated public func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            LuysAdManager.shared.isRewardedReady = false
            LuysAdManager.shared.preloadMetaRewarded()
        }
    }
}
#endif

// MARK: - Алиас для обратной совместимости вызовов
public typealias AdManager = LuysAdManager
