import SwiftUI

// MARK: - Рост Гранатового Древа: что видел человек и что выросло с тех пор
/// Состояние древа, которое можно сравнить с прошлым визитом.
struct PomegranateGrowthSnapshot: Equatable {
    var stage: PomegranateStage
    /// Рост внутри ступени, 0...1
    var within: Double
    /// Плоды дня: по одному за каждое выполненное сегодня задание
    var fruits: Int
    /// День, к которому относятся плоды (yyyy-MM-dd)
    var day: String
}

// MARK: - Кривые плавности
enum PomegranateEase {
    static func clamp(_ x: CGFloat) -> CGFloat {
        max(0, min(1, x))
    }

    static func smooth(_ x: CGFloat) -> CGFloat {
        let t = clamp(x)
        return t * t * (3 - 2 * t)
    }

    static func outCubic(_ x: CGFloat) -> CGFloat {
        let t = clamp(x)
        let u = 1 - t
        return 1 - u * u * u
    }

    /// Доходит до цели с небольшим перелётом и возвращается
    static func outBack(_ x: CGFloat) -> CGFloat {
        let t = clamp(x)
        let c1: CGFloat = 1.70158
        let c3: CGFloat = c1 + 1
        let u = t - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }

    /// Очередь: элемент `index` из `count` проходит свой отрезок внутри общего хода `p`
    static func stagger(_ p: CGFloat, index: Int, count: Int, spread: CGFloat) -> CGFloat {
        let share: CGFloat = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0
        return clamp(p * (1 + spread) - spread * share)
    }
}

// MARK: - Один кадр роста
/// Всё, что отрисовке нужно знать о росте в данный момент. Считается из плана как чистая функция времени.
struct PomegranateGrowthFrame {
    struct GrowingFruit {
        let index: Int
        let phase: CGFloat
    }

    /// Поза растущего плода
    struct FruitPose {
        /// Размер: 0 — нет, 1 — готовый плод (по пути слегка перелетает)
        let scale: CGFloat
        /// 0 — зелёная завязь, 1 — спелый
        let ripeness: CGFloat
        /// Качание на черенке, радианы
        let swing: CGFloat
        /// Вспышка блика, 0...1
        let sparkle: CGFloat
        /// Разлёт золотых искр, 0...1 (вне этого отрезка искр нет)
        let burst: CGFloat
    }

    var stage: PomegranateStage
    var within: CGFloat
    /// Сколько плодов дня уже выросло
    var dailyFruits: Int
    /// Плоды дня, которые растут прямо сейчас
    var growing: [GrowingFruit] = []
    /// «Вдох» кроны: прибавка к масштабу
    var swell: CGFloat = 0
    /// Волна роста от ствола к концам веток, 0...1
    var wave: CGFloat?
    /// Падение росинки, 0...1
    var drop: CGFloat?
    /// Кольцо от росинки на земле, 0...1
    var ripple: CGFloat?
    /// Вырастание дерева новой ступени, 0...1
    var reveal: CGFloat?
    /// Росток поднимается из земли, 0...1
    var emerge: CGFloat?
    /// Прежняя ступень, которая растворяется
    var ghostStage: PomegranateStage?
    var ghostWithin: CGFloat = 1
    var ghostFruits: Int = 0
    var ghostOpacity: CGFloat = 0
    /// Ветви и листья у ступеней совпадают: меняются только цветы и плоды
    var sameSkeleton = false

    init(stage: PomegranateStage, within: CGFloat, dailyFruits: Int) {
        self.stage = stage
        self.within = within
        self.dailyFruits = dailyFruits
    }

    /// Древо стоит: рост закончен
    init(resting snapshot: PomegranateGrowthSnapshot) {
        self.init(stage: snapshot.stage, within: CGFloat(snapshot.within), dailyFruits: snapshot.fruits)
    }

