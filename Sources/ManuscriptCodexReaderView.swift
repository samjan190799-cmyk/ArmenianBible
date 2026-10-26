import SwiftUI

// MARK: - Читалка кодекса: том как настоящая книга
struct ManuscriptReaderLaunch: Identifiable {
    let id = UUID()
    let title: String
    let pages: [ManuscriptPage]
    let startId: UUID
}

/// Все листы тома по порядку, листаются загибом, как страницы книги. Листы не переписываются: это чтение,
/// а не мастерская. Подпись владельца стоит под листом.
struct ManuscriptCodexReaderView: View {
    let title: String
    let pages: [ManuscriptPage]

    @State private var currentId: UUID
    @State private var shareItem: ShareItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var motion = ManuscriptMotion()
    @ObservedObject private var subscription = SubscriptionManager.shared
    @AppStorage(ManuscriptPen.storageKey) private var penRaw = ManuscriptPen.defaultValue.rawValue

    private static let backdrop = ManuscriptPalette.color(0x15100B)
    private static let parchmentInk = ManuscriptPalette.color(0xF2E8CF)

    init(title: String, pages: [ManuscriptPage], startId: UUID) {
        self.title = title
        self.pages = pages
        _currentId = State(initialValue: startId)
    }

    private var language: AppLanguage { BibleManager.shared.appLanguage }
    private var currentIndex: Int { pages.firstIndex { $0.id == currentId } ?? 0 }
    private var currentPage: ManuscriptPage { pages[min(currentIndex, pages.count - 1)] }

    /// Выбранное перо; если Premium закончился, платное перо заменяется бесплатным
    private var pen: ManuscriptPen {
        let chosen = ManuscriptPen(rawValue: penRaw) ?? ManuscriptPen.defaultValue
        return chosen.isFree || subscription.isPremium ? chosen : ManuscriptPen.defaultValue
    }

    var body: some View {
        ZStack {
            Self.backdrop.ignoresSafeArea()
            RadialGradient(
                colors: [ManuscriptPalette.color(0xC1902F, 0.22), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                GeometryReader { geo in
                    let scale = min(geo.size.width / ManuscriptGeometry.size.width, geo.size.height / ManuscriptGeometry.size.height)
                    ManuscriptCurlPager(ids: pages.map(\.id), currentId: $currentId, refreshToken: "") { id, isCurrent in
                        pageView(id, isCurrent: isCurrent, scale: scale)
                    }
                    .frame(width: ManuscriptGeometry.size.width * scale, height: ManuscriptGeometry.size.height * scale)
                    .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.vertical, 6)

                // Подпись владельца; место под неё занято всегда, чтобы лист не прыгал при перелистывании
                Text(currentPage.note ?? " ")
                    .font(PaperFont.font(size: 15))
                    .foregroundColor(Self.parchmentInk.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 40)
                    .padding(.horizontal, 24)

                Text(ManuscriptText.pick(
                    language,
                    hy: "Թերթեք էջերը գրքի պես",
                    ru: "Листайте страницы, как в книге",
                    en: "Swipe the pages like a book"
                ))
                .font(PaperFont.font(size: 12))
                .foregroundColor(Self.parchmentInk.opacity(0.55))
                .padding(.bottom, 14)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onChange(of: currentId) { _ in
            Haptics.impact(.soft)
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
    }

    // MARK: Лист
    private func pageView(_ id: UUID, isCurrent: Bool, scale: CGFloat) -> AnyView {
        guard let page = pages.first(where: { $0.id == id }) else { return AnyView(Color.clear) }
        let width = ManuscriptGeometry.size.width * scale
        let height = ManuscriptGeometry.size.height * scale
        // Блик живёт только на открытом листе; соседние под загибом неподвижны
        guard isCurrent, !reduceMotion else {
            return AnyView(
                ManuscriptPageView(page: page, reveal: .complete, sheen: CGPoint(x: 0.2, y: -0.1), pen: pen)
                    .scaleEffect(scale)
                    .frame(width: width, height: height)
            )
        }
        return AnyView(
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                ManuscriptPageView(page: page, reveal: .complete, sheen: sheen(at: timeline.date), pen: pen)
                    .scaleEffect(scale)
                    .frame(width: width, height: height)
            }
        )
    }

    private func sheen(at date: Date) -> CGPoint {
        if let tilt = motion.currentSheen() {
            return tilt
        }
        // Без датчика блик сам медленно гуляет по золоту
        let t = date.timeIntervalSinceReferenceDate
        return CGPoint(x: sin(t * 0.7) * 0.85, y: cos(t * 0.45) * 0.35)
    }

    // MARK: Шапка
    private var topBar: some View {
        HStack {
            circleButton(icon: "xmark", label: ManuscriptText.pick(language, hy: "Փակել", ru: "Закрыть", en: "Close")) {
                dismiss()
            }

            Spacer()

            VStack(spacing: 1) {
                Text(title)
                    .font(PaperFont.font(size: 17, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                Text("\(currentIndex + 1)/\(pages.count) · \(currentPage.reference)")
                    .font(PaperFont.font(size: 11))
                    .foregroundColor(Self.parchmentInk.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            circleButton(icon: "square.and.arrow.up", label: ManuscriptText.pick(language, hy: "Կիսվել", ru: "Поделиться", en: "Share")) {
                sharePage()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func circleButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Self.parchmentInk)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .accessibilityLabel(Text(label))
    }

    @MainActor
    private func sharePage() {
        guard let image = ManuscriptExport.pageImage(currentPage, pen: pen, scale: 3) else { return }
        Haptics.impact(.soft)
        shareItem = ShareItem(image: image)
    }
}
