import SwiftUI
import UIKit

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork

// MARK: - Нативный контейнер баннера Meta Audience Network (UIViewRepresentable)
/// Обертка над `FBAdView`, соответствующая стандартам 2026 года:
/// Swift 6 Strict Concurrency, изоляция `@MainActor` и безопасная работа с памятью.
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
        
        let rootVC = LuysAdManager.shared.getTopViewController()
        let adView = FBAdView(
            placementID: placementID,
            adSize: kFBAdSizeHeight50Banner,
            rootViewController: rootVC
        )
        adView.delegate = context.coordinator
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
        
        context.coordinator.adView = adView
        adView.loadAd()
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }
    
    @MainActor
    final class Coordinator: NSObject, FBAdViewDelegate {
        var parent: MetaBannerContainerView
        weak var adView: FBAdView?
        
        init(_ parent: MetaBannerContainerView) {
            self.parent = parent
        }
        
        nonisolated func adViewDidLoad(_ adView: FBAdView) {
            Task { @MainActor in
                self.parent.onAdLoaded?()
                LuysAdManager.shared.logImpression()
                #if DEBUG
                print("✅ [MetaBanner] Баннер успешно загружен")
                #endif
            }
        }
        
        nonisolated func adView(_ adView: FBAdView, didFailWithError error: Error) {
            Task { @MainActor in
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