    /// Жизнь одного плода за отрезок 0...1: завязь, рост, наливание цветом, качание и блик.
    static func fruitPose(_ phase: CGFloat) -> FruitPose {
        let p = PomegranateEase.clamp(phase)
        let bud = PomegranateEase.outCubic(p / 0.14) * 0.22
        let scale = bud + 0.78 * PomegranateEase.outBack((p - 0.14) / 0.50)
        let ripeness = PomegranateEase.smooth((p - 0.26) / 0.50)
        let tau = PomegranateEase.clamp((p - 0.50) / 0.50)
        let swing = 0.20 * sin(tau * CGFloat.pi * 4.5) * (1 - tau) * (1 - tau)
        let sparkle = sin(CGFloat.pi * PomegranateEase.clamp((p - 0.62) / 0.28))
        let burst = PomegranateEase.clamp((p - 0.60) / 0.30)
        return FruitPose(scale: scale, ripeness: ripeness, swing: swing, sparkle: sparkle, burst: burst)
    }
}

// MARK: - План анимации от прошлого состояния к нынешнему
struct PomegranateGrowthPlan {
    static let fruitDuration: Double = 2.8
    /// Плоды появляются по очереди, следующий — пока предыдущий ещё качается
    static let fruitGap: Double = 1.6

    let from: PomegranateGrowthSnapshot
    let to: PomegranateGrowthSnapshot
    let start: Date
    /// Пауза перед началом: экран успевает открыться
    let delay: Double

    let stageUp: Bool
    let sameDay: Bool
    /// Сколько плодов дня человек уже видел
    let fruitsFrom: Int
    let newFruits: Int
    let grew: Bool
    /// Длительность главной части: смена ступени или волна роста
    let mainDuration: Double
    let fruitStart: Double
    let total: Double

    init(from: PomegranateGrowthSnapshot, to: PomegranateGrowthSnapshot, start: Date, delay: Double) {
        self.from = from
        self.to = to
        self.start = start
        self.delay = delay

        let stageUp = to.stage > from.stage
        let sameDay = from.day == to.day
        let fruitsFrom = sameDay ? min(from.fruits, to.fruits) : 0
        let newFruits = max(0, to.fruits - fruitsFrom)
        let grew = to.stage == from.stage && to.within > from.within + 0.0005

        var mainDuration: Double = 0
        if stageUp {
            mainDuration = to.stage <= .sprout ? 3.0 : 4.6
        } else if grew || newFruits > 0 {
            mainDuration = 1.9
        }
        let fruitStart = delay + max(0, mainDuration - 0.35)
        var fruitsEnd: Double = 0
        if newFruits > 0 {
            fruitsEnd = fruitStart + Double(newFruits - 1) * Self.fruitGap + Self.fruitDuration
        }

        self.stageUp = stageUp
        self.sameDay = sameDay
        self.fruitsFrom = fruitsFrom
        self.newFruits = newFruits
        self.grew = grew
        self.mainDuration = mainDuration
        self.fruitStart = fruitStart
        self.total = max(delay + mainDuration, fruitsEnd)
    }

    /// Показывать нечего: ничего не выросло
    var isEmpty: Bool {
        !(stageUp || grew || newFruits > 0)
    }

    /// Ветви и листья совпадают, когда у ступеней одинаковые стволы, глубина ветвления и число пар листьев
    static func sameSkeleton(_ a: PomegranateStage, _ b: PomegranateStage) -> Bool {
        let pa = PomegranateTreeLayout.params(for: a)
        let pb = PomegranateTreeLayout.params(for: b)
        return pa.stems > 1 && pa.stems == pb.stems && pa.depth == pb.depth && pa.trunk == pb.trunk && pa.pairs == pb.pairs
    }

