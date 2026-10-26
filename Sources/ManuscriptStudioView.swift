import SwiftUI
import CoreMotion
import Photos

// MARK: - Наклон телефона → блик на золоте
/// Датчик опрашивается из TimelineView раз в кадр, поэтому издателю ничего публиковать не нужно.
final class ManuscriptMotion: ObservableObject {
    private let manager = CMMotionManager()
    private var reference: (roll: Double, pitch: Double)?
    private var smoothed = CGPoint.zero

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates()
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        reference = nil
    }

    /// nil — датчика нет (симулятор) или первых данных ещё нет
    func currentSheen() -> CGPoint? {
        guard let motion = manager.deviceMotion else { return nil }
        let roll = motion.attitude.roll
        let pitch = motion.attitude.pitch
        var ref = reference ?? (roll: roll, pitch: pitch)
        // Середина медленно подстраивается под то, как человек держит телефон
        ref.roll += (roll - ref.roll) * 0.004
        ref.pitch += (pitch - ref.pitch) * 0.004
        reference = ref
        let target = CGPoint(
            x: max(-1, min(1, (roll - ref.roll) / 0.45)),
            y: max(-1, min(1, (pitch - ref.pitch) / 0.45))
        )
        smoothed.x += (target.x - smoothed.x) * 0.2
        smoothed.y += (target.y - smoothed.y) * 0.2
        return smoothed
    }
}

// MARK: - Мастерская рукописи
struct ManuscriptStudioView: View {
    @State private var pages: [ManuscriptPage]
    @State private var currentId: UUID
    @State private var style: ManuscriptStyle
    @State private var surface: ManuscriptSurface
    private let isEndless: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var library = ManuscriptLibrary.shared
    @StateObject private var motion = ManuscriptMotion()
    @AppStorage("luys_manuscript_name") private var name = ""
    @AppStorage(ManuscriptWritingSpeed.storageKey) private var writingSpeedRaw = ManuscriptWritingSpeed.defaultValue.rawValue
    @AppStorage(ManuscriptPen.storageKey) private var penRaw = ManuscriptPen.defaultValue.rawValue
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var isShowingPens = false
    @State private var isShowingSurfaces = false

    @State private var startDate = Date()
    @State private var isTurned: Bool
    @State private var isEditingName = false
    @State private var nameDraft = ""
    @State private var shareItem: ShareItem?
    @State private var toast: String?
    @State private var isShowingLibrary = false
    @State private var animationToken = UUID()

    /// Для скриншотов в CI: застывшая секунда анимации (аргумент запуска -manuscript_time 3.5)
    private let frozenTime: Double? = {
        let value = UserDefaults.standard.double(forKey: "manuscript_time")
        return value > 0 ? value : nil
    }()
    init(source: ManuscriptSource) {
        // Для скриншотов в CI: показать лист так, как он пишется после перелистывания (-manuscript_turned YES)
        _isTurned = State(initialValue: UserDefaults.standard.bool(forKey: "manuscript_turned"))
        switch source {
        case .curated(let first):
            let more = ManuscriptPool.curatedPages(language: first.language, excluding: [first.reference], count: 24)
            _pages = State(initialValue: [first] + more)
            _currentId = State(initialValue: first.id)
            _style = State(initialValue: first.style)
            _surface = State(initialValue: first.surface)
            isEndless = true
        case .chapter(let chapterPages, let startId):
            _pages = State(initialValue: chapterPages)
            _currentId = State(initialValue: startId)
            _style = State(initialValue: chapterPages.first?.style ?? .roslin)
            _surface = State(initialValue: chapterPages.first?.surface ?? .parchment)
            isEndless = false
        }
    }

    init(page: ManuscriptPage) {
        self.init(source: .curated(first: page))
    }

    private var currentIndex: Int { pages.firstIndex { $0.id == currentId } ?? 0 }
    private var currentPage: ManuscriptPage { styled(pages[min(currentIndex, pages.count - 1)]) }
    private var language: AppLanguage { currentPage.language }

