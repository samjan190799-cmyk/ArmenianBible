import SwiftUI

// MARK: - Баннерный Компонент Luys (Адаптер обратной совместимости)
/// Обертка над `LuysHybridBannerView`, обеспечивающая плавную обратную совместимость
/// всех существующих вызовов `BannerAdView()`, автоматически переключая их на
/// Yandex Mobile Ads v8.x с авторотацией и резервными креативами.
public struct BannerAdView: View {
    public let placement: LuysBannerPlacement
    
    public init(placement: LuysBannerPlacement = .home) {
        self.placement = placement
    }
    
    public var body: some View {
        LuysHybridBannerView(placement: placement)
    }
}
