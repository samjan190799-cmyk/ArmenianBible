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
        Coordinator(self)
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
        if context.coordinator.bannerView?.rootViewController == nil {
            context.coordinator.bannerView?.rootViewController = LuysAdManager.shared.getTopViewController()
        }
    }
    
    // MARK: - Делегат AdMob Banner
    final class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: AdMobBannerContainerView
        weak var bannerView: GADBannerView?
        
        init(_ parent: AdMobBannerContainerView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            #if DEBUG
            print("✅ [AdMob Banner] Баннер успешно загружен!")
            #endif
            parent.onAdLoaded?(50)
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("⚠️ [AdMob Banner] Ошибка загрузки баннера: \(error.localizedDescription)")
            #endif
            parent.onAdFailed?(error)
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            LuysAdManager.shared.logImpression()
        }
        
        func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            LuysAdManager.shared.logClick()
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