    /// Стиль, основа и имя общие для всех страниц: так листы складываются в один кодекс
    private func styled(_ page: ManuscriptPage) -> ManuscriptPage {
        styled(page, look: (style: style, name: name, surface: activeSurface))
    }

    private func styled(_ page: ManuscriptPage, look: (style: ManuscriptStyle, name: String, surface: ManuscriptSurface)) -> ManuscriptPage {
        var result = page
        result.style = look.style
        result.name = look.name
        result.surface = look.surface
        return result
    }

    /// К следующему листу (для CI и на случай кнопки «дальше» в будущем)
    private func advance() {
        guard currentIndex + 1 < pages.count else { return }
        withAnimation { currentId = pages[currentIndex + 1].id }
    }

    private static let backdrop = ManuscriptPalette.color(0x15100B)
    private static let parchmentInk = ManuscriptPalette.color(0xF2E8CF)

    var body: some View {
        // Всё, от чего зависит рисунок листа, читаем здесь, чтобы лента гарантированно обновлялась
        let turned = isTurned
        let started = startDate
        let look = (style: style, name: name, surface: activeSurface)
        return ZStack {
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
                    // Лист перелистывается, как страница книги: загибается у края, под ним следующий
                    ManuscriptCurlPager(
                        ids: pages.map(\.id),
                        currentId: $currentId,
                        refreshToken: "\(look.style.rawValue)|\(look.surface.rawValue)|\(look.name)"
                    ) { id, isCurrent in
                        guard let raw = pages.first(where: { $0.id == id }) else { return AnyView(Color.clear) }
                        return AnyView(pageContent(raw, isCurrent: isCurrent, scale: scale, turned: turned, started: started, look: look))
                    }
                    .frame(width: ManuscriptGeometry.size.width * scale, height: ManuscriptGeometry.size.height * scale)
                    .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.vertical, 6)

                Text(motionHint)
                    .font(PaperFont.font(size: 12))
                    .foregroundColor(Self.parchmentInk.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                stylePicker
                    .padding(.bottom, 12)
                actionRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            if let toast {
                VStack {
                    Text(toast)
                        .font(PaperFont.font(size: 14, weight: .semibold))
                        .foregroundColor(Self.backdrop)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Self.parchmentInk))
                        .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
                        .padding(.top, 64)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Funnel.track("feature_used", ["feature": "manuscript"])
            motion.start()
            scheduleHaptics()
            exportForTestsIfNeeded()
            // Для CI: имитация свайпа к следующему листу (-manuscript_autoswipe YES)
            if UserDefaults.standard.bool(forKey: "manuscript_autoswipe") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { advance() }
            }
        }
        .onDisappear {
            motion.stop()
        }
        .onChange(of: currentId) { _ in
            // Новый лист: рамка и заставка остаются, текст пишется заново
            isTurned = true
            startDate = Date()
            scheduleHaptics()
            extendIfNeeded()
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .sheet(isPresented: $isShowingLibrary) {
            ManuscriptLibraryView { opened in
                open(opened)
            }
        }
        .sheet(isPresented: $isShowingPens) {
            ManuscriptPenSheet(language: language, selectedRaw: $penRaw)
        }
        .sheet(isPresented: $isShowingSurfaces) {
            ManuscriptSurfaceSheet(language: language, selection: surfaceSelection)
        }
        .onChange(of: penRaw) { _ in
            // Новое перо сразу пишет страницу заново: видно и перо, и чернила
            restart()
        }

        .alert(
            language.pick(hy: "Անուն հիշատակարանի համար", ru: "Имя для памятной записи", en: "Name for the colophon"),
            isPresented: $isEditingName
        ) {
            TextField(language.pick(hy: "Ձեր անունը", ru: "Ваше имя", en: "Your name"), text: $nameDraft)
            Button(language.pick(hy: "Պատրաստ է", ru: "Готово", en: "Done")) {
                applyName(nameDraft)
            }
            Button(language.pick(hy: "Չեղարկել", ru: "Отмена", en: "Cancel"), role: .cancel) {}
        } message: {
            Text(language.pick(
                hy: "Ձեռագրի վերջում գրիչը խնդրում էր հիշել իրեն աղոթքում: Ձեր անունը կգրվի էջի ներքևում:",
                ru: "В конце армянской рукописи переписчик просил помянуть его в молитве. Ваше имя появится внизу страницы.",
                en: "Armenian scribes closed a manuscript asking to be remembered in prayer. Your name will appear at the foot of the page."
            ))
        }
    }

