import SwiftUI
import UIKit

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork

// MARK: - Нативный контейнер баннера Meta Audience Network (UIViewRepresentable)
/// Обертка над `FBAdView`, соответствующая стандартам 2026 года:
/// Swift 6 Strict Concurrency, изоляция `@MainActor`, безопасная асинхронная привязка rootViewController
/// и защита от сбоев жизненного цикла при ранней инициализации.
struct MetaBannerContainerView: UIViewRepresentable {
    let placementID: String
    var onAdLoaded: (() -> Void)?
    var onAdFailed: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        container.backgroundColor = .clear
        context.coordinator.containerView = container
        context.coordinator.loadBanner(placementID: placementID)
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.adView == nil {
            context.coordinator.loadBanner(placementID: placementID)
        }
    }
    
    @MainActor
    final class Coordinator: NSObject, FBAdViewDelegate {
        var parent: MetaBannerContainerView
        weak var containerView: UIView?
        var adView: FBAdView?
        private var isLoading: Bool = false
        
        init(_ parent: MetaBannerContainerView) {
            self.parent = parent
        }
        
        func loadBanner(placementID: String) {
            guard !placementID.isEmpty, adView == nil, !isLoading else { return }
            guard let container = containerView else { return }
            
            // Если rootViewController еще не смонтирован (при самом раннем запуске приложения),
            // безопасно откладываем создание FBAdView на следующий цикл RunLoop, когда сцена будет активна
            guard let rootVC = LuysAdManager.shared.getTopViewController() else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.loadBanner(placementID: placementID)
                }
                return
            }
            
            isLoading = true
            let adView = FBAdView(
                placementID: placementID,
                adSize: kFBAdSizeHeight50Banner,
                rootViewController: rootVC
            )
            adView.delegate = self
            adView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(adView)
            
            NSLayoutConstraint.activate([
                adView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                adView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                adView.topAnchor.constraint(equalTo: container.topAnchor),
                adView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                adView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
                adView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
            ])
            
            self.adView = adView
            adView.loadAd()
        }
        
        nonisolated func adViewDidLoad(_ adView: FBAdView) {
            Task { @MainActor in
                self.isLoading = false
                self.parent.onAdLoaded?()
                LuysAdManager.shared.logImpression()
                #if DEBUG
                print("✅ [MetaBanner] Баннер успешно загружен")
                #endif
            }
        }
        
        nonisolated func adView(_ adView: FBAdView, didFailWithError error: Error) {
            Task { @MainActor in
                self.isLoading = false
                self.parent.onAdFailed?(error.localizedDescription)
                #if DEBUG
                print("⚠️ [MetaBanner] Ошибка загрузки баннера: \(error.localizedDescription)")
                #endif
            }
        }
        
        nonisolated func adViewDidClick(_ adView: FBAdView) {
            Task { @MainActor in
                LuysAdManager.shared.logClick()
            }
        }
    }
}
#else
// Резервный контейнер на случай сборки без SDK FBAudienceNetwork
struct MetaBannerContainerView: View {
    let placementID: String
    var onAdLoaded: (() -> Void)?
    var onAdFailed: ((String) -> Void)?
    
    var body: some View {
        EmptyView()
    }
}
#endif
