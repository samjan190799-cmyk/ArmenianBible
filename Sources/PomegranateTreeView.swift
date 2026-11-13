import SwiftUI

// MARK: - Режим отображения Древа (Display Style)
enum PomegranateViewStyle {
    case compact(height: CGFloat = 84)
    case majestic(height: CGFloat = 280)

    var height: CGFloat {
        switch self {
        case .compact(let h): return h
        case .majestic(let h): return h
        }
    }

    var isCompact: Bool {
        if case .compact = self { return true }
        return false
    }
}

// MARK: - Гранатовое Древо Веры (Pomegranate Tree View)
/// Процедурная иллюстрация настоящего граната (Punica granatum): кустистое дерево из нескольких
/// стволов, густая округлая крона, парные узкие глянцевые листья (молодые — красновато-бронзовые),
/// воронковидные алые цветы, плоды, висящие на концах веток короной вниз. У Древа Жизни часть плодов
/// раскрыта (видны рубиновые зёрна) и над кроной золотой нимб, как в армянских рукописях.
/// Рисунок детерминирован: одно и то же дерево растёт от стадии к стадии.
struct PomegranateTreeView: View {
    let stage: PomegranateStage
    let style: PomegranateViewStyle
    let isThirsting: Bool
    let onFruitTapped: ((Int) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        stage: PomegranateStage,
        style: PomegranateViewStyle = .majestic(),
        isThirsting: Bool = false,
        onFruitTapped: ((Int) -> Void)? = nil
    ) {
        self.stage = stage
        self.style = style
        self.isThirsting = isThirsting
        self.onFruitTapped = onFruitTapped
    }

    var body: some View {
        let palette = colorScheme == .dark ? PomegranatePalette.dark : PomegranatePalette.light
        let paused = reduceMotion || style.isCompact
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { timeline in
                let time = paused ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                let scene = PomegranateScene(
                    stage: stage,
                    size: geo.size,
                    time: time,
                    thirst: isThirsting,
                    compact: style.isCompact
                )
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in
                        PomegranateRenderer.draw(scene, palette: palette, in: context)
                    }
                    if let onFruitTapped {
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
                    }
                }
            }
        }
        .frame(width: style.isCompact ? style.height : nil, height: style.height)
        .frame(maxWidth: style.isCompact ? nil : .infinity)
        .accessibilityElement(children: onFruitTapped == nil ? .ignore : .contain)
        .accessibilityLabel(Text(stage.title(for: BibleManager.shared.appLanguage)))
    }
}

