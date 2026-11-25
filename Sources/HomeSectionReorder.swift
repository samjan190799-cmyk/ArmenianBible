import SwiftUI
import UIKit

// MARK: - Перестановка разделов главного экрана за ручку
// В правом верхнем углу каждой карточки стоят три точки. Если подержать на них палец и повести,
// карточка поднимается целиком (в полный размер, чуть крупнее, с тенью), идёт за пальцем, остальные
// расступаются, а у края экрана список сам прокручивается. Отпустили: карточка мягко садится на место.
// Порядок хранится как раньше (HomeSectionOrder.storageKey, идентификаторы через запятую).

// MARK: - Числа перетаскивания в одном месте
enum HomeSectionLayout {
    /// Промежуток между карточками: тот же, что у колонки на главном экране
    static let spacing: CGFloat = 24
    /// Боковое поле карточки. Оно уже входит в рамку каждой карточки (`.padding(.horizontal, 20)` у всех карточек)
    static let cardInset: CGFloat = 20
    /// Сторона области нажатия ручки (не меньше 44 pt)
    static let handleSide: CGFloat = 44
    /// Область нажатия чуть выше верхнего края карточки: точки стоят у самого угла, а кнопка «+» на карточке рукописи не закрыта
    static let handleRise: CGFloat = -10
    /// Сколько подержать палец на ручке, чтобы карточка поднялась
    static let holdDuration: Double = 0.15
    /// На сколько палец может уйти за это время: дальше это уже листание, а не «взять карточку»
    static let holdTolerance: CGFloat = 10
    /// Увеличение поднятой карточки
    static let liftScale: CGFloat = 1.03
    /// Полоса у края экрана, в которой список прокручивается сам
    static let edgeZone: CGFloat = 100
    /// Самая быстрая прокрутка у края, pt в секунду
    static let maxScrollSpeed: CGFloat = 900
    /// Сколько карточка садится на место, прежде чем настоящая карточка снова станет видимой
    static let landingDelay: Double = 0.42

    /// Остальные карточки расступаются
    static let reorderAnimation = Animation.spring(response: 0.34, dampingFraction: 0.86)
    /// Подъём: увеличение и тень
    static let liftAnimation = Animation.spring(response: 0.26, dampingFraction: 0.78)
    /// Посадка на место
    static let landAnimation = Animation.spring(response: 0.30, dampingFraction: 0.84)
}

// MARK: - Размеры карточек: каждая карточка сообщает свой размер колонке
private struct HomeSectionSizeKey: PreferenceKey {
    static let defaultValue: [HomeSection: CGSize] = [:]

    static func reduce(value: inout [HomeSection: CGSize], nextValue: () -> [HomeSection: CGSize]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Три точки
struct HomeSectionHandleDots: View {
    var isActive = false

    private var dotColor: Color {
        isActive ? Paper.gold : Paper.inkSecondary.opacity(0.8)
    }

    var body: some View {
        HStack(spacing: 3.5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(dotColor)
                    .frame(width: 4.5, height: 4.5)
            }
        }
        .accessibilityHidden(true)
    }
}

private extension View {
    /// Ручка стоит в правом верхнем углу карточки: боковое поле карточки учтено, область нажатия чуть выступает над верхним краем
    func homeSectionHandleCorner() -> some View {
        self
            .padding(.trailing, HomeSectionLayout.cardInset)
            .offset(y: HomeSectionLayout.handleRise)
    }
}

// MARK: - Одно касание ручки
/// Класс, а не поля вида: меняется на каждый сдвиг пальца, а перерисовывать из-за этого ручку не нужно
private final class HomeHandleTouch {
    /// Касание началось
    var isActive = false
    /// Это касание подняло карточку
    var isLifted = false
    /// Палец ушёл раньше времени: человек листает, а не берёт карточку
    var isAbandoned = false
    var fingerY: CGFloat = 0
    var translation: CGSize = .zero
    var timer: DispatchWorkItem?

