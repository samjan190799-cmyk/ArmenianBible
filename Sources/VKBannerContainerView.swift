import SwiftUI
import UIKit

#if canImport(MyTargetSDK)
import MyTargetSDK
#endif

// MARK: - Нативный контейнер баннера VK Рекламы / myTarget (UIViewRepresentable)
/// Обертка над `MTRGAdView`, соответствующая стандартам 2026 года:
/// Swift 6 Strict Concurrency, изоляция `@MainActor` и безопасная работа с памятью.
#if canImport(MyTargetSDK)
struct VKBannerContainerView: UIViewRepresentable {
    let slotId: UInt
    let isVisible: Bool
    var autoRefreshInterval: TimeInterval = AdConfig.bannerAutoRefreshInterval
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((String) -> Void)?
    
    init(
        slotId: UInt,
        isVisible: Bool = true,
        autoRefreshInterval: TimeInterval = AdConfig.bannerAutoRefreshInterval,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((String) -> Void)? = nil
    ) {
        self.slotId = slotId
        self.isVisible = isVisible
        self.autoRefreshInterval = autoRefreshInterval
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        container.backgroundColor = .clear
        context.coordinator.containerView = container
        context.coordinator.loadBanner(slotId: slotId)
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.currentSlotId != slotId {
            context.coordinator.loadBanner(slotId: slotId)
        }
    }
    
    @MainActor
    final class Coordinator: NSObject, MTRGAdViewDelegate {
        var parent: VKBannerContainerView
        weak var containerView: UIView?
        var currentSlotId: UInt = 0
        var adView: MTRGAdView?
        
        init(_ parent: VKBannerContainerView) {
            self.parent = parent
        }
        
        func loadBanner(slotId: UInt) {
            guard slotId > 0 else { return }
            self.currentSlotId = slotId
            
            // Очищаем старый баннер перед созданием нового
            adView?.removeFromSuperview()
            adView?.delegate = nil
            
            let banner = MTRGAdView(slotId: slotId, shouldRefreshAd: true)
            banner.delegate = self
            banner.adSize = MTRGAdSize.adSizeForCurrentOrientation()
            banner.translatesAutoresizingMaskIntoConstraints = false
            self.adView = banner
            
            if let container = containerView {
                container.addSubview(banner)
                NSLayoutConstraint.activate([
                    banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    banner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    banner.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
                    banner.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor),
                    banner.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
                    banner.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
                ])
            }
            
            banner.load()
        }
        
        // MARK: - MTRGAdViewDelegate (Swift 6 Concurrency Safe)
        nonisolated func onLoad(with adView: MTRGAdView) {
            Task { @MainActor in
                let height = adView.adSize.size.height
                self.parent.onAdLoaded?(height > 0 ? height : 50)
                LuysAdManager.shared.logImpression()
            }
        }
        
        nonisolated func onLoadFailed(error: any Error, adView: MTRGAdView) {
            Task { @MainActor in
                self.parent.onAdFailed?(error.localizedDescription)
            }
        }
        
        nonisolated func onAdClick(with adView: MTRGAdView) {
            Task { @MainActor in
                LuysAdManager.shared.logClick()
            }
        }
        
        nonisolated func onAdShow(with adView: MTRGAdView) {
            Task { @MainActor in
                LuysAdManager.shared.logImpression()
            }
        }
    }
}
#else
// Резервный пустой контейнер на случай сборки без SDK
struct VKBannerContainerView: View {
    let slotId: UInt
    let isVisible: Bool
    var autoRefreshInterval: TimeInterval = 45.0
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((String) -> Void)?
    
    init(
        slotId: UInt,
        isVisible: Bool = true,
        autoRefreshInterval: TimeInterval = 45.0,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((String) -> Void)? = nil
    ) {
        self.slotId = slotId
        self.isVisible = isVisible
        self.autoRefreshInterval = autoRefreshInterval
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }
    
    var body: some View {
        EmptyView()
    }
}
#endif
