import SwiftUI
import UIKit

// MARK: - Спонсорские креативы для резервного показа (Graceful Fallback)
struct LuysSponsorCreative: Identifiable, Sendable {
    let id: String
    let tagHy: String
    let tagRu: String
    let tagEn: String
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let subtitleHy: String
    let subtitleRu: String
    let subtitleEn: String
    let icon: String
    let colorHex: String
    let targetUrl: String
    
    func tag(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return tagHy
        case .russian: return tagRu
        case .english: return tagEn
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func subtitle(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return subtitleHy
        case .russian: return subtitleRu
        case .english: return subtitleEn
        }
    }
}

// MARK: - Универсальный гибридный баннер Luys (Yandex РСЯ + Apple HIG Резерв)
/// Полностью исчезает при активной PRO-подписке, адаптируется под размер экрана,
/// поддерживает авторотацию, плавные пружинные анимации и резервные креативы.
public struct LuysHybridBannerView: View {
    public let placement: LuysBannerPlacement
    
    @ObservedObject private var adManager = LuysAdManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isShowingPaywall: Bool = false
    @State private var isLiveAdLoaded: Bool = false
    @State private var liveBannerHeight: CGFloat = 60
    @State private var isVisibleOnScreen: Bool = false
    @State private var currentCreativeIndex: Int = 0
    
    // Духовные спонсорские креативы Luys для гарантированного показа без пустых мест
    private let sponsorCreatives: [LuysSponsorCreative] = [
        LuysSponsorCreative(
            id: "narek_audio",
            tagHy: "ԱՈՒԴԻՈԳԻՐՔ",
            tagRu: "АУДИОКНИГА",
            tagEn: "AUDIOBOOK",
            titleHy: "Մատեան Ողբերգութեան",
            titleRu: "Книга Скорбных Песнопений",
            titleEn: "Book of Lamentations",
            subtitleHy: "Սբ. Գրիգոր Նարեկացու աղոթքների ոգեշնչող ձայնագրությունը",
            subtitleRu: "Молитвы св. Григора Нарекаци в благоговейном исполнении",
            subtitleEn: "Soulful prayers of St. Gregory of Narek with audio narration",
            icon: "headphones",
            colorHex: "D97706",
            targetUrl: "https://armenianchurch.org"
        ),
        LuysSponsorCreative(
            id: "children_bible",
            tagHy: "ԸՆՏԱՆԻՔ",
            tagRu: "ДЕТЯМ",
            tagEn: "FAMILY",
            titleHy: "Մանկական Աստվածաշունչ",
            titleRu: "Детская Библия с иллюстрациями",
            titleEn: "Illustrated Children's Bible",
            subtitleHy: "Պատմություններ Հին և Նոր Կտակարաններից փոքրիկների համար",
            subtitleRu: "Священные библейские сюжеты, доступные для детей и семьи",
            subtitleEn: "Inspiring Biblical stories crafted for children and families",
            icon: "figure.2.and.child.holdinghands",
            colorHex: "2563EB",
            targetUrl: "https://armenianbible.org"
        ),
        LuysSponsorCreative(
            id: "aac_calendar",
            tagHy: "ՏՈՆԱՑՈՒՅՑ",
            tagRu: "КАЛЕНДАРЬ ААЦ",
            tagEn: "CHURCH CALENDAR",
            titleHy: "Հայ Եկեղեցու Տոնացույց",
            titleRu: "Календарь праздников и постов ААЦ",
            titleEn: "Armenian Apostolic Church Calendar",
            subtitleHy: "Ամենօրյա սուրբգրային ընթերցումներ և եկեղեցական տոներ",
            subtitleRu: "Ежедневные чтения Писания, дни памяти святых и посты",
            subtitleEn: "Daily Bible readings, holy fasts and saint commemorations",
            icon: "calendar.badge.clock",
            colorHex: "059669",
            targetUrl: "https://qahana.am"
        ),
        LuysSponsorCreative(
            id: "sacred_shrines",
            tagHy: "ՈՒԽՏԱԳՆԱՑՈՒԹՅՈՒՆ",
            tagRu: "ПАЛОМНИЧЕСТВО",
            tagEn: "PILGRIMAGE",
            titleHy: "Հայաստանի Սուրբ Վանքերը",
            titleRu: "Древние святыни Армении",
            titleEn: "Sacred Monasteries of Armenia",
            subtitleHy: "Էջմիածին, Տաթև, Գեղարդ. վիրտուալ 3D շրջայցեր",
            subtitleRu: "Эчмиадзин, Татев, Гегард. Виртуальные паломнические туры",
            subtitleEn: "Echmiadzin, Tatev, Geghard. Discover historic Christian heritage",
            icon: "building.columns.fill",
            colorHex: "7C3AED",
            targetUrl: "https://armenianchurch.org"
        )
    ]
    
