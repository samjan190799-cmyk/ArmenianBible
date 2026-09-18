import SwiftUI
import UIKit
import Combine
import AppTrackingTransparency
import AdSupport

#if canImport(YandexMobileAds)
import YandexMobileAds
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
    case yandex = "Яндекс РСЯ"
    case meta = "Meta Audience Network"
    case houseAd = "Luys House Ad"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .yandex: return "y.circle.fill"
        case .meta: return "m.circle.fill"
        case .houseAd: return "cross.fill"
        }
    }
}

// MARK: - Центральный менеджер рекламы Luys (Yandex Mobile Ads v8.x + Meta Fallback)
/// Построен строго по архитектурным стандартам 2026 года: Swift 6 Strict Concurrency,
/// изоляция `@MainActor`, гео-роутинг и безопасное управление жизненным циклом памяти.
@MainActor
public final class LuysAdManager: NSObject, ObservableObject {
    public static let shared = LuysAdManager()
    
    // MARK: - Включение / Отключение показа рекламы
    @AppStorage("luys_ads_enabled") public var isAdsEnabled: Bool = true
    @AppStorage("luys_ad_test_mode") public var isTestMode: Bool = false
    
    // MARK: - Идентификаторы Yandex Mobile Ads (РСЯ v8.x) для раздельных экранов
    @AppStorage("yandex_rewarded_unit_id") public var yandexRewardedId: String = AdConfig.yandexDefaultRewardedId
    @AppStorage("yandex_banner_home_id") public var yandexBannerHomeId: String = AdConfig.yandexBannerHomeId
    @AppStorage("yandex_banner_reader_id") public var yandexBannerReaderId: String = AdConfig.yandexBannerReaderId
    @AppStorage("yandex_banner_favorites_id") public var yandexBannerFavoritesId: String = AdConfig.yandexBannerFavoritesId
    @AppStorage("yandex_banner_narekatsi_id") public var yandexBannerNarekatsiId: String = AdConfig.yandexBannerNarekatsiId
    @AppStorage("yandex_banner_settings_id") public var yandexBannerSettingsId: String = AdConfig.yandexBannerSettingsId
    
    // MARK: - Аналитика показов, кликов и наград
    @AppStorage("luys_ad_impressions") public var totalImpressions: Int = 0
    @AppStorage("luys_ad_clicks") public var totalClicks: Int = 0
    @AppStorage("luys_rewarded_bonuses_earned") public var totalRewardedBonusesEarned: Int = 0
    
    // MARK: - Состояния рекламы
    @Published public private(set) var isYandexInitialized: Bool = false
    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var isRewardedReady: Bool = false
    @Published public private(set) var isInterstitialReady: Bool = false
    @Published public private(set) var isTrackingAuthorized: Bool = false
    @Published public private(set) var activeProviderType: LuysAdNetworkType = .yandex
    @Published public private(set) var detectedRegionCode: String = "AM"
    
    // MARK: - Внутренние свойства
    private var lastInterstitialTime: Date? = nil
    private var actionCounter: Int = 0
    private var onRewardCompletion: (() -> Void)? = nil
    
    #if canImport(YandexMobileAds)
    private var yandexRewardedLoader: RewardedAdLoader?
    private var yandexRewardedAd: RewardedAd?
    /// КРИТИЧЕСКИЙ SWIFT 6 БАГФИКС: Сохраняем сильную ссылку на показываемое объявление,
    /// иначе ARC очищает объект из памяти до завершения воспроизведения и коллбэка награды.
    private var currentlyShowingRewardedAd: RewardedAd?
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
    /// Для стран СНГ (Армения, Россия, Беларусь, Казахстан и др.) приоритетно используется Яндекс РСЯ.
    public func determineActiveNetworkByGeo() {
        let region = Locale.current.region?.identifier.uppercased() ?? "AM"
        self.detectedRegionCode = region
        
        let cisRegions: Set<String> = ["AM", "RU", "BY", "KZ", "UZ", "KG", "TJ", "AZ", "MD", "GE"]
        if cisRegions.contains(region) {
            self.activeProviderType = .yandex
        } else {
            self.activeProviderType = .meta
        }
    }
    
    /// Получение индивидуального AdUnitID для экрана для избежания No-Fill при параллельных запросах
    public func bannerId(for placement: LuysBannerPlacement) -> String {
        if isTestMode {
            return AdConfig.yandexDemoBannerId
        }
        switch placement {
        case .home:
            return !yandexBannerHomeId.isEmpty ? yandexBannerHomeId : AdConfig.yandexBannerHomeId
        case .reader:
            return !yandexBannerReaderId.isEmpty ? yandexBannerReaderId : AdConfig.yandexBannerReaderId
        case .favorites:
            return !yandexBannerFavoritesId.isEmpty ? yandexBannerFavoritesId : AdConfig.yandexBannerFavoritesId
        case .narekatsi:
            return !yandexBannerNarekatsiId.isEmpty ? yandexBannerNarekatsiId : AdConfig.yandexBannerNarekatsiId
        case .settings:
            return !yandexBannerSettingsId.isEmpty ? yandexBannerSettingsId : AdConfig.yandexBannerSettingsId
        }
    }
    
    // MARK: - Инициализация рекламных SDK
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        determineActiveNetworkByGeo()
        
