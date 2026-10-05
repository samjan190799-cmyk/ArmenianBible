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

// MARK: - Центральный менеджер рекламы Luys (Meta Audience Network + VK Ads)
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
    @Published public private(set) var activeProviderType: LuysAdNetworkType = .meta
    @Published public private(set) var detectedRegionCode: String = "AM"
    /// Последнее событие по каждому формату (banner / interstitial / rewarded / sdk) для панели тестировщика
    @Published public private(set) var adDiagnostics: [String: String] = [:]
    
    // MARK: - Внутренние свойства
    private var lastInterstitialTime: Date? = nil
    private var actionCounter: Int = 0
    private var onRewardCompletion: (() -> Void)? = nil
    private var onDismissWithoutReward: (() -> Void)? = nil
    
    
    #if canImport(FBAudienceNetwork)
    private var metaRewardedAd: FBRewardedInterstitialAd?
    private var metaInterstitialAd: FBInterstitialAd?
    private var currentlyShowingMetaRewarded: FBRewardedInterstitialAd?
    private var currentlyShowingMetaInterstitial: FBInterstitialAd?
    private var isMetaRewardedLoading: Bool = false
    private var isMetaInterstitialLoading: Bool = false
    #endif

    #if canImport(MyTargetSDK)
    private var vkRewardedAd: MTRGRewardedAd?
    /// КРИТИЧЕСКИЙ SWIFT 6 БАГФИКС: Сохраняем сильную ссылку на показываемое объявление,
    /// иначе ARC очищает объект из памяти до завершения воспроизведения и коллбэка награды.
    private var currentlyShowingRewardedAd: MTRGRewardedAd?
    #endif
    
    private override init() {
        super.init()
        determineActiveNetworkByGeo()
    }
    
    // MARK: - Диагностика рекламы (панель тестировщика)
    public func recordAdEvent(_ key: String, _ text: String) {
        adDiagnostics[key] = text
    }

    public static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "ошибка \(nsError.code): \(nsError.localizedDescription)"
    }

    public var diagnosticsSummary: String {
        var lines = [
            "Провайдер: \(activeProviderType.rawValue), регион \(detectedRegionCode)",
            "Реклама включена: \(isAdsEnabled ? "да" : "нет"), ATT: \(isTrackingAuthorized ? "разрешён" : "нет")"
        ]
        for key in ["sdk", "banner", "interstitial", "rewarded"] {
            lines.append("\(key): \(adDiagnostics[key] ?? "событий нет")")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Гео-маршрутизация (Geo-Routing)
    /// В РФ и Беларуси используется VK Реклама (myTarget).
    /// В Армении и по всему миру используется Meta Audience Network.
    public func determineActiveNetworkByGeo() {
        let region = Locale.current.region?.identifier.uppercased() ?? "AM"
        self.detectedRegionCode = region

        let vkOnlyRegions: Set<String> = ["RU", "BY"]
        if vkOnlyRegions.contains(region) {
            self.activeProviderType = .vk
        } else {
            self.activeProviderType = .meta
        }
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
        

        #if canImport(FBAudienceNetwork)
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: { result in
            let summary = "\(result.isSuccess ? "инициализирован" : "не инициализирован"): \(result.message)"
            Task { @MainActor in
                LuysAdManager.shared.recordAdEvent("sdk", summary)
            }
            #if DEBUG
            print("✅ [Meta] Audience Network инициализирован: \(result.isSuccess) \(result.message)")
            #endif
        })
        #endif

        #if canImport(MyTargetSDK)
        MTRGManager.setDebugMode(isTestMode)
        #endif
        
        preloadAds()
        startPeriodicAdCheck()
        
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
            guard UIApplication.shared.applicationState == .active else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.requestTrackingPermission()
                }
                return
            }
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
                
                
                #if canImport(FBAudienceNetwork)
                if self.activeProviderType == .meta {
                    if !self.isRewardedReady { self.preloadMetaRewarded() }
                    if !self.isInterstitialReady { self.preloadMetaInterstitial() }
                }
                #endif

                #if canImport(MyTargetSDK)
                if self.activeProviderType == .vk && !self.isRewardedReady {
                    #if DEBUG
                    print("🔄 [LuysAds] Периодический цикл: Запрос новой VK RewardedAd")
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
        

        #if canImport(FBAudienceNetwork)
        preloadMetaRewarded()
        preloadMetaInterstitial()
        #endif

        #if canImport(MyTargetSDK)
        preloadVkRewarded()
        #endif
    }

    // MARK: - Предзагрузка Meta Audience Network
    public func preloadMetaRewarded() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        guard activeProviderType == .meta else { return }
        guard metaRewardedAd == nil, !isMetaRewardedLoading else { return }
        isMetaRewardedLoading = true

        let ad = FBRewardedInterstitialAd(placementID: AdConfig.metaRewardedInterstitialPlacementID)
        ad.delegate = self
        metaRewardedAd = ad
        ad.load()
        #endif
    }

    public func preloadMetaInterstitial() {
        #if canImport(FBAudienceNetwork)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        guard activeProviderType == .meta else { return }
        guard metaInterstitialAd == nil, !isMetaInterstitialLoading else { return }
        isMetaInterstitialLoading = true

        let ad = FBInterstitialAd(placementID: AdConfig.metaInterstitialPlacementID)
        ad.delegate = self
        metaInterstitialAd = ad
        ad.load()
        #endif
    }
    
    // MARK: - Предзагрузка VK Рекламы
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
        if activeProviderType == .meta, let ad = metaInterstitialAd, ad.isAdValid {
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
        let rootVC = viewController ?? getTopViewController()
        guard let presenter = rootVC else { return false }
        

        #if canImport(FBAudienceNetwork)
        if activeProviderType == .meta, let interstitial = self.metaInterstitialAd, interstitial.isAdValid {
            self.currentlyShowingMetaInterstitial = interstitial
            self.metaInterstitialAd = nil
            self.isInterstitialReady = false
            self.lastInterstitialTime = Date()
            self.actionCounter = 0
            #if DEBUG
            print("🎬 [Meta Interstitial] Показ полноэкранного объявления Meta...")
            #endif
            interstitial.show(fromRootViewController: presenter)
            return true
        }
        #endif

        return false
    }
    
    @discardableResult
    public func showInterstitialIfAllowed(from viewController: UIViewController? = nil) -> Bool {
        return showInterstitialIfReady(from: viewController)
    }
    
    // MARK: - Реклама с вознаграждением (Rewarded Video)
    @discardableResult
    public func showRewardedAd(
        from viewController: UIViewController? = nil,
        onReward: @escaping () -> Void,
        onDismissWithoutReward: (() -> Void)? = nil
    ) -> Bool {
        // Если у пользователя Premium — сразу начисляем бонус без рекламы
        if SubscriptionManager.shared.isPremium || !isAdsEnabled {
            onReward()
            return true
        }
        
        let rootVC = viewController ?? getTopViewController()
        self.onDismissWithoutReward = onDismissWithoutReward
        
        
        #if canImport(FBAudienceNetwork)
        if activeProviderType == .meta, let metaAd = self.metaRewardedAd, metaAd.isAdValid, let presenter = rootVC {
            self.onRewardCompletion = onReward
            self.currentlyShowingMetaRewarded = metaAd
            self.metaRewardedAd = nil
            self.isRewardedReady = false
            #if DEBUG
            print("🎬 [Meta Rewarded] Запуск показа видео Meta...")
            #endif
            metaAd.show(fromRootViewController: presenter, animated: true)
            return true
        }
        #endif

        #if canImport(MyTargetSDK)
        if isRewardedReady, let vkAd = self.vkRewardedAd, let presenter = rootVC {
            self.onRewardCompletion = onReward
            self.currentlyShowingRewardedAd = vkAd
            self.vkRewardedAd = nil
            self.isRewardedReady = false
            #if DEBUG
            print("🎬 [VK Rewarded] Запуск показа полноэкранного видео...")
            #endif
            vkAd.show(with: presenter)
            return true
        }
        #endif
        
        preloadAds()
        return false
    }
    
    // MARK: - Начисление награды
    public func completeRewardedAdAndGrantReward() {
        SubscriptionManager.shared.grantBonusAiQuestionFromAd()
        totalRewardedBonusesEarned += 1
        
        let callback = onRewardCompletion
        onRewardCompletion = nil
        onDismissWithoutReward = nil
        callback?()
        
        preloadAds()
    }
    
    // MARK: - Аналитика
    public func logImpression() {
        totalImpressions += 1
    }
    
    public func logClick() {
        totalClicks += 1
    }
    
    // MARK: - Поиск верхнего UIViewController
    @MainActor
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

