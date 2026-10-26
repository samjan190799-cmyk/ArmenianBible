import SwiftUI

// MARK: - Реалистичная свеча: процедурный рендер
// Пламя, воск, фитиль, оплавленная чаша, капли, латунный подсвечник и свет на стенах ниши
// рисуются в Canvas. Пламя живёт не по кругу из двух анимаций, а по «шуму»: суммы синусов с
// несоизмеримыми частотами плюс редкие порывы, у каждой свечи своя фаза.

enum CandleQuality {
    case compact, hero

    var framesPerSecond: Double { self == .hero ? 60 : 30 }
    var flameSteps: Int { self == .hero ? 44 : 26 }
    var blur: CGFloat { self == .hero ? 1.0 : 0.75 }
    var showsSparks: Bool { self == .hero }
}

struct CandleScene {
    var tier: CandleTier
    var time: Double
    var seed: Double
    var burn: Double
    var isLit: Bool
    var showsNiche: Bool
    /// Секунды с момента зажжения; nil — свеча давно горит
    var ignitionAge: Double?
    var quality: CandleQuality
}

// MARK: - Мерцание
struct CandleFlicker {
    var intensity: CGFloat = 1
    var bend: CGFloat = 0
    var height: CGFloat = 1
    var width: CGFloat = 1
    var wobble: CGFloat = 0
    var gust: CGFloat = 0

    init(time t: Double, seed s: Double) {
        let slow = 0.55 * sin(t * 1.15 + s) + 0.45 * sin(t * 0.73 + s * 1.7)
        let mid = 0.5 * sin(t * 3.4 + s * 2.1) + 0.5 * sin(t * 5.3 + s * 0.9)
        let fast = 0.34 * sin(t * 11.7 + s * 3.3) + 0.33 * sin(t * 17.9 + s * 1.3) + 0.33 * sin(t * 29.3 + s * 0.7)
        // Порыв: короткий резкий наклон, раз в десяток секунд
        let gustWave = pow(max(0.0, sin(t * 0.43 + s * 4.1)), 14.0)
        let gustSign: Double = sin(s * 9.0) > 0 ? 1 : -1
        intensity = CGFloat(0.93 + 0.045 * mid + 0.035 * fast - 0.10 * gustWave)
        bend = CGFloat(0.10 * slow + 0.05 * mid + 0.22 * gustWave * gustSign)
        height = CGFloat(1.0 + 0.07 * slow + 0.05 * mid + 0.025 * fast - 0.12 * gustWave)
        width = CGFloat(1.0 - 0.04 * mid + 0.02 * fast + 0.10 * gustWave)
        wobble = CGFloat(0.05 * mid + 0.03 * fast)
        gust = CGFloat(gustWave)
    }
}

// MARK: - Палитры
private struct WaxPalette {
    let light: UInt32
    let mid: UInt32
    let dark: UInt32
}

// MARK: - Детерминированный генератор случайных чисел (mulberry32)
/// Свой, чтобы рендер свечи не тянул за собой файлы дерева: его собирает и расширение виджетов
struct CandleRandom {
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

enum CandleRenderer {
    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    private static func gradient(_ stops: [(UInt32, Double, CGFloat)]) -> Gradient {
        Gradient(stops: stops.map { Gradient.Stop(color: c($0.0, $0.1), location: $0.2) })
    }

    private static func ellipse(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
    }

    /// Мягкое пятно света: круглый радиальный градиент, растянутый в эллипс
    private static func glow(_ ctx: GraphicsContext, center: CGPoint, rx: CGFloat, ry: CGFloat, stops: [(UInt32, Double, CGFloat)]) {
        var g = ctx
        g.translateBy(x: center.x, y: center.y)
        g.scaleBy(x: 1, y: ry / max(rx, 0.001))
        g.fill(
            Path(ellipseIn: CGRect(x: -rx, y: -rx, width: rx * 2, height: rx * 2)),
            with: .radialGradient(gradient(stops), center: .zero, startRadius: 0, endRadius: rx)
        )
    }

    private static func easeOutBack(_ x: CGFloat) -> CGFloat {
        let t = min(1, max(0, x))
        let c1: CGFloat = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }

    /// Зажжение: тишина, вспышка, маленькое голубое пламя, которое набирает силу
    private static func ignitionFactor(_ age: Double) -> CGFloat {
        if age < 0.35 { return 0 }
        return max(0, easeOutBack(CGFloat((age - 0.35) / 1.1)))
    }

