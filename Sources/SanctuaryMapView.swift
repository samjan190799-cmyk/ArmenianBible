import SwiftUI
import MapKit
import CoreLocation

// MARK: - Местоположение (необязательно, только на устройстве)
/// Положение нужно лишь чтобы показать расстояние до святынь; оно нигде не сохраняется и никуда не отправляется.
final class SanctuaryLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var status: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// MARK: - Карта святынь
struct SanctuaryMapView: View {
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var subscription = SubscriptionManager.shared
    @StateObject private var location = SanctuaryLocation()
    @Environment(\.dismiss) private var dismiss

    private enum Mode: Hashable { case map, list }

    @State private var mode: Mode = .map
    @State private var selected: Sanctuary?
    @State private var isShowingPaywall = false
    @State private var manuscriptLaunch: ManuscriptLaunch?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.25, longitude: 45.1),
        span: MKCoordinateSpan(latitudeDelta: 2.2, longitudeDelta: 2.8)
    )

    private var language: AppLanguage { manager.appLanguage }
    private var sites: [Sanctuary] { SanctuaryCatalog.all }

    private func isLocked(_ site: Sanctuary) -> Bool {
        !subscription.isPremium && !site.isFree
    }

    private func distanceText(_ site: Sanctuary) -> String? {
        guard let here = location.location else { return nil }
        let km = Int((site.distance(from: here) / 1000).rounded())
        return language.pick(hy: "\(km) կմ", ru: "\(km) км", en: "\(km) km")
    }

    private var sortedSites: [Sanctuary] {
        guard let here = location.location else { return sites }
        return sites.sorted { $0.distance(from: here) < $1.distance(from: here) }
    }

    /// Ближайшая святыня, если человек от неё не дальше 15 км
    private var nearbySite: Sanctuary? {
        guard let here = location.location,
              let nearest = sites.min(by: { $0.distance(from: here) < $1.distance(from: here) }),
              nearest.distance(from: here) < 15_000 else { return nil }
        return nearest
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PaperBackground()
                VStack(spacing: 0) {
                    controls
                    if mode == .map {
                        mapLayer
                    } else {
                        listLayer
                    }
                }
                if let site = selected {
                    detailCard(site)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(language.pick(hy: "Սրբավայրերի քարտեզ", ru: "Карта святынь", en: "Map of Sanctuaries"))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(Paper.ink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Paper.inkSecondary)
                    }
                    .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .fullScreenCover(item: $manuscriptLaunch) { launch in
            ManuscriptStudioView(source: launch.source)
        }
        .onAppear {
            runLaunchArguments()
            if location.isAuthorized { location.request() }
        }
    }

    // MARK: Переключатели
    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Picker("", selection: $mode) {
                    Text(language.pick(hy: "Քարտեզ", ru: "Карта", en: "Map")).tag(Mode.map)
                    Text(language.pick(hy: "Ցանկ", ru: "Список", en: "List")).tag(Mode.list)
                }
                .pickerStyle(.segmented)

                Button {
                    Haptics.impact(.soft)
                    location.request()
                } label: {
                    Image(systemName: location.location == nil ? "location" : "location.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Paper.ink)
                        .frame(width: 40, height: 34)
                        .paperField(cornerRadius: 10)
                }
                .accessibilityLabel(Text(language.pick(hy: "Մոտակայքում", ru: "Рядом со мной", en: "Near me")))
            }

            if let nearby = nearbySite, selected == nil {
                Button {
                    Haptics.impact(.soft)
                    select(nearby)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Paper.cinnabar)
                        Text(language.pick(hy: "Մոտակայքում՝ ", ru: "Рядом с вами: ", en: "Near you: ") + nearby.name(language))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(Paper.ink)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Paper.inkTertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .paperField(cornerRadius: 10)
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.97))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: Карта
    private var mapLayer: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: location.isAuthorized,
            annotationItems: sites
        ) { site in
            MapAnnotation(coordinate: site.coordinate) {
                Button {
                    Haptics.impact(.light)
                    select(site)
                } label: {
                    SanctuaryPin(
                        title: site.name(language),
                        isSelected: selected?.id == site.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Список
    private var listLayer: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(sortedSites) { site in
                    Button {
                        Haptics.impact(.light)
                        mode = .map
                        select(site)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Paper.gold.opacity(0.12))
                                Image(systemName: "cross")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Paper.gold)
                            }
                            .frame(width: 38, height: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(site.name(language))
                                    .font(PaperFont.font(size: 16, weight: .semibold))
                                    .foregroundColor(Paper.ink)
                                    .multilineTextAlignment(.leading)
                                Text([site.region(language), site.era(language)].joined(separator: " · "))
                                    .font(PaperFont.font(size: 12))
                                    .foregroundColor(Paper.inkSecondary)
                            }
                            Spacer()
                            if let distance = distanceText(site) {
                                Text(distance)
                                    .font(PaperFont.font(size: 12, weight: .medium))
                                    .foregroundColor(Paper.inkTertiary)
                            }
                            if isLocked(site) {
                                Image(systemName: "lock")
                                    .font(.system(size: 11))
                                    .foregroundColor(Paper.inkTertiary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Paper.inkTertiary)
                        }
                        .padding(12)
                        .paperSheet(cornerRadius: 14)
                    }
                    .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.97))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: Карточка святыни
    private func detailCard(_ site: Sanctuary) -> some View {
        let locked = isLocked(site)
        let verse = locked ? nil : SanctuaryCatalog.verse(for: site, language: language)
        let feast = locked ? nil : SanctuaryCatalog.nextFeast(for: site)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(site.name(language))
                        .font(PaperFont.font(size: 20, weight: .semibold))
                        .foregroundColor(Paper.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text([site.region(language), site.era(language), distanceText(site)].compactMap { $0 }.joined(separator: " · "))
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                }
                Spacer()
                Button {
                    Haptics.impact(.soft)
                    withAnimation(PaperMotion.appear) { selected = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Paper.inkTertiary)
                }
                .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))
            }

            if locked {
                lockedBlock
            } else {
                let content = VStack(alignment: .leading, spacing: 12) {
                        Text(site.history(language))
                            .font(PaperFont.font(size: 14))
                            .foregroundColor(Paper.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        if let feast {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(Paper.gold)
                                    .font(.system(size: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.pick(hy: "Մոտակա տոնը", ru: "Ближайший праздник", en: "Next feast"))
                                        .font(PaperFont.font(size: 10, weight: .semibold))
                                        .foregroundColor(Paper.inkTertiary)
                                        .tracking(1.0)
                                    Text("\(feast.title(for: language)) · \(feast.formattedDate(for: language))")
                                        .font(PaperFont.font(size: 13, weight: .medium))
                                        .foregroundColor(Paper.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        if let verse {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(verse.text)
                                    .font(PaperFont.font(size: 14).italic())
                                    .foregroundColor(Paper.ink)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(verse.reference)
                                    .font(PaperFont.font(size: 12, weight: .semibold))
                                    .foregroundColor(Paper.cinnabar)
                            }
                            .padding(.leading, 12)
                            .overlay(alignment: .leading) {
                                Rectangle().fill(Paper.gold.opacity(0.7)).frame(width: 2)
                            }
                        }
                }

                FittedScrollView(maxHeight: UIScreen.main.bounds.height * 0.36) {
                    content
                }

                HStack(spacing: 10) {
                    cardButton(icon: "map", title: language.pick(hy: "Երթուղի", ru: "Маршрут", en: "Directions")) {
                        openInMaps(site)
                    }
                    if let verse {
                        cardButton(icon: "scroll", title: language.pick(hy: "Ձեռագրի վրա", ru: "На рукопись", en: "To manuscript")) {
                            Haptics.impact(.soft)
                            let page = ManuscriptPage(
                                text: verse.text,
                                reference: verse.reference,
                                language: language,
                                style: ManuscriptPage.preferredStyle,
                                name: ManuscriptPage.rememberedName
                            )
                            manuscriptLaunch = ManuscriptLaunch(source: .curated(first: page))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Paper.sheet)
                .shadow(color: Paper.shadow, radius: 18, x: 0, y: -4)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Paper.hairline, lineWidth: 1))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }

    private var lockedBlock: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 22))
                .foregroundColor(Paper.gold)
            Text(language.pick(
                hy: "Այս սրբավայրը բաց է Premium-ով: Անվճար են Էջմիածինը, Խոր Վիրապը, Գեղարդը և Տաթևը:",
                ru: "Эта святыня открыта с Premium. Бесплатно доступны Эчмиадзин, Хор Вирап, Гегард и Татев.",
                en: "This sanctuary opens with Premium. Etchmiadzin, Khor Virap, Geghard and Tatev are free."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            Button {
                Haptics.impact(.soft)
                isShowingPaywall = true
            } label: {
                Text(language.pick(hy: "Բացել Premium", ru: "Открыть Premium", en: "Unlock Premium"))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(Paper.onAccent)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Paper.cinnabar))
            }
            .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.95))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func cardButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(Paper.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.fillSubtle))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Paper.hairline, lineWidth: 1))
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.95))
    }

    // MARK: Действия
    private func select(_ site: Sanctuary) {
        withAnimation(PaperMotion.appear) {
            selected = site
            region = MKCoordinateRegion(
                // Центр ниже святыни: пин поднимается над карточкой (у закрытой святыни карточка ниже)
                center: CLLocationCoordinate2D(latitude: site.latitude - (isLocked(site) ? 0.05 : 0.105), longitude: site.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
            )
        }
    }

    private func openInMaps(_ site: Sanctuary) {
        Haptics.impact(.soft)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: site.coordinate))
        item.name = site.name(language)
        item.openInMaps()
    }

    /// Аргументы запуска для скриншотов в CI: -sanctuary_select khor_virap -sanctuary_mode list
    private func runLaunchArguments() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "sanctuary_mode") == "list" {
            mode = .list
        }
        if let id = defaults.string(forKey: "sanctuary_select"), let site = SanctuaryCatalog.site(id: id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if mode == .list { mode = .map }
                select(site)
            }
        }
    }
}