// MARK: - Делегаты Meta Audience Network (Interstitial + Rewarded Interstitial)
#if canImport(FBAudienceNetwork)
extension LuysAdManager: FBInterstitialAdDelegate {
    nonisolated public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            let manager = LuysAdManager.shared
            manager.isMetaInterstitialLoading = false
            manager.recordAdEvent("interstitial", "загружена")
            if manager.activeProviderType == .meta {
                manager.isInterstitialReady = true
            }
            #if DEBUG
            print("✅ [Meta Interstitial] Межстраничная реклама готова к показу!")
            #endif
        }
    }

    nonisolated public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        let description = LuysAdManager.describe(error)
        Task { @MainActor in
            let manager = LuysAdManager.shared
            manager.recordAdEvent("interstitial", description)
            manager.isMetaInterstitialLoading = false
            manager.metaInterstitialAd = nil
            manager.isInterstitialReady = false
            #if DEBUG
            print("⚠️ [Meta Interstitial] Ошибка: \(error.localizedDescription)")
            #endif
        }
    }

    nonisolated public func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }

    nonisolated public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.logClick()
        }
    }

    nonisolated public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.currentlyShowingMetaInterstitial = nil
            LuysAdManager.shared.preloadAds()
        }
    }
}

extension LuysAdManager: FBRewardedInterstitialAdDelegate {
    nonisolated public func rewardedInterstitialAdDidLoad(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        Task { @MainActor in
            let manager = LuysAdManager.shared
            manager.isMetaRewardedLoading = false
            manager.recordAdEvent("rewarded", "загружена")
            if manager.activeProviderType == .meta {
                manager.isRewardedReady = true
            }
            #if DEBUG
            print("✅ [Meta Rewarded] Видео успешно загружено и готово к показу!")
            #endif
        }
    }