    func reset() {
        timer?.cancel()
        timer = nil
        isActive = false
        isLifted = false
        isAbandoned = false
    }
}

// MARK: - Ручка: подержать и вести
/// Карточка поднимается, если палец на ручке продержался около 0,15 с почти на месте. Быстрый свайп по ручке
/// не поднимает карточку: жест подключён вместе с прокруткой экрана, а не вместо неё, поэтому экран листается как обычно.
struct HomeSectionDragHandle: View {
    let language: AppLanguage
    /// Место карточки в колонке, с нуля
    let index: Int
    let total: Int
    let isLifted: Bool
    /// Подъём: положение пальца на экране и сдвиг от места касания. true: карточка поднята
    let onLift: (CGFloat, CGFloat) -> Bool
    /// Палец двинулся: положение на экране и сдвиг от места касания (по вертикали)
    let onDrag: (CGFloat, CGFloat) -> Void
    let onDrop: () -> Void
    /// Сдвиг на одну позицию выше (-1) или ниже (+1): для VoiceOver
    let onMove: (Int) -> Void

    /// Сбрасывается сам, когда жест кончился или его отменили: по этому ловим и отмену
    @GestureState private var isTouching = false
    @State private var touch = HomeHandleTouch()

    private var grab: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isTouching) { _, state, _ in
                state = true
            }
            .onChanged { value in
                touchChanged(value)
            }
            .onEnded { _ in
                touchEnded()
            }
    }

    var body: some View {
        HomeSectionHandleDots()
            .opacity(isLifted ? 0 : 1)
            .frame(width: HomeSectionLayout.handleSide, height: HomeSectionLayout.handleSide)
            .contentShape(Rectangle())
            .simultaneousGesture(grab)
            .onChange(of: isTouching) { touching in
                if !touching { touchEnded() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(language.pick(hy: "Տեղափոխել բաժինը", ru: "Переместить раздел", en: "Move section")))
            .accessibilityValue(Text(language.pick(
                hy: "Դիրք \(index + 1)՝ \(total)-ից",
                ru: "Позиция \(index + 1) из \(total)",
                en: "Position \(index + 1) of \(total)"
            )))
            .accessibilityAction(named: Text(language.pick(hy: "Տեղափոխել վերև", ru: "Переместить выше", en: "Move up"))) {
                onMove(-1)
            }
            .accessibilityAction(named: Text(language.pick(hy: "Տեղափոխել ներքև", ru: "Переместить ниже", en: "Move down"))) {
                onMove(1)
            }
    }

    // MARK: Касание
    private func touchChanged(_ value: DragGesture.Value) {
        touch.fingerY = value.location.y
        touch.translation = value.translation

        if touch.isLifted {
            onDrag(value.location.y, value.translation.height)
            return
        }
        if touch.isAbandoned { return }

        if !touch.isActive {
            // Палец лёг на ручку: если он продержится на месте, карточка поднимется
            touch.isActive = true
            let item = DispatchWorkItem {
                liftNow()
            }
            touch.timer = item
            DispatchQueue.main.asyncAfter(deadline: .now() + HomeSectionLayout.holdDuration, execute: item)
            return
        }

        // Палец ушёл раньше времени: это листание, карточку не берём
        let drift = hypot(value.translation.width, value.translation.height)
        if drift > HomeSectionLayout.holdTolerance {
            touch.timer?.cancel()
            touch.timer = nil
            touch.isAbandoned = true
        }
    }

    private func liftNow() {
        guard touch.isActive, !touch.isLifted, !touch.isAbandoned else { return }
        touch.timer = nil
        if onLift(touch.fingerY, touch.translation.height) {
            touch.isLifted = true
        } else {
            touch.isAbandoned = true
        }
    }

    private func touchEnded() {
        let wasLifted = touch.isLifted
        touch.reset()
        if wasLifted { onDrop() }
    }
}