    // MARK: Параметры свечи
    private static func params(for tier: CandleTier) -> (width: CGFloat, factor: CGFloat, wax: WaxPalette) {
        switch tier {
        case .freeDaily: return (16, 0.60, WaxPalette(light: 0xFBF3DF, mid: 0xEEDDB8, dark: 0xC8A874))
        case .rewarded: return (19, 0.78, WaxPalette(light: 0xF9EBC8, mid: 0xEBCF94, dark: 0xBE9048))
        case .small: return (18, 0.70, WaxPalette(light: 0xF9EBC8, mid: 0xEBCF94, dark: 0xBE9048))
        case .temple: return (21, 0.88, WaxPalette(light: 0xF6E4B0, mid: 0xE6C177, dark: 0xB07C34))
        case .generous: return (24, 1.0, WaxPalette(light: 0xF3DA9A, mid: 0xE0B25E, dark: 0xA26C2A))
        }
    }

    // MARK: Главный рисунок
    static func draw(_ ctx: GraphicsContext, size: CGSize, scene: CandleScene) {
        let s = size.height / 150
        let seed = scene.seed.truncatingRemainder(dividingBy: 1000)
        let flick = CandleFlicker(time: scene.time, seed: seed)
        let burn = CGFloat(min(1, max(0, scene.burn)))
        let ignition: CGFloat = scene.ignitionAge.map { ignitionFactor($0) } ?? 1
        let lit = scene.isLit && burn < 0.999
        let light: CGFloat = lit ? flick.intensity * ignition : 0

        let p = params(for: scene.tier)
        let cw = p.width * s
        let rx = cw / 2
        let ry = rx * 0.20
        let cx = size.width / 2

        // Вертикальная раскладка: подсвечник внизу, пламя вверху, воск между ними
        let trayRX = min(size.width * 0.44, cw * 1.55 + 8 * s)
        let trayRY = trayRX * 0.17
        let groundY = size.height - 9 * s - trayRY
        let cupH = 10 * s
        let cupTopY = groundY - trayRY * 0.15 - cupH
        let flameH = cw * 1.75
        let wickH = cw * 0.30
        let available = cupTopY - (flameH * 1.04 + wickH + 6 * s)
        let maxWax = max(10 * s, available * p.factor)
        let wax = maxWax * (1 - 0.78 * burn)
        let topY = cupTopY - wax
        let wickBase = CGPoint(x: cx, y: topY + ry * 0.1)
        let wickTip = CGPoint(x: cx + cw * 0.03, y: topY - wickH)
        let flameBase = CGPoint(x: wickTip.x, y: wickTip.y + flameH * 0.10)
        let flameCenter = CGPoint(x: flameBase.x + flick.bend * flameH * 0.2, y: flameBase.y - flameH * 0.45)

        if scene.showsNiche {
            drawNiche(ctx, size: size, flameCenter: flameCenter, flameH: flameH, light: light, scene: scene)
        }
        drawTray(ctx, cx: cx, y: groundY, rx: trayRX, ry: trayRY, cw: cw, s: s, light: light)
        drawCupBack(ctx, cx: cx, topY: cupTopY, rx: rx + 4 * s, ry: ry * 1.15)
        drawBody(
            ctx, cx: cx, rx: rx, ry: ry, topY: topY, bottomY: cupTopY + ry * 1.15,
            wax: p.wax, light: light, flameCenter: flameCenter, s: s, seed: seed, burn: burn
        )
        drawDrips(ctx, cx: cx, rx: rx, ry: ry, topY: topY, wax: wax, palette: p.wax, s: s, seed: seed, burn: burn, light: light)
        drawCupFront(ctx, cx: cx, topY: cupTopY, h: cupH, topRX: rx + 4 * s, bottomRX: rx + 7 * s, ry: ry * 1.15, light: light)
        drawTopPool(
            ctx, cx: cx, topY: topY, rx: rx, ry: ry, palette: p.wax, burn: burn,
            light: light, lit: lit, flameBase: flameBase, time: scene.time
        )
        drawWick(ctx, base: wickBase, tip: wickTip, cw: cw, s: s, lit: lit, light: light, time: scene.time, seed: seed)

        if lit && ignition > 0.01 {
            drawFlame(
                ctx, base: flameBase, h: flameH * ignition, w: flameH * 0.47 * (0.55 + 0.45 * ignition),
                flick: flick, light: light, scene: scene, ignition: ignition
            )
            if scene.quality.showsSparks {
                drawSparks(ctx, flameBase: flameBase, flameH: flameH, time: scene.time, seed: seed, light: light)
            }
        } else if !lit {
            drawSmoke(ctx, tip: wickTip, cw: cw, flameH: flameH, time: scene.time, seed: seed, s: s)
        }
        if let age = scene.ignitionAge, age > 0.2, age < 0.7 {
            // Вспышка спички
            let k = CGFloat(1 - abs(age - 0.42) / 0.28)
            var flash = ctx
            flash.blendMode = .plusLighter
            glow(flash, center: wickTip, rx: cw * 1.6, ry: cw * 1.6, stops: [(0xFFE9B0, 0.7 * Double(max(0, k)), 0), (0xFFB347, 0, 1)])
        }
    }

