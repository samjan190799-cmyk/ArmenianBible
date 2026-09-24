import Foundation

// MARK: - Конфигурация Рекламы Meta Audience Network
/// Централизованное хранилище идентификаторов рекламных блоков и настроек показа.
public enum AdConfig {
    
    // MARK: - Идентификатор приложения в Meta (Новый зарубежный аккаунт)
    /// Новый Facebook App ID будет указан после создания приложения в новом аккаунте Meta Developer
    public static let facebookAppID: String = ""
    
    // MARK: - Режим тестирования
    /// Если false — показывается реальная реклама Meta Audience Network.
    /// В Debug-сборках SDK Meta также автоматически регистрирует тестовый хеш устройства,
    /// защищая вас от случайных кликов.
    public static var isTestMode: Bool = false
    
    // MARK: - Рабочие Placement ID Meta (Новый зарубежный аккаунт)
    /// Рабочий Placement ID для Баннера (320x50 / адаптивный)
    public static let productionBannerPlacementID: String = ""
    
    /// Рабочий Placement ID для Межстраничной рекламы (Interstitial)
    public static let productionInterstitialPlacementID: String = ""
    
    /// Рабочий Placement ID для Рекламы с вознаграждением (Rewarded Video)
    public static let productionRewardedPlacementID: String = ""
    
    // MARK: - Тестовые Placement ID от Meta (Новый зарубежный аккаунт)
    public static let testBannerPlacementID: String = ""
    public static let testInterstitialPlacementID: String = ""
    public static let testRewardedPlacementID: String = ""
    
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
    /// Безопасный интервал автообновления баннера (по правилам РСЯ: 30-60 сек)
    public static let bannerAutoRefreshInterval: TimeInterval = 45.0
    
    // MARK: - Активные Placement ID Meta
    public static var bannerPlacementID: String {
        isTestMode ? testBannerPlacementID : productionBannerPlacementID
    }
    
    public static var interstitialPlacementID: String {
        isTestMode ? testInterstitialPlacementID : productionInterstitialPlacementID
    }
    
    public static var rewardedPlacementID: String {
        isTestMode ? testRewardedPlacementID : productionRewardedPlacementID
    }
    
    /// Флаг готовности рекламных блоков Meta нового аккаунта
    public static var hasMetaPlacements: Bool {
        !facebookAppID.isEmpty && (!bannerPlacementID.isEmpty || !interstitialPlacementID.isEmpty || !rewardedPlacementID.isEmpty)
    }
    
    // MARK: - Настройки частоты показа (Кулдауны для бережного UX)
    /// Минимальный интервал между показами полноэкранной межстраничной рекламы (в секундах).
    /// 180 секунд (3 минуты), чтобы не отвлекать от духовного чтения.
    public static let interstitialCooldownSeconds: TimeInterval = 180
    
    /// Количество действий (например, сохранений обоев), после которых можно показать полноэкранную рекламу
    public static let interstitialActionInterval: Int = 2
}