    /// Кадр через `elapsed` секунд после начала плана.
    func frame(at elapsed: Double) -> PomegranateGrowthFrame {
        var frame = PomegranateGrowthFrame(stage: to.stage, within: CGFloat(to.within), dailyFruits: fruitsFrom)
        let x: CGFloat = mainDuration > 0 ? CGFloat((elapsed - delay) / mainDuration) : 1

        if stageUp {
            let oldFruits = sameDay ? from.fruits : 0
            if x <= 0 {
                frame.stage = from.stage
                frame.within = CGFloat(from.within)
                frame.dailyFruits = oldFruits
            } else if x < 1 {
                frame.ghostStage = from.stage
                frame.ghostWithin = CGFloat(from.within)
                frame.ghostFruits = oldFruits
                if to.stage <= .sprout {
                    frame.ghostOpacity = 1 - PomegranateEase.smooth(x / 0.5)
                    frame.emerge = PomegranateEase.outCubic((x - 0.08) / 0.85)
                } else {
                    let same = Self.sameSkeleton(from.stage, to.stage)
                    frame.sameSkeleton = same
                    frame.ghostOpacity = 1 - PomegranateEase.smooth((x - 0.04) / (same ? 0.40 : 0.46))
                    frame.reveal = x
                }
                frame.swell = 0.03 * sin(CGFloat.pi * PomegranateEase.clamp((x - 0.8) / 0.2))
            }
        } else if mainDuration > 0 {
            let startWithin = CGFloat(to.stage == from.stage ? min(from.within, to.within) : to.within)
            let endWithin = CGFloat(to.within)
            if x <= 0 {
                frame.within = startWithin
            } else if x < 1 {
                if x < 0.26 {
                    frame.drop = x / 0.26
                }
                let spread = (x - 0.26) / 0.30
                if spread > 0 && spread < 1 {
                    frame.ripple = spread
                }
                let k = PomegranateEase.clamp((x - 0.24) / 0.76)
                frame.within = startWithin + (endWithin - startWithin) * PomegranateEase.outBack(k)
                if x >= 0.24 {
                    frame.wave = k
                    frame.swell = 0.04 * sin(CGFloat.pi * k)
                }
            }
        }

        for j in 0..<newFruits {
            let phase = (elapsed - (fruitStart + Double(j) * Self.fruitGap)) / Self.fruitDuration
            if phase >= 1 {
                frame.dailyFruits += 1
            } else if phase > 0 {
                frame.growing.append(PomegranateGrowthFrame.GrowingFruit(index: fruitsFrom + j, phase: CGFloat(phase)))
            }
        }
        return frame
    }

    /// Моменты лёгкой вибрации: новая ступень выросла, плод набрал размер
    var hapticMoments: [Double] {
        var moments: [Double] = []
        if stageUp {
            moments.append(delay + mainDuration * 0.9)
        }
        for j in 0..<newFruits {
            moments.append(fruitStart + Double(j) * Self.fruitGap + Self.fruitDuration * 0.60)
        }
        return moments
    }
}

// MARK: - Живое древо на экране сада
/// Большое древо с анимацией роста: помнит, каким его видели в прошлый раз, и при открытии дорастает до нынешнего.
/// После выполненного задания к корням падает росинка, по кроне проходит волна роста и на ветке вырастает новый гранат.
struct PomegranateGrowingTreeView: View {
    let height: CGFloat
    /// Нажатие на плод Духа (номер с единицы)
    let onFruitTapped: (Int) -> Void
    /// Нажатие на плод дня
    let onDailyFruitTapped: () -> Void

    @ObservedObject private var tree = PomegranateTreeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var plan: PomegranateGrowthPlan? = nil
    /// Состояние, до которого древо уже доросло (или дорастает) на экране
    @State private var shown: PomegranateGrowthSnapshot? = nil
    @State private var timer: Task<Void, Never>? = nil

