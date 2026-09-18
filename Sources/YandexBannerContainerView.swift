import SwiftUI
import UIKit

#if canImport(YandexMobileAds)
import YandexMobileAds
#endif

// MARK: - Нативный контейнер баннера Yandex Mobile Ads (UIViewRepresentable)
/// Реализует адаптивный баннер Яндекса с авторотацией каждые 45 секунд, защитой от мигания (No-Flicker)
/// и строгой безопасностью потоков Swift 6 Concurrency.
#if canImport(YandexMobileAds)
struct YandexBannerContainerView: UIViewRepresentable {
    let adUnitID: String
    var isVisible: Bool
    var autoRefreshInterval: TimeInterval = 45.0 // Стандарт РСЯ: 30-60 секунд
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((any Error) -> Void)?
    
    init(
        adUnitID: String,
        isVisible: Bool = true,
        autoRefreshInterval: TimeInterval = 45.0,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((any Error) -> Void)? = nil
    ) {
        self.adUnitID = adUnitID
        self.isVisible = isVisible
        self.autoRefreshInterval = autoRefreshInterval
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let screenWidth = max(320, UIScreen.main.bounds.width - 32)
        let adSize = BannerAdSize.sticky(containerWidth: screenWidth)
        let bannerView = BannerAdView(adSize: adSize)
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.layer.cornerRadius = 14
        bannerView.clipsToBounds = true
        
        container.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: container.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        context.coordinator.bannerView = bannerView
        
        // Отложенная загрузка: инициируем запрос только если экран открыт пользователю
        if isVisible {
            context.coordinator.loadBanner(adUnitID: adUnitID)
            context.coordinator.startAutoRefreshTimer()
        }
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateVisibility(isVisible: isVisible, adUnitID: adUnitID)
    }
    
    // В Swift 6 остановку таймеров необходимо производить в dismantleUIView,
    // так как обращение к @MainActor в deinit вызывает ошибку изоляции памяти.
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stopAutoRefreshTimer()
    }
    
    // MARK: - Координатор и Делегат баннера Яндекса
    final class Coordinator: NSObject, @unchecked Sendable, BannerAdViewDelegate {
        let parent: YandexBannerContainerView
        var bannerView: BannerAdView?
        var isLoaded: Bool = false
        var hasEverLoaded: Bool = false
        var lastAttemptDate: Date = .distantPast
        var lastLoadedDate: Date = .distantPast
        private var refreshTimer: Timer?
        
        init(_ parent: YandexBannerContainerView) {
            self.parent = parent
        }
        
        func updateVisibility(isVisible: Bool, adUnitID: String) {
            if isVisible {
                startAutoRefreshTimer()
                let timeSinceLastAttempt = Date().timeIntervalSince(lastAttemptDate)
                let timeSinceLastLoad = Date().timeIntervalSince(lastLoadedDate)
                
                // Если баннер еще ни разу не загрузился и прошло > 15 секунд от предыдущей попытки
                if !isLoaded && timeSinceLastAttempt > 15 {
                    loadBanner(adUnitID: adUnitID)
                } else if isLoaded && timeSinceLastLoad >= parent.autoRefreshInterval {
                    // Если пользователь вернулся на экран спустя интервал авторотации (45+ секунд)
                    loadBanner(adUnitID: adUnitID)
                }
            } else {
                stopAutoRefreshTimer()
            }
        }
        
        func startAutoRefreshTimer() {
            guard refreshTimer == nil else { return }
            refreshTimer = Timer.scheduledTimer(withTimeInterval: parent.autoRefreshInterval, repeats: true) { [weak self] _ in
                guard let self = self, self.parent.isVisible else { return }
                if Date().timeIntervalSince(self.lastAttemptDate) >= 30 {
                    self.loadBanner(adUnitID: self.parent.adUnitID)
                }
            }
        }
        
        func stopAutoRefreshTimer() {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        
        func loadBanner(adUnitID: String) {
            guard let bannerView, !adUnitID.isEmpty else { return }
            lastAttemptDate = Date()
            
            // Чистый AdRequest без передачи персональных данных согласно App Store Guidelines
            let request = AdRequest(adUnitID: adUnitID)
            bannerView.loadAd(with: request)
        }
        
        // MARK: - BannerAdViewDelegate (Strict Concurrency Safe)
        nonisolated public func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
            Task { @MainActor in
                self.isLoaded = true
                self.hasEverLoaded = true
                self.lastLoadedDate = Date()
                let height = bannerAdView.intrinsicContentSize.height
                self.parent.onAdLoaded?(height > 0 ? height : 50)
                LuysAdManager.shared.logImpression()
            }
        }
        
        nonisolated public func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: any Error) {
            Task { @MainActor in
                self.isLoaded = false
                // Защита от мигания (No-Flicker):
                // Если баннер уже однажды успешно отобразился, при временном сбое ротации
                // не скрываем старый креатив, он продолжает висеть до следующего цикла.
                if !self.hasEverLoaded {
                    self.parent.onAdFailed?(error)
                }
            }
        }
        
        nonisolated public func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {
            Task { @MainActor in
                LuysAdManager.shared.logClick()
            }
        }
        
        nonisolated public func bannerAdView(_ bannerAdView: BannerAdView, didTrackImpression impressionData: (any ImpressionData)?) {
            Task { @MainActor in
                LuysAdManager.shared.logImpression()
            }
        }
    }
}
#endif