// MARK: - Плод граната отдельно (плоды Духа, карточки)
struct PomegranateFruitGlyph: View {
    let size: CGFloat
    var isOpen: Bool = false
    var isLocked: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = colorScheme == .dark ? PomegranatePalette.dark : PomegranatePalette.light
        Canvas { context, canvasSize in
            let r = min(canvasSize.width, canvasSize.height) * 0.34
            let fruit = PomegranateTreeLayout.Fruit(
                x: canvasSize.width / 2,
                y: canvasSize.height * 0.46,
                r: r,
                stemX: canvasSize.width / 2,
                stemY: canvasSize.height * 0.46 - r,
                isOpen: isOpen
            )
            PomegranateRenderer.drawFruit(fruit, palette: palette, lineWidth: max(0.6, size * 0.012), withStem: false, in: context)
        }
        .frame(width: size, height: size)
        .saturation(isLocked ? 0 : 1)
        .opacity(isLocked ? 0.3 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Палитра иллюстрации
struct PomegranatePalette {
    let ink: UInt32
    let gold: UInt32
    let goldLight: UInt32
    let halo: UInt32
    let leaf: UInt32
    let leafDark: UInt32
    let leafLight: UInt32
    let leafYoung: UInt32
    let bark: UInt32
    let barkLight: UInt32
    let barkDark: UInt32
    let fruit: UInt32
    let fruitDark: UInt32
    let fruitLight: UInt32
    let pith: UInt32
    let aril: UInt32
    let arilLight: UInt32
    let flower: UInt32
    let flowerLight: UInt32
    let soil: UInt32
    let soilDark: UInt32
    let dew: UInt32

    static let light = PomegranatePalette(
        ink: 0x2B241D, gold: 0x8F6B2A, goldLight: 0xC9A45C, halo: 0xE7C67C,
        leaf: 0x5A7A4C, leafDark: 0x3D5634, leafLight: 0x86A36C, leafYoung: 0xB0553E,
        bark: 0x6E4F33, barkLight: 0x9A7350, barkDark: 0x3F2D1E,
        fruit: 0xB2352A, fruitDark: 0x6A1A13, fruitLight: 0xE27462,
        pith: 0xF1DFC0, aril: 0xC21F3A, arilLight: 0xF2788A,
        flower: 0xC2412B, flowerLight: 0xEA7C50,
        soil: 0x8A6A48, soilDark: 0x5C4530, dew: 0xBFD8E8
    )

    static let dark = PomegranatePalette(
        ink: 0xECE3D2, gold: 0xCFAE6E, goldLight: 0xE9CF93, halo: 0xCFAE6E,
        leaf: 0x7E9F67, leafDark: 0x56744A, leafLight: 0xA8C58C, leafYoung: 0xE0906F,
        bark: 0x9A7552, barkLight: 0xC29A72, barkDark: 0x5C4530,
        fruit: 0xC9463A, fruitDark: 0x7A231B, fruitLight: 0xF08C78,
        pith: 0xE9D3AE, aril: 0xE0405A, arilLight: 0xFF9AA8,
        flower: 0xDA5A40, flowerLight: 0xF59A70,
        soil: 0x6E5338, soilDark: 0x46352A, dew: 0xA9C8DC
    )

    static func color(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let ca = Double((a >> shift) & 0xFF)
            let cb = Double((b >> shift) & 0xFF)
            return UInt32((ca + (cb - ca) * t).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    /// Переход через середину: a → b → c
    static func mix3(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ t: Double) -> UInt32 {
        t < 0.5 ? mix(a, b, t * 2) : mix(b, c, (t - 0.5) * 2)
    }
}

// MARK: - Детерминированный генератор случайных чисел (mulberry32)
struct PomegranateRandom {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed
    }

    mutating func next() -> CGFloat {
        state = state &+ 0x6D2B79F5
        var t = (state ^ (state >> 15)) &* (1 | state)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return CGFloat(Double(t ^ (t >> 14)) / 4_294_967_296.0)
    }
}

// MARK: - Геометрия дерева
/// Координаты: основание в (0, 0), крона растёт в отрицательные Y. H — высота области рисования.
/// Макет статичен и кэшируется; покачивание на ветру делается сдвигом при рисовании.
struct PomegranateTreeLayout {
    struct Segment {
        var x: CGFloat, y: CGFloat, ex: CGFloat, ey: CGFloat, mx: CGFloat, my: CGFloat
        var w0: CGFloat, w1: CGFloat
        var level: Int
    }
    struct Leaf {
        var x: CGFloat, y: CGFloat, angle: CGFloat, length: CGFloat
        /// 0 — тёмный, 1 — основной, 2 — светлый, 3 — молодой бронзовый
        var tone: Int
    }
    struct Fruit {
        var x: CGFloat, y: CGFloat, r: CGFloat, stemX: CGFloat, stemY: CGFloat
        var isOpen: Bool
    }
    struct Flower {
        var x: CGFloat, y: CGFloat, angle: CGFloat, size: CGFloat
    }
    private struct Tip {
        var x: CGFloat, y: CGFloat, angle: CGFloat
    }

    var segments: [Segment] = []
    var leaves: [Leaf] = []
    var fruits: [Fruit] = []
    var flowers: [Flower] = []
    var buds: [Flower] = []
    /// Когда на шкале вырастания 0...1 появляется место крепления листа (индексы как у leaves)
    var leafBirth: [CGFloat] = []
    /// Места для плодов дня: свободные концы веток
    var dailySlots: [Fruit] = []
    /// Доля шкалы вырастания на один ярус ветвей
    var growUnit: CGFloat = 1
    /// Готовые контуры ветвей: считаются один раз вместе с макетом
    var branchOutlines: [Path] = []
    var branchHighlights: [Path] = []
    var crownX: CGFloat = 0
    var crownY: CGFloat = 0
    var crownR: CGFloat = 0
    var minX: CGFloat = 0
    var maxX: CGFloat = 0
    var minY: CGFloat = 0

    /// Сколько плодов дня помещается на дереве
    static let dailyCapacity = 4
    /// Ветвь растёт дольше, чем длится её ярус: соседние ярусы перекрываются
    static let growSpan: CGFloat = 1.3

    struct Params {
        let stems: Int
        let trunk: CGFloat
        let width: CGFloat
        let depth: Int
        let leaf: CGFloat
        let pairs: Int
        let fruits: Int
        let flowers: Int
        let buds: Int
        let isLife: Bool
    }

    static func params(for stage: PomegranateStage) -> Params {
        switch stage {
        case .seed:
            return Params(stems: 0, trunk: 0, width: 0, depth: 0, leaf: 0, pairs: 0, fruits: 0, flowers: 0, buds: 0, isLife: false)
        case .sprout:
            return Params(stems: 1, trunk: 0.30, width: 0.014, depth: 0, leaf: 0.095, pairs: 0, fruits: 0, flowers: 0, buds: 0, isLife: false)
        case .youngTree:
            return Params(stems: 3, trunk: 0.17, width: 0.022, depth: 3, leaf: 0.052, pairs: 4, fruits: 1, flowers: 0, buds: 2, isLife: false)
        case .bloomingTree:
            return Params(stems: 4, trunk: 0.16, width: 0.026, depth: 4, leaf: 0.048, pairs: 3, fruits: 3, flowers: 7, buds: 3, isLife: false)
        case .fruitfulTree:
            return Params(stems: 4, trunk: 0.16, width: 0.028, depth: 4, leaf: 0.046, pairs: 3, fruits: 6, flowers: 2, buds: 0, isLife: false)
        case .treeOfLife:
            return Params(stems: 5, trunk: 0.16, width: 0.030, depth: 4, leaf: 0.044, pairs: 3, fruits: 9, flowers: 6, buds: 0, isLife: true)
        }
    }

    // MARK: Кэш макетов (генерация сотен листьев не должна повторяться каждый кадр)
    private static let cacheLock = NSLock()
    private static var cache: [String: PomegranateTreeLayout] = [:]

    static func cached(stage: PomegranateStage, height H: CGFloat) -> PomegranateTreeLayout {
        let key = "\(stage.rawValue)|\(Int(H.rounded()))"
        cacheLock.lock()
        if let hit = cache[key] {
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()
        let made = make(stage: stage, height: H)
        cacheLock.lock()
        if cache.count > 64 { cache.removeAll() }
        cache[key] = made
        cacheLock.unlock()
        return made
    }

    static func make(stage: PomegranateStage, height H: CGFloat) -> PomegranateTreeLayout {
        let p = params(for: stage)
        var rng = PomegranateRandom(seed: 20_260_929)
        var out = PomegranateTreeLayout()
        var tips: [Tip] = []
        let unit: CGFloat = 1 / (CGFloat(p.depth) + growSpan)
        out.growUnit = unit

        func sign(_ v: CGFloat) -> CGFloat { v > 0 ? 1 : (v < 0 ? -1 : 0) }
        func point(_ t: CGFloat, _ s: Segment) -> CGPoint {
            let u = 1 - t
            return CGPoint(x: u * u * s.x + 2 * u * t * s.mx + t * t * s.ex,
                           y: u * u * s.y + 2 * u * t * s.my + t * t * s.ey)
        }
        func addLeaf(_ x: CGFloat, _ y: CGFloat, _ angle: CGFloat, _ length: CGFloat, _ tone: Int, _ birth: CGFloat) {
            out.leaves.append(Leaf(x: x, y: y, angle: angle, length: length, tone: tone))
            out.leafBirth.append(birth)
        }
        func grow(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat, _ len: CGFloat, _ w: CGFloat, _ depth: Int, _ level: Int) {
            let a = ang
            let ex = x + sin(a) * len
            let ey = y - cos(a) * len
            let bend = (rng.next() - 0.5) * (level == 0 ? 0.55 : 0.34) * len
            let mx = (x + ex) / 2 + cos(a) * bend
            let my = (y + ey) / 2 + sin(a) * bend
            let seg = Segment(x: x, y: y, ex: ex, ey: ey, mx: mx, my: my, w0: w, w1: w * 0.66, level: level)
            out.segments.append(seg)
            let born = CGFloat(level) * unit

            if depth == 0 {
                tips.append(Tip(x: ex, y: ey, angle: a))
                // Листья парами друг напротив друга вдоль веточки
                let m = p.pairs
                for i in 0..<m {
                    let t = 0.30 + 0.70 * CGFloat(i) / CGFloat(max(1, m - 1))
                    let pt = point(t, seg)
                    let k = 0.92 - 0.25 * abs(t - 0.65)
                    let spread = 0.95 + rng.next() * 0.25
                    let young = t > 0.8 && rng.next() < 0.7
                    let l1 = H * p.leaf * k * (0.9 + rng.next() * 0.2)
                    addLeaf(pt.x, pt.y, a + spread, l1, young ? 3 : (rng.next() < 0.3 ? 0 : 1), born + t * growSpan * unit)
                    let l2 = H * p.leaf * k * (0.9 + rng.next() * 0.2)
                    addLeaf(pt.x, pt.y, a - spread, l2, young ? 3 : (rng.next() < 0.3 ? 0 : 2), born + t * growSpan * unit)
                }
                addLeaf(ex, ey, a + (rng.next() - 0.5) * 0.25, H * p.leaf * 1.1, rng.next() < 0.55 ? 3 : 2, born + growSpan * unit)
                return
            }

            let n = (level >= 1 && rng.next() < 0.30) ? 3 : 2
            var kids: [CGFloat] = []
            if n == 2 {
                kids.append(-(0.26 + rng.next() * 0.20))
                kids.append(0.24 + rng.next() * 0.22)
            } else {
                kids.append(-(0.46 + rng.next() * 0.12))
                kids.append((rng.next() - 0.5) * 0.18)
                kids.append(0.46 + rng.next() * 0.12)
            }
            for da in kids {
                var na = a + da - sign(a + da) * 0.045 * CGFloat(level)
                na = max(-1.50, min(1.50, na))
                let childLength = len * (0.76 + rng.next() * 0.12)
                grow(ex, ey, na, childLength, w * 0.66, depth - 1, level + 1)
            }
            // Боковая веточка с листьями
            if depth <= 2 && rng.next() < 0.8 {
                let t = 0.5 + rng.next() * 0.35
                let pt = point(t, seg)
                let side: CGFloat = rng.next() < 0.5 ? -1 : 1
                for k in 0..<2 {
                    let angle = a + side * (0.8 + CGFloat(k) * 0.5 + rng.next() * 0.2)
                    addLeaf(pt.x, pt.y, angle, H * p.leaf * 0.9, rng.next() < 0.4 ? 0 : 1, born + t * growSpan * unit)
                }
            }
        }

        if p.stems > 1 {
            for i in 0..<p.stems {
                let f = (CGFloat(i) / CGFloat(p.stems - 1) - 0.5) * 2
                let ang = f * 0.26 + (rng.next() - 0.5) * 0.08
                let x0 = f * H * 0.026
                let length = H * p.trunk * (0.92 + rng.next() * 0.18)
                let width = H * p.width * (0.9 + rng.next() * 0.25)
                grow(x0, 0, ang, length, width, p.depth, 0)
            }
        }

        // Плоды висят на концах нижних и боковых веток, цветы — выше
        var used = Set<Int>()
        func spreadPick(_ k: Int, _ candidates: [Int]) -> [Int] {
            guard k > 0, !candidates.isEmpty else { return [] }
            let sortedByX = candidates.sorted { tips[$0].x < tips[$1].x }
            let count = sortedByX.count
            var picked: [Int] = []
            for i in 0..<k {
                let raw = (CGFloat(i) + 0.5) * CGFloat(count) / CGFloat(k) - 0.5
                let target = min(count - 1, max(0, Int(raw.rounded())))
                var j = target
                while used.contains(sortedByX[j]) && j < count - 1 { j += 1 }
                if used.contains(sortedByX[j]) {
                    j = target
                    while used.contains(sortedByX[j]) && j > 0 { j -= 1 }
                }
                if used.contains(sortedByX[j]) { continue }
                used.insert(sortedByX[j])
                picked.append(sortedByX[j])
            }
            return picked
        }
        let byBottom = tips.indices.sorted { tips[$0].y > tips[$1].y }
        let fruitCandidates = byBottom.enumerated().filter { $0.offset % 2 == 0 || $0.offset < p.fruits }.map { $0.element }
        let fruitPool = Array(fruitCandidates.prefix(max(p.fruits * 2, Int(Double(fruitCandidates.count) * 0.7))))
        let fruitIdx = spreadPick(p.fruits, fruitPool)
        let upper = Array(tips.indices.sorted { tips[$0].y < tips[$1].y }.prefix(max(p.flowers * 2, 6)))
        let flowerIdx = spreadPick(p.flowers, upper)
        let budIdx = spreadPick(p.buds, tips.indices.filter { !used.contains($0) })

        let fr = H * (stage >= .treeOfLife ? 0.040 : 0.044)
        out.fruits = fruitIdx.enumerated().map { i, idx in
            let tip = tips[idx]
            return Fruit(
                x: tip.x,
                y: tip.y + fr * 1.18,
                r: fr * (i % 3 == 1 ? 0.92 : 1),
                stemX: tip.x,
                stemY: tip.y,
                isOpen: p.isLife && (i == 2 || i == 6)
            )
        }
        out.flowers = flowerIdx.map { Flower(x: tips[$0].x, y: tips[$0].y, angle: tips[$0].angle, size: H * 0.036) }
        out.buds = budIdx.map { Flower(x: tips[$0].x, y: tips[$0].y, angle: tips[$0].angle, size: H * 0.028) }

        // Места для плодов дня: свободные концы веток, подальше от плодов и друг от друга
        // (цветы мешают меньше: они смотрят вверх, а плод висит вниз)
        var hanging: [CGPoint] = fruitIdx.map { CGPoint(x: tips[$0].x, y: tips[$0].y) }
        let blooming: [CGPoint] = (flowerIdx + budIdx).map { CGPoint(x: tips[$0].x, y: tips[$0].y) }
        let freeTips = byBottom.filter { !used.contains($0) }
        var slotIdx: [Int] = []
        if !hanging.isEmpty {
            for _ in 0..<dailyCapacity {
                var best = -1
                var bestScore: CGFloat = -1
                for idx in freeTips where !slotIdx.contains(idx) {
                    var distance = CGFloat.greatestFiniteMagnitude
                    for pt in hanging { distance = min(distance, hypot(tips[idx].x - pt.x, tips[idx].y - pt.y)) }
                    for pt in blooming { distance = min(distance, 2 * hypot(tips[idx].x - pt.x, tips[idx].y - pt.y)) }
                    if distance > bestScore {
                        bestScore = distance
                        best = idx
                    }
                }
                guard best >= 0 else { break }
                slotIdx.append(best)
                hanging.append(CGPoint(x: tips[best].x, y: tips[best].y))
            }
        }
        let dailyRadius = fr * 0.9
        out.dailySlots = slotIdx.map { idx in
            let tip = tips[idx]
            return Fruit(x: tip.x, y: tip.y + dailyRadius * 1.18, r: dailyRadius, stemX: tip.x, stemY: tip.y, isOpen: false)
        }
        out.branchOutlines = out.segments.map { PomegranateRenderer.branchOutline($0, upTo: 1) }
        out.branchHighlights = out.segments.map { PomegranateRenderer.branchHighlight($0, upTo: 1) }

        // Центр кроны и габариты рисунка
        var lx0: CGFloat = 0, lx1: CGFloat = 0, ly0: CGFloat = 0, ly1: CGFloat = -.greatestFiniteMagnitude
        var bx0: CGFloat = 0, bx1: CGFloat = 0, by0: CGFloat = 0
        for leaf in out.leaves {
            lx0 = min(lx0, leaf.x); lx1 = max(lx1, leaf.x)
            ly0 = min(ly0, leaf.y); ly1 = max(ly1, leaf.y)
            bx0 = min(bx0, leaf.x - leaf.length); bx1 = max(bx1, leaf.x + leaf.length)
            by0 = min(by0, leaf.y - leaf.length)
        }
        if ly1 == -.greatestFiniteMagnitude { ly1 = 0 }
        for fruit in out.fruits {
            bx0 = min(bx0, fruit.x - fruit.r); bx1 = max(bx1, fruit.x + fruit.r)
            by0 = min(by0, fruit.y - fruit.r * 1.5)
        }
        for flower in out.flowers {
            by0 = min(by0, flower.y - flower.size * 1.8)
        }
        out.crownX = (lx0 + lx1) / 2
        out.crownY = (ly0 + ly1) / 2
        out.crownR = max(lx1 - lx0, ly1 - ly0) * 0.5 + H * 0.03
        out.minX = bx0
        out.maxX = bx1
        out.minY = by0
        return out
    }

    /// Масштаб, при котором весь рисунок помещается в область.
    func fitScale(width W: CGFloat, height H: CGFloat) -> CGFloat {
        let bw = max(1, max(-minX, maxX) * 2)
        let bh = max(1, -minY)
        return min(1, (H * 0.84) / bh, (W * 0.94) / bw)
    }
}

// MARK: - Сцена для одного кадра
struct PomegranateScene {
    struct HitTarget {
        let center: CGPoint
        let diameter: CGFloat
    }

    let stage: PomegranateStage
    let size: CGSize
    let time: Double
    let thirst: Bool
    let compact: Bool
    /// Кадр анимации роста; nil — дерево стоит в обычном виде своей ступени
    let frame: PomegranateGrowthFrame?
    let layout: PomegranateTreeLayout
    let fit: CGFloat
    let base: CGPoint
    /// Горизонтальный сдвиг кроны от ветра (чем выше точка, тем больше)
    let shear: CGFloat

    init(stage: PomegranateStage, size: CGSize, time: Double, thirst: Bool, compact: Bool,
         frame: PomegranateGrowthFrame? = nil) {
        let shownStage = frame?.stage ?? stage
        self.stage = shownStage
        self.size = size
        self.time = time
        self.thirst = thirst
        self.compact = compact
        self.frame = frame
        let H = max(1, size.height)
        let layout = PomegranateTreeLayout.cached(stage: shownStage, height: H)
        self.layout = layout
        let swell: CGFloat = 1 + (frame?.swell ?? 0)
        let baseFit: CGFloat = shownStage <= .sprout ? 1 : layout.fitScale(width: max(1, size.width), height: H)
        self.fit = baseFit * swell
        self.base = CGPoint(x: size.width / 2, y: H * 0.90)
        self.shear = CGFloat(sin(time * 0.9) * 0.014)
    }

    /// Насколько пробился побег у зёрнышка: в обычном виде ступени побега нет
    var seedGrowth: CGFloat { frame?.within ?? 0 }

    /// Насколько вытянулся росток: в обычном виде ступени он в полный рост
    var sproutGrowth: CGFloat { frame?.within ?? 1 }

    /// Области нажатия на плоды Духа в координатах вида.
    var fruitHitTargets: [HitTarget] {
        layout.fruits.map { hitTarget(for: $0) }
    }

    /// Области нажатия на выросшие плоды дня.
    var dailyHitTargets: [HitTarget] {
        let count = min(frame?.dailyFruits ?? 0, layout.dailySlots.count)
        return layout.dailySlots.prefix(count).map { hitTarget(for: $0) }
    }

    private func hitTarget(for fruit: PomegranateTreeLayout.Fruit) -> HitTarget {
        HitTarget(
            center: CGPoint(x: base.x + (fruit.x + shear * fruit.y) * fit, y: base.y + fruit.y * fit),
            diameter: max(30, fruit.r * fit * 2.6)
        )
    }
}

// MARK: - Отрисовка
enum PomegranateRenderer {
    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        PomegranatePalette.color(hex, alpha)
    }

    private static func quadPoint(_ s: PomegranateTreeLayout.Segment, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * s.x + 2 * u * t * s.mx + t * t * s.ex,
                       y: u * u * s.y + 2 * u * t * s.my + t * t * s.ey)
    }

    static func draw(_ scene: PomegranateScene, palette P: PomegranatePalette, in context: GraphicsContext) {
        let H = max(1, scene.size.height)
        let W = max(1, scene.size.width)
        let lw = max(0.5, H * 0.0035)
        var ctx = context
        ctx.translateBy(x: scene.base.x, y: scene.base.y)
        let frame = scene.frame

        // Прежняя ступень: растворяется, пока вырастает новая
        var ghost: PomegranateScene?
        if let frame, let ghostStage = frame.ghostStage, frame.ghostOpacity > 0.01 {
            ghost = PomegranateScene(
                stage: ghostStage,
                size: scene.size,
                time: scene.time,
                thirst: scene.thirst,
                compact: scene.compact,
                frame: PomegranateGrowthFrame(stage: ghostStage, within: frame.ghostWithin, dailyFruits: frame.ghostFruits)
            )
        }
        let ornamentsOnly = frame?.sameSkeleton ?? false
        let ghostOpacity = Double(frame?.ghostOpacity ?? 0)

        // 1. Нимб — в масштабе кроны
        if let ghost, !ornamentsOnly {
            var faded = ctx
            faded.opacity = ghostOpacity
            drawStageHalo(ghost, height: H, palette: P, in: faded)
        }
        var haloAlpha: CGFloat = 1
        if let frame {
            if let reveal = frame.reveal, !frame.sameSkeleton {
                haloAlpha = PomegranateEase.smooth((reveal - 0.45) / 0.45)
            }
            if let emerge = frame.emerge {
                haloAlpha = PomegranateEase.smooth(emerge)
            }
        }
        if haloAlpha > 0.01 {
            var haloCtx = ctx
            haloCtx.opacity = Double(haloAlpha)
            drawStageHalo(scene, height: H, palette: P, in: haloCtx)
        }

        // 2. Земля — всегда во всю ширину
        drawGround(width: W, height: H, lineWidth: lw, thirst: scene.thirst, compact: scene.compact, palette: P, in: ctx)

        // 3. Прежняя ступень — отдельным слоем, чтобы гасла целиком, а не по одному листу
        if let ghost {
            var faded = ctx
            faded.opacity = ghostOpacity
            faded.drawLayer { layer in
                drawBody(ghost, lineWidth: lw, palette: P, ornamentsOnly: ornamentsOnly, in: layer)
            }
        }

        // 4. Само растение
        drawBody(scene, lineWidth: lw, palette: P, ornamentsOnly: false, in: ctx)

        // 5. Росинка, с которой начинается рост
        if let frame {
            drawDew(frame, width: W, height: H, lineWidth: lw, compact: scene.compact, palette: P, in: ctx)
        }
    }

    private static func drawStageHalo(_ scene: PomegranateScene, height H: CGFloat, palette P: PomegranatePalette,
                                      in context: GraphicsContext) {
        guard scene.stage >= .sprout, !scene.compact else { return }
        var haloCtx = context
        haloCtx.scaleBy(x: scene.fit, y: scene.fit)
        if scene.stage == .sprout {
            drawHalo(cx: 0, cy: -H * 0.22, r: H * 0.24, stage: scene.stage, time: scene.time, palette: P, in: haloCtx)
        } else {
            let layout = scene.layout
            drawHalo(cx: layout.crownX, cy: layout.crownY, r: layout.crownR, stage: scene.stage, time: scene.time, palette: P, in: haloCtx)
        }
    }

    // MARK: Растение целиком: зёрнышко, росток или дерево
    private static func drawBody(_ scene: PomegranateScene, lineWidth lw: CGFloat, palette P: PomegranatePalette,
                                 ornamentsOnly: Bool, in context: GraphicsContext) {
        let H = max(1, scene.size.height)
        let W = max(1, scene.size.width)
        let frame = scene.frame

        if scene.stage == .seed {
            drawSeed(height: H, width: W, lineWidth: lw, time: scene.time, compact: scene.compact,
                     growth: scene.seedGrowth, palette: P, in: context)
            return
        }
        if scene.stage == .sprout {
            drawSprout(height: H, lineWidth: lw, time: scene.time, thirst: scene.thirst,
                       growth: scene.sproutGrowth, emerge: frame?.emerge ?? 1, palette: P, in: context)
            return
        }

        // Дерево: крона слегка «ведётся» ветром
        var ctx = context
        let layout = scene.layout
        let fit = scene.fit
        ctx.scaleBy(x: fit, y: fit)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: scene.shear, d: 1, tx: 0, ty: 0))
        let slw = lw / fit
        let detailed = !scene.compact

        // Часы вырастания нового дерева: сначала ветви, за ними листья, потом цветы и плоды
        let reveal = frame?.reveal
        let keepsCrown = reveal == nil || (frame?.sameSkeleton ?? false)
        let q: CGFloat = reveal ?? 1
        let skeleton: CGFloat = keepsCrown ? 1 : PomegranateEase.smooth(q / 0.50)
        let foliage: CGFloat = keepsCrown ? 1 : PomegranateEase.smooth((q - 0.10) / 0.60)
        let bloom: CGFloat = reveal == nil ? 1 : PomegranateEase.clamp((q - 0.62) / 0.22)
        let fruiting: CGFloat = reveal == nil ? 1 : PomegranateEase.clamp((q - 0.70) / 0.30)
        // Волна роста идёт от ствола к концам веток
        var wave: CGFloat?
        if let front = frame?.wave {
            wave = front * 1.4 - 0.2
        }

        if !ornamentsOnly {
            let births = layout.leafBirth
            let plainLeaves = foliage >= 1 && wave == nil
            func leafScale(_ index: Int) -> CGFloat {
                if plainLeaves { return 1 }
                let birth: CGFloat = index < births.count ? births[index] : 1
                var scale: CGFloat = 1
                if foliage < 1 {
                    scale = PomegranateEase.outBack((foliage * 1.28 - birth) / 0.28)
                }
                if let wave {
                    scale *= 1 + 0.34 * PomegranateEase.smooth(1 - abs(wave - birth) / 0.2)
                }
                return scale
            }

            if detailed {
                for (index, leaf) in layout.leaves.enumerated() where leaf.tone == 0 {
                    drawLeaf(leaf, scale: leafScale(index), lineWidth: slw, thirst: scene.thirst, palette: P, in: ctx)
                }
            }

            let unit = layout.growUnit
            let hasCachedPaths = layout.branchOutlines.count == layout.segments.count
                && layout.branchHighlights.count == layout.segments.count
            for (index, segment) in layout.segments.enumerated() {
                var grown: CGFloat = 1
                if skeleton < 1 {
                    grown = PomegranateEase.clamp((skeleton - CGFloat(segment.level) * unit) / (PomegranateTreeLayout.growSpan * unit))
                }
                if grown <= 0 { continue }
                if grown >= 1 && hasCachedPaths {
                    drawBranch(segment, outline: layout.branchOutlines[index], highlight: layout.branchHighlights[index],
                               lineWidth: slw, palette: P, in: ctx)
                } else {
                    drawBranch(segment, outline: branchOutline(segment, upTo: grown), highlight: branchHighlight(segment, upTo: grown),
                               lineWidth: slw, palette: P, in: ctx)
                }
            }

            for (index, leaf) in layout.leaves.enumerated() where leaf.tone != 0 {
                drawLeaf(leaf, scale: leafScale(index), lineWidth: slw, thirst: scene.thirst, palette: P, in: ctx)
            }

            // Золотые искры на фронте волны роста
            if let wave, detailed {
                for (index, leaf) in layout.leaves.enumerated() where index % 7 == 0 {
                    let birth: CGFloat = index < births.count ? births[index] : 1
                    let glow = PomegranateEase.smooth(1 - abs(wave - birth) / 0.16)
                    if glow <= 0.02 { continue }
                    let tipX = leaf.x + sin(leaf.angle) * leaf.length
                    let tipY = leaf.y - cos(leaf.angle) * leaf.length
                    let radius = H * 0.009 * (0.6 + 0.4 * glow)
                    ctx.fill(Path(ellipseIn: CGRect(x: tipX - radius, y: tipY - radius, width: radius * 2, height: radius * 2)),
                             with: .color(c(P.goldLight, 0.9 * Double(glow))))
                }
            }
        }

        for (index, bud) in layout.buds.enumerated() {
            let scale: CGFloat = bloom >= 1 ? 1
                : PomegranateEase.outBack(PomegranateEase.stagger(bloom, index: index, count: layout.buds.count, spread: 0.5))
            if scale > 0.01 {
                drawFlower(bud, isBud: true, scale: scale, lineWidth: slw, palette: P, in: ctx)
            }
        }
        for (index, flower) in layout.flowers.enumerated() {
            let scale: CGFloat = bloom >= 1 ? 1
                : PomegranateEase.outBack(PomegranateEase.stagger(bloom, index: index, count: layout.flowers.count, spread: 0.5))
            if scale > 0.01 {
                drawFlower(flower, isBud: false, scale: scale, lineWidth: slw, palette: P, in: ctx)
            }
        }

        // Плоды Духа и уже выросшие плоды дня
        let shownDaily = min(frame?.dailyFruits ?? 0, layout.dailySlots.count)
        let hangingFruits: [PomegranateTreeLayout.Fruit] = layout.fruits + Array(layout.dailySlots.prefix(shownDaily))
        for (index, fruit) in hangingFruits.enumerated() {
            if fruiting >= 1 {
                drawFruit(fruit, palette: P, lineWidth: slw, withStem: true, in: ctx)
                continue
            }
            let local = PomegranateEase.stagger(fruiting, index: index, count: hangingFruits.count, spread: 0.6)
            if local > 0 {
                let pose = PomegranateGrowthFrame.FruitPose(
                    scale: PomegranateEase.outBack(local),
                    ripeness: PomegranateEase.smooth((local - 0.2) / 0.7),
                    swing: 0,
                    sparkle: 0,
                    burst: 1
                )
                drawGrowingFruit(fruit, pose: pose, lineWidth: slw, palette: P, in: ctx)
            }
        }

        // Плоды дня, которые растут прямо сейчас
        if let frame {
            for item in frame.growing where item.index >= 0 && item.index < layout.dailySlots.count {
                drawGrowingFruit(layout.dailySlots[item.index], pose: PomegranateGrowthFrame.fruitPose(item.phase),
                                 lineWidth: slw, palette: P, in: ctx)
            }
        }

        if detailed && scene.stage >= .bloomingTree && !ornamentsOnly {
            let pollen: CGFloat = reveal == nil ? 1 : PomegranateEase.smooth((q - 0.6) / 0.4)
            if pollen > 0.01 {
                drawPollen(cx: layout.crownX, cy: layout.crownY, r: layout.crownR, height: H, time: scene.time,
                           alpha: Double(pollen), palette: P, in: ctx)
            }
        }
    }