    public init(placement: LuysBannerPlacement = .home) {
        self.placement = placement
    }
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var removeAdsTitle: String {
        switch language {
        case .armenian: return "Անջատել գովազդը PRO-ում"
        case .russian: return "Отключить рекламу в PRO"
        case .english: return "Remove ads in PRO"
        }
    }
    
    private var adBadgeTitle: String {
        switch language {
        case .armenian: return "ԳՈՎԱԶԴ"
        case .russian: return "РЕКЛАМА"
        case .english: return "AD"
        }
    }
    
    public var body: some View {
        // При активной PRO-подписке баннеры полностью удаляются из иерархии вьюшек
        if subscriptionManager.isPremium || !adManager.isAdsEnabled {
            EmptyView()
        } else {
            let adUnitId = adManager.bannerId(for: placement)
            let creative = sponsorCreatives[currentCreativeIndex]
            
            VStack(spacing: 6) {
                // Живой адаптивный баннер Яндекса
                #if canImport(YandexMobileAds)
                if adManager.activeProviderType == .yandex && !adUnitId.isEmpty {
                    YandexBannerContainerView(
                        adUnitID: adUnitId,
                        isVisible: isVisibleOnScreen,
                        autoRefreshInterval: AdConfig.bannerAutoRefreshInterval,
                        onAdLoaded: { height in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                liveBannerHeight = height
                                isLiveAdLoaded = true
                            }
                        },
                        onAdFailed: { _ in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isLiveAdLoaded = false
                            }
                        }
                    )
                    .frame(height: isLiveAdLoaded ? liveBannerHeight : 0)
                    .frame(maxWidth: .infinity)
                    .opacity(isLiveAdLoaded ? 1 : 0)
                    .clipped()
                }
                #endif
                
                // Резервный спонсорский баннер в эстетике Apple HIG (при No-Fill, офлайн или загрузке)
                if !isLiveAdLoaded {
                    fallbackSponsorCard(creative: creative)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                
                // Компактная полоса с кнопкой «Отключить рекламу в PRO»
                HStack {
                    Text(adBadgeTitle)
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
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 4)
            .onAppear {
                isVisibleOnScreen = true
                currentCreativeIndex = Int.random(in: 0..<sponsorCreatives.count)
            }
            .onDisappear {
                isVisibleOnScreen = false
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Резервная карточка спонсора Apple HIG
    @ViewBuilder
    private func fallbackSponsorCard(creative: LuysSponsorCreative) -> some View {
        Button {
            triggerHaptic(.light)
            if let url = URL(string: creative.targetUrl) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: creative.colorHex).opacity(0.14))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: creative.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: creative.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(creative.tag(for: language))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: creative.colorHex))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(hex: creative.colorHex).opacity(0.1))
                            .cornerRadius(4)
                        
                        Text(creative.title(for: language))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    Text(creative.subtitle(for: language))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: creative.colorHex).opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