// MARK: - Прокрутка у края экрана
/// Находит прокрутку, внутри которой лежат карточки (ищет вверх по иерархии от невидимого помощника)
final class HomeScrollProbeView: UIView {
    var enclosingScrollView: UIScrollView? {
        var current: UIView? = superview
        while let view = current {
            if let scroll = view as? UIScrollView { return scroll }
            current = view.superview
        }
        return nil
    }
}

struct HomeScrollProbe: UIViewRepresentable {
    let engine: HomeSectionDragEngine

    func makeUIView(context: Context) -> HomeScrollProbeView {
        let view = HomeScrollProbeView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        engine.probe = view
        return view
    }

    func updateUIView(_ uiView: HomeScrollProbeView, context: Context) {
        engine.probe = uiView
    }
}

/// Ссылка на экран не держит прокрутку: сильная связь осталась бы у CADisplayLink
private final class HomeDisplayLinkProxy: NSObject {
    weak var owner: HomeAutoScroller?

    @objc func step(_ link: CADisplayLink) {
        owner?.step(link)
    }
}

/// Катит список вверх или вниз, пока карточку держат у края экрана
final class HomeAutoScroller {
    /// Скорость, pt в секунду: больше нуля вниз, меньше нуля вверх
    var velocity: CGFloat = 0 {
        didSet { link?.isPaused = (velocity == 0) }
    }

    private weak var scrollView: UIScrollView?
    private var onTick: (() -> Void)?
    private var link: CADisplayLink?
    private let proxy = HomeDisplayLinkProxy()

    deinit {
        link?.invalidate()
    }

    func start(_ scrollView: UIScrollView, onTick: @escaping () -> Void) {
        invalidateLink()
        self.scrollView = scrollView
        self.onTick = onTick
        proxy.owner = self
        let newLink = CADisplayLink(target: proxy, selector: #selector(HomeDisplayLinkProxy.step(_:)))
        newLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        newLink.isPaused = true
        newLink.add(to: .main, forMode: .common)
        link = newLink
    }

    func stop() {
        invalidateLink()
        scrollView = nil
        onTick = nil
        velocity = 0
    }

    private func invalidateLink() {
        link?.invalidate()
        link = nil
    }

    fileprivate func step(_ link: CADisplayLink) {
        guard velocity != 0, let scrollView = scrollView else { return }
        let seconds = link.targetTimestamp - link.timestamp
        let inset = scrollView.adjustedContentInset
        let lowest = -inset.top
        let highest = max(lowest, scrollView.contentSize.height - scrollView.bounds.height + inset.bottom)
        let current = scrollView.contentOffset.y
        let next = min(max(current + velocity * CGFloat(seconds), lowest), highest)
        guard next != current else { return }
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: next)
        onTick?()
    }
}

// MARK: - Ход перетаскивания
/// Хранит всё, что нужно, пока карточку несут. Колонка его не наблюдает (иначе все карточки перерисовывались бы
/// на каждый кадр): наблюдает только поднятая карточка, которая читает `top`, `isRaised` и `isLanding`.
final class HomeSectionDragEngine: ObservableObject {
    /// Верх поднятой карточки в колонке (меняется на каждый кадр)
    @Published private(set) var top: CGFloat = 0
    /// Карточка поднята: крупнее и с тенью
    @Published private(set) var isRaised = false
    /// Карточка садится на своё место
    @Published private(set) var isLanding = false

    /// Кого несут сейчас (nil: никого)
    private(set) var section: HomeSection?

    /// Порядок изменился: сохранить
    var onReorder: (([String]) -> Void)?
    /// Карточка села: показать настоящую
    var onLanded: (() -> Void)?
    /// Невидимый помощник внутри прокрутки: от него ищется сама прокрутка
    weak var probe: HomeScrollProbeView?

    private var order: [String] = []
    private var heights: [String: CGFloat] = [:]
    private var spacing: CGFloat = HomeSectionLayout.spacing
    private var startTop: CGFloat = 0
    /// Сдвиг пальца в момент подъёма: карточка идёт за пальцем от этого места, а не прыгает
    private var translationAnchor: CGFloat = 0
    private var translation: CGFloat = 0
    private var fingerY: CGFloat = 0
    private var hasMoved = false
    /// Номер перетаскивания: отложенное завершение прошлого не должно закончить следующее
    private var generation = 0