    // MARK: Ниша: тёмный храмовый свод и тёплый свет от пламени
    private static func drawNiche(_ ctx: GraphicsContext, size: CGSize, flameCenter: CGPoint, flameH: CGFloat, light: CGFloat, scene: CandleScene) {
        let rect = CGRect(origin: .zero, size: size)
        ctx.fill(Path(rect), with: .linearGradient(
            gradient([(0x1C120B, 1, 0), (0x0A0604, 1, 1)]),
            startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)
        ))

        // Арка ниши
        let archW = size.width * 0.86
        let r = archW / 2
        let minX = (size.width - archW) / 2
        let minY = size.height * 0.05
        var arch = Path()
        arch.move(to: CGPoint(x: minX, y: size.height))
        arch.addLine(to: CGPoint(x: minX, y: minY + r))
        var angle: CGFloat = 180
        while angle <= 360 {
            let rad = angle * .pi / 180
            arch.addLine(to: CGPoint(x: minX + r + r * cos(rad), y: minY + r + r * sin(rad)))
            angle += 6
        }
        arch.addLine(to: CGPoint(x: minX + archW, y: size.height))
        arch.closeSubpath()
        ctx.fill(arch, with: .linearGradient(
            gradient([(0x2A1B11, 1, 0), (0x140D08, 1, 0.6), (0x0C0705, 1, 1)]),
            startPoint: CGPoint(x: 0, y: minY), endPoint: CGPoint(x: 0, y: size.height)
        ))
        ctx.stroke(arch, with: .color(c(0x7A5A30, 0.30 + 0.25 * Double(light))), lineWidth: max(1, size.height / 150))

        // Тёплый свет пламени на камне: большой, средний и малый ореол
        var g = ctx
        g.blendMode = .plusLighter
        glow(g, center: flameCenter, rx: size.width * 0.95, ry: size.height * 0.85, stops: [
            (0xFF8A2A, 0.26 * Double(light), 0), (0xB04A12, 0.10 * Double(light), 0.55), (0x000000, 0, 1)
        ])
        glow(g, center: flameCenter, rx: flameH * 1.6, ry: flameH * 1.6, stops: [
            (0xFFB347, 0.34 * Double(light), 0), (0xFF7A18, 0.10 * Double(light), 0.6), (0x000000, 0, 1)
        ])

        // Виньетка по краям
        ctx.fill(Path(rect), with: .radialGradient(
            gradient([(0x000000, 0, 0), (0x000000, 0.55, 1)]),
            center: CGPoint(x: size.width / 2, y: size.height * 0.55),
            startRadius: size.width * 0.30, endRadius: max(size.width, size.height) * 0.78
        ))
    }

    // MARK: Латунный поднос и чашка подсвечника
    private static func brass(_ x0: CGFloat, _ x1: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(
            gradient([
                (0x2E1C06, 1, 0), (0x7A5418, 1, 0.16), (0xC9983C, 1, 0.34),
                (0xF0D48A, 1, 0.46), (0xC9983C, 1, 0.58), (0x7A5418, 1, 0.82), (0x2E1C06, 1, 1)
            ]),
            startPoint: CGPoint(x: x0, y: 0), endPoint: CGPoint(x: x1, y: 0)
        )
    }

