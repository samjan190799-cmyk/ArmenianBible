import Foundation

// MARK: - Конфигурация Рекламы Meta Audience Network
/// Централизованное хранилище идентификаторов рекламных блоков и настроек показа.
public enum AdConfig {
    
    // MARK: - Идентификатор приложения в Meta
    public static let facebookAppID: String = "2096476450939558"
    
    // MARK: - Режим тестирования
    /// Если false — показывается реальная реклама Meta Audience Network.
    /// В Debug-сборках SDK Meta также автоматически регистрирует тестовый хеш устройства,
    /// защищая вас от случайных кликов.
    public static var isTestMode: Bool = false
    
    // MARK: - Рабочие Placement ID Meta (Armenian Bible)
    /// Рабочий Placement ID для Баннера (320x50 / адаптивный)
    public static let productionBannerPlacementID: String = "2096476450939558_2096479904272546"
    
    /// Рабочий Placement ID для Межстраничной рекламы (Interstitial)
    public static let productionInterstitialPlacementID: String = "2096476450939558_2096479900939213"
    
    /// Рабочий Placement ID для Рекламы с вознаграждением (Rewarded Video)
    public static let productionRewardedPlacementID: String = "2096476450939558_2096479907605879"
    
    // MARK: - Тестовые Placement ID от Meta
    public static let testBannerPlacementID: String = "IMG_16_9_APP_INSTALL#2096476450939558_2096479904272546"
    public static let testInterstitialPlacementID: String = "VID_HD_9_16_39S_APP_INSTALL#2096476450939558_2096479900939213"
    public static let testRewardedPlacementID: String = "VID_HD_9_16_39S_APP_INSTALL#2096476450939558_2096479907605879"
    
    // MARK: - Активные Placement ID
    public static var bannerPlacementID: String {
        isTestMode ? testBannerPlacementID : productionBannerPlacementID
    }
    
    public static var interstitialPlacementID: String {
        isTestMode ? testInterstitialPlacementID : productionInterstitialPlacementID
    }
    
    public static var rewardedPlacementID: String {
        isTestMode ? testRewardedPlacementID : productionRewardedPlacementID
    }
    
    // MARK: - Настройки частоты показа (Кулдауны для бережного UX)
    /// Минимальный интервал между показами полноэкранной межстраничной рекламы (в секундах).
    /// 180 секунд (3 минуты), чтобы не отвлекать от духовного чтения.
    public static let interstitialCooldownSeconds: TimeInterval = 180
    
    /// Количество действий (например, сохранений обоев), после которых можно показать полноэкранную рекламу
    public static let interstitialActionInterval: Int = 2
}