    private weak var scrollView: UIScrollView?
    private var scrollStart: CGFloat = 0
    private let scroller = HomeAutoScroller()

    /// Подъём. false: поднять не вышло (нет размеров карточек или уже что-то несут)
    func begin(
        section: HomeSection,
        order: [String],
        heights: [String: CGFloat],
        spacing: CGFloat,
        fingerY: CGFloat,
        translation: CGFloat
    ) -> Bool {
        guard self.section == nil else { return false }
        guard let index = order.firstIndex(of: section.rawValue),
              order.allSatisfy({ heights[$0] != nil }) else { return false }

        generation += 1
        self.section = section
        self.order = order
        self.heights = heights
        self.spacing = spacing
        startTop = HomeSectionOrder.tops(order, heights: heights, spacing: spacing)[index]
        translationAnchor = translation
        self.translation = translation
        self.fingerY = fingerY
        hasMoved = false
        top = startTop
        isLanding = false
        isRaised = false

        if let found = probe?.enclosingScrollView {
            scrollView = found
            scrollStart = found.contentOffset.y
            scroller.start(found) { [weak self] in
                self?.refresh()
            }
        } else {
            scrollView = nil
            scrollStart = 0
        }

        Haptics.impact(.medium)
        return true
    }

    /// Карточка появилась над колонкой: поднять (увеличение и тень)
    func raise() {
        guard section != nil, !isLanding else { return }
        isRaised = true
    }

    /// Палец двинулся. `translation`: сдвиг от места касания; `fingerY`: положение пальца на экране
    func drag(section: HomeSection, fingerY: CGFloat, translation: CGFloat) {
        guard self.section == section, !isLanding else { return }
        self.fingerY = fingerY
        self.translation = translation
        if abs(translation - translationAnchor) > 6 { hasMoved = true }
        refresh()
    }

    /// Палец поднят: карточка садится на своё место
    func drop(section: HomeSection) {
        guard self.section == section, !isLanding else { return }
        scroller.stop()
        isLanding = true
        isRaised = false
        if let index = order.firstIndex(of: section.rawValue) {
            top = HomeSectionOrder.tops(order, heights: heights, spacing: spacing)[index]
        }
        Haptics.impact(.light)
        let token = generation
        let delay = PaperMotion.reduceMotion ? 0.02 : HomeSectionLayout.landingDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.generation == token else { return }
            self.finish()
        }
    }

    /// Сразу, без посадки: экран ушёл в фон или закрылся
    func cancel() {
        guard section != nil else { return }
        finish()
    }

    private func finish() {
        guard section != nil else { return }
        scroller.stop()
        let landed = onLanded
        section = nil
        isLanding = false
        isRaised = false
        onReorder = nil
        onLanded = nil
        scrollView = nil
        landed?()
    }

    /// Пересчёт: где верх карточки (с учётом прокрутки), не пора ли соседям уступить место, не пора ли катить список
    private func refresh() {
        guard let section = section, !isLanding else { return }
        let height = heights[section.rawValue] ?? 0
        let moved = translation - translationAnchor
        let scrolled = (scrollView?.contentOffset.y ?? scrollStart) - scrollStart
        let limit = max(0, HomeSectionOrder.columnHeight(order, heights: heights, spacing: spacing) - height)
        let newTop = min(max(startTop + moved + scrolled, 0), limit)
        if newTop != top {
            top = newTop
        }

        let updated = HomeSectionOrder.settle(order, id: section.rawValue, top: newTop, heights: heights, spacing: spacing)
        if updated != order {
            order = updated
            Haptics.selection()
            onReorder?(updated)
        }
        updateAutoScroll()
    }

    private func updateAutoScroll() {
        guard hasMoved, let scrollView = scrollView else {
            scroller.velocity = 0
            return
        }
        let visible = scrollView.convert(scrollView.bounds, to: nil)
        let insets = scrollView.safeAreaInsets
        let zone = HomeSectionLayout.edgeZone
        let upperLine = visible.minY + insets.top + zone
        let lowerLine = visible.maxY - insets.bottom - zone
        var speed: CGFloat = 0
        if fingerY < upperLine {
            speed = -HomeSectionLayout.maxScrollSpeed * ramp((upperLine - fingerY) / zone)
        } else if fingerY > lowerLine {
            speed = HomeSectionLayout.maxScrollSpeed * ramp((fingerY - lowerLine) / zone)
        }
        scroller.velocity = speed
    }

    /// Чем глубже палец в полосе у края, тем быстрее прокрутка; у входа в полосу она медленная
    private func ramp(_ depth: CGFloat) -> CGFloat {
        0.15 + 0.85 * min(max(depth, 0), 1)
    }
}