    /// Съёмка экранов в CI задаёт дни аргументом запуска: там нужен готовый кадр, а не середина роста.
    /// С `-pomegranate_growth YES` анимация идёт и в такой съёмке (для записи ролика).
    private static let isStillCapture: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-pomegranate_debug_days") && !arguments.contains("-pomegranate_growth")
    }()

    var body: some View {
        let palette = colorScheme == .dark ? PomegranatePalette.dark : PomegranatePalette.light
        let current = tree.growthSnapshot
        // До первого появления показываем то, что человек видел в прошлый раз: иначе мелькнёт готовый результат
        let resting = shown ?? tree.growthBaseline(for: current)
        let running = plan
        let thirst = tree.isThirstingForDew
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: running == nil ? 1.0 / 30.0 : 1.0 / 60.0, paused: reduceMotion)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                let frame = Self.growthFrame(at: timeline.date, plan: running, resting: resting)
                let scene = PomegranateScene(
                    stage: frame.stage,
                    size: geo.size,
                    time: time,
                    thirst: thirst,
                    compact: false,
                    frame: frame
                )
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in
                        PomegranateRenderer.draw(scene, palette: palette, in: context)
                    }
                    ForEach(Array(scene.fruitHitTargets.enumerated()), id: \.offset) { index, target in
                        Button {
                            onFruitTapped(index + 1)
                        } label: {
                            Circle()
                                .fill(Color.white.opacity(0.001))
                                .frame(width: target.diameter, height: target.diameter)
                        }
                        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.84))
                        .position(x: target.center.x, y: target.center.y)
                    }
                    ForEach(Array(scene.dailyHitTargets.enumerated()), id: \.offset) { _, target in
                        Button {
                            onDailyFruitTapped()
                        } label: {
                            Circle()
                                .fill(Color.white.opacity(0.001))
                                .frame(width: target.diameter, height: target.diameter)
                        }
                        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.84))
                        .position(x: target.center.x, y: target.center.y)
                    }
                }
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(current.stage.title(for: BibleManager.shared.appLanguage)))
        .onAppear {
            tree.refreshDewAndStreakStatus()
            tree.refreshTasksForToday()
            sync(delay: 0.55)
        }
        .onChange(of: current) { _ in
            sync(delay: 0.15)
        }
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }

    /// Кадр на данный момент: идёт рост или древо стоит.
    private static func growthFrame(at date: Date, plan: PomegranateGrowthPlan?, resting: PomegranateGrowthSnapshot) -> PomegranateGrowthFrame {
        guard let plan else { return PomegranateGrowthFrame(resting: resting) }
        return plan.frame(at: date.timeIntervalSince(plan.start))
    }

    /// Сверяет показанное с нынешним и, если древо выросло, запускает рост.
    private func sync(delay: Double) {
        // План, который уже доиграл, больше не нужен: древо стоит
        if let finished = plan, Date().timeIntervalSince(finished.start) > finished.total {
            plan = nil
        }
        let now = tree.growthSnapshot
        if shown == now { return }
        let base = shown ?? tree.growthBaseline(for: now)
        shown = now
        tree.markGrowthSeen(now)

        let fresh = PomegranateGrowthPlan(from: base, to: now, start: Date(), delay: delay)
        // Новая ступень показывается всегда. Остальной рост — только после сегодняшнего действия:
        // наутро без действия древо просто стоит, хотя вчерашний день и досчитан целиком
        let earned = fresh.stageUp || tree.isWateredToday
        guard !reduceMotion, !Self.isStillCapture, earned, !fresh.isEmpty else {
            timer?.cancel()
            timer = nil
            plan = nil
            return
        }
        plan = fresh
        schedule(fresh)
    }

    /// Вибрация в нужные моменты и снятие плана, когда рост закончился.
    private func schedule(_ running: PomegranateGrowthPlan) {
        timer?.cancel()
        let moments = running.hapticMoments
        let total = running.total
        let startedAt = running.start
        timer = Task { @MainActor in
            var passed: Double = 0
            for moment in moments {
                let wait = moment - passed
                if wait > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
                if Task.isCancelled { return }
                Haptics.impact(.soft)
                passed = moment
            }
            let rest = total - passed + 0.05
            if rest > 0 {
                try? await Task.sleep(nanoseconds: UInt64(rest * 1_000_000_000))
            }
            if Task.isCancelled { return }
            if plan?.start == startedAt {
                plan = nil
            }
        }
    }
}