    nonisolated public func rewardedInterstitialAd(_ rewardedInterstitialAd: FBRewardedInterstitialAd, didFailWithError error: Error) {
        let description = LuysAdManager.describe(error)
        Task { @MainActor in
            let manager = LuysAdManager.shared
            manager.recordAdEvent("rewarded", description)
            manager.isMetaRewardedLoading = false
            manager.metaRewardedAd = nil
            manager.isRewardedReady = false
            #if DEBUG
            print("⚠️ [Meta Rewarded] Ошибка: \(error.localizedDescription)")
            #endif
        }
    }

    nonisolated public func rewardedInterstitialAdWillLogImpression(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }

    nonisolated public func rewardedInterstitialAdDidClick(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.logClick()
        }
    }

    nonisolated public func rewardedInterstitialAdVideoComplete(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        Task { @MainActor in
            LuysAdManager.shared.completeRewardedAdAndGrantReward()
        }
    }

    nonisolated public func rewardedInterstitialAdDidClose(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        Task { @MainActor in
            let manager = LuysAdManager.shared
            manager.currentlyShowingMetaRewarded = nil
            if manager.onRewardCompletion != nil {
                manager.onDismissWithoutReward?()
                manager.onRewardCompletion = nil
                manager.onDismissWithoutReward = nil
            }
            manager.preloadAds()
        }
    }
}
#endif


// MARK: - Делегаты VK Рекламы / myTarget (Rewarded Video)
#if canImport(MyTargetSDK)
extension LuysAdManager: MTRGRewardedAdDelegate {
    nonisolated public func onLoad(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            #if DEBUG
            print("✅ [VK Rewarded] Видео успешно загружено и готово к показу!")
            #endif
            if LuysAdManager.shared.activeProviderType == .vk {
                LuysAdManager.shared.isRewardedReady = true
            }
        }
    }
    
    nonisolated public func onLoadFailed(error: any Error, rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            #if DEBUG
            print("⚠️ [VK Rewarded] Ошибка загрузки видео: \(error.localizedDescription)")
            #endif
            if LuysAdManager.shared.activeProviderType == .vk {
                LuysAdManager.shared.isRewardedReady = false
            }
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
            if LuysAdManager.shared.onRewardCompletion != nil {
                LuysAdManager.shared.onDismissWithoutReward?()
                LuysAdManager.shared.onRewardCompletion = nil
                LuysAdManager.shared.onDismissWithoutReward = nil
            }
            LuysAdManager.shared.preloadVkRewarded()
        }
    }
}
#endif

// MARK: - Алиас для обратной совместимости вызовов
public typealias AdManager = LuysAdManager
