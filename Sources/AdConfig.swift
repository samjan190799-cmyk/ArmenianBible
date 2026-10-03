import Foundation

// MARK: - Конфигурация Рекламы Meta Audience Network & VK
/// Централизованное хранилище идентификаторов рекламных блоков и настроек показа.
public enum AdConfig {
    
    // MARK: - Идентификаторы Meta Audience Network
    /// Monetization Manager → Luys: Armenian Bible & AI (iOS) → Ad Space for ios
    public static let metaBannerPlacementID: String = "965349189941367_965349289941357"
    public static let metaInterstitialPlacementID: String = "965349189941367_965349296608023"
    public static let metaRewardedInterstitialPlacementID: String = "965349189941367_965349299941356"

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