    private static func drawTray(_ ctx: GraphicsContext, cx: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, cw: CGFloat, s: CGFloat, light: CGFloat) {
        // Тень под подносом
        glow(ctx, center: CGPoint(x: cx, y: y + ry * 0.9), rx: rx * 1.15, ry: ry * 1.4, stops: [(0x000000, 0.55, 0), (0x000000, 0, 1)])
        // Борт подноса
        let thickness = 3.2 * s
        var side = Path()
        side.addEllipse(in: CGRect(x: cx - rx, y: y - ry + thickness, width: rx * 2, height: ry * 2))
        ctx.fill(side, with: brass(cx - rx, cx + rx))
        // Верхняя плоскость
        ctx.fill(ellipse(CGPoint(x: cx, y: y), rx, ry), with: .linearGradient(
            gradient([(0x6B4A16, 1, 0), (0xE0B860, 1, 0.5), (0x6B4A16, 1, 1)]),
            startPoint: CGPoint(x: cx - rx, y: y), endPoint: CGPoint(x: cx + rx, y: y)
        ))
        // Углубление чаши подноса
        ctx.fill(ellipse(CGPoint(x: cx, y: y + ry * 0.05), rx * 0.80, ry * 0.74), with: .linearGradient(
            gradient([(0x2A1A07, 1, 0), (0x80591B, 1, 0.5), (0x2A1A07, 1, 1)]),
            startPoint: CGPoint(x: cx - rx, y: y), endPoint: CGPoint(x: cx + rx, y: y)
        ))
        ctx.stroke(ellipse(CGPoint(x: cx, y: y), rx, ry), with: .color(c(0xFFE9A8, 0.55)), lineWidth: max(0.6, 0.7 * s))
        // Свет свечи на металле
        var g = ctx
        g.blendMode = .plusLighter
        glow(g, center: CGPoint(x: cx, y: y - ry * 0.1), rx: rx * 0.95, ry: ry * 0.95, stops: [
            (0xFFB347, 0.55 * Double(light), 0), (0xFF7A18, 0.0, 1)
        ])
    }

    private static func drawCupBack(_ ctx: GraphicsContext, cx: CGFloat, topY: CGFloat, rx: CGFloat, ry: CGFloat) {
        ctx.fill(ellipse(CGPoint(x: cx, y: topY), rx, ry), with: .color(c(0x120A03)))
    }

    private static func drawCupFront(_ ctx: GraphicsContext, cx: CGFloat, topY: CGFloat, h: CGFloat, topRX: CGFloat, bottomRX: CGFloat, ry: CGFloat, light: CGFloat) {
        var wall = Path()
        wall.move(to: CGPoint(x: cx - topRX, y: topY))
        wall.addLine(to: CGPoint(x: cx - bottomRX, y: topY + h))
        wall.addQuadCurve(to: CGPoint(x: cx + bottomRX, y: topY + h), control: CGPoint(x: cx, y: topY + h + ry * 2.2))
        wall.addLine(to: CGPoint(x: cx + topRX, y: topY))
        wall.addQuadCurve(to: CGPoint(x: cx - topRX, y: topY), control: CGPoint(x: cx, y: topY + ry * 2))
        wall.closeSubpath()
        ctx.fill(wall, with: brass(cx - bottomRX, cx + bottomRX))
        // Тёплый отсвет пламени на верхнем крае чашки
        var g = ctx
        g.blendMode = .plusLighter
        g.clip(to: wall)
        glow(g, center: CGPoint(x: cx, y: topY), rx: topRX * 1.2, ry: h * 0.9, stops: [
            (0xFFC15A, 0.65 * Double(light), 0), (0xFF7A18, 0, 1)
        ])
        // Блик по верхней кромке
        var lip = Path()
        lip.move(to: CGPoint(x: cx - topRX, y: topY))
        lip.addQuadCurve(to: CGPoint(x: cx + topRX, y: topY), control: CGPoint(x: cx, y: topY + ry * 2))
        ctx.stroke(lip, with: .color(c(0xFFEFB8, 0.8)), lineWidth: max(0.6, h * 0.07))
    }

