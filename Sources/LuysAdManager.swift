import SwiftUI
import UIKit
import Combine
import AppTrackingTransparency
import AdSupport

#if canImport(MyTargetSDK)
import MyTargetSDK
#endif

#if canImport(GoogleMobileAds)
import GoogleMobileAds
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
    case admob = "Google AdMob"
    case houseAd = "Luys House Ad"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .vk: return "v.circle.fill"
        case .admob: return "g.circle.fill"
        case .houseAd: return "cross.fill"
        }
    }
}

// MARK: - Центральный менеджер рекламы Luys (Google AdMob + VK Ads)
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
    /// Google Mobile Ads SDK запущен (после согласия и ответа на ATT): только теперь можно запрашивать рекламу Google
    @Published public private(set) var isSdkReady: Bool = false
    @Published public private(set) var activeProviderType: LuysAdNetworkType = .admob
    @Published public private(set) var detectedRegionCode: String = "AM"
    
    // MARK: - Внутренние свойства
    private var lastInterstitialTime: Date? = nil
    private var actionCounter: Int = 0
    private var onRewardCompletion: (() -> Void)? = nil
    private var onDismissWithoutReward: (() -> Void)? = nil
    
    // MARK: - Диагностика (в боевой сборке раньше ничего не логировалось)
    private var lastAdErrors: [String: String] = [:]
    private var adapterStatusSummary: String = "SDK ещё не запущен"
    private var isSdkStarting: Bool = false
    
    /// Тестовый режим VK действует только в TestFlight и DEBUG: в App Store он невозможен
    private var effectiveTestMode: Bool {
        isTestMode && Bundle.isTestFlightOrDebug
    }
    
    #if canImport(GoogleMobileAds)
    private var admobRewardedAd: RewardedAd?
    private var admobInterstitialAd: InterstitialAd?
    private var currentlyShowingAdMobRewarded: RewardedAd?
    private var currentlyShowingAdMobInterstitial: InterstitialAd?
    private var isAdMobRewardedLoading: Bool = false
    private var isAdMobInterstitialLoading: Bool = false
    #endif
    
    #if canImport(MyTargetSDK)
    private var isVkRewardedLoading: Bool = false
    private var vkRewardedAd: MTRGRewardedAd?
    /// КРИТИЧЕСКИЙ SWIFT 6 БАГФИКС: Сохраняем сильную ссылку на показываемое объявление,
    /// иначе ARC очищает объект из памяти до завершения воспроизведения и коллбэка награды.
    private var currentlyShowingRewardedAd: MTRGRewardedAd?
    #endif
    
    private override init() {
        super.init()
        determineActiveNetworkByGeo()
    }
    
    // MARK: - Гео-маршрутизация (Geo-Routing)
    /// В РФ и Беларуси используется VK Реклама (myTarget).
    /// В Армении и по всему миру используется Google AdMob.
    public func determineActiveNetworkByGeo() {
        let region = Locale.current.region?.identifier.uppercased() ?? "AM"
        self.detectedRegionCode = region
        
        let vkOnlyRegions: Set<String> = ["RU", "BY"]
        if vkOnlyRegions.contains(region) {
            self.activeProviderType = .vk
        } else {
            self.activeProviderType = .admob
        }
    }
    
    /// Получение индивидуального Slot ID для экрана для избежания No-Fill при параллельных запросах
    public func bannerSlotId(for placement: LuysBannerPlacement) -> UInt {
        if effectiveTestMode {
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
    /// Порядок запуска: согласие (ЕС/Великобритания/Швейцария) → запрос ATT → запуск Google Mobile Ads SDK →
    /// загрузка объявлений. Раньше SDK стартовал сразу, а ATT спрашивался через 3 секунды: первые запросы
    /// уходили без IDFA и до готовности адаптеров, что снижает ставки.
    @MainActor
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        determineActiveNetworkByGeo()
        
        #if canImport(MyTargetSDK)
        MTRGManager.setDebugMode(effectiveTestMode)
        #endif
        
        startPeriodicAdCheck()
        
        AdConsentManager.shared.gatherConsent { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.recordAdError("Согласие", error)
            }
            self.requestTrackingPermission { [weak self] in
                self?.startAdSdksIfAllowed()
            }
        }
    }
    
    /// Запускает Google Mobile Ads SDK, когда это разрешено, и затем предзагружает рекламу.
    /// Безопасно вызывать повторно: срабатывает один раз.
    private func startAdSdksIfAllowed() {
        // VK (РФ и Беларусь) не зависит от согласия Google
        preloadAds()
        
        #if canImport(GoogleMobileAds)
        guard !isSdkReady, !isSdkStarting else { return }
        guard AdConsentManager.shared.canRequestAds else {
            adapterStatusSummary = "SDK не запущен: согласие не получено"
            return
        }
        isSdkStarting = true
        
        #if canImport(FBAudienceNetwork)
        // Meta Audience Network (ставки через AdMob): на iOS 16 флаг нужно выставить до запуска SDK
        FBAdSettings.setAdvertiserTrackingEnabled(isTrackingAuthorized)
        #endif
        
        MobileAds.shared.start { [weak self] status in
            let summary = status.adapterStatusesByClassName
                .map { name, adapter in
                    let shortName = name.split(separator: ".").last.map(String.init) ?? name
                    return "\(shortName): \(adapter.state == .ready ? "готов" : "не готов")"
                }
                .sorted()
                .joined(separator: ", ")
            Task { @MainActor in
                guard let self = self else { return }
                self.isSdkStarting = false
                self.isSdkReady = true
                self.adapterStatusSummary = summary.isEmpty ? "адаптеров нет" : summary
                self.preloadAds()
            }
        }
        #endif
    }
    
    // MARK: - Запрос разрешения Apple ATT (iOS 14.5+)
    /// Спрашивает разрешение и вызывает completion после ответа (или сразу, если вопрос уже решён).
    public func requestTrackingPermission(completion: (() -> Void)? = nil) {
        #if !targetEnvironment(simulator)
        if #available(iOS 14.5, *) {
            guard UIApplication.shared.applicationState == .active else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.requestTrackingPermission(completion: completion)
                }
                return
            }
            let current = ATTrackingManager.trackingAuthorizationStatus
            if current != .notDetermined {
                isTrackingAuthorized = (current == .authorized)
                completion?()
                return
            }
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.isTrackingAuthorized = (status == .authorized)
                    completion?()
                }
            }
            return
        }
        #endif
        completion?()
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
                
                #if canImport(GoogleMobileAds)
                if self.activeProviderType == .admob {
                    // Повторные попытки: первая неудача (например, no-fill на новом блоке) больше не навсегда
                    if !self.isSdkReady { self.startAdSdksIfAllowed() }
                    if !self.isRewardedReady { self.preloadAdMobRewarded() }
                    if !self.isInterstitialReady { self.preloadAdMobInterstitial() }
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
        
        #if canImport(GoogleMobileAds)
        preloadAdMobRewarded()
        preloadAdMobInterstitial()
        #endif
        
        #if canImport(MyTargetSDK)
        preloadVkRewarded()
        #endif
    }
    
    // MARK: - Предзагрузка Google AdMob
    public func preloadAdMobRewarded() {
        #if canImport(GoogleMobileAds)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        guard activeProviderType == .admob, isSdkReady else { return }
        guard admobRewardedAd == nil, !isAdMobRewardedLoading else { return }
        isAdMobRewardedLoading = true
        
        let unitId = AdConfig.admobRewardedUnitID
        Task { @MainActor in
            do {
                let ad = try await RewardedAd.load(with: unitId, request: Request())
                self.isAdMobRewardedLoading = false
                self.admobRewardedAd = ad
                ad.fullScreenContentDelegate = self
                self.lastAdErrors["Награда"] = nil
                if self.activeProviderType == .admob {
                    self.isRewardedReady = true
                }
                #if DEBUG
                print("✅ [AdMob Rewarded] Видео успешно загружено и готово к показу!")
                #endif
            } catch {
                self.isAdMobRewardedLoading = false
                self.recordAdError("Награда", error)
                #if DEBUG
                print("⚠️ [AdMob Rewarded] Ошибка предзагрузки: \(error.localizedDescription)")
                #endif
                self.admobRewardedAd = nil
                if self.activeProviderType == .admob {
                    self.isRewardedReady = false
                }
            }
        }
        #endif
    }
    
    public func preloadAdMobInterstitial() {
        #if canImport(GoogleMobileAds)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        guard activeProviderType == .admob, isSdkReady else { return }
        guard admobInterstitialAd == nil, !isAdMobInterstitialLoading else { return }
        isAdMobInterstitialLoading = true
        
        let unitId = AdConfig.admobInterstitialUnitID
        Task { @MainActor in
            do {
                let ad = try await InterstitialAd.load(with: unitId, request: Request())
                self.isAdMobInterstitialLoading = false
                self.admobInterstitialAd = ad
                ad.fullScreenContentDelegate = self
                self.lastAdErrors["Интерстициал"] = nil
                if self.activeProviderType == .admob {
                    self.isInterstitialReady = true
                }
                #if DEBUG
                print("✅ [AdMob Interstitial] Межстраничная реклама готова к показу!")
                #endif
            } catch {
                self.isAdMobInterstitialLoading = false
                self.recordAdError("Интерстициал", error)
                #if DEBUG
                print("⚠️ [AdMob Interstitial] Ошибка предзагрузки: \(error.localizedDescription)")
                #endif
                self.admobInterstitialAd = nil
                if self.activeProviderType == .admob {
                    self.isInterstitialReady = false
                }
            }
        }
        #endif
    }
    
    // MARK: - Предзагрузка VK Рекламы
    public func preloadVkRewarded() {
        #if canImport(MyTargetSDK)
        guard !SubscriptionManager.shared.isPremium, isAdsEnabled else { return }
        // VK только для РФ и Беларуси: иначе его SDK запрашивал данные устройства у всех (в том числе в ЕС) без согласия
        guard activeProviderType == .vk else { return }
        guard !isRewardedReady, !isVkRewardedLoading else { return }
        
        let slotId = effectiveTestMode ? AdConfig.vkDemoRewardedSlotId : UInt(max(0, vkRewardedSlotId))
        guard slotId > 0 else { return }
        
        isVkRewardedLoading = true
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
        
        #if canImport(GoogleMobileAds)
        if activeProviderType == .admob && admobInterstitialAd != nil {
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
        
        #if canImport(GoogleMobileAds)
        if activeProviderType == .admob, let interstitial = self.admobInterstitialAd {
            self.currentlyShowingAdMobInterstitial = interstitial
            self.admobInterstitialAd = nil
            self.isInterstitialReady = false
            self.lastInterstitialTime = Date()
            self.actionCounter = 0
            #if DEBUG
            print("🎬 [AdMob Interstitial] Показ полноэкранного объявления Google...")
            #endif
            interstitial.present(from: presenter)
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
        
        #if canImport(GoogleMobileAds)
        if activeProviderType == .admob, let admobAd = self.admobRewardedAd, let presenter = rootVC {
            self.onRewardCompletion = onReward
            self.currentlyShowingAdMobRewarded = admobAd
            self.admobRewardedAd = nil
            self.isRewardedReady = false
            #if DEBUG
            print("🎬 [AdMob Rewarded] Запуск показа Google видео...")
            #endif
            admobAd.present(from: presenter) { [weak self] in
                Task { @MainActor in
                    self?.completeRewardedAdAndGrantReward()
                }
            }
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
    
    // MARK: - Диагностика рекламы (TestFlight / отладка)
    public func recordAdError(_ format: String, _ error: Error) {
        let nsError = error as NSError
        lastAdErrors[format] = "\(nsError.domain) #\(nsError.code): \(nsError.localizedDescription)"
    }
    
    public func clearAdError(_ format: String) {
        lastAdErrors[format] = nil
    }
    
    private var trackingStatusText: String {
        #if targetEnvironment(simulator)
        return "симулятор"
        #else
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: return "разрешено"
        case .denied: return "запрещено"
        case .restricted: return "ограничено"
        case .notDetermined: return "не выбрано"
        @unknown default: return "?"
        }
        #endif
    }
    
    /// Сводка для панели тестировщика: почему реклама может не показываться
    public var diagnosticsSummary: String {
        var lines: [String] = []
        lines.append("Сеть: \(activeProviderType.rawValue) · регион \(detectedRegionCode)")
        lines.append("Google SDK: \(isSdkReady ? "запущен" : "не запущен") · ATT: \(trackingStatusText)")
        lines.append("Согласие: \(AdConsentManager.shared.canRequestAds ? "реклама разрешена" : "не получено")")
        lines.append("Premium: \(SubscriptionManager.shared.isPremium ? "да, рекламы нет" : "нет") · показ рекламы \(isAdsEnabled ? "включён" : "выключен")")
        lines.append("Адаптеры: \(adapterStatusSummary)")
        lines.append("Готово: награда \(isRewardedReady ? "да" : "нет"), интерстициал \(isInterstitialReady ? "да" : "нет")")
        for (format, text) in lastAdErrors.sorted(by: { $0.key < $1.key }) {
            lines.append("Ошибка · \(format): \(text)")
        }
        return lines.joined(separator: "\n")
    }
    
    /// Инспектор рекламы Google: показывает, какие источники отвечают на запросы (нужен запущенный SDK)
    public func presentAdInspector() {
        #if canImport(GoogleMobileAds)
        guard isSdkReady, let presenter = getTopViewController() else { return }
        Task { @MainActor in
            do {
                try await MobileAds.shared.presentAdInspector(from: presenter)
            } catch {
                self.recordAdError("Инспектор", error)
            }
        }
        #endif
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

// MARK: - Делегаты Google AdMob (FullScreen Content)
#if canImport(GoogleMobileAds)
extension LuysAdManager: FullScreenContentDelegate {
    nonisolated public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            LuysAdManager.shared.logImpression()
        }
    }
    
    nonisolated public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            LuysAdManager.shared.logClick()
        }
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            LuysAdManager.shared.currentlyShowingAdMobRewarded = nil
            LuysAdManager.shared.currentlyShowingAdMobInterstitial = nil
            if LuysAdManager.shared.onRewardCompletion != nil {
                LuysAdManager.shared.onDismissWithoutReward?()
                LuysAdManager.shared.onRewardCompletion = nil
                LuysAdManager.shared.onDismissWithoutReward = nil
            }
            LuysAdManager.shared.preloadAds()
        }
    }
    
    nonisolated public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            #if DEBUG
            print("⚠️ [AdMob] Ошибка показа полноэкранной рекламы: \(error.localizedDescription)")
            #endif
            LuysAdManager.shared.recordAdError("Показ", error)
            LuysAdManager.shared.currentlyShowingAdMobRewarded = nil
            LuysAdManager.shared.currentlyShowingAdMobInterstitial = nil
            LuysAdManager.shared.onDismissWithoutReward?()
            LuysAdManager.shared.onRewardCompletion = nil
            LuysAdManager.shared.onDismissWithoutReward = nil
            LuysAdManager.shared.preloadAds()
        }
    }
}
#endif

// MARK: - Делегаты VK Рекламы / myTarget (Rewarded Video)
#if canImport(MyTargetSDK)
extension LuysAdManager: MTRGRewardedAdDelegate {
    nonisolated public func onLoad(with rewardedAd: MTRGRewardedAd) {
        Task { @MainActor in
            LuysAdManager.shared.isVkRewardedLoading = false
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
            LuysAdManager.shared.isVkRewardedLoading = false
            LuysAdManager.shared.recordAdError("VK награда", error)
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
