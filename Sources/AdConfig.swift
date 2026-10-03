import Foundation

// MARK: - Конфигурация Рекламы Google AdMob & VK
/// Централизованное хранилище идентификаторов рекламных блоков и настроек показа.
public enum AdConfig {
    
    // MARK: - Идентификаторы Google AdMob
    /// AdMob Publisher ID: pub-2894315025786699
    /// Официальный App ID для iOS: ca-app-pub-2894315025786699~1008604498
    public static var admobAppID: String = "ca-app-pub-2894315025786699~1008604498"
    
    // MARK: - Режим тестирования
    public static let isTestMode: Bool = false
    
    // MARK: - Тестовые идентификаторы Google AdMob (Официальные от Google)
    public static let googleTestBannerUnitID: String = "ca-app-pub-3940256099942544/2934735716"
    public static let googleTestInterstitialUnitID: String = "ca-app-pub-3940256099942544/4411468910"
    public static let googleTestRewardedUnitID: String = "ca-app-pub-3940256099942544/1712485313"
    
    // MARK: - Рабочие Placement ID Google AdMob
    public static let productionAdmobBannerUnitID: String = "ca-app-pub-2894315025786699/5035479415"
    public static let productionAdmobInterstitialUnitID: String = "ca-app-pub-2894315025786699/4860219591"
    public static let productionAdmobRewardedUnitID: String = "ca-app-pub-2894315025786699/7566273984"
    
    // MARK: - Активные Ad Unit ID Google AdMob
    public static var admobBannerUnitID: String {
        if isTestMode || productionAdmobBannerUnitID.isEmpty {
            return googleTestBannerUnitID
        }
        return productionAdmobBannerUnitID
    }
    
    public static var admobInterstitialUnitID: String {
        if isTestMode || productionAdmobInterstitialUnitID.isEmpty {
            return googleTestInterstitialUnitID
        }
        return productionAdmobInterstitialUnitID
    }
    
    public static var admobRewardedUnitID: String {
        if isTestMode || productionAdmobRewardedUnitID.isEmpty {
            return googleTestRewardedUnitID
        }
        return productionAdmobRewardedUnitID
    }
    
    public static var hasAdMobPlacements: Bool {
        !admobAppID.isEmpty
    }
    
    // MARK: - Идентификаторы VK Рекламы / myTarget (ads.vk.com)
    /// Официальные стабильные демо/тестовые Slot ID для MyTarget SDK
    public static let vkDemoBannerSlotId: UInt = 794557
    public static let vkDemoRewardedSlotId: UInt = 577495
    public static let vkDemoInterstitialSlotId: UInt = 6899
    
    /// Боевые Slot ID для раздельных экранов Luys
    public static let vkDefaultBannerSlotId: UInt = 2071440
    public static let vkDefaultRewardedSlotId: UInt = 2071443
    public static let vkBannerHomeSlotId: UInt = 2071440
    public static let vkBannerReaderSlotId: UInt = 2071440
    public static let vkBannerFavoritesSlotId: UInt = 2071440
    public static let vkBannerNarekatsiSlotId: UInt = 2071440
    public static let vkBannerSettingsSlotId: UInt = 2071440
    
    // MARK: - Тайминги авторотации и безопасности UX
    /// Безопасный интервал автообновления баннера (по правилам: 30-60 сек)
    public static let bannerAutoRefreshInterval: TimeInterval = 45.0
    
    // MARK: - Настройки частоты показа (Кулдауны для бережного UX)
    /// Минимальный интервал между показами полноэкранной межстраничной рекламы (в секундах).
    /// 180 секунд (3 минуты), чтобы не отвлекать от духовного чтения.
    public static let interstitialCooldownSeconds: TimeInterval = 180
    
    /// Количество действий (например, сохранений обоев), после которых можно показать полноэкранную рекламу
    public static let interstitialActionInterval: Int = 2
}