    // MARK: Ветвь (сужающийся ствол по кривой)
    /// Контур ветви, выросшей на долю `upTo` своей длины. Для целой ветви считается один раз в макете.
    static func branchOutline(_ s: PomegranateTreeLayout.Segment, upTo: CGFloat) -> Path {
        let n = 8
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        // Растущая ветвь тоньше готовой
        let thin = 0.55 + 0.45 * upTo
        for i in 0...n {
            let t = upTo * CGFloat(i) / CGFloat(n)
            let p = quadPoint(s, t)
            let q = quadPoint(s, min(1, t + 0.01))
            let o = quadPoint(s, max(0, t - 0.01))
            var dx = q.x - o.x, dy = q.y - o.y
            let d = max(0.0001, hypot(dx, dy))
            dx /= d; dy /= d
            let w = (s.w0 + (s.w1 - s.w0) * t) / 2 * thin
            left.append(CGPoint(x: p.x - dy * w, y: p.y + dx * w))
            right.append(CGPoint(x: p.x + dy * w, y: p.y - dx * w))
        }
        var path = Path()
        path.move(to: left[0])
        for p in left.dropFirst() { path.addLine(to: p) }
        for p in right.reversed() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    /// Линия блика вдоль ветви.
    static func branchHighlight(_ s: PomegranateTreeLayout.Segment, upTo: CGFloat) -> Path {
        let n = 8
        var highlight = Path()
        for i in 1..<n {
            let t = upTo * CGFloat(i) / CGFloat(n)
            let p = quadPoint(s, t)
            let q = quadPoint(s, min(1, t + 0.01))
            let dx = q.x - p.x, dy = q.y - p.y
            let d = max(0.0001, hypot(dx, dy))
            let w = (s.w0 + (s.w1 - s.w0) * t) / 2
            let h = CGPoint(x: p.x - (dy / d) * w * 0.45, y: p.y + (dx / d) * w * 0.45)
            if i == 1 { highlight.move(to: h) } else { highlight.addLine(to: h) }
        }
        return highlight
    }

    private static func drawBranch(_ s: PomegranateTreeLayout.Segment, outline: Path, highlight: Path, lineWidth lw: CGFloat,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        ctx.fill(outline, with: .color(c(P.bark)))
        ctx.stroke(outline, with: .color(c(P.barkDark, 0.9)), lineWidth: lw)
        // Блик коры
        if s.w0 > lw * 3 {
            ctx.stroke(highlight, with: .color(c(P.barkLight, 0.8)),
                       style: StrokeStyle(lineWidth: max(lw, s.w0 * 0.12), lineCap: .round))
        }
    }

    // MARK: Лист граната (узкий, ланцетовидный)
    /// Лист единичной длины: один контур на все листья, размер задаётся масштабом при рисовании
    private static let leafUnitPath: Path = {
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -1), control: CGPoint(x: -0.21, y: -0.45))
        path.addQuadCurve(to: .zero, control: CGPoint(x: 0.21, y: -0.45))
        path.closeSubpath()
        return path
    }()

    private static let leafRibUnitPath: Path = {
        var rib = Path()
        rib.move(to: CGPoint(x: 0, y: -0.05))
        rib.addQuadCurve(to: CGPoint(x: 0, y: -0.92), control: CGPoint(x: 0.21 * 0.12, y: -0.5))
        return rib
    }()

    private static func drawLeaf(_ leaf: PomegranateTreeLayout.Leaf, scale: CGFloat = 1, lineWidth lw: CGFloat, thirst: Bool,
                                 palette P: PomegranatePalette, in context: GraphicsContext) {
        let len = leaf.length * scale
        guard len > 0.05 else { return }
        var ctx = context
        ctx.translateBy(x: leaf.x, y: leaf.y)
        ctx.rotate(by: .radians(Double(leaf.angle)))
        ctx.scaleBy(x: len, y: len)
        let tones = [P.leafDark, P.leaf, P.leafLight, P.leafYoung]
        var tone = tones[max(0, min(3, leaf.tone))]
        if thirst { tone = PomegranatePalette.mix(tone, P.soil, 0.38) }
        // Толщина линий задана в размерах листа, поэтому делится на его длину
        ctx.fill(leafUnitPath, with: .color(c(tone)))
        ctx.stroke(leafUnitPath, with: .color(c(P.ink, 0.28)), lineWidth: lw * 0.8 / len)
        ctx.stroke(leafRibUnitPath, with: .color(c(P.leafLight, 0.55)), lineWidth: lw * 0.7 / len)
    }

    // MARK: Корона-чашечка на нижнем конце висящего плода
    private static func drawCrownSepals(cx: CGFloat, bottomY: CGFloat, r: CGFloat, lineWidth lw: CGFloat, fill: UInt32,
                                        palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let nw = r * 0.34, nh = r * 0.20
        var path = Path()
        path.move(to: CGPoint(x: cx - nw * 0.60, y: bottomY - r * 0.10))
        path.addLine(to: CGPoint(x: cx - nw * 0.52, y: bottomY + nh * 0.2))
        let teeth = 6
        let spanW = nw * 1.5
        for i in 0...teeth {
            let tx = cx - spanW / 2 + spanW * CGFloat(i) / CGFloat(teeth)
            let outward = (CGFloat(i) / CGFloat(teeth) - 0.5) * 2
            let ty = i % 2 == 0 ? bottomY + nh * 0.6 : bottomY + nh + r * 0.26
            path.addLine(to: CGPoint(x: tx + outward * r * 0.04, y: ty))
        }
        path.addLine(to: CGPoint(x: cx + nw * 0.52, y: bottomY + nh * 0.2))
        path.addLine(to: CGPoint(x: cx + nw * 0.60, y: bottomY - r * 0.10))
        path.closeSubpath()
        ctx.fill(path, with: .color(c(fill)))
        ctx.stroke(path, with: .color(c(P.ink, 0.5)), lineWidth: lw)
    }

    // MARK: Плод граната: черенок сверху, корона снизу
    /// `ripeness`: 0 — зелёная завязь, 0.5 — золотистый, 1 — спелый красный плод.
    static func drawFruit(_ f: PomegranateTreeLayout.Fruit, palette P: PomegranatePalette, lineWidth lw: CGFloat,
                          withStem: Bool, in ctx: GraphicsContext, ripeness: CGFloat = 1) {
        let x = f.x, y = f.y, r = f.r
        var light = P.fruitLight
        var middle = P.fruit
        var dark = P.fruitDark
        if ripeness < 1 {
            let t = Double(max(0, ripeness))
            light = PomegranatePalette.mix3(P.leafLight, PomegranatePalette.mix(P.goldLight, P.pith, 0.45), P.fruitLight, t)
            middle = PomegranatePalette.mix3(P.leaf, PomegranatePalette.mix(P.goldLight, P.flowerLight, 0.35), P.fruit, t)
            dark = PomegranatePalette.mix3(P.leafDark, PomegranatePalette.mix(P.gold, P.flower, 0.4), P.fruitDark, t)
        }
        if withStem {
            var stem = Path()
            stem.move(to: CGPoint(x: f.stemX, y: f.stemY))
            stem.addQuadCurve(
                to: CGPoint(x: x, y: y - r * 0.98),
                control: CGPoint(x: f.stemX + (x - f.stemX) * 0.5, y: f.stemY + (y - r * 0.95 - f.stemY) * 0.4)
            )
            ctx.stroke(stem, with: .color(c(P.bark)), style: StrokeStyle(lineWidth: max(lw, r * 0.12), lineCap: .round))
        }
        drawCrownSepals(cx: x, bottomY: y + r * 0.92, r: r, lineWidth: lw, fill: dark, palette: P, in: ctx)

        // «Плечи» шире, книзу плод слегка сужается
        var body = Path()
        body.move(to: CGPoint(x: x, y: y - r * 0.96))
        body.addCurve(to: CGPoint(x: x + r * 0.22, y: y + r * 0.95),
                      control1: CGPoint(x: x + r * 1.18, y: y - r * 1.00),
                      control2: CGPoint(x: x + r * 1.12, y: y + r * 0.55))
        body.addLine(to: CGPoint(x: x - r * 0.22, y: y + r * 0.95))
        body.addCurve(to: CGPoint(x: x, y: y - r * 0.96),
                      control1: CGPoint(x: x - r * 1.12, y: y + r * 0.55),
                      control2: CGPoint(x: x - r * 1.18, y: y - r * 1.00))
        body.closeSubpath()
        ctx.fill(body, with: .radialGradient(
            Gradient(stops: [
                .init(color: c(light), location: 0),
                .init(color: c(middle), location: 0.45),
                .init(color: c(dark), location: 1)
            ]),
            center: CGPoint(x: x - r * 0.38, y: y - r * 0.42),
            startRadius: r * 0.08,
            endRadius: r * 1.25
        ))
        ctx.stroke(body, with: .color(c(P.ink, 0.45)), lineWidth: lw)

        var inner = ctx
        inner.clip(to: body)
        for k: CGFloat in [-0.5, 0.5] {
            var rib = Path()
            rib.move(to: CGPoint(x: x + r * k * 0.3, y: y - r))
            rib.addQuadCurve(to: CGPoint(x: x + r * k * 0.25, y: y + r), control: CGPoint(x: x + r * k * 1.45, y: y))
            inner.stroke(rib, with: .color(c(dark, 0.30)), lineWidth: lw * 0.9)
        }
        if f.isOpen {
            // Раскрытая долька с рубиновыми зёрнами
            let center = CGPoint(x: x, y: y + r * 0.05)
            var wedge = Path()
            wedge.move(to: center)
            let steps = 16
            for i in 0...steps {
                let angle = Double.pi * (0.08 + 0.84 * Double(i) / Double(steps))
                wedge.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * r * 0.78,
                                          y: center.y + CGFloat(sin(angle)) * r * 0.78))
            }
            wedge.closeSubpath()
            inner.fill(wedge, with: .color(c(P.pith)))
            inner.stroke(wedge, with: .color(c(P.fruitDark, 0.7)), lineWidth: lw)
            var arils = PomegranateRandom(seed: UInt32(truncatingIfNeeded: Int((x * 7 + y * 13).rounded())))
            for _ in 0..<16 {
                let angle = CGFloat.pi * (0.14 + arils.next() * 0.72)
                let dist = r * (0.18 + arils.next() * 0.52)
                let ax = x + cos(angle) * dist
                let ay = y + r * 0.05 + sin(angle) * dist
                let ar = r * (0.10 + arils.next() * 0.04)
                let seed = Path(ellipseIn: CGRect(x: -ar, y: -ar * 1.15, width: ar * 2, height: ar * 2.3))
                    .applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: ax, y: ay)))
                inner.fill(seed, with: .color(c(P.aril)))
                let shine = Path(ellipseIn: CGRect(x: ax - ar * 0.3 - ar * 0.32, y: ay - ar * 0.35 - ar * 0.32,
                                                   width: ar * 0.64, height: ar * 0.64))
                inner.fill(shine, with: .color(c(P.arilLight, 0.9)))
            }
        }
        // Блик
        let gloss = Path(ellipseIn: CGRect(x: -r * 0.20, y: -r * 0.12, width: r * 0.40, height: r * 0.24))
            .applying(CGAffineTransform(rotationAngle: -0.6).concatenating(CGAffineTransform(translationX: x - r * 0.42, y: y - r * 0.46)))
        ctx.fill(gloss, with: .color(Color.white.opacity(0.55)))
    }

    // MARK: Плод в росте
    /// Плод растёт и качается вокруг точки, где черенок держится за ветку: завязь, рост, наливание цветом, искра.
    private static func drawGrowingFruit(_ f: PomegranateTreeLayout.Fruit, pose: PomegranateGrowthFrame.FruitPose,
                                         lineWidth lw: CGFloat, palette P: PomegranatePalette, in context: GraphicsContext) {
        let s = max(0.02, pose.scale)
        let r = f.r
        var ctx = context
        ctx.translateBy(x: f.stemX, y: f.stemY)
        ctx.rotate(by: .radians(Double(pose.swing)))
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -f.stemX, y: -f.stemY)

        // Сияние за созревшим плодом
        if pose.sparkle > 0.01 {
            let glowRadius = r * 2.4
            ctx.fill(
                Path(ellipseIn: CGRect(x: f.x - glowRadius, y: f.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                with: .radialGradient(
                    Gradient(colors: [c(P.halo, 0.55 * Double(pose.sparkle)), c(P.halo, 0)]),
                    center: CGPoint(x: f.x, y: f.y),
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )
        }

        drawFruit(f, palette: P, lineWidth: lw / s, withStem: true, in: ctx, ripeness: pose.ripeness)

        // Золотые искры разлетаются в момент, когда плод набрал размер
        if pose.burst > 0 && pose.burst < 1 {
            let distance = r * (1.15 + 1.5 * PomegranateEase.outCubic(pose.burst))
            let dot = r * 0.11 * (1 - pose.burst * 0.6)
            for i in 0..<8 {
                let angle = CGFloat(i) / 8 * 2 * .pi + 0.3
                let px = f.x + cos(angle) * distance
                let py = f.y + sin(angle) * distance
                ctx.fill(Path(ellipseIn: CGRect(x: px - dot, y: py - dot, width: dot * 2, height: dot * 2)),
                         with: .color(c(P.goldLight, 0.95 * Double(1 - pose.burst))))
            }
        }

        // Четырёхлучевая искра на блике
        if pose.sparkle > 0.01 {
            let cx = f.x - r * 0.42
            let cy = f.y - r * 0.46
            let long = r * 0.62 * pose.sparkle
            let short = long * 0.22
            var star = Path()
            for i in 0..<8 {
                let angle = CGFloat(i) / 8 * 2 * .pi
                let reach = i % 2 == 0 ? long : short
                let point = CGPoint(x: cx + cos(angle) * reach, y: cy + sin(angle) * reach)
                if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(Color.white.opacity(0.95 * Double(pose.sparkle))))
        }
    }

    // MARK: Цветок и бутон граната (воронка с гофрированными лепестками)
    private static func drawFlower(_ f: PomegranateTreeLayout.Flower, isBud: Bool, scale: CGFloat = 1, lineWidth lw: CGFloat,
                                   palette P: PomegranatePalette, in context: GraphicsContext) {
        var ctx = context
        ctx.translateBy(x: f.x, y: f.y)
        ctx.rotate(by: .radians(Double(f.angle * 0.7)))
        let s = f.size * scale
        if !isBud {
            for (dx, rot) in [(CGFloat(-0.30), -0.5), (0.30, 0.5), (0, 0)] {
                var petalCtx = ctx
                petalCtx.translateBy(x: dx * s, y: -s * 1.05)
                petalCtx.rotate(by: .radians(rot))
                let petal = Path(ellipseIn: CGRect(x: -s * 0.34, y: -s * 0.30 - s * 0.42, width: s * 0.68, height: s * 0.84))
                petalCtx.fill(petal, with: .color(c(P.flowerLight)))
                petalCtx.stroke(petal, with: .color(c(P.ink, 0.3)), lineWidth: lw * 0.8)
            }
        }
        let h = isBud ? s * 1.0 : s * 1.15
        let wb = s * 0.30, wn = s * 0.20, wt = isBud ? s * 0.26 : s * 0.44
        var calyx = Path()
        calyx.move(to: CGPoint(x: -wb * 0.3, y: 0))
        calyx.addQuadCurve(to: CGPoint(x: -wn, y: -h * 0.62), control: CGPoint(x: -wb * 1.4, y: -h * 0.35))
        calyx.addLine(to: CGPoint(x: -wt, y: -h))
        calyx.addLine(to: CGPoint(x: -wt * 0.45, y: -h * 0.86))
        calyx.addLine(to: CGPoint(x: 0, y: -h * 1.02))
        calyx.addLine(to: CGPoint(x: wt * 0.45, y: -h * 0.86))
        calyx.addLine(to: CGPoint(x: wt, y: -h))
        calyx.addLine(to: CGPoint(x: wn, y: -h * 0.62))
        calyx.addQuadCurve(to: CGPoint(x: wb * 0.3, y: 0), control: CGPoint(x: wb * 1.4, y: -h * 0.35))
        calyx.closeSubpath()
        ctx.fill(calyx, with: .linearGradient(
            Gradient(colors: [c(P.fruitDark), c(P.flower)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: -h)
        ))
        ctx.stroke(calyx, with: .color(c(P.ink, 0.4)), lineWidth: lw * 0.9)
        if !isBud {
            for dx: CGFloat in [-0.16, 0, 0.16] {
                let dot = Path(ellipseIn: CGRect(x: dx * s - s * 0.07, y: -h * 1.08 - s * 0.07, width: s * 0.14, height: s * 0.14))
                ctx.fill(dot, with: .color(c(P.goldLight)))
            }
        }
    }

    // MARK: Земля
    private static func groundHalfWidth(width W: CGFloat, height H: CGFloat, compact: Bool) -> CGFloat {
        compact ? H * 0.42 : min(W * 0.36, H * 0.62)
    }

    private static func drawGround(width W: CGFloat, height H: CGFloat, lineWidth lw: CGFloat, thirst: Bool, compact: Bool,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let gw = groundHalfWidth(width: W, height: H, compact: compact)
        let gh = H * 0.055
        var mound = Path()
        mound.move(to: CGPoint(x: -gw, y: 0))
        mound.addQuadCurve(to: CGPoint(x: gw, y: 0), control: CGPoint(x: 0, y: -gh * 2))
        mound.addQuadCurve(to: CGPoint(x: -gw, y: 0), control: CGPoint(x: 0, y: gh * 0.9))
        mound.closeSubpath()
        let topColor = thirst ? PomegranatePalette.mix(P.soil, P.gold, 0.3) : P.soil
        ctx.fill(mound, with: .linearGradient(
            Gradient(colors: [c(topColor), c(P.soilDark)]),
            startPoint: CGPoint(x: 0, y: -gh),
            endPoint: CGPoint(x: 0, y: gh)
        ))
        var rim = Path()
        rim.move(to: CGPoint(x: -gw, y: 0))
        rim.addQuadCurve(to: CGPoint(x: gw, y: 0), control: CGPoint(x: 0, y: -gh * 2))
        ctx.stroke(rim, with: .color(c(P.ink, 0.35)), lineWidth: lw)
        guard !compact else { return }

        // Штриховка, как на гравюре
        for i in -5...5 {
            let x = CGFloat(i) * gw * 0.16
            let top = -gh * 2 * (1 - (x / gw) * (x / gw)) * 0.5
            var hatch = Path()
            hatch.move(to: CGPoint(x: x - gw * 0.03, y: top + gh * 0.35))
            hatch.addLine(to: CGPoint(x: x + gw * 0.03, y: top + gh * 0.75))
            ctx.stroke(hatch, with: .color(c(P.ink, 0.16)), lineWidth: lw * 0.8)
        }
        // Пучки травы
        var rng = PomegranateRandom(seed: 77)
        let grass = thirst ? PomegranatePalette.mix(P.leaf, P.soil, 0.45) : P.leaf
        for sx: CGFloat in [-0.78, -0.55, 0.52, 0.80] {
            let bx = sx * gw
            let by = -gh * 2 * (1 - sx * sx) * 0.5 + 1
            for k in 0..<4 {
                let a = (CGFloat(k) - 1.5) * 0.28 + (rng.next() - 0.5) * 0.2
                let l = H * (0.028 + rng.next() * 0.022)
                var blade = Path()
                blade.move(to: CGPoint(x: bx, y: by))
                blade.addQuadCurve(to: CGPoint(x: bx + sin(a) * l, y: by - l * cos(a)),
                                   control: CGPoint(x: bx + sin(a) * l * 0.4, y: by - l * 0.6))
                ctx.stroke(blade, with: .color(c(grass)), style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))
            }
        }
    }

    // MARK: Росинка
    /// Росинка падает к корням и расходится кольцом по земле: с неё начинается рост после задания.
    private static func drawDew(_ frame: PomegranateGrowthFrame, width W: CGFloat, height H: CGFloat, lineWidth lw: CGFloat,
                                compact: Bool, palette P: PomegranatePalette, in ctx: GraphicsContext) {
        if let fall = frame.drop {
            let d = PomegranateEase.clamp(fall)
            let y = -H * 0.66 + H * 0.64 * d * d
            let r = H * 0.017
            let alpha = Double(PomegranateEase.clamp(d / 0.2))
            var drop = Path()
            drop.move(to: CGPoint(x: 0, y: y - r * 2.3))
            drop.addCurve(to: CGPoint(x: r, y: y),
                          control1: CGPoint(x: r * 0.5, y: y - r * 1.2),
                          control2: CGPoint(x: r, y: y - r * 0.5))
            drop.addCurve(to: CGPoint(x: -r, y: y),
                          control1: CGPoint(x: r, y: y + r * 1.33),
                          control2: CGPoint(x: -r, y: y + r * 1.33))
            drop.addCurve(to: CGPoint(x: 0, y: y - r * 2.3),
                          control1: CGPoint(x: -r, y: y - r * 0.5),
                          control2: CGPoint(x: -r * 0.5, y: y - r * 1.2))
            drop.closeSubpath()
            ctx.fill(drop, with: .color(c(P.dew, 0.95 * alpha)))
            ctx.stroke(drop, with: .color(c(P.ink, 0.25 * alpha)), lineWidth: lw * 0.8)
            let shine = r * 0.26
            ctx.fill(Path(ellipseIn: CGRect(x: -r * 0.35 - shine, y: y - r * 0.2 - shine, width: shine * 2, height: shine * 2)),
                     with: .color(Color.white.opacity(0.9 * alpha)))
        }
        if let spread = frame.ripple {
            let p = PomegranateEase.clamp(spread)
            let gw = groundHalfWidth(width: W, height: H, compact: compact)
            let rx = gw * (0.12 + 0.62 * PomegranateEase.outCubic(p))
            let ry = rx * 0.16
            let ring = Path(ellipseIn: CGRect(x: -rx, y: -H * 0.02 - ry, width: rx * 2, height: ry * 2))
            ctx.stroke(ring, with: .color(c(P.dew, 0.85 * Double(1 - p))), lineWidth: lw * 2.2 * (1 - p * 0.6))
        }
    }

    // MARK: Нимб
    private static func drawHalo(cx: CGFloat, cy: CGFloat, r: CGFloat, stage: PomegranateStage, time: Double,
                                 palette P: PomegranatePalette, in context: GraphicsContext) {
        let rr = r * 1.15
        let glow = Path(ellipseIn: CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2))
        context.fill(glow, with: .radialGradient(
            Gradient(stops: [
                .init(color: c(P.halo, stage >= .treeOfLife ? 0.42 : 0.26), location: 0),
                .init(color: c(P.halo, 0.10), location: 0.6),
                .init(color: c(P.halo, 0), location: 1)
            ]),
            center: CGPoint(x: cx, y: cy),
            startRadius: rr * 0.1,
            endRadius: rr
        ))
        guard stage >= .treeOfLife else { return }

        // Золотой нимб с лучами — как в рукописях
        var ctx = context
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: .radians(time * 0.04))
        let ring = Path(ellipseIn: CGRect(x: -r * 0.98, y: -r * 0.98, width: r * 1.96, height: r * 1.96))
        ctx.stroke(ring, with: .color(c(P.gold, 0.55)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        for i in 0..<36 {
            let a = Double(i) / 36 * 2 * .pi
            let r0 = r * 1.02
            let r1 = r * (i % 2 == 1 ? 1.07 : 1.12)
            var ray = Path()
            ray.move(to: CGPoint(x: CGFloat(cos(a)) * r0, y: CGFloat(sin(a)) * r0))
            ray.addLine(to: CGPoint(x: CGFloat(cos(a)) * r1, y: CGFloat(sin(a)) * r1))
            ctx.stroke(ray, with: .color(c(P.gold, i % 2 == 1 ? 0.25 : 0.45)), lineWidth: 1)
        }
    }

    // MARK: Стадия 1: зёрнышко и обетование будущего Древа
    /// `growth` 0...1: после заданий корешки удлиняются, из зёрнышка пробивается побег с двумя листками.
    private static func drawSeed(height H: CGFloat, width W: CGFloat, lineWidth lw: CGFloat, time: Double, compact: Bool,
                                 growth: CGFloat, palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let r = compact ? H * 0.11 : H * 0.06
        let grown = PomegranateEase.clamp(growth)
        if !compact {
            // Нисходящий луч света
            var beam = Path()
            beam.move(to: CGPoint(x: -H * 0.05, y: -H * 0.85))
            beam.addLine(to: CGPoint(x: H * 0.05, y: -H * 0.85))
            beam.addLine(to: CGPoint(x: H * 0.14, y: 0))
            beam.addLine(to: CGPoint(x: -H * 0.14, y: 0))
            beam.closeSubpath()
            ctx.fill(beam, with: .linearGradient(
                Gradient(stops: [
                    .init(color: c(P.halo, 0), location: 0),
                    .init(color: c(P.halo, 0.30), location: 0.7),
                    .init(color: c(P.halo, 0.05), location: 1)
                ]),
                startPoint: CGPoint(x: 0, y: -H * 0.85),
                endPoint: .zero
            ))

            // Золотой пунктир будущего Древа Жизни
            let vision = PomegranateTreeLayout.cached(stage: .treeOfLife, height: H)
            let visionFit = vision.fitScale(width: W, height: H)
            var visionCtx = ctx
            visionCtx.scaleBy(x: visionFit, y: visionFit)
            for s in vision.segments {
                var branch = Path()
                branch.move(to: CGPoint(x: s.x, y: s.y))
                branch.addQuadCurve(to: CGPoint(x: s.ex, y: s.ey), control: CGPoint(x: s.mx, y: s.my))
                visionCtx.stroke(branch, with: .color(c(P.gold, 0.22)),
                                 style: StrokeStyle(lineWidth: max(0.8, s.w0 * 0.18) / visionFit, lineCap: .round, dash: [2 / visionFit, 4 / visionFit]))
            }

            // Корешки
            let reach = 1 + 0.45 * grown
            for dx: CGFloat in [-1, 0, 1] {
                var root = Path()
                root.move(to: CGPoint(x: 0, y: -r * 0.2))
                root.addQuadCurve(to: CGPoint(x: dx * r * 1.6 * reach, y: (r * 0.7 + (dx == 0 ? r * 0.3 : 0)) * reach),
                                  control: CGPoint(x: dx * r * 0.8 * reach, y: r * 0.4 * reach))
                ctx.stroke(root, with: .color(c(P.gold, 0.7)), lineWidth: lw)
            }
        }

        // Побег пробивается из зёрнышка
        let shoot = PomegranateEase.smooth((grown - 0.12) / 0.88)
        if shoot > 0.01 {
            let x0 = -r * 0.31
            let y0 = -r * 1.90
            let length = H * 0.12 * shoot
            let tip = CGPoint(x: x0 + length * 0.22, y: y0 - length)
            var stalk = Path()
            stalk.move(to: CGPoint(x: x0, y: y0 + r * 0.5))
            stalk.addCurve(to: tip,
                           control1: CGPoint(x: x0 - length * 0.22, y: y0 - length * 0.35),
                           control2: CGPoint(x: x0 + length * 0.30, y: y0 - length * 0.62))
            ctx.stroke(stalk, with: .color(c(P.leafLight)), style: StrokeStyle(lineWidth: H * 0.010, lineCap: .round))
            let unfold = PomegranateEase.smooth((shoot - 0.45) / 0.55)
            if unfold > 0.02 {
                for side: CGFloat in [-1, 1] {
                    let leaf = PomegranateTreeLayout.Leaf(
                        x: tip.x,
                        y: tip.y,
                        angle: side * (0.35 + 0.55 * unfold),
                        length: H * 0.050 * unfold,
                        tone: side > 0 ? 2 : 3
                    )
                    drawLeaf(leaf, lineWidth: lw, thirst: false, palette: P, in: ctx)
                }
            }
        }

        // Светящееся зёрнышко граната
        let pulse = 0.5 + 0.5 * sin(time * 1.6)
        let glowRect = CGRect(x: -r * 2.6, y: -r * 0.8 - r * 2.6, width: r * 5.2, height: r * 5.2)
        ctx.fill(Path(ellipseIn: glowRect), with: .radialGradient(
            Gradient(colors: [c(P.aril, 0.30 + 0.15 * pulse), c(P.aril, 0)]),
            center: CGPoint(x: 0, y: -r * 0.8),
            startRadius: 0,
            endRadius: r * 2.6
        ))
        var seedCtx = ctx
        seedCtx.translateBy(x: 0, y: -r * 0.75)
        seedCtx.rotate(by: .radians(-0.25))
        var seed = Path()
        seed.move(to: CGPoint(x: 0, y: -r * 1.25))
        seed.addCurve(to: CGPoint(x: 0, y: r * 0.8), control1: CGPoint(x: r * 0.95, y: -r * 0.4), control2: CGPoint(x: r * 0.85, y: r * 0.75))
        seed.addCurve(to: CGPoint(x: 0, y: -r * 1.25), control1: CGPoint(x: -r * 0.85, y: r * 0.75), control2: CGPoint(x: -r * 0.95, y: -r * 0.4))
        seed.closeSubpath()
        seedCtx.fill(seed, with: .radialGradient(
            Gradient(stops: [
                .init(color: c(P.arilLight), location: 0),
                .init(color: c(P.aril), location: 0.5),
                .init(color: c(P.fruitDark), location: 1)
            ]),
            center: CGPoint(x: -r * 0.3, y: -r * 0.3),
            startRadius: r * 0.05,
            endRadius: r * 1.4
        ))
        seedCtx.stroke(seed, with: .color(c(P.ink, 0.45)), lineWidth: lw)
        let shine = Path(ellipseIn: CGRect(x: -r * 0.16, y: -r * 0.3, width: r * 0.32, height: r * 0.6))
            .applying(CGAffineTransform(rotationAngle: -0.3).concatenating(CGAffineTransform(translationX: -r * 0.28, y: -r * 0.45)))
        seedCtx.fill(shine, with: .color(Color.white.opacity(0.6)))
    }

    // MARK: Стадия 2: росток (молодые листья — бронзовые)
    /// `growth` 0...1: рост внутри ступени (1 — росток в полный рост, как в обычном виде).
    /// `emerge` 0...1: росток поднимается из земли при переходе с зёрнышка.
    private static func drawSprout(height H: CGFloat, lineWidth lw: CGFloat, time: Double, thirst: Bool,
                                   growth: CGFloat, emerge: CGFloat, palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let grown = max(0, min(1.1, growth))
        let rise = PomegranateEase.clamp(emerge)
        let h = max(H * 0.004, H * (0.20 + 0.10 * grown) * rise)
        let sw = CGFloat(sin(time * 0.9)) * H * 0.006 * rise
        var stem = Path()
        stem.move(to: .zero)
        stem.addCurve(to: CGPoint(x: sw, y: -h),
                      control1: CGPoint(x: -H * 0.02 * rise, y: -h * 0.35),
                      control2: CGPoint(x: (H * 0.02 + sw * 0.5) * rise, y: -h * 0.65))
        ctx.stroke(stem, with: .color(c(P.leaf)), style: StrokeStyle(lineWidth: H * 0.012, lineCap: .round))

        let leafLength = H * 0.095
        let droop: CGFloat = thirst ? 0.35 : 0
        // Узлы стоят на своей высоте: пара листьев раскрывается, когда стебель до неё дорос
        let nodes: [(CGFloat, CGFloat, CGFloat)] = [(H * 0.135, 1.0, 0.8), (H * 0.234, 0.85, 1.0)]
        var upperOpen: CGFloat = 0
        for (index, node) in nodes.enumerated() {
            let (nodeY, s, k) = node
            let open = PomegranateEase.smooth((h - nodeY) / (H * 0.045))
            if index == 1 { upperOpen = open }
            if open <= 0.02 { continue }
            for side: CGFloat in [-1, 1] {
                let leaf = PomegranateTreeLayout.Leaf(
                    x: sw * (nodeY / h),
                    y: -nodeY,
                    angle: side * (0.95 + droop) + sw * 0.02,
                    length: leafLength * s * k * open,
                    tone: nodeY > h * 0.7 ? 3 : (side > 0 ? 2 : 1)
                )
                drawLeaf(leaf, lineWidth: lw, thirst: thirst, palette: P, in: ctx)
            }
        }
        // Верхушечная пара молодых листьев
        let tipOpen = PomegranateEase.smooth((rise - 0.25) / 0.5) * (0.72 + 0.28 * min(1, grown))
        if tipOpen > 0.02 {
            for side: CGFloat in [-1, 1] {
                let leaf = PomegranateTreeLayout.Leaf(
                    x: sw,
                    y: -h,
                    angle: side * (0.95 + droop) + sw * 0.02,
                    length: leafLength * 0.7 * 0.75 * tipOpen,
                    tone: 3
                )
                drawLeaf(leaf, lineWidth: lw, thirst: thirst, palette: P, in: ctx)
            }
        }
        // Росинка на верхнем листе
        if upperOpen > 0.6 {
            let alpha = Double((upperOpen - 0.6) / 0.4)
            let dx = sw + leafLength * 0.55, dy = -H * 0.234 - leafLength * 0.35
            let dr = H * 0.010
            ctx.fill(Path(ellipseIn: CGRect(x: dx - dr, y: dy - dr, width: dr * 2, height: dr * 2)), with: .color(c(P.dew, 0.95 * alpha)))
            let hr = H * 0.003
            ctx.fill(Path(ellipseIn: CGRect(x: dx - H * 0.003 - hr, y: dy - H * 0.003 - hr, width: hr * 2, height: hr * 2)),
                     with: .color(Color.white.opacity(0.9 * alpha)))
        }
    }

    // MARK: Золотая пыльца
    private static func drawPollen(cx: CGFloat, cy: CGFloat, r: CGFloat, height H: CGFloat, time: Double, alpha: Double = 1,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let span = Double(H * 0.75)
        for i in 0..<12 {
            let travel = (time * 10 + Double(i) * 41).truncatingRemainder(dividingBy: span)
            let y = cy + r - CGFloat(travel)
            let x = cx + CGFloat(sin(time * 0.5 + Double(i) * 1.7)) * r * 0.9 * (CGFloat(i % 5) / 5 + 0.3)
            let fade = sin(travel / span * .pi)
            let size: CGFloat = i % 3 == 0 ? 1.8 : 1.1
            ctx.fill(Path(ellipseIn: CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)),
                     with: .color(c(P.goldLight, 0.75 * fade * alpha)))
        }
    }
}
