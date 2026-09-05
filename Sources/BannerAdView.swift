import SwiftUI
import UIKit

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif

// MARK: - Баннерный Компонент Meta Audience Network для SwiftUI
/// Отображает адаптивный баннер Meta с аккуратной плашкой «Реклама» и кнопкой «Убрать рекламу».
/// Если у пользователя активирован Premium, баннер автоматически полностью скрывается.
public struct BannerAdView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isShowingPaywall: Bool = false
    @State private var isAdLoaded: Bool = false
    
    public init() {}
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var accentColor: Color {
        Color(hex: bibleManager.accentTheme.colorHex)
    }
    
    private var adBadgeTitle: String {
        switch language {
        case .armenian: return "Գովազդ"
        case .russian: return "Реклама"
        case .english: return "Ad"
        }
    }
    
    private var removeAdsTitle: String {
        switch language {
        case .armenian: return "Անջատել"
        case .russian: return "Убрать рекламу"
        case .english: return "Remove Ads"
        }
    }
    
    public var body: some View {
        if subscriptionManager.isPremium {
            EmptyView()
        } else {
            VStack(spacing: 4) {
                // Верхняя информационная полоса с кнопкой «Убрать рекламу»
                HStack {
                    Text(adBadgeTitle.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Button {
                        triggerHaptic(.light)
                        isShowingPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text(removeAdsTitle)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                
                // Нативный баннерный контейнер
                #if canImport(FBAudienceNetwork)
                MetaBannerRepresentable(isLoaded: $isAdLoaded)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
                    )
                #else
                // Заглушка для отладки в симуляторе без подключенного SPM пакета
                HStack(spacing: 8) {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(.secondary)
                    Text("Meta Audience Network (Test Banner)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                #endif
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

#if canImport(FBAudienceNetwork)
// MARK: - UIViewRepresentable для FBAdView
struct MetaBannerRepresentable: UIViewRepresentable {
    @Binding var isLoaded: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return containerView
        }
        
        let placementID = AdConfig.bannerPlacementID
        let adView = FBAdView(
            placementID: placementID,
            adSize: kFBAdSizeHeight50Banner,
            rootViewController: rootVC
        )
        adView.delegate = context.coordinator
        adView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(adView)
        
        NSLayoutConstraint.activate([
            adView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            adView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            adView.topAnchor.constraint(equalTo: containerView.topAnchor),
            adView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            adView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            adView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        ])
        
        adView.loadAd()
        context.coordinator.adView = adView
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    class Coordinator: NSObject, FBAdViewDelegate {
        var parent: MetaBannerRepresentable
        weak var adView: FBAdView?
        
        init(_ parent: MetaBannerRepresentable) {
            self.parent = parent
        }
        
        func adViewDidLoad(_ adView: FBAdView) {
            Task { @MainActor in
                self.parent.isLoaded = true
                #if DEBUG
                print("✅ [BannerAdView] Meta Баннер успешно загружен")
                #endif
            }
        }
        
        func adView(_ adView: FBAdView, didFailWithError error: Error) {
            Task { @MainActor in
                self.parent.isLoaded = false
                #if DEBUG
                print("⚠️ [BannerAdView] Ошибка загрузки баннера: \(error.localizedDescription)")
                #endif
            }
        }
    }
}
#endif
