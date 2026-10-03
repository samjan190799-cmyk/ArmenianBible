import SwiftUI
import UIKit
import Combine

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
        
        let bannerView = BannerView(adSize: AdSizeBanner)
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
        
        // Запрос уходит только после запуска SDK (согласие → ATT → start), а не при первой отрисовке
        context.coordinator.loadWhenSdkReady()
        
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
    final class Coordinator: NSObject, BannerViewDelegate {
        var onAdLoaded: ((CGFloat) -> Void)?
        var onAdFailed: ((Error) -> Void)?
        weak var bannerView: BannerView?
        
        private var readyCancellable: AnyCancellable?
        private var retryAttempt: Int = 0
        
        init(onAdLoaded: ((CGFloat) -> Void)?, onAdFailed: ((Error) -> Void)?) {
            self.onAdLoaded = onAdLoaded
            self.onAdFailed = onAdFailed
        }
        
        /// Загружает баннер сразу, если SDK запущен, иначе ждёт его запуска
        @MainActor
        func loadWhenSdkReady() {
            if LuysAdManager.shared.isSdkReady {
                bannerView?.load(Request())
                return
            }
            readyCancellable = LuysAdManager.shared.$isSdkReady
                .filter { $0 }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.bannerView?.load(Request())
                }
        }
        
        /// Повтор после неудачи (например, no-fill на новом блоке): 30, 60, 120, затем каждые 300 секунд
        @MainActor
        private func scheduleRetry() {
            let delay = min(30.0 * pow(2.0, Double(retryAttempt)), 300.0)
            retryAttempt += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let banner = self?.bannerView else { return }
                banner.load(Request())
            }
        }
        
        nonisolated func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("✅ [AdMob Banner] Баннер успешно загружен!")
                #endif
                self?.retryAttempt = 0
                LuysAdManager.shared.clearAdError("Баннер")
                self?.onAdLoaded?(50)
            }
        }
        
        nonisolated func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("⚠️ [AdMob Banner] Ошибка загрузки баннера: \(error.localizedDescription)")
                #endif
                LuysAdManager.shared.recordAdError("Баннер", error)
                self?.onAdFailed?(error)
                self?.scheduleRetry()
            }
        }
        
        nonisolated func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            Task { @MainActor in
                LuysAdManager.shared.logImpression()
            }
        }
        
        nonisolated func bannerViewDidRecordClick(_ bannerView: BannerView) {
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