    // MARK: Лист книги
    @ViewBuilder
    private func pageContent(_ raw: ManuscriptPage, isCurrent: Bool, scale: CGFloat, turned: Bool, started: Date,
                             look: (style: ManuscriptStyle, name: String, surface: ManuscriptSurface)) -> some View {
        if isCurrent {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let page = styled(raw, look: look)
                let length = ManuscriptTextLayout.cached(for: page, pen: activePen).length
                let elapsed = frozenTime ?? timeline.date.timeIntervalSince(started)
                let reveal = reduceMotion ? ManuscriptReveal.complete : ManuscriptReveal.at(time: elapsed, textLength: length, turned: turned, speed: writingSpeed)
                pageFrame(page: page, reveal: reveal, sheen: sheen(at: timeline.date), scale: scale)
            }
            .contentShape(Rectangle())
            .onTapGesture { restart() }
        } else {
            // Следующий лист виден под загибом: чистый пергамент с рамкой, текст допишется после остановки
            pageFrame(
                page: styled(raw, look: look),
                reveal: reduceMotion ? ManuscriptReveal.complete : ManuscriptReveal.leaf,
                sheen: CGPoint(x: 0.2, y: -0.1),
                scale: scale
            )
        }
    }

    private func pageFrame(page: ManuscriptPage, reveal: ManuscriptReveal, sheen: CGPoint, scale: CGFloat) -> some View {
        ManuscriptPageView(page: page, reveal: reveal, sheen: sheen, pen: activePen)
            .scaleEffect(scale)
            .frame(width: ManuscriptGeometry.size.width * scale, height: ManuscriptGeometry.size.height * scale)
    }

    // MARK: Шапка
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))

            // Основа слева, перо и «Матенадаран» справа: по две кнопки с каждой стороны, заголовок по центру
            Button {
                Haptics.impact(.soft)
                isShowingSurfaces = true
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Էջի հիմք", ru: "Основа листа", en: "Page surface")))

            Spacer()

            VStack(spacing: 1) {
                Text(language.pick(hy: "Ձեռագիր", ru: "Рукопись", en: "Manuscript"))
                    .font(PaperFont.font(size: 17, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                Text(isEndless ? currentPage.reference : "\(currentPage.reference) · \(currentIndex + 1)/\(pages.count)")
                    .font(PaperFont.font(size: 11))
                    .foregroundColor(Self.parchmentInk.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Haptics.impact(.soft)
                isShowingPens = true
            } label: {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Գրիչ", ru: "Перо", en: "Pen")))

            Button {
                Haptics.impact(.soft)
                isShowingLibrary = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Self.parchmentInk)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                    if !library.pages.isEmpty {
                        Text("\(library.pages.count)")
                            .font(PaperFont.font(size: 9, weight: .semibold))
                            .foregroundColor(Self.backdrop)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 15, minHeight: 15)
                            .background(Capsule().fill(Paper.gold))
                            .offset(x: 3, y: -2)
                    }
                }
            }
            .accessibilityLabel(Text(language.pick(hy: "Իմ Մատենադարանը", ru: "Мой Матенадаран", en: "My Matenadaran")))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var motionHint: String {
        language.pick(
            hy: "Թերթեք՝ նոր համարների համար · թեքեք հեռախոսը՝ ոսկին կկենդանանա · հպեք՝ նորից գրելու համար",
            ru: "Листайте — новые стихи · наклоните телефон — золото оживёт · нажмите, чтобы переписать",
            en: "Swipe for new verses · tilt your phone — the gold comes alive · tap to write again"
        )
    }

    // MARK: Выбор стиля
    private var stylePicker: some View {
        HStack(spacing: 10) {
            ForEach(ManuscriptStyle.allCases) { option in
                let isSelected = option == style
                Button {
                    guard option != style else { return }
                    Haptics.selection()
                    style = option
                    UserDefaults.standard.set(option.rawValue, forKey: "luys_manuscript_style")
                    if library.contains(currentPage) { library.save(currentPage) }
                } label: {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(ManuscriptPalette.color(option.palette.field))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(ManuscriptPalette.color(option.palette.goldLight), lineWidth: 1.5))
                        Text(option.title(for: language))
                            .font(PaperFont.font(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(Self.parchmentInk.opacity(isSelected ? 1 : 0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(isSelected ? 0.12 : 0.05)))
                    .overlay(Capsule().strokeBorder(isSelected ? Paper.gold.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.94))
            }
        }
    }

    // MARK: Действия
    private var actionRow: some View {
        let isSaved = library.contains(currentPage)
        return HStack(spacing: 10) {
            actionButton(
                icon: "signature",
                title: language.pick(hy: "Անուն", ru: "Имя", en: "Name")
            ) {
                nameDraft = name
                isEditingName = true
            }
            actionButton(
                icon: isSaved ? "checkmark" : "books.vertical",
                title: isSaved
                    ? language.pick(hy: "Պահված է", ru: "Сохранено", en: "Saved")
                    : language.pick(hy: "Պահել", ru: "Сохранить", en: "Save")
            ) {
                saveToLibrary()
            }
            actionButton(
                icon: "square.and.arrow.up",
                title: language.pick(hy: "Կիսվել", ru: "Поделиться", en: "Share")
            ) {
                if let image = renderImage() {
                    Haptics.impact(.soft)
                    shareItem = ShareItem(image: image)
                }
            }
            actionButton(
                icon: "square.and.arrow.down",
                title: language.pick(hy: "Լուսանկարներ", ru: "В Фото", en: "Photos")
            ) {
                saveToPhotos()
            }
        }
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Paper.gold)
                    .frame(height: 20)
                Text(title)
                    .font(PaperFont.font(size: 11, weight: .medium))
                    .foregroundColor(Self.parchmentInk.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.94))
    }

    // MARK: Логика
    private func sheen(at date: Date) -> CGPoint {
        if frozenTime != nil {
            return CGPoint(x: 0.1, y: -0.2)
        }
        if let tilt = motion.currentSheen() {
            return tilt
        }
        // Без датчика (симулятор, iPad на подставке) блик сам медленно гуляет по золоту
        let t = date.timeIntervalSinceReferenceDate
        return CGPoint(x: sin(t * 0.7) * 0.85, y: cos(t * 0.45) * 0.35)
    }

    /// Выбранное перо; если Premium закончился, платное перо заменяется бесплатным
    private var activePen: ManuscriptPen {
        let chosen = ManuscriptPen(rawValue: penRaw) ?? ManuscriptPen.defaultValue
        return chosen.isFree || subscription.isPremium ? chosen : ManuscriptPen.defaultValue
    }

    /// Выбранная основа; если Premium закончился, платная заменяется пергаментом
    private var activeSurface: ManuscriptSurface {
        surface.isFree || subscription.isPremium ? surface : .parchment
    }

    /// Выбор основы в листе. Запоминается и пишет страницу заново только тогда, когда основу выбрал человек,
    /// а не когда лист из «Матенадарана» принёс свою
    private var surfaceSelection: Binding<ManuscriptSurface> {
        Binding(
            get: { surface },
            set: { chosen in
                guard chosen != surface else { return }
                surface = chosen
                UserDefaults.standard.set(chosen.rawValue, forKey: ManuscriptSurface.storageKey)
                if library.contains(currentPage) { library.save(currentPage) }
                restart()
            }
        )
    }

    private var writingSpeed: ManuscriptWritingSpeed {
        ManuscriptWritingSpeed(rawValue: writingSpeedRaw) ?? ManuscriptWritingSpeed.defaultValue
    }

    private func restart() {
        isTurned = false
        startDate = Date()
        scheduleHaptics()
    }

    private func scheduleHaptics() {
        guard !reduceMotion, frozenTime == nil else { return }
        let token = UUID()
        animationToken = token
        let length = ManuscriptTextLayout.cached(for: currentPage, pen: activePen).length
        let turned = isTurned
        let finish = ManuscriptReveal.totalDuration(textLength: length, turned: turned, speed: writingSpeed) - 0.3
        let firstTick = turned ? 0.3 : 1.6
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTick) {
            if animationToken == token { Haptics.impact(.soft) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + finish) {
            if animationToken == token { Haptics.notify(.success) }
        }
    }

    /// Пока листаешь к концу ленты, подкладываем новые стихи
    private func extendIfNeeded() {
        guard isEndless, currentIndex >= pages.count - 4 else { return }
        let existing = Set(pages.map { $0.reference })
        let more = ManuscriptPool.curatedPages(language: language, excluding: existing, count: 20)
        guard !more.isEmpty else { return }
        pages.append(contentsOf: more)
    }

    /// Страница из «Матенадарана»: открывается первой, дальше снова новые стихи
    private func open(_ opened: ManuscriptPage) {
        let more = ManuscriptPool.curatedPages(language: opened.language, excluding: [opened.reference], count: 24)
        style = opened.style
        surface = opened.surface
        pages = [opened] + more
        currentId = opened.id
        isTurned = false
        startDate = Date()
        scheduleHaptics()
    }

    private func applyName(_ draft: String) {
        let trimmed = String(draft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        name = trimmed
        if library.contains(currentPage) { library.save(currentPage) }
        Haptics.impact(.soft)
    }

    private func saveToLibrary() {
        let page = currentPage
        let wasSaved = library.contains(page)
        library.save(page)
        guard !wasSaved else { return }
        let count = library.pages.count
        if count == ManuscriptLibrary.codexSize {
            Haptics.notify(.success)
            showToast(language.pick(hy: "Կոդեքսը կազմված է", ru: "Кодекс переплетён!", en: "Your codex is bound!"))
        } else {
            Haptics.impact(.soft)
            let progress = "\(min(count, ManuscriptLibrary.codexSize))/\(ManuscriptLibrary.codexSize)"
            showToast(language.pick(
                hy: "Պահվեց Մատենադարանում · \(progress)",
                ru: "Сохранено в Матенадаран · \(progress)",
                en: "Saved to your Matenadaran · \(progress)"
            ))
        }
    }

    private func saveToPhotos() {
        guard let image = renderImage() else { return }
        let savedText = language.pick(hy: "Պահվեց Լուսանկարներում", ru: "Сохранено в Фото", en: "Saved to Photos")
        let deniedText = language.pick(
            hy: "Թույլատրեք մուտքը Լուսանկարներ՝ Կարգավորումներում",
            ru: "Разрешите доступ к Фото в Настройках",
            en: "Allow Photos access in Settings"
        )
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { showToast(deniedText) }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { Haptics.notify(.success) }
                    showToast(success ? savedText : deniedText)
                }
            })
        }
    }

    private func showToast(_ text: String) {
        withAnimation(PaperMotion.appear) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toast == text {
                withAnimation(PaperMotion.swap) { toast = nil }
            }
        }
    }

    /// Картинка 1080×1920 для сторис и фотоальбома: готовая страница, золото с бликом, подпись Luys
    @MainActor
    private func renderImage() -> UIImage? {
        let content = ManuscriptPageView(page: currentPage, reveal: .complete, sheen: CGPoint(x: 0.18, y: -0.12), showsWatermark: true, pen: activePen)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        if let image = renderer.uiImage {
            return image
        }
        let host = UIHostingController(rootView: content)
        host.view.frame = CGRect(origin: .zero, size: ManuscriptGeometry.size)
        host.view.backgroundColor = .clear
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        return UIGraphicsImageRenderer(size: ManuscriptGeometry.size, format: format).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Для CI: сохраняет экспортную картинку в Documents, чтобы её можно было забрать с симулятора
    private func exportForTestsIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "manuscript_export_test") else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let data = renderImage()?.pngData(),
                  let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            try? data.write(to: folder.appendingPathComponent("manuscript_export_test.png"), options: .atomic)
        }
    }
}

