import SwiftUI
import UIKit

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork

// MARK: - Meta Audience Network Баннерный контейнер (UIViewRepresentable)
@MainActor
struct MetaBannerContainerView: UIViewRepresentable {
    let placementID: String
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((Error) -> Void)?

    init(
        placementID: String = AdConfig.metaBannerPlacementID,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((Error) -> Void)? = nil
    ) {
        self.placementID = placementID
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onAdLoaded: onAdLoaded, onAdFailed: onAdFailed)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let bannerView = FBAdView(
            placementID: placementID,
            adSize: kFBAdSizeHeight50Banner,
            rootViewController: LuysAdManager.shared.getTopViewController()
        )
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

        bannerView.loadAd()
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onAdLoaded = onAdLoaded
        context.coordinator.onAdFailed = onAdFailed
    }

    // MARK: - Делегат Meta Banner
    final class Coordinator: NSObject, FBAdViewDelegate {
        var onAdLoaded: ((CGFloat) -> Void)?
        var onAdFailed: ((Error) -> Void)?

        init(onAdLoaded: ((CGFloat) -> Void)?, onAdFailed: ((Error) -> Void)?) {
            self.onAdLoaded = onAdLoaded
            self.onAdFailed = onAdFailed
        }

        nonisolated func adViewDidLoad(_ adView: FBAdView) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("✅ [Meta Banner] Баннер успешно загружен!")
                #endif
                self?.onAdLoaded?(50)
            }
        }

        nonisolated func adView(_ adView: FBAdView, didFailWithError error: Error) {
            Task { @MainActor [weak self] in
                #if DEBUG
                print("⚠️ [Meta Banner] Ошибка загрузки баннера: \(error.localizedDescription)")
                #endif
                self?.onAdFailed?(error)
            }
        }

        nonisolated func adViewWillLogImpression(_ adView: FBAdView) {
            Task { @MainActor in
                LuysAdManager.shared.logImpression()
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
// Заглушка, если SDK еще не собран локально в окружении без Xcode
struct MetaBannerContainerView: View {
    let placementID: String
    var onAdLoaded: ((CGFloat) -> Void)?
    var onAdFailed: ((Error) -> Void)?

    init(
        placementID: String = AdConfig.metaBannerPlacementID,
        onAdLoaded: ((CGFloat) -> Void)? = nil,
        onAdFailed: ((Error) -> Void)? = nil
    ) {
        self.placementID = placementID
        self.onAdLoaded = onAdLoaded
        self.onAdFailed = onAdFailed
    }

    var body: some View {
        Color.clear
            .frame(height: 0)
            .onAppear {
                onAdFailed?(NSError(domain: "Meta", code: -1, userInfo: [NSLocalizedDescriptionKey: "FBAudienceNetwork SDK not loaded"]))
            }
    }
}
#endif