    // MARK: Восковой столб
    private static func drawBody(
        _ ctx: GraphicsContext, cx: CGFloat, rx: CGFloat, ry: CGFloat, topY: CGFloat, bottomY: CGFloat,
        wax: WaxPalette, light: CGFloat, flameCenter: CGPoint, s: CGFloat, seed: Double, burn: CGFloat
    ) {
        let body = Path(CGRect(x: cx - rx, y: topY, width: rx * 2, height: bottomY - topY))
        // Цилиндр: тёмные края, блик чуть левее середины
        ctx.fill(body, with: .linearGradient(
            gradient([
                (wax.dark, 1, 0), (wax.mid, 1, 0.16), (wax.light, 1, 0.36),
                (wax.mid, 1, 0.62), (wax.dark, 1, 0.9), (0x4A3018, 1, 1)
            ]),
            startPoint: CGPoint(x: cx - rx, y: 0), endPoint: CGPoint(x: cx + rx, y: 0)
        ))

        var layer = ctx
        layer.clip(to: body)

        // Низ тонет в темноте ниши
        layer.fill(body, with: .linearGradient(
            gradient([(0x24120A, 0, 0), (0x24120A, 0.50, 1)]),
            startPoint: CGPoint(x: 0, y: topY), endPoint: CGPoint(x: 0, y: bottomY)
        ))
        // Мягкий вертикальный блик на воске
        layer.fill(Path(CGRect(x: cx - rx * 0.62, y: topY, width: rx * 0.46, height: bottomY - topY)), with: .linearGradient(
            gradient([(0xFFFFFF, 0.20, 0), (0xFFFFFF, 0.06, 1)]),
            startPoint: CGPoint(x: 0, y: topY), endPoint: CGPoint(x: 0, y: bottomY)
        ))

        // Просвечивающий воск у пламени: тёплое свечение изнутри
        var warm = layer
        warm.blendMode = .plusLighter
        glow(warm, center: CGPoint(x: cx, y: topY - 4 * s), rx: rx * 2.4, ry: max(18 * s, (bottomY - topY) * 0.75), stops: [
            (0xFFA94D, 0.60 * Double(light), 0), (0xFF8A2A, 0.20 * Double(light), 0.55), (0xFF7A18, 0, 1)
        ])
        let bandH = max(5 * s, (bottomY - topY) * 0.16)
        layer.fill(Path(CGRect(x: cx - rx, y: topY, width: rx * 2, height: bandH)), with: .linearGradient(
            gradient([(0xFFE8B0, 0.55 * Double(light), 0), (0xFFE8B0, 0, 1)]),
            startPoint: CGPoint(x: 0, y: topY), endPoint: CGPoint(x: 0, y: topY + bandH)
        ))

        // Тонкие продольные неровности воска
        var rng = CandleRandom(seed: UInt32(truncatingIfNeeded: Int(seed * 1000) &+ 7))
        for _ in 0..<5 {
            let x = cx - rx + rng.next() * rx * 2
            let dark = rng.next() > 0.5
            var streak = Path()
            streak.move(to: CGPoint(x: x, y: topY))
            streak.addLine(to: CGPoint(x: x + (rng.next() - 0.5) * 2 * s, y: bottomY))
            layer.stroke(streak, with: .color(dark ? c(0x4A3018, 0.10) : c(0xFFF4D0, 0.10)), lineWidth: max(0.4, 0.6 * s))
        }
        // Кромка света справа: пламя подсвечивает край столба
        var rim = Path()
        rim.move(to: CGPoint(x: cx + rx - 0.4 * s, y: topY))
        rim.addLine(to: CGPoint(x: cx + rx - 0.4 * s, y: bottomY))
        layer.stroke(rim, with: .linearGradient(
            gradient([(0xFFC878, 0.55 * Double(light), 0), (0xFFC878, 0, 1)]),
            startPoint: CGPoint(x: 0, y: topY), endPoint: CGPoint(x: 0, y: bottomY)
        ), lineWidth: max(0.6, 0.9 * s))
    }