// MARK: - Пин на карте
struct SanctuaryPin: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(isSelected ? Paper.cinnabar : Paper.sheet)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .overlay(Circle().strokeBorder(Paper.gold, lineWidth: isSelected ? 2 : 1.5))
                    .shadow(color: Paper.shadow, radius: 4, y: 2)
                Image(systemName: "cross.fill")
                    .font(.system(size: isSelected ? 15 : 11, weight: .regular))
                    .foregroundColor(isSelected ? Paper.onAccent : Paper.gold)
            }
            if isSelected {
                Text(title)
                    .font(PaperFont.font(size: 11, weight: .semibold))
                    .foregroundColor(Paper.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Paper.sheet.opacity(0.95)))
                    .overlay(Capsule().strokeBorder(Paper.hairline, lineWidth: 1))
                    .fixedSize()
            }
        }
        .animation(PaperMotion.animation(PaperMotion.press), value: isSelected)
    }
}

// MARK: - Карточка на главном экране
struct SanctuaryMapBannerCardView: View {
    let language: AppLanguage
    let secondaryAccentColor: Color
    let primaryTextColor: Color
    let onOpen: () -> Void

    @ObservedObject private var subscription = SubscriptionManager.shared

    var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: 16) {
                PaperIconBadge(tint: Paper.gold) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 19, weight: .light))
                        .foregroundColor(Paper.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(language.pick(hy: "ՍՐԲԱՎԱՅՐԵՐԻ ՔԱՐՏԵԶ", ru: "КАРТА СВЯТЫНЬ", en: "SANCTUARY MAP"))
                            .font(PaperFont.font(size: 10, weight: .semibold))
                            .foregroundColor(Paper.cinnabar)
                            .tracking(1.2)
                        if !subscription.isPremium {
                            Text("PREMIUM")
                                .font(PaperFont.font(size: 8, weight: .semibold))
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .overlay(Capsule().strokeBorder(Paper.gold.opacity(0.6), lineWidth: 0.8))
                        }
                    }
                    Text(language.pick(hy: "Վանքեր և եկեղեցիներ", ru: "Монастыри и храмы Армении", en: "Monasteries and churches of Armenia"))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(language.pick(
                        hy: "Պատմություն, տոներ և համարներ յուրաքանչյուր վայրի համար",
                        ru: "История, праздники и стихи для каждого места",
                        en: "History, feasts and verses for every place"
                    ))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(secondaryAccentColor)
                    .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
            .padding(16)
            .paperSheet(cornerRadius: 18)
            .padding(.horizontal, 20)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
    }
}

// MARK: - Прокрутка по высоте содержимого
/// Короткий текст занимает ровно свою высоту, длинный прокручивается внутри заданного максимума.
private struct FittedScrollHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FittedScrollView<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: FittedScrollHeightKey.self, value: proxy.size.height)
                    }
                )
        }
        .frame(height: min(max(contentHeight, 40), maxHeight))
        .onPreferenceChange(FittedScrollHeightKey.self) { contentHeight = $0 }
    }
}
