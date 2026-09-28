import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds

// MARK: - AdMob Баннерный контейнер (UIViewRepresentable)
/// Реализован строго по стандартам iOS 17+/Swift 6 с изоляцией на `@MainActor`.
@MainActor
struct AdMobBannerContainerView: UIViewRepresentable {
    let adUnitID: String
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((Error) -> Void)?
    
    init(
        adUnitID: String = AdConfig.admobBannerUnitID,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((Error) -> Void)? = nil
    ) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onAdLoaded: onAdLoaded, onAdFailed: onAdFailed)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = LuysAdManager.shared.getTopViewController()
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.widthAnchor.constraint(equalToConstant: 320),
            bannerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        context.coordinator.bannerView = bannerView
        
        let request = GADRequest()
        bannerView.load(request)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onAdLoaded = onAdLoaded
        context.coordinator.onAdFailed = onAdFailed
        if context.coordinator.bannerView?.rootViewController == nil {
            context.coordinator.bannerView?.rootViewController = LuysAdManager.shared.getTopViewController()
        }
    }
    
    // MARK: - Делегат AdMob Banner (Swift 6 Strict Concurrency)
    final class Coordinator: NSObject, GADBannerViewDelegate {
        var onAdLoaded: ((CGFloat) -> Void)?
        var onAdFailed: ((Error) -> Void)?
        weak var bannerView: GADBannerView?
        
        init(onAdLoaded: ((CGFloat) -> Void)?, onAdFailed: ((Error) -> Void)?) {
            self.onAdLoaded = onAdLoaded
            self.onAdFailed = onAdFailed
        }
        
        nonisolated func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("✅ [AdMob Banner] Баннер успешно загружен!")
                #endif
                self?.onAdLoaded?(50)
            }
        }
        
        nonisolated func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("⚠️ [AdMob Banner] Ошибка загрузки баннера: \(error.localizedDescription)")
                #endif
                self?.onAdFailed?(error)
            }
        }
        
        nonisolated func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            Task { @MainActor in
                LuysAdManager.shared.logImpression()
            }
        }
        
        nonisolated func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            Task { @MainActor in
                LuysAdManager.shared.logClick()
            }
        }
    }
}
#else
// Заглушка, если SDK еще не собран локально в окружении без Xcode
struct AdMobBannerContainerView: View {
    let adUnitID: String
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((Error) -> Void)?
    
    init(
        adUnitID: String = AdConfig.admobBannerUnitID,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((Error) -> Void)? = nil
    ) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }
    
    var body: some View {
        Color.clear
            .frame(height: 0)
            .onAppear {
                onAdFailed?(NSError(domain: "AdMob", code: -1, userInfo: [NSLocalizedDescriptionKey: "GoogleMobileAds SDK not loaded"]))
            }
    }
}
#endif
