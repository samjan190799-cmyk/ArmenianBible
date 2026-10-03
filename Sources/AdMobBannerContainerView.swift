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
        private var pendingRetry: DispatchWorkItem?
        private var hasReceivedAd: Bool = false
        
        init(onAdLoaded: ((CGFloat) -> Void)?, onAdFailed: ((Error) -> Void)?) {
            self.onAdLoaded = onAdLoaded
            self.onAdFailed = onAdFailed
        }
        
        deinit {
            pendingRetry?.cancel()
        }
        
        /// Загружает баннер сразу, если SDK запущен и согласие действует, иначе ждёт запуска SDK
        @MainActor
        func loadWhenSdkReady() {
            if LuysAdManager.shared.canRequestGoogleAds {
                bannerView?.load(Request())
                return
            }
            readyCancellable = LuysAdManager.shared.$isSdkReady
                .filter { $0 }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard LuysAdManager.shared.canRequestGoogleAds else { return }
                    self?.bannerView?.load(Request())
                }
        }
        
        /// Повтор после неудачи (например, no-fill на новом блоке): 30, 60, 120, затем каждые 300 секунд.
        /// Одна отложенная попытка за раз и только пока не показано ни одного объявления: после первого
        /// показа баннер обновляет сам SDK, и собственные повторы только множили бы запросы.
        @MainActor
        private func scheduleRetry() {
            guard !hasReceivedAd, pendingRetry == nil else { return }
            let delay = min(30.0 * pow(2.0, Double(retryAttempt)), 300.0)
            retryAttempt += 1
            let work = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.performRetry()
                }
            }
            pendingRetry = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
        
        @MainActor
        private func performRetry() {
            pendingRetry = nil
            // Баннер уже убран с экрана или согласие отозвано: не запрашиваем
            guard let banner = bannerView, banner.window != nil,
                  LuysAdManager.shared.canRequestGoogleAds else { return }
            banner.load(Request())
        }
        
        nonisolated func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("✅ [AdMob Banner] Баннер успешно загружен!")
                #endif
                self?.hasReceivedAd = true
                self?.retryAttempt = 0
                self?.pendingRetry?.cancel()
                self?.pendingRetry = nil
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