        #if canImport(YandexMobileAds)
        Task.detached(priority: .utility) {
            await YandexAds.initializeSDK()
            await MainActor.run {
                LuysAdManager.shared.isYandexInitialized = true
                LuysAdManager.shared.preloadYandexRewarded()
            }
        }
        #endif
        
        #if canImport(FBAudienceNetwork)
        // Meta Audience Network инициализируется ТОЛЬКО вне стран СНГ
        if self.activeProviderType == .meta {
            Task.detached(priority: .background) {
                FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
                FBAudienceNetworkAds.initialize(with: nil) { [weak self] _ in
                    Task { @MainActor in
                        self?.preloadInterstitial()
                    }
                }
            }
        }
        #endif
        
        #if !targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
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
    
    // MARK: - Предзагрузка объявлений
    public func preloadAds() {
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        
        #if canImport(YandexMobileAds)
        preloadYandexRewarded()
        #endif
        
        #if canImport(FBAudienceNetwork)
        preloadInterstitial()
        preloadMetaRewarded()
        #endif
    }
    
    public func preloadYandexRewarded() {
        #if canImport(YandexMobileAds)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        
        let unitId = isTestMode ? AdConfig.yandexDemoRewardedId : yandexRewardedId
        guard !unitId.isEmpty else { return }
        
        let loader = RewardedAdLoader()
        self.yandexRewardedLoader = loader
        
        // Согласно правилам Apple: передаем только чистый AdRequest без персональных данных
        let request = AdRequest(adUnitID: unitId)
        Task {
            do {
                let ad = try await loader.loadAd(with: request)
                self.yandexRewardedAd = ad
                ad.delegate = self
                self.isRewardedReady = true
            } catch {
                self.isRewardedReady = false
            }
        }
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
        
        #if canImport(FBAudienceNetwork)
        if let interstitial = currentInterstitial, interstitial.isAdValid {
            return true
        }
        #endif
        return false
    }
    
    public func recordActionAndShowInterstitialIfReady(from viewController: UIViewController? = nil) {
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        
        actionCounter += 1
        if actionCounter >= AdConfig.interstitialActionInterval {
            showInterstitialIfReady(from: viewController)
        }
    }
    
    @discardableResult
    public func showInterstitialIfReady(from viewController: UIViewController? = nil) -> Bool {
        guard canShowInterstitial() else { return false }
        
        #if canImport(FBAudienceNetwork)
        guard let interstitial = currentInterstitial, interstitial.isAdValid else { return false }
        let presenter = viewController ?? getTopViewController()
        guard let targetVC = presenter else { return false }
        
        interstitial.show(fromRootViewController: targetVC)
        lastInterstitialTime = Date()
        actionCounter = 0
        isInterstitialReady = false
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Реклама с вознаграждением (Rewarded Video)
    public func showRewardedAd(from viewController: UIViewController? = nil, onReward: @escaping () -> Void) {
        // Если у пользователя Premium — сразу начисляем бонус без рекламы
        if SubscriptionManager.shared.isPremium || !isAdsEnabled {
            onReward()
            return
        }
        
        let rootVC = viewController ?? getTopViewController()
        
        // 1. Приоритетный показ Yandex Mobile Ads
        #if canImport(YandexMobileAds)
        if let yandexAd = self.yandexRewardedAd, let presenter = rootVC {
            self.onRewardCompletion = onReward
            yandexAd.delegate = self
            // Фиксируем сильную ссылку для защиты от ARC
            self.currentlyShowingRewardedAd = yandexAd
            self.yandexRewardedAd = nil
            self.isRewardedReady = false
            yandexAd.show(from: presenter)
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
        preloadYandexRewarded()
    }
    
    // MARK: - Начисление награды
    public func completeRewardedAdAndGrantReward() {
        SubscriptionManager.shared.grantBonusAiQuestionFromAd()
        totalRewardedBonusesEarned += 1
        
        let callback = onRewardCompletion
        onRewardCompletion = nil
        callback?()
        
        preloadYandexRewarded()
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

// MARK: - Делегаты Yandex Mobile Ads (Rewarded Video)
#if canImport(YandexMobileAds)
extension LuysAdManager: RewardedAdDelegate {
    nonisolated public func rewardedAd(_ rewardedAd: RewardedAd, didReward reward: Reward) {
        Task { @MainActor in
            LuysAdManager.shared.completeRewardedAdAndGrantReward()
        }
    }
    
    nonisolated public func rewardedAdDidShow(_ rewardedAd: RewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }
    
    nonisolated public func rewardedAd(_ rewardedAd: RewardedAd, didTrackImpression impressionData: (any ImpressionData)?) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }
    
    nonisolated public func rewardedAdDidClick(_ rewardedAd: RewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.logClick()
        }
    }
    
    nonisolated public func rewardedAdDidDismiss(_ rewardedAd: RewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.currentlyShowingRewardedAd = nil
            LuysAdManager.shared.preloadYandexRewarded()
        }
    }
    
    nonisolated public func rewardedAd(_ rewardedAd: RewardedAd, didFailToShow error: any Error) {
        Task { @MainActor in
            LuysAdManager.shared.currentlyShowingRewardedAd = nil
            // При ошибке показа выполняем фолбек начисления, чтобы не ломать UX
            LuysAdManager.shared.completeRewardedAdAndGrantReward()
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