// MARK: - Страница для скриншотов в CI
extension ManuscriptPage {
    /// Аргументы запуска: -manuscript_language russian -manuscript_style cilicia -manuscript_name Самвел
    /// -manuscript_verse long -manuscript_source chapter (Иоанна 3: лента стихов главы)
    static func debugSource(fallbackLanguage: AppLanguage) -> ManuscriptSource {
        let defaults = UserDefaults.standard
        let language = defaults.string(forKey: "manuscript_language").flatMap(AppLanguage.init(rawValue:)) ?? fallbackLanguage
        let style = defaults.string(forKey: "manuscript_style").flatMap(ManuscriptStyle.init(rawValue:)) ?? .roslin
        let surface = defaults.string(forKey: "manuscript_surface").flatMap(ManuscriptSurface.init(rawValue:)) ?? .parchment
        if let name = defaults.string(forKey: "manuscript_name") {
            defaults.set(name, forKey: "luys_manuscript_name")
        }
        if defaults.string(forKey: "manuscript_source") == "chapter",
           let book = BibleDatabase.shared.getBook(id: 43),
           let source = ManuscriptPool.chapterSource(book: book, chapter: 3, startVerse: 16, language: language, style: style, surface: surface) {
            return source
        }
        // -manuscript_verse long — длинный стих, чтобы проверить плотную страницу
        let wantsLong = defaults.string(forKey: "manuscript_verse") == "long"
        let longVerse = BibleVerse.database.min { abs($0.text(for: language).count - 240) < abs($1.text(for: language).count - 240) }
        let verse = (wantsLong ? longVerse : nil) ?? BibleVerse.shortPearls.first ?? BibleManager.shared.currentVerse
        var page = ManuscriptPage.from(verse: verse, language: language)
        page.style = style
        page.surface = surface
        return .curated(first: page)
    }
}