// MARK: - Поднятая карточка
/// Полноразмерная копия карточки над колонкой: идёт за пальцем, на настоящем месте в это время пусто.
private struct HomeSectionGhost<Content: View>: View {
    @ObservedObject var engine: HomeSectionDragEngine
    let size: CGSize
    let content: Content

    var body: some View {
        content
            // Размер как у настоящей карточки: иначе накладка над колонкой предложила бы ей высоту всей колонки
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topTrailing) {
                HomeSectionHandleDots(isActive: true)
                    .frame(width: HomeSectionLayout.handleSide, height: HomeSectionLayout.handleSide)
                    .homeSectionHandleCorner()
            }
            .scaleEffect(engine.isRaised ? HomeSectionLayout.liftScale : 1)
            .shadow(
                color: Color.black.opacity(engine.isRaised ? 0.28 : 0),
                radius: engine.isRaised ? 18 : 0,
                x: 0,
                y: engine.isRaised ? 12 : 0
            )
            .animation(PaperMotion.animation(HomeSectionLayout.liftAnimation), value: engine.isRaised)
            .offset(y: engine.top)
            // За пальцем идёт без задержки; плавно движется только при посадке
            .animation(engine.isLanding ? PaperMotion.animation(HomeSectionLayout.landAnimation) : nil, value: engine.top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                engine.raise()
            }
    }
}

// MARK: - Колонка разделов главного экрана
/// Карточки одна под другой в сохранённом порядке. У каждой в правом верхнем углу ручка.
struct HomeReorderableSections<Card: View>: View {
    let language: AppLanguage
    /// Пока несут карточку, листание главного экрана выключено (его выключает сам экран: `.scrollDisabled`)
    @Binding private var isReordering: Bool
    private let card: (HomeSection) -> Card

    init(language: AppLanguage, isReordering: Binding<Bool>, @ViewBuilder card: @escaping (HomeSection) -> Card) {
        self.language = language
        self._isReordering = isReordering
        self.card = card
    }

    /// Порядок разделов на экране: сохранённые идентификаторы через запятую (пусто: порядок по умолчанию)
    @AppStorage(HomeSectionOrder.storageKey) private var savedOrderRaw: String = ""
    @Environment(\.scenePhase) private var scenePhase
    /// Ход перетаскивания. Колонка его не наблюдает, поэтому карточки не перерисовываются на каждый кадр
    @State private var engine = HomeSectionDragEngine()
    /// Какую карточку несут (её настоящее место пусто, сама она идёт над колонкой)
    @State private var lifted: HomeSection? = nil
    @State private var sizes: [HomeSection: CGSize] = [:]

    /// Разделы в порядке пользователя: сохранённый порядок слит с порядком по умолчанию
    private var orderedSections: [HomeSection] {
        HomeSectionOrder.merge(saved: HomeSectionOrder.decode(savedOrderRaw), defaults: HomeSection.defaultOrder)
            .compactMap { HomeSection(rawValue: $0) }
    }

