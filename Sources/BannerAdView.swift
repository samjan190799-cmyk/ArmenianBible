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
// MARK: - Контейнер с отслеживанием жизненного цикла окна для надежного RootViewController
final class MetaBannerContainerUIView: UIView {
    var onAttachedToWindow: (() -> Void)?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            onAttachedToWindow?()
        }
    }
}

// MARK: - UIViewRepresentable для FBAdView
struct MetaBannerRepresentable: UIViewRepresentable {
    @Binding var isLoaded: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MetaBannerContainerUIView {
        let containerView = MetaBannerContainerUIView()
        containerView.backgroundColor = .clear
        
        context.coordinator.containerView = containerView
        containerView.onAttachedToWindow = { [weak context] in
            context?.coordinator.setupAdViewIfNeeded()
        }
        
        // Попытка первичной инициализации
        context.coordinator.setupAdViewIfNeeded()
        return containerView
    }
    
    func updateUIView(_ uiView: MetaBannerContainerUIView, context: Context) {}
    
    class Coordinator: NSObject, FBAdViewDelegate {
        var parent: MetaBannerRepresentable
        weak var adView: FBAdView?
        weak var containerView: MetaBannerContainerUIView?
        weak var rootVC: UIViewController?
        private var hasFallenBackToTest: Bool = false
        
        init(_ parent: MetaBannerRepresentable) {
            self.parent = parent
        }
        
        func setupAdViewIfNeeded() {
            guard adView == nil, let container = containerView else { return }
            
            // Надежный поиск активного RootViewController
            let foundRoot: UIViewController? = {
                if let winRoot = container.window?.rootViewController {
                    return winRoot
                }
                for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
                    if let key = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        return key
                    }
                    if let first = scene.windows.first?.rootViewController {
                        return first
                    }
                }
                return UIApplication.shared.windows.first?.rootViewController
            }()
            
            guard let root = foundRoot else { return }
            self.rootVC = root
            
            let placementID = AdConfig.bannerPlacementID
            let newAdView = FBAdView(
                placementID: placementID,
                adSize: kFBAdSizeHeight50Banner,
                rootViewController: root
            )
            newAdView.delegate = self
            newAdView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(newAdView)
            
            NSLayoutConstraint.activate([
                newAdView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                newAdView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                newAdView.topAnchor.constraint(equalTo: container.topAnchor),
                newAdView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                newAdView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
                newAdView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
            ])
            
            self.adView = newAdView
            newAdView.loadAd()
            #if DEBUG
            print("📢 [BannerAdView] Инициализация баннера Meta: \(placementID)")
            #endif
        }
        
        func adViewDidLoad(_ adView: FBAdView) {
            Task { @MainActor in
                self.parent.isLoaded = true
                #if DEBUG
                print("✅ [BannerAdView] Meta Баннер успешно загружен и отображается")
                #endif
            }
        }
        
        func adView(_ adView: FBAdView, didFailWithError error: Error) {
            #if DEBUG
            print("⚠️ [BannerAdView] Ошибка загрузки боевого баннера: \(error.localizedDescription)")
            #endif
            
            // Если в боевом режиме нет показа (No fill / код 1001) или аккаунт на проверке,
            // мгновенно переключаемся на гарантированный тестовый баннер Meta для показа в UI
            if !hasFallenBackToTest, let container = containerView, let root = rootVC {
                hasFallenBackToTest = true
                #if DEBUG
                print("🔄 [BannerAdView] Авто-переключение на гарантированный тестовый креатив Meta...")
                #endif
                
                adView.removeFromSuperview()
                let testAdView = FBAdView(
                    placementID: AdConfig.testBannerPlacementID,
                    adSize: kFBAdSizeHeight50Banner,
                    rootViewController: root
                )
                testAdView.delegate = self
                testAdView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(testAdView)
                
                NSLayoutConstraint.activate([
                    testAdView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    testAdView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    testAdView.topAnchor.constraint(equalTo: container.topAnchor),
                    testAdView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    testAdView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
                    testAdView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
                ])
                
                self.adView = testAdView
                testAdView.loadAd()
                return
            }
            
            Task { @MainActor in
                self.parent.isLoaded = false
            }
        }
    }
}
#endif