// MARK: - «Матенадаран»: собранные страницы и будущий кодекс
struct ManuscriptLibraryView: View {
    @ObservedObject private var library = ManuscriptLibrary.shared
    @Environment(\.dismiss) private var dismiss
    let onOpen: (ManuscriptPage) -> Void

    private var language: AppLanguage { BibleManager.shared.appLanguage }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    codexHeader
                    if library.pages.isEmpty {
                        Text(ManuscriptText.pick(
                            language,
                            hy: "Այստեղ կպահվեն ձեր ձեռագիր էջերը: Ստեղծեք առաջինը ցանկացած համարից:",
                            ru: "Здесь будут храниться ваши рукописные страницы. Создайте первую из любого стиха.",
                            en: "Your manuscript pages will be kept here. Create the first one from any verse."
                        ))
                        .font(PaperFont.font(size: 15))
                        .foregroundColor(Paper.inkSecondary)
                        .padding(.top, 20)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                            ForEach(library.pages) { page in
                                Button {
                                    onOpen(page)
                                    dismiss()
                                } label: {
                                    thumbnail(page)
                                }
                                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
                                .contextMenu {
                                    Button(role: .destructive) {
                                        library.delete(page)
                                    } label: {
                                        Label(ManuscriptText.pick(language, hy: "Ջնջել", ru: "Удалить", en: "Delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(PaperBackground())
            .navigationTitle(ManuscriptText.pick(language, hy: "Իմ Մատենադարանը", ru: "Мой Матенадаран", en: "My Matenadaran"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Paper.inkSecondary)
                    }
                }
            }
        }
    }

    private var codexHeader: some View {
        let count = library.pages.count
        let total = ManuscriptLibrary.codexSize
        return HStack(spacing: 14) {
            ManuscriptCodexCover(isBound: library.isCodexBound)
                .frame(width: 52, height: 68)
            VStack(alignment: .leading, spacing: 6) {
                Text(library.isCodexBound
                     ? ManuscriptText.pick(language, hy: "Կոդեքսը կազմված է", ru: "Кодекс переплетён", en: "Codex bound")
                     : ManuscriptText.pick(language, hy: "Ձեր կոդեքսը", ru: "Ваш кодекс", en: "Your codex"))
                    .font(PaperFont.font(size: 17, weight: .semibold))
                    .foregroundColor(Paper.ink)
                Text(library.isCodexBound
                     ? ManuscriptText.pick(language, hy: "\(count) էջ", ru: "\(count) стр.", en: "\(count) pages")
                     : ManuscriptText.pick(
                        language,
                        hy: "\(count) էջ · մինչև կազմը՝ \(total - count)",
                        ru: "\(count) стр. · до переплёта: \(total - count)",
                        en: "\(count) pages · \(total - count) to bind it"
                     ))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(Paper.inkSecondary)
                ProgressView(value: Double(min(count, total)), total: Double(total))
                    .tint(Paper.gold)
            }
        }
        .padding(16)
        .paperSheet(cornerRadius: 18)
    }

    private func thumbnail(_ page: ManuscriptPage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ManuscriptPageView(page: page)
                    .scaleEffect(geo.size.width / ManuscriptGeometry.size.width, anchor: .topLeading)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .aspectRatio(ManuscriptGeometry.size.width / ManuscriptGeometry.size.height, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: Paper.shadow, radius: 8, x: 0, y: 4)
            Text(page.reference)
                .font(PaperFont.font(size: 12, weight: .semibold))
                .foregroundColor(Paper.ink)
                .lineLimit(1)
            Text(page.createdAt, style: .date)
                .font(PaperFont.font(size: 11))
                .foregroundColor(Paper.inkTertiary)
        }
    }
}

// MARK: - Переплёт кодекса: кожа, золотая рама, крест и наугольники
struct ManuscriptCodexCover: View {
    let isBound: Bool

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let leather = isBound ? ManuscriptPalette.color(0x5A2E1C) : ManuscriptPalette.color(0x8A7A68, 0.35)
            context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(leather))
            let gold = ManuscriptGold(palette: .roslin, sheen: CGPoint(x: 0.1, y: -0.3))
            let goldShading: GraphicsContext.Shading = isBound ? gold.shading : .color(ManuscriptPalette.color(0x8A7A68, 0.7))
            context.stroke(Path(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 2), with: goldShading, lineWidth: 1)
            let scale = size.width / 52
            let cross = ManuscriptRenderer.blossomCross(center: CGPoint(x: rect.midX, y: rect.midY), size: 26 * scale)
            context.fill(cross, with: goldShading)
            for corner in [CGPoint(x: 8, y: 8), CGPoint(x: size.width - 8, y: 8),
                           CGPoint(x: 8, y: size.height - 8), CGPoint(x: size.width - 8, y: size.height - 8)] {
                context.fill(Path(ellipseIn: CGRect(x: corner.x - 2.2, y: corner.y - 2.2, width: 4.4, height: 4.4)), with: goldShading)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Карточка на главном экране: «Мой Матенадаран»
/// Стих дня на главной уже есть в верхней карточке (там же кнопка «На пергаменте»), поэтому эта
/// карточка не повторяет его, а ведёт к собранным листам и к новому листу.
struct ManuscriptBannerCardView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    /// Открыть собранные листы (когда они есть)
    let onOpenCodex: () -> Void
    /// Открыть мастерскую на новом случайном листе
    let onNewLeaf: () -> Void

    @ObservedObject private var library = ManuscriptLibrary.shared
    @State private var samplePage: ManuscriptPage?

    private var thumbnailPage: ManuscriptPage? { library.pages.first ?? samplePage }

    private var subtitle: String {
        let count = library.pages.count
        let total = ManuscriptLibrary.codexSize
        if count == 0 {
            return ManuscriptText.pick(
                language,
                hy: "Դեռ դատարկ է. բացեք համարը մագաղաթի վրա և պահեք էջը",
                ru: "Пока пусто. Откройте стих на пергаменте и сохраните лист",
                en: "Nothing yet. Open a verse on vellum and save the page"
            )
        }
        if library.isCodexBound {
            return ManuscriptText.pick(
                language,
                hy: "Կոդեքսը կազմված է · \(count) էջ",
                ru: "Кодекс переплетён · \(count) стр.",
                en: "Codex bound · \(count) pages"
            )
        }
        return ManuscriptText.pick(
            language,
            hy: "\(count) էջ · մինչև կազմը՝ \(total - count)",
            ru: "\(count) стр. · до переплёта: \(total - count)",
            en: "\(count) pages · \(total - count) to bind it"
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if library.pages.isEmpty { onNewLeaf() } else { onOpenCodex() }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ManuscriptPalette.color(0x15100B))
                            .frame(width: 68, height: 68)
                        if let page = thumbnailPage {
                            ManuscriptPageView(page: page, sheen: CGPoint(x: 0.25, y: -0.2))
                                .scaleEffect(60 / ManuscriptGeometry.size.height)
                                .frame(width: ManuscriptGeometry.size.width * 60 / ManuscriptGeometry.size.height, height: 60)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(ManuscriptText.pick(language, hy: "ՁԵՌԱԳԻՐ", ru: "РУКОПИСЬ", en: "MANUSCRIPT"))
                                .font(PaperFont.font(size: 10, weight: .semibold))
                                .foregroundColor(Paper.cinnabar)
                                .tracking(1.2)
                            if library.pages.isEmpty {
                                Text(ManuscriptText.pick(language, hy: "ՆՈՐ", ru: "НОВОЕ", en: "NEW"))
                                    .font(PaperFont.font(size: 8, weight: .semibold))
                                    .foregroundColor(Paper.gold)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .overlay(Capsule().strokeBorder(Paper.gold.opacity(0.6), lineWidth: 0.8))
                            } else {
                                Text("\(library.pages.count)/\(ManuscriptLibrary.codexSize)")
                                    .font(PaperFont.font(size: 8, weight: .semibold))
                                    .foregroundColor(Paper.inkSecondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .overlay(Capsule().strokeBorder(Paper.hairline, lineWidth: 0.8))
                            }
                        }
                        Text(ManuscriptText.pick(language, hy: "Իմ Մատենադարանը", ru: "Мой Матенадаран", en: "My Matenadaran"))
                            .font(PaperFont.font(size: 17, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text(subtitle)
                            .font(PaperFont.font(size: 12))
                            .foregroundColor(Paper.inkSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.97))

            if library.pages.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            } else {
                // Новый лист: случайный стих на пергаменте, не стих дня
                Button {
                    onNewLeaf()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Paper.gold)
                        .frame(width: 36, height: 36)
                        .background(Circle().strokeBorder(Paper.gold.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.9))
                .accessibilityLabel(Text(ManuscriptText.pick(language, hy: "Նոր էջ", ru: "Новый лист", en: "New page")))
            }
        }
        .padding(14)
        .paperSheet(cornerRadius: 18)
        .padding(.horizontal, 20)
        .onAppear {
            if samplePage == nil {
                samplePage = ManuscriptPool.curatedPages(language: language, excluding: [], count: 1).first
            }
        }
    }
}