    var body: some View {
        let sections = orderedSections
        VStack(spacing: HomeSectionLayout.spacing) {
            ForEach(Array(sections.enumerated()), id: \.element) { position, section in
                row(section, position: position, total: sections.count)
            }
        }
        // Остальные карточки расступаются плавно: анимация привязана к самому порядку
        .animation(PaperMotion.animation(HomeSectionLayout.reorderAnimation), value: savedOrderRaw)
        .overlay(alignment: .top) {
            ghost
        }
        .background(HomeScrollProbe(engine: engine))
        .onPreferenceChange(HomeSectionSizeKey.self) { value in
            sizes = value
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { engine.cancel() }
        }
        .onDisappear {
            engine.cancel()
        }
    }

    // MARK: Строка колонки
    @ViewBuilder
    private func row(_ section: HomeSection, position: Int, total: Int) -> some View {
        let isLifted = lifted == section
        card(section)
            // VoiceOver: перестановка без жестов перетаскивания
            .accessibilityAction(named: Text(language.pick(hy: "Տեղափոխել վերև", ru: "Переместить выше", en: "Move up"))) {
                moveWithoutDragging(section, by: -1)
            }
            .accessibilityAction(named: Text(language.pick(hy: "Տեղափոխել ներքև", ru: "Переместить ниже", en: "Move down"))) {
                moveWithoutDragging(section, by: 1)
            }
            .staggeredEntrance(index: min(position, 8) + 2)
            .opacity(isLifted ? 0 : 1)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: HomeSectionSizeKey.self, value: [section: proxy.size])
                }
            )
            .overlay(alignment: .topTrailing) {
                HomeSectionDragHandle(
                    language: language,
                    index: position,
                    total: total,
                    isLifted: isLifted,
                    onLift: { fingerY, translation in
                        lift(section, fingerY: fingerY, translation: translation)
                    },
                    onDrag: { fingerY, translation in
                        engine.drag(section: section, fingerY: fingerY, translation: translation)
                    },
                    onDrop: { engine.drop(section: section) },
                    onMove: { delta in moveWithoutDragging(section, by: delta) }
                )
                .homeSectionHandleCorner()
            }
    }

    // MARK: Поднятая карточка
    @ViewBuilder
    private var ghost: some View {
        if let section = lifted, let size = sizes[section] {
            HomeSectionGhost(engine: engine, size: size, content: card(section))
        }
    }

    // MARK: Подъём и перестановка
    /// true: карточка поднята
    private func lift(_ section: HomeSection, fingerY: CGFloat, translation: CGFloat) -> Bool {
        // Пока несут одну карточку (или она садится), другую не поднять
        guard engine.section == nil else { return false }
        var heights: [String: CGFloat] = [:]
        for (key, size) in sizes {
            heights[key.rawValue] = size.height
        }
        let order = orderedSections.map { $0.rawValue }
        guard engine.begin(
            section: section,
            order: order,
            heights: heights,
            spacing: HomeSectionLayout.spacing,
            fingerY: fingerY,
            translation: translation
        ) else { return false }
        engine.onReorder = { updated in
            savedOrderRaw = HomeSectionOrder.encode(updated)
        }
        engine.onLanded = {
            lifted = nil
            isReordering = false
        }
        lifted = section
        isReordering = true
        return true
    }

    /// Сдвиг на одну позицию без перетаскивания (для VoiceOver)
    private func moveWithoutDragging(_ section: HomeSection, by delta: Int) {
        guard engine.section == nil else { return }
        let current = orderedSections.map { $0.rawValue }
        let updated = HomeSectionOrder.shift(current, id: section.rawValue, by: delta)
        guard updated != current else { return }
        savedOrderRaw = HomeSectionOrder.encode(updated)
        Haptics.impact(.light)
        let newPosition = (updated.firstIndex(of: section.rawValue) ?? 0) + 1
        let message = language.pick(
            hy: "Բաժինը տեղափոխվեց. դիրք \(newPosition)՝ \(updated.count)-ից",
            ru: "Раздел перемещён: позиция \(newPosition) из \(updated.count)",
            en: "Section moved: position \(newPosition) of \(updated.count)"
        )
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
