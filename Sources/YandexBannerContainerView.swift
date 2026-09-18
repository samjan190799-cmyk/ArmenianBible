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
        context.coordinator.container = container
        context.coordinator.parent = self
        context.coordinator.currentIsVisible = isVisible
        context.coordinator.currentAdUnitID = adUnitID
        
        // Отложенная безопасная загрузка: запускаем запрос только после стабилизации сцены и SDK
        if isVisible {
            context.coordinator.safeLoadBanner(adUnitID: adUnitID)
            context.coordinator.startAutoRefreshTimer()
        }
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateVisibility(isVisible: isVisible, adUnitID: adUnitID)
    }
    
    // В Swift 6 остановку таймеров необходимо производить в dismantleUIView,
    // так как обращение к @MainActor в deinit вызывает ошибку изоляции памяти.
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stopAutoRefreshTimer()
    }
    
    // MARK: - Координатор и Делегат баннера Яндекса
    @MainActor
    final class Coordinator: NSObject, BannerAdViewDelegate {
        var parent: YandexBannerContainerView
        weak var container: UIView?
        var bannerView: YandexMobileAds.BannerAdView?
        var isLoaded: Bool = false
        var hasEverLoaded: Bool = false
        var lastAttemptDate: Date = .distantPast
        var lastLoadedDate: Date = .distantPast
        var currentIsVisible: Bool = true
        var currentAdUnitID: String = ""
        private var refreshTimer: Timer?
        
        init(_ parent: YandexBannerContainerView) {
            self.parent = parent
            self.currentIsVisible = parent.isVisible
            self.currentAdUnitID = parent.adUnitID
        }
        
        func updateVisibility(isVisible: Bool, adUnitID: String) {
            self.currentIsVisible = isVisible
            self.currentAdUnitID = adUnitID
            
            if isVisible {
                startAutoRefreshTimer()
                let timeSinceLastAttempt = Date().timeIntervalSince(lastAttemptDate)
                let timeSinceLastLoad = Date().timeIntervalSince(lastLoadedDate)
                
                // Если баннер еще ни разу не загрузился и прошло > 10 секунд от предыдущей попытки
                if !isLoaded && timeSinceLastAttempt > 10 {
                    safeLoadBanner(adUnitID: adUnitID)
                } else if isLoaded && timeSinceLastLoad >= parent.autoRefreshInterval {
                    // Если пользователь вернулся на экран спустя интервал авторотации (45+ секунд)
                    safeLoadBanner(adUnitID: adUnitID)
                }
            } else {
                stopAutoRefreshTimer()
            }
        }
        
        func startAutoRefreshTimer() {
            guard refreshTimer == nil else { return }
            let interval = parent.autoRefreshInterval > 0 ? parent.autoRefreshInterval : 45.0
            let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard self.currentIsVisible else { return }
                #if DEBUG
                print("🔄 [LuysAds] Авторотация баннера (каждые \(interval)с): запрос свежей рекламы для \(self.currentAdUnitID)")
                #endif
                self.safeLoadBanner(adUnitID: self.currentAdUnitID)
            }
            RunLoop.main.add(timer, forMode: .common)
            self.refreshTimer = timer
        }
        
        func stopAutoRefreshTimer() {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        
        func safeLoadBanner(adUnitID: String) {
            guard !adUnitID.isEmpty else { return }
            
            // Предотвращение дедлока (Watchdog 0x8BADF00D):
            // Ждем завершения инициализации SDK в AppDelegate
            guard LuysAdManager.shared.isYandexInitialized else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.safeLoadBanner(adUnitID: adUnitID)
                }
                return
            }
            
            guard let container = self.container else { return }
            
            // Ленивое создание BannerAdView строго после готовности SDK
            if bannerView == nil {
                let screenWidth = max(320, UIScreen.main.bounds.width - 32)
                let adSize = BannerAdSize.sticky(containerWidth: screenWidth)
                let bView = YandexMobileAds.BannerAdView(adSize: adSize)
                bView.delegate = self
                bView.translatesAutoresizingMaskIntoConstraints = false
                bView.layer.cornerRadius = 14
                bView.clipsToBounds = true
                
                container.addSubview(bView)
                NSLayoutConstraint.activate([
                    bView.topAnchor.constraint(equalTo: container.topAnchor),
                    bView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    bView.centerXAnchor.constraint(equalTo: container.centerXAnchor)
                ])
                self.bannerView = bView
            }
            
            lastAttemptDate = Date()
            
            // Чистый AdRequest без передачи персональных данных согласно App Store Guidelines
            let request = AdRequest(adUnitID: adUnitID)
            bannerView?.loadAd(with: request)
        }
        
        // MARK: - BannerAdViewDelegate (YandexMobileAds)
        func bannerAdViewDidLoad(_ bannerAdView: YandexMobileAds.BannerAdView) {
            self.isLoaded = true
            self.hasEverLoaded = true
            self.lastLoadedDate = Date()
            let height = bannerAdView.intrinsicContentSize.height
            self.parent.onAdLoaded?(height > 0 ? height : 50)
            LuysAdManager.shared.logImpression()
        }
        
        func bannerAdViewDidFailLoading(_ bannerAdView: YandexMobileAds.BannerAdView, error: any Error) {
            self.isLoaded = false
            // Защита от мигания (No-Flicker):
            // Если баннер уже однажды успешно отобразился, при временном сбое ротации
            // не скрываем старый креатив, он продолжает висеть до следующего цикла.
            if !self.hasEverLoaded {
                self.parent.onAdFailed?(error)
            }
        }
        
        func bannerAdViewDidClick(_ bannerAdView: YandexMobileAds.BannerAdView) {
            LuysAdManager.shared.logClick()
        }
        
        func bannerAdView(_ bannerAdView: YandexMobileAds.BannerAdView, didTrackImpression impressionData: (any ImpressionData)?) {
            LuysAdManager.shared.logImpression()
        }
    }
}
#endif