    // MARK: Потёки воска
    private static func drawDrips(
        _ ctx: GraphicsContext, cx: CGFloat, rx: CGFloat, ry: CGFloat, topY: CGFloat, wax: CGFloat,
        palette: WaxPalette, s: CGFloat, seed: Double, burn: CGFloat, light: CGFloat
    ) {
        guard burn > 0.04 else { return }
        var rng = CandleRandom(seed: UInt32(truncatingIfNeeded: Int(seed * 977) &+ 31))
        let count = 2 + Int(burn * 3.4)
        for i in 0..<count {
            let u = (CGFloat(i) + 0.25 + rng.next() * 0.5) / CGFloat(count)
            let angle = CGFloat.pi * (0.08 + 0.84 * u)          // дуга по передней кромке
            let x = cx - rx * cos(angle)
            let y0 = topY + ry * sin(angle)
            let lengthJitter: CGFloat = 0.10 + 0.38 * rng.next()
            let lengthScale: CGFloat = 0.55 + 0.7 * burn
            let length: CGFloat = wax * lengthJitter * lengthScale
            let width = (1.5 + 1.5 * rng.next()) * s
            let tipY = min(y0 + length, topY + wax * 0.92)
            let drip = Path(roundedRect: CGRect(x: x - width / 2, y: y0 - 0.5 * s, width: width, height: max(width, tipY - y0)), cornerRadius: width / 2)
            ctx.fill(drip, with: .linearGradient(
                gradient([(palette.light, 1, 0), (palette.mid, 1, 1)]),
                startPoint: CGPoint(x: x - width / 2, y: 0), endPoint: CGPoint(x: x + width / 2, y: 0)
            ))
            // Блик капли и мягкая тень от неё на столбе
            var hi = Path()
            hi.move(to: CGPoint(x: x - width * 0.18, y: y0 + width * 0.4))
            hi.addLine(to: CGPoint(x: x - width * 0.18, y: tipY - width * 0.4))
            ctx.stroke(hi, with: .color(c(0xFFFFFF, 0.45)), lineWidth: max(0.4, width * 0.16))
            var shade = Path()
            shade.move(to: CGPoint(x: x + width * 0.62, y: y0 + width * 0.5))
            shade.addLine(to: CGPoint(x: x + width * 0.62, y: tipY))
            ctx.stroke(shade, with: .color(c(0x3A2208, 0.22)), lineWidth: max(0.4, width * 0.22))
            // Тёплый отсвет на верхней части капли
            var g = ctx
            g.blendMode = .plusLighter
            g.fill(drip, with: .linearGradient(
                gradient([(0xFFB347, 0.35 * Double(light), 0), (0xFFB347, 0, 1)]),
                startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: tipY)
            ))
        }
    }

    // MARK: Верх свечи: кромка и озеро расплавленного воска
    private static func drawTopPool(
        _ ctx: GraphicsContext, cx: CGFloat, topY: CGFloat, rx: CGFloat, ry: CGFloat, palette: WaxPalette,
        burn: CGFloat, light: CGFloat, lit: Bool, flameBase: CGPoint, time: Double
    ) {
        let center = CGPoint(x: cx, y: topY)
        // Твёрдая кромка
        ctx.fill(ellipse(center, rx, ry), with: .linearGradient(
            gradient([(palette.mid, 1, 0), (palette.light, 1, 0.4), (palette.mid, 1, 1)]),
            startPoint: CGPoint(x: cx - rx, y: topY), endPoint: CGPoint(x: cx + rx, y: topY)
        ))
        // Озеро растёт по мере горения
        let poolScale = 0.52 + 0.30 * burn
        let poolCenter = CGPoint(x: cx, y: topY + ry * 0.06)
        let poolRX = rx * poolScale
        let poolRY = ry * poolScale * 0.96
        let poolPath = ellipse(poolCenter, poolRX, poolRY)
        ctx.fill(poolPath, with: .linearGradient(
            gradient(lit
                ? [(0xB9772A, 1, 0), (0xF2B24E, 1, 0.5), (0xFFD98A, 1, 1)]
                : [(0x8A6A3A, 1, 0), (0xBFA06A, 1, 1)]),
            startPoint: CGPoint(x: 0, y: topY - poolRY), endPoint: CGPoint(x: 0, y: topY + poolRY)
        ))
        // Свечение озера вокруг фитиля
        if lit {
            var g = ctx
            g.blendMode = .plusLighter
            g.clip(to: poolPath)
            glow(g, center: CGPoint(x: cx, y: topY - ry * 0.15), rx: poolRX, ry: poolRY, stops: [
                (0xFFF0B8, 0.95 * Double(light), 0), (0xFFB347, 0.45 * Double(light), 0.55), (0xFF7A18, 0, 1)
            ])
        }
        // Внутренняя тень дальней стенки
        var shade = ctx
        shade.clip(to: poolPath)
        var back = Path()
        back.addEllipse(in: CGRect(x: cx - poolRX * 1.1, y: topY - poolRY * 1.35, width: poolRX * 2.2, height: poolRY * 1.1))
        shade.fill(back, with: .color(c(0x5A3A12, 0.38)))
        // Отражение пламени
        if lit {
            let wobble = CGFloat(sin(time * 7.3)) * 0.04
            var g = ctx
            g.blendMode = .plusLighter
            g.fill(ellipse(CGPoint(x: cx + poolRX * 0.1, y: topY + poolRY * 0.18), poolRX * (0.22 + wobble), poolRY * 0.32),
                   with: .color(c(0xFFF6D8, 0.55 * Double(light))))
        }
        // Край чаши: светлая линия спереди, тёмная сзади
                ctx.stroke(ellipse(center, rx, ry), with: .color(c(0x6B4410, 0.28)), lineWidth: 0.6)
        var lip = Path()
        lip.move(to: CGPoint(x: cx - rx, y: topY))
        lip.addQuadCurve(to: CGPoint(x: cx + rx, y: topY), control: CGPoint(x: cx, y: topY + ry * 2))
        ctx.stroke(lip, with: .color(c(0xFFF2CC, 0.55)), lineWidth: 0.9)
    }

    // MARK: Фитиль
    private static func drawWick(
        _ ctx: GraphicsContext, base: CGPoint, tip: CGPoint, cw: CGFloat, s: CGFloat, lit: Bool,
        light: CGFloat, time: Double, seed: Double
    ) {
        let width = max(0.8, cw * 0.075)
        var wick = Path()
        wick.move(to: base)
        wick.addQuadCurve(
            to: tip,
            control: CGPoint(x: base.x - cw * 0.05, y: (base.y + tip.y) / 2)
        )
        ctx.stroke(wick, with: .linearGradient(
            gradient([(0x1A1410, 1, 0), (0x3A2A1C, 1, 1)]),
            startPoint: base, endPoint: tip
        ), style: StrokeStyle(lineWidth: width, lineCap: .round))
        if lit {
            // Раскалённый кончик: тлеет в такт пламени
            let pulse = 0.75 + 0.25 * sin(time * 9.0 + seed)
            var g = ctx
            g.blendMode = .plusLighter
            glow(g, center: tip, rx: width * 2.6, ry: width * 2.6, stops: [
                (0xFF9A3C, 0.95 * pulse * Double(light), 0), (0xFF5A00, 0, 1)
            ])
            ctx.fill(ellipse(tip, width * 0.75, width * 0.9), with: .color(c(0xFF7A1A, 0.95)))
        } else {
            ctx.fill(ellipse(tip, width * 0.6, width * 0.7), with: .color(c(0x14100C)))
        }
    }

    // MARK: Пламя
    private static func flameOutline(base: CGPoint, height h: CGFloat, width w: CGFloat, bend: CGFloat, wobble: CGFloat, phase: CGFloat, steps: Int) -> Path {
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let shape = pow(max(0, sin(.pi * pow(t, 0.62))), 0.85)
            let half = w / 2 * shape * (1 + 0.05 * sin(t * 6 + phase))
            let center = base.x + bend * h * pow(t, 1.7) + wobble * h * t * sin(t * 3.1 + phase)
            let y = base.y - t * h
            left.append(CGPoint(x: center - half, y: y))
            right.append(CGPoint(x: center + half, y: y))
        }
        var path = Path()
        path.move(to: left[0])
        for point in left.dropFirst() { path.addLine(to: point) }
        for point in right.reversed() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    private static func drawFlame(
        _ ctx: GraphicsContext, base: CGPoint, h: CGFloat, w: CGFloat, flick: CandleFlicker,
        light: CGFloat, scene: CandleScene, ignition: CGFloat
    ) {
        let q = scene.quality
        let height = h * flick.height
        let width = w * flick.width
        let phase = CGFloat(scene.seed.truncatingRemainder(dividingBy: 6.28)) + CGFloat(scene.time * 2.2)
        let center = CGPoint(x: base.x + flick.bend * height * 0.28, y: base.y - height * 0.45)
        let tip = CGPoint(x: base.x + flick.bend * height, y: base.y - height)

        // 1. Ореол: плавный свет вокруг пламени (складывается с фоном)
        var halo = ctx
        halo.blendMode = .plusLighter
        glow(halo, center: center, rx: height * 2.4, ry: height * 2.1, stops: [
            (0xFF8A2A, 0.20 * Double(light), 0), (0xFF6A10, 0.08 * Double(light), 0.55), (0xFF6A10, 0, 1)
        ])
        glow(halo, center: center, rx: height * 1.15, ry: height * 1.05, stops: [
            (0xFFB347, 0.40 * Double(light), 0), (0xFF8A2A, 0.14 * Double(light), 0.6), (0xFF8A2A, 0, 1)
        ])

        // 2. Внешнее пламя: оранжевое, с мягким краем
        let outer = flameOutline(base: base, height: height, width: width, bend: flick.bend, wobble: flick.wobble, phase: phase, steps: q.flameSteps)
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: max(0.5, width * 0.10 * q.blur)))
            layer.fill(outer, with: .linearGradient(
                gradient([
                    (0xFFD36E, 0.95, 0), (0xFFB02E, 0.95, 0.30), (0xFF7A18, 0.80, 0.58),
                    (0xE8420C, 0.34, 0.84), (0xC93005, 0, 1)
                ]),
                startPoint: base, endPoint: tip
            ))
        }

        // 3. Голубая зона у фитиля: здесь воск ещё не прогорел полностью
        var blue = ctx
        blue.blendMode = .plusLighter
        glow(blue, center: CGPoint(x: base.x, y: base.y - height * 0.05), rx: width * 0.46, ry: height * 0.16, stops: [
            (0x5E8BFF, 0.85 * Double(light), 0), (0x3B5BDB, 0.35 * Double(light), 0.6), (0x3B5BDB, 0, 1)
        ])

        // 4. Жёлтая середина
        let mid = flameOutline(
            base: CGPoint(x: base.x, y: base.y - height * 0.03), height: height * 0.80, width: width * 0.70,
            bend: flick.bend * 0.9, wobble: flick.wobble, phase: phase + 0.7, steps: q.flameSteps
        )
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: max(0.4, width * 0.05 * q.blur)))
            layer.fill(mid, with: .linearGradient(
                gradient([(0xFFF2B0, 0.98, 0), (0xFFD060, 0.85, 0.45), (0xFF9A2A, 0, 1)]),
                startPoint: base, endPoint: tip
            ))
        }

        // 5. Белое ядро
        let core = flameOutline(
            base: CGPoint(x: base.x, y: base.y - height * 0.02), height: height * 0.46, width: width * 0.40,
            bend: flick.bend * 0.5, wobble: flick.wobble * 0.5, phase: phase + 1.6, steps: q.flameSteps
        )
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: max(0.3, width * 0.035 * q.blur)))
            layer.fill(core, with: .linearGradient(
                gradient([(0xFFFFFF, 1, 0), (0xFFF8D8, 0.92, 0.5), (0xFFE08A, 0, 1)]),
                startPoint: base, endPoint: CGPoint(x: base.x, y: base.y - height * 0.46)
            ))
        }

        // 6. Тёмная зона вокруг фитиля внутри пламени
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: max(0.3, width * 0.05)))
            layer.fill(
                ellipse(CGPoint(x: base.x, y: base.y - height * 0.07), width * 0.07, height * 0.13),
                with: .color(c(0x3A1500, 0.40 * Double(ignition)))
            )
        }

        // 7. Ближний блум поверх огня
        glow(halo, center: CGPoint(x: base.x + flick.bend * height * 0.1, y: base.y - height * 0.28), rx: width * 0.9, ry: height * 0.5, stops: [
            (0xFFEBB0, 0.30 * Double(light), 0), (0xFFB347, 0, 1)
        ])
    }

    // MARK: Искры
    private static func drawSparks(_ ctx: GraphicsContext, flameBase: CGPoint, flameH: CGFloat, time: Double, seed: Double, light: CGFloat) {
        var g = ctx
        g.blendMode = .plusLighter
        for k in 0..<3 {
            let period = 2.3 + Double(k) * 1.15
            let shifted = time + seed * 0.37 + Double(k) * 1.9
            let age = shifted.truncatingRemainder(dividingBy: period)
            let cycle = Int(shifted / period)
            guard (cycle + k) % 3 == 0, age < 1.5 else { continue }
            let u = CGFloat(age / 1.5)
            let drift = CGFloat(sin(shifted * 3.1 + Double(k))) * flameH * 0.25 * u
            let x = flameBase.x + drift + CGFloat(sin(Double(cycle) * 7.7 + Double(k))) * flameH * 0.1
            let y = flameBase.y - flameH * (0.75 + 1.1 * u)
            let fade = Double((1 - u) * (1 - u)) * Double(light)
            glow(g, center: CGPoint(x: x, y: y), rx: flameH * 0.07, ry: flameH * 0.07, stops: [
                (0xFFD27A, 0.95 * fade, 0), (0xFF7A18, 0, 1)
            ])
        }
    }

    // MARK: Дымок потухшей свечи
    private static func drawSmoke(_ ctx: GraphicsContext, tip: CGPoint, cw: CGFloat, flameH: CGFloat, time: Double, seed: Double, s: CGFloat) {
        let period = 7.0
        let age = time.truncatingRemainder(dividingBy: period)
        guard age < 4.6 else { return }
        let progress = CGFloat(age / 4.6)
        let rise = flameH * (0.5 + 1.9 * progress)
        var path = Path()
        let steps = 28
        for i in 0...steps {
            let u = CGFloat(i) / CGFloat(steps)
            let sway = sin(Double(u) * 9.0 + time * 1.4 + seed) * Double(cw) * 0.22 * Double(u)
            let point = CGPoint(x: tip.x + CGFloat(sway), y: tip.y - u * rise)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        let alpha = Double(sin(.pi * progress)) * 0.42
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: max(0.8, 1.3 * s)))
            layer.stroke(path, with: .linearGradient(
                gradient([(0xE8E2D8, 0, 0), (0xE8E2D8, alpha, 0.35), (0xE8E2D8, 0, 1)]),
                startPoint: tip, endPoint: CGPoint(x: tip.x, y: tip.y - rise)
            ), style: StrokeStyle(lineWidth: max(1, 2.2 * s), lineCap: .round))
        }
    }
}
