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
    var crownX: CGFloat = 0
    var crownY: CGFloat = 0
    var crownR: CGFloat = 0
    var minX: CGFloat = 0
    var maxX: CGFloat = 0
    var minY: CGFloat = 0

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

        func sign(_ v: CGFloat) -> CGFloat { v > 0 ? 1 : (v < 0 ? -1 : 0) }
        func point(_ t: CGFloat, _ s: Segment) -> CGPoint {
            let u = 1 - t
            return CGPoint(x: u * u * s.x + 2 * u * t * s.mx + t * t * s.ex,
                           y: u * u * s.y + 2 * u * t * s.my + t * t * s.ey)
        }
        func addLeaf(_ x: CGFloat, _ y: CGFloat, _ angle: CGFloat, _ length: CGFloat, _ tone: Int) {
            out.leaves.append(Leaf(x: x, y: y, angle: angle, length: length, tone: tone))
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
                    addLeaf(pt.x, pt.y, a + spread, l1, young ? 3 : (rng.next() < 0.3 ? 0 : 1))
                    let l2 = H * p.leaf * k * (0.9 + rng.next() * 0.2)
                    addLeaf(pt.x, pt.y, a - spread, l2, young ? 3 : (rng.next() < 0.3 ? 0 : 2))
                }
                addLeaf(ex, ey, a + (rng.next() - 0.5) * 0.25, H * p.leaf * 1.1, rng.next() < 0.55 ? 3 : 2)
                return
            }

            let n = (level >= 1 && rng.next() < 0.30) ? 3 : 2
            var kids: [CGFloat] = []
            if n == 2 {
                kids.append(-(0.30 + rng.next() * 0.24))
                kids.append(0.28 + rng.next() * 0.26)
            } else {
                kids.append(-(0.52 + rng.next() * 0.14))
                kids.append((rng.next() - 0.5) * 0.20)
                kids.append(0.52 + rng.next() * 0.14)
            }
            for da in kids {
                var na = a + da - sign(a + da) * 0.045 * CGFloat(level)
                na = max(-1.50, min(1.50, na))
                let childLength = len * (0.72 + rng.next() * 0.12)
                grow(ex, ey, na, childLength, w * 0.66, depth - 1, level + 1)
            }
            // Боковая веточка с листьями
            if depth <= 2 && rng.next() < 0.8 {
                let t = 0.5 + rng.next() * 0.35
                let pt = point(t, seg)
                let side: CGFloat = rng.next() < 0.5 ? -1 : 1
                for k in 0..<2 {
                    let angle = a + side * (0.8 + CGFloat(k) * 0.5 + rng.next() * 0.2)
                    addLeaf(pt.x, pt.y, angle, H * p.leaf * 0.9, rng.next() < 0.4 ? 0 : 1)
                }
            }
        }

        if p.stems > 1 {
            for i in 0..<p.stems {
                let f = (CGFloat(i) / CGFloat(p.stems - 1) - 0.5) * 2
                let ang = f * 0.34 + (rng.next() - 0.5) * 0.10
                let x0 = f * H * 0.030
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
    let layout: PomegranateTreeLayout
    let fit: CGFloat
    let base: CGPoint
    /// Горизонтальный сдвиг кроны от ветра (чем выше точка, тем больше)
    let shear: CGFloat

    init(stage: PomegranateStage, size: CGSize, time: Double, thirst: Bool, compact: Bool) {
        self.stage = stage
        self.size = size
        self.time = time
        self.thirst = thirst
        self.compact = compact
        let H = max(1, size.height)
        let layout = PomegranateTreeLayout.cached(stage: stage, height: H)
        self.layout = layout
        self.fit = stage <= .sprout ? 1 : layout.fitScale(width: max(1, size.width), height: H)
        self.base = CGPoint(x: size.width / 2, y: H * 0.90)
        self.shear = CGFloat(sin(time * 0.9) * 0.014)
    }

    /// Области нажатия на плоды в координатах вида.
    var fruitHitTargets: [HitTarget] {
        layout.fruits.map { fruit in
            HitTarget(
                center: CGPoint(x: base.x + (fruit.x + shear * fruit.y) * fit, y: base.y + fruit.y * fit),
                diameter: max(30, fruit.r * fit * 2.6)
            )
        }
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
        let layout = scene.layout
        let fit = scene.fit

        // 1. Нимб — в масштабе кроны
        if scene.stage >= .sprout && !scene.compact {
            var haloCtx = ctx
            haloCtx.scaleBy(x: fit, y: fit)
            if scene.stage == .sprout {
                drawHalo(cx: 0, cy: -H * 0.22, r: H * 0.24, stage: scene.stage, time: scene.time, palette: P, in: haloCtx)
            } else {
                drawHalo(cx: layout.crownX, cy: layout.crownY, r: layout.crownR, stage: scene.stage, time: scene.time, palette: P, in: haloCtx)
            }
        }

        // 2. Земля — всегда во всю ширину
        drawGround(width: W, height: H, lineWidth: lw, thirst: scene.thirst, compact: scene.compact, palette: P, in: ctx)

        if scene.stage == .seed {
            drawSeed(height: H, width: W, lineWidth: lw, time: scene.time, compact: scene.compact, palette: P, in: ctx)
            return
        }
        if scene.stage == .sprout {
            drawSprout(height: H, lineWidth: lw, time: scene.time, thirst: scene.thirst, palette: P, in: ctx)
            return
        }

        // 3. Дерево: крона слегка «ведётся» ветром
        ctx.scaleBy(x: fit, y: fit)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: scene.shear, d: 1, tx: 0, ty: 0))
        let slw = lw / fit
        let detailed = !scene.compact
        for leaf in layout.leaves where leaf.tone == 0 && detailed {
            drawLeaf(leaf, lineWidth: slw, thirst: scene.thirst, palette: P, in: ctx)
        }
        for segment in layout.segments {
            drawBranch(segment, lineWidth: slw, palette: P, in: ctx)
        }
        for leaf in layout.leaves where leaf.tone != 0 {
            drawLeaf(leaf, lineWidth: slw, thirst: scene.thirst, palette: P, in: ctx)
        }
        for bud in layout.buds {
            drawFlower(bud, isBud: true, lineWidth: slw, palette: P, in: ctx)
        }
        for flower in layout.flowers {
            drawFlower(flower, isBud: false, lineWidth: slw, palette: P, in: ctx)
        }
        for fruit in layout.fruits {
            drawFruit(fruit, palette: P, lineWidth: slw, withStem: true, in: ctx)
        }
        if detailed && scene.stage >= .bloomingTree {
            drawPollen(cx: layout.crownX, cy: layout.crownY, r: layout.crownR, height: H, time: scene.time, palette: P, in: ctx)
        }
    }

    // MARK: Ветвь (сужающийся ствол по кривой)
    private static func drawBranch(_ s: PomegranateTreeLayout.Segment, lineWidth lw: CGFloat, palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let n = 8
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let p = quadPoint(s, t)
            let q = quadPoint(s, min(1, t + 0.01))
            let o = quadPoint(s, max(0, t - 0.01))
            var dx = q.x - o.x, dy = q.y - o.y
            let d = max(0.0001, hypot(dx, dy))
            dx /= d; dy /= d
            let w = (s.w0 + (s.w1 - s.w0) * t) / 2
            left.append(CGPoint(x: p.x - dy * w, y: p.y + dx * w))
            right.append(CGPoint(x: p.x + dy * w, y: p.y - dx * w))
        }
        var path = Path()
        path.move(to: left[0])
        for p in left.dropFirst() { path.addLine(to: p) }
        for p in right.reversed() { path.addLine(to: p) }
        path.closeSubpath()
        ctx.fill(path, with: .color(c(P.bark)))
        ctx.stroke(path, with: .color(c(P.barkDark, 0.9)), lineWidth: lw)

        // Блик коры
        if s.w0 > lw * 3 {
            var highlight = Path()
            for i in 1..<n {
                let t = CGFloat(i) / CGFloat(n)
                let p = quadPoint(s, t)
                let q = quadPoint(s, min(1, t + 0.01))
                let dx = q.x - p.x, dy = q.y - p.y
                let d = max(0.0001, hypot(dx, dy))
                let w = (s.w0 + (s.w1 - s.w0) * t) / 2
                let h = CGPoint(x: p.x - (dy / d) * w * 0.45, y: p.y + (dx / d) * w * 0.45)
                if i == 1 { highlight.move(to: h) } else { highlight.addLine(to: h) }
            }
            ctx.stroke(highlight, with: .color(c(P.barkLight, 0.8)),
                       style: StrokeStyle(lineWidth: max(lw, s.w0 * 0.12), lineCap: .round))
        }
    }

    // MARK: Лист граната (узкий, ланцетовидный)
    private static func drawLeaf(_ leaf: PomegranateTreeLayout.Leaf, lineWidth lw: CGFloat, thirst: Bool,
                                 palette P: PomegranatePalette, in context: GraphicsContext) {
        var ctx = context
        ctx.translateBy(x: leaf.x, y: leaf.y)
        ctx.rotate(by: .radians(Double(leaf.angle)))
        let len = leaf.length
        let w = len * 0.21
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -len), control: CGPoint(x: -w, y: -len * 0.45))
        path.addQuadCurve(to: .zero, control: CGPoint(x: w, y: -len * 0.45))
        path.closeSubpath()
        let tones = [P.leafDark, P.leaf, P.leafLight, P.leafYoung]
        var tone = tones[max(0, min(3, leaf.tone))]
        if thirst { tone = PomegranatePalette.mix(tone, P.soil, 0.38) }
        ctx.fill(path, with: .color(c(tone)))
        ctx.stroke(path, with: .color(c(P.ink, 0.28)), lineWidth: lw * 0.8)
        var rib = Path()
        rib.move(to: CGPoint(x: 0, y: -len * 0.05))
        rib.addQuadCurve(to: CGPoint(x: 0, y: -len * 0.92), control: CGPoint(x: w * 0.12, y: -len * 0.5))
        ctx.stroke(rib, with: .color(c(P.leafLight, 0.55)), lineWidth: lw * 0.7)
    }

    // MARK: Корона-чашечка на нижнем конце висящего плода
    private static func drawCrownSepals(cx: CGFloat, bottomY: CGFloat, r: CGFloat, lineWidth lw: CGFloat,
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
        ctx.fill(path, with: .color(c(P.fruitDark)))
        ctx.stroke(path, with: .color(c(P.ink, 0.5)), lineWidth: lw)
    }

    // MARK: Плод граната: черенок сверху, корона снизу
    static func drawFruit(_ f: PomegranateTreeLayout.Fruit, palette P: PomegranatePalette, lineWidth lw: CGFloat,
                          withStem: Bool, in ctx: GraphicsContext) {
        let x = f.x, y = f.y, r = f.r
        if withStem {
            var stem = Path()
            stem.move(to: CGPoint(x: f.stemX, y: f.stemY))
            stem.addQuadCurve(
                to: CGPoint(x: x, y: y - r * 0.98),
                control: CGPoint(x: f.stemX + (x - f.stemX) * 0.5, y: f.stemY + (y - r * 0.95 - f.stemY) * 0.4)
            )
            ctx.stroke(stem, with: .color(c(P.bark)), style: StrokeStyle(lineWidth: max(lw, r * 0.12), lineCap: .round))
        }
        drawCrownSepals(cx: x, bottomY: y + r * 0.92, r: r, lineWidth: lw, palette: P, in: ctx)

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
                .init(color: c(P.fruitLight), location: 0),
                .init(color: c(P.fruit), location: 0.45),
                .init(color: c(P.fruitDark), location: 1)
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
            inner.stroke(rib, with: .color(c(P.fruitDark, 0.30)), lineWidth: lw * 0.9)
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

    // MARK: Цветок и бутон граната (воронка с гофрированными лепестками)
    private static func drawFlower(_ f: PomegranateTreeLayout.Flower, isBud: Bool, lineWidth lw: CGFloat,
                                   palette P: PomegranatePalette, in context: GraphicsContext) {
        var ctx = context
        ctx.translateBy(x: f.x, y: f.y)
        ctx.rotate(by: .radians(Double(f.angle * 0.7)))
        let s = f.size
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
    private static func drawGround(width W: CGFloat, height H: CGFloat, lineWidth lw: CGFloat, thirst: Bool, compact: Bool,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let gw = compact ? H * 0.42 : min(W * 0.36, H * 0.62)
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
    private static func drawSeed(height H: CGFloat, width W: CGFloat, lineWidth lw: CGFloat, time: Double, compact: Bool,
                                 palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let r = compact ? H * 0.11 : H * 0.06
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
            for dx: CGFloat in [-1, 0, 1] {
                var root = Path()
                root.move(to: CGPoint(x: 0, y: -r * 0.2))
                root.addQuadCurve(to: CGPoint(x: dx * r * 1.6, y: r * 0.7 + (dx == 0 ? r * 0.3 : 0)),
                                  control: CGPoint(x: dx * r * 0.8, y: r * 0.4))
                ctx.stroke(root, with: .color(c(P.gold, 0.7)), lineWidth: lw)
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
    private static func drawSprout(height H: CGFloat, lineWidth lw: CGFloat, time: Double, thirst: Bool,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let h = H * 0.30
        let sw = CGFloat(sin(time * 0.9)) * H * 0.006
        var stem = Path()
        stem.move(to: .zero)
        stem.addCurve(to: CGPoint(x: sw, y: -h), control1: CGPoint(x: -H * 0.02, y: -h * 0.35), control2: CGPoint(x: H * 0.02 + sw * 0.5, y: -h * 0.65))
        ctx.stroke(stem, with: .color(c(P.leaf)), style: StrokeStyle(lineWidth: H * 0.012, lineCap: .round))

        let leafLength = H * 0.095
        let pairs: [(CGFloat, CGFloat, CGFloat)] = [(-h * 0.45, 1.0, 0.8), (-h * 0.78, 0.85, 1.0), (-h, 0.7, 0.75)]
        for (y, s, k) in pairs {
            for side: CGFloat in [-1, 1] {
                let droop: CGFloat = thirst ? 0.35 : 0
                let leaf = PomegranateTreeLayout.Leaf(
                    x: sw * (-y / h),
                    y: y,
                    angle: side * (0.95 + droop) + sw * 0.02,
                    length: leafLength * s * k,
                    tone: y < -h * 0.7 ? 3 : (side > 0 ? 2 : 1)
                )
                drawLeaf(leaf, lineWidth: lw, thirst: thirst, palette: P, in: ctx)
            }
        }
        // Росинка
        let dx = sw + leafLength * 0.55, dy = -h * 0.78 - leafLength * 0.35
        let dr = H * 0.010
        ctx.fill(Path(ellipseIn: CGRect(x: dx - dr, y: dy - dr, width: dr * 2, height: dr * 2)), with: .color(c(P.dew, 0.95)))
        let hr = H * 0.003
        ctx.fill(Path(ellipseIn: CGRect(x: dx - H * 0.003 - hr, y: dy - H * 0.003 - hr, width: hr * 2, height: hr * 2)),
                 with: .color(Color.white.opacity(0.9)))
    }

    // MARK: Золотая пыльца
    private static func drawPollen(cx: CGFloat, cy: CGFloat, r: CGFloat, height H: CGFloat, time: Double,
                                   palette P: PomegranatePalette, in ctx: GraphicsContext) {
        let span = Double(H * 0.75)
        for i in 0..<12 {
            let travel = (time * 10 + Double(i) * 41).truncatingRemainder(dividingBy: span)
            let y = cy + r - CGFloat(travel)
            let x = cx + CGFloat(sin(time * 0.5 + Double(i) * 1.7)) * r * 0.9 * (CGFloat(i % 5) / 5 + 0.3)
            let fade = sin(travel / span * .pi)
            let size: CGFloat = i % 3 == 0 ? 1.8 : 1.1
            ctx.fill(Path(ellipseIn: CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)),
                     with: .color(c(P.goldLight, 0.75 * fade)))
        }
    }
}
