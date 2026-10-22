import SwiftUI

// MARK: - Мультфильм «Рождество Христово»: семь сцен
// 0 путь в Вифлеем, 1 прибытие, 2 рождение, 3 пастухи и ангелы, 4 волхвы идут за звездой, 5 поклонение волхвов, 6 финал.
// Каждая сцена — чистая функция времени: кадр целиком определяется t (секунды с начала сцены) и ambient (часы для мерцания).

enum NativityArt {

    static func render(scene: Int, time t: Double, ambient: Double, size: CGSize, in ctx: inout GraphicsContext) {
        let s = NativityStage(size: size)
        switch scene {
        case 0: journey(&ctx, s, t, ambient)
        case 1: arrival(&ctx, s, t, ambient)
        case 2: birth(&ctx, s, t, ambient)
        case 3: shepherds(&ctx, s, t, ambient)
        case 4: magi(&ctx, s, t, ambient)
        case 5: adoration(&ctx, s, t, ambient)
        default: finale(&ctx, s, t, ambient)
        }
    }

    // MARK: 0. Путь в Вифлеем

    private static func journey(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        let tt = CGFloat(t)
        NativityPainter.sky(&ctx, s, top: NP.rgb(8, 12, 44), middle: NP.rgb(46, 34, 100), horizon: NP.rgb(216, 130, 98))
        NativityPainter.stars(&ctx, s, ambient: amb, seed: 3)
        let rise = nvEase(t / 7)
        let starPoint = CGPoint(x: s.w * 0.76, y: s.h * CGFloat(0.28 - 0.10 * rise))
        NativityPainter.star(&ctx, at: starPoint, radius: 15 * u, ambient: amb)

        NativityPainter.hills(&ctx, s, base: s.ground - 72 * u, amplitude: 24 * u, wavelength: 90 * u, phase: 0.6, scroll: tt * 5 * u, top: NP.rgb(104, 66, 124), bottom: NP.rgb(74, 46, 100))
        NativityPainter.hills(&ctx, s, base: s.ground - 30 * u, amplitude: 20 * u, wavelength: 70 * u, phase: 2.1, scroll: tt * 12 * u, top: NP.rgb(62, 40, 96), bottom: NP.rgb(42, 30, 76))
        NativityPainter.hills(&ctx, s, base: s.ground + 10 * u, amplitude: 10 * u, wavelength: 55 * u, phase: 4.0, scroll: tt * 26 * u, top: NP.rgb(32, 26, 66), bottom: NP.rgb(20, 16, 44))
        let roadTop = s.ground + 44 * u
        NativityPainter.road(&ctx, s, top: roadTop, thickness: 52 * u, scroll: tt * 26 * u, color: NP.rgb(92, 66, 100), stone: NP.rgb(122, 92, 124))

        let feet = roadTop + 40 * u
        let walk = t * 5.4
        let x = s.w * 0.50

        // пыль за ослом
        for i in 0..<5 {
            let k = (amb * 0.9 + Double(i) * 0.2).truncatingRemainder(dividingBy: 1)
            let px = x - 46 * u - CGFloat(k) * 46 * u
            let py = feet - 3 * u - CGFloat(k) * 8 * u
            let r = (3 + CGFloat(k) * 7) * u
            ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)), with: .color(NP.rgb(150, 120, 140, 0.30 * (1 - k))))
        }
        // осёл с Марией и Иосиф впереди
        NativityPainter.donkey(&ctx, at: CGPoint(x: x, y: feet), length: 84 * u, walk: walk)
        NativityPainter.person(&ctx, .mary, at: CGPoint(x: x - 4 * u, y: feet - 60 * u), height: 58 * u, skirt: true)
        NativityPainter.person(&ctx, .joseph, at: CGPoint(x: x + 118 * u, y: feet), height: 88 * u, walk: walk + 1)
    }

    // MARK: 1. Вифлеем

    private static func arrival(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        NativityPainter.sky(&ctx, s, top: NP.rgb(10, 14, 48), middle: NP.rgb(52, 36, 104), horizon: NP.rgb(228, 140, 100))
        NativityPainter.stars(&ctx, s, ambient: amb, seed: 4)
        let starPoint = CGPoint(x: s.w * 0.64, y: s.h * 0.20)
        NativityPainter.star(&ctx, at: starPoint, radius: 17 * u, ambient: amb)

        NativityPainter.hills(&ctx, s, base: s.ground - 62 * u, amplitude: 20 * u, wavelength: 95 * u, phase: 1.2, scroll: 0, top: NP.rgb(104, 66, 124), bottom: NP.rgb(74, 46, 100))
        let lit = 0.15 + 0.85 * nvEase(t / 3)
        NativityPainter.town(&ctx, s, baseY: s.ground - 12 * u, scroll: 0, ambient: amb, lit: lit)
        NativityPainter.hills(&ctx, s, base: s.ground + 6 * u, amplitude: 8 * u, wavelength: 80 * u, phase: 3.3, scroll: 0, top: NP.rgb(34, 26, 68), bottom: NP.rgb(20, 16, 44))
        let roadTop = s.ground + 40 * u
        NativityPainter.road(&ctx, s, top: roadTop, thickness: 46 * u, scroll: 0, color: NP.rgb(92, 66, 100), stone: NP.rgb(122, 92, 124))

        // хлев справа: тёмный проём, в нём разгорается свет
        let glowK = nvEase((t - 3) / 6)
        let sx = s.w * 0.78
        let sy = roadTop + 24 * u
        let door = CGRect(x: sx - 54 * u, y: sy - 62 * u, width: 108 * u, height: 62 * u)
        ctx.fill(Path(roundedRect: door, cornerRadius: 6 * u), with: .color(NP.rgb(34, 24, 36)))
        NativityPainter.glow(&ctx, at: CGPoint(x: sx, y: sy - 24 * u), radius: 120 * u, color: NP.rgb(255, 200, 120), alpha: 0.8 * glowK)
        for side in [-1.0, 1.0] {
            let post = CGRect(x: sx + CGFloat(side) * 54 * u - 4 * u, y: sy - 66 * u, width: 8 * u, height: 66 * u)
            ctx.fill(Path(post), with: .color(NP.wood))
        }
        var roof = Path()
        roof.move(to: CGPoint(x: sx - 82 * u, y: sy - 52 * u))
        roof.addLine(to: CGPoint(x: sx, y: sy - 104 * u))
        roof.addLine(to: CGPoint(x: sx + 88 * u, y: sy - 52 * u))
        roof.closeSubpath()
        ctx.fill(roof, with: .linearGradient(Gradient(colors: [NP.rgb(132, 100, 56), NP.rgb(86, 62, 38)]), startPoint: CGPoint(x: sx, y: sy - 104 * u), endPoint: CGPoint(x: sx, y: sy - 50 * u)))
        NativityPainter.beam(&ctx, from: starPoint, topWidth: 6 * u, to: CGPoint(x: sx, y: sy - 52 * u), bottomWidth: 110 * u, color: NP.warmLight, alpha: 0.30 * glowK)

        // путники подходят, замедляясь у хлева
        let progress = nvEase(t / 9)
        let moving = t < 9.2
        let feet = roadTop + 32 * u
        let jx = nvLerp(-0.10 * s.w, 0.55 * s.w, progress)
        let walk = t * 4.6
        let k: CGFloat = 1.0
        NativityPainter.donkey(&ctx, at: CGPoint(x: jx - 104 * u * k, y: feet), length: 84 * u * k, walk: moving ? walk : nil)
        NativityPainter.person(&ctx, .mary, at: CGPoint(x: jx - 108 * u * k, y: feet - 60 * u * k), height: 58 * u * k, skirt: true)
        NativityPainter.person(&ctx, .joseph, at: CGPoint(x: jx, y: feet), height: 88 * u * k, walk: moving ? walk + 1 : nil)
    }

    // MARK: Общий интерьер хлева и дома

    private static func interior(_ ctx: inout GraphicsContext, _ s: NativityStage, ambient amb: Double, starStrength: Double, window: CGPoint, windowRadius: CGFloat) -> CGFloat {
        let u = s.u
        let floorY = s.ground + 52 * u
        ctx.fill(Path(CGRect(origin: .zero, size: s.size)), with: .linearGradient(Gradient(colors: [NP.rgb(26, 18, 24), NP.rgb(82, 54, 34)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: floorY)))
        // окно в кровле, в нём звезда
        let win = CGRect(x: window.x - windowRadius, y: window.y - windowRadius, width: windowRadius * 2, height: windowRadius * 2)
        ctx.fill(Path(ellipseIn: win), with: .linearGradient(Gradient(colors: [NP.rgb(14, 20, 60), NP.rgb(86, 58, 112)]), startPoint: CGPoint(x: 0, y: win.minY), endPoint: CGPoint(x: 0, y: win.maxY)))
        NativityPainter.star(&ctx, at: window, radius: windowRadius * 0.5, ambient: amb, strength: starStrength)
        ctx.stroke(Path(ellipseIn: win), with: .color(NP.wood), lineWidth: 4 * u)
        // стропила, перекладина и столбы
        let apex = CGPoint(x: s.w * 0.5, y: s.h * 0.02)
        let eaveY = s.h * 0.27
        var rafters = Path()
        rafters.move(to: CGPoint(x: -10 * u, y: eaveY))
        rafters.addLine(to: apex)
        rafters.addLine(to: CGPoint(x: s.w + 10 * u, y: eaveY))
        ctx.stroke(rafters, with: .color(NP.wood), lineWidth: 12 * u)
        ctx.fill(Path(CGRect(x: 0, y: eaveY - 5 * u, width: s.w, height: 11 * u)), with: .color(NP.wood))
        for px in [10 * u, s.w - 10 * u] {
            ctx.fill(Path(CGRect(x: px - 9 * u, y: eaveY, width: 18 * u, height: floorY - eaveY)), with: .color(NP.rgb(70, 46, 30)))
        }
        // пол из соломы
        let floor = CGRect(x: 0, y: floorY, width: s.w, height: s.h - floorY)
        ctx.fill(Path(floor), with: .linearGradient(Gradient(colors: [NP.rgb(128, 94, 50), NP.rgb(66, 46, 30)]), startPoint: CGPoint(x: 0, y: floorY), endPoint: CGPoint(x: 0, y: s.h)))
        for i in 0..<46 {
            let x = nvNoise(i * 5) * s.w
            let y = floorY + nvNoise(i * 5 + 1) * (s.h - floorY) * 0.5
            let len = (6 + nvNoise(i * 5 + 2) * 10) * u
            var straw = Path()
            straw.move(to: CGPoint(x: x, y: y))
            straw.addLine(to: CGPoint(x: x + len, y: y - len * 0.25))
            ctx.stroke(straw, with: .color(NP.straw.opacity(0.7)), lineWidth: max(1, 1.3 * u))
        }
        return floorY
    }

    // MARK: 2. Рождество

    private static func birth(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        let lightK = nvEase((t - 1.5) / 3.5)
        let babyK = nvEase((t - 4.0) / 2.0)
        let window = CGPoint(x: s.w * 0.5, y: s.h * 0.145)
        let floorY = interior(&ctx, s, ambient: amb, starStrength: 0.7 + 0.3 * lightK, window: window, windowRadius: 26 * u)
        let mangerX = s.w * 0.5
        NativityPainter.beam(&ctx, from: window, topWidth: 30 * u, to: CGPoint(x: mangerX, y: floorY), bottomWidth: 170 * u, color: NP.warmLight, alpha: 0.42 * lightK)

        // животные у яслей
        NativityPainter.donkey(&ctx, at: CGPoint(x: s.w * 0.17, y: floorY - 14 * u), length: 78 * u, headDown: 0.25)
        NativityPainter.ox(&ctx, at: CGPoint(x: s.w * 0.85, y: floorY - 16 * u), length: 84 * u, facing: -1, ambient: amb)
        NativityPainter.manger(&ctx, at: CGPoint(x: mangerX, y: floorY + 4 * u), width: 120 * u, ambient: amb, baby: babyK, glowStrength: 0.25 * lightK + 0.75 * babyK)

        // Мария склонилась к яслям, Иосиф стоит рядом
        let breath = CGFloat(sin(amb * 0.9)) * 0.015
        NativityPainter.person(&ctx, .mary, at: CGPoint(x: mangerX - 112 * u, y: floorY + 8 * u), height: 98 * u, lean: 0.10 + breath, skirt: true)
        NativityPainter.person(&ctx, .joseph, at: CGPoint(x: mangerX + 128 * u, y: floorY + 2 * u), height: 116 * u, facing: -1, lean: 0.04)

        NativityPainter.motes(&ctx, s, ambient: amb, count: 26, color: NP.warmLight, alpha: 0.9 * lightK, area: CGRect(x: s.w * 0.25, y: s.h * 0.22, width: s.w * 0.5, height: floorY - s.h * 0.22))
    }

    // MARK: 3. Пастухи и ангелы

    private static func shepherds(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        let reveal = nvEase((t - 2.5) / 2.0)
        NativityPainter.sky(&ctx, s, top: NP.rgb(6, 10, 38), middle: NP.rgb(30, 28, 84), horizon: NP.rgb(92, 64, 118))
        NativityPainter.stars(&ctx, s, ambient: amb, seed: 5, alpha: 1 - 0.6 * reveal)
        // небо вспыхивает золотом
        ctx.drawLayer { g in
            g.blendMode = .plusLighter
            let gradient = Gradient(colors: [NP.rgb(255, 214, 130, 0.50 * reveal), NP.rgb(255, 190, 110, 0.22 * reveal), NP.rgb(255, 170, 100, 0)])
            g.fill(Path(CGRect(origin: .zero, size: s.size)), with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: s.ground + 40 * u)))
        }
        NativityPainter.hills(&ctx, s, base: s.ground - 40 * u, amplitude: 22 * u, wavelength: 100 * u, phase: 0.9, scroll: 0, top: NP.rgb(58, 52, 112), bottom: NP.rgb(36, 32, 80))
        NativityPainter.hills(&ctx, s, base: s.ground + 4 * u, amplitude: 12 * u, wavelength: 70 * u, phase: 2.6, scroll: 0, top: NP.rgb(34, 40, 78), bottom: NP.rgb(18, 22, 48))

        // ангел и воинство небесное
        let main = CGPoint(x: s.w * 0.5, y: s.h * 0.30)
        NativityPainter.angel(&ctx, at: main, scale: 0.82 * u, ambient: amb, strength: reveal)
        let host = nvEase((t - 9) / 2.0)
        if host > 0.001 {
            // воинство небесное по сторонам от главного ангела, зеркально
            let spots: [(CGFloat, CGFloat)] = [(0.11, 0.35), (0.22, 0.26), (0.30, 0.37), (0.14, 0.21)]
            for (i, spot) in spots.enumerated() {
                for side in [0, 1] {
                    let x = side == 0 ? spot.0 : 1 - spot.0
                    let bob = CGFloat(sin(amb * 1.1 + Double(i * 2 + side))) * 4 * u
                    let c = CGPoint(x: s.w * x, y: s.h * spot.1 + bob)
                    NativityPainter.angel(&ctx, at: c, scale: 0.30 * u, ambient: amb + Double(i * 2 + side), strength: host * 0.9)
                }
            }
        }

        // костёр, пастухи и овцы
        let feet = s.ground + 74 * u
        NativityPainter.fire(&ctx, at: CGPoint(x: s.w * 0.48, y: feet - 4 * u), size: 34 * u, ambient: amb)
        let lean = -0.10 * CGFloat(reveal)
        NativityPainter.person(&ctx, .shepherdA, at: CGPoint(x: s.w * 0.20, y: feet), height: 88 * u, facing: 1, lean: lean)
        NativityPainter.person(&ctx, .shepherdB, at: CGPoint(x: s.w * 0.73, y: feet + 4 * u), height: 84 * u, facing: -1, lean: lean, skirt: true)
        NativityPainter.person(&ctx, .shepherdC, at: CGPoint(x: s.w * 0.86, y: feet - 2 * u), height: 90 * u, facing: -1, lean: lean)
        let flock: [(CGFloat, CGFloat, CGFloat)] = [(0.08, 14, 1), (0.31, 22, 1), (0.60, 16, -1), (0.94, 24, -1), (0.42, 38, 1)]
        for sheep in flock {
            NativityPainter.sheep(&ctx, at: CGPoint(x: s.w * sheep.0, y: feet + sheep.1 * u), size: 34 * u, facing: sheep.2, lying: true, ambient: amb)
        }
    }

    // MARK: 4. Волхвы идут за звездой

    private static func magi(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        let tt = CGFloat(min(t, 9.5))
        NativityPainter.sky(&ctx, s, top: NP.rgb(6, 12, 44), middle: NP.rgb(24, 40, 98), horizon: NP.rgb(214, 142, 98))
        NativityPainter.stars(&ctx, s, ambient: amb, seed: 6)
        let starPoint = CGPoint(x: nvLerp(s.w * 0.80, s.w * 0.84, nvEase((t - 2) / 9)), y: s.h * CGFloat(0.22 + 0.10 * nvEase((t - 5) / 6)))
        NativityPainter.star(&ctx, at: starPoint, radius: 20 * u, ambient: amb)

        NativityPainter.hills(&ctx, s, base: s.ground - 52 * u, amplitude: 18 * u, wavelength: 110 * u, phase: 0.3, scroll: tt * 6 * u, top: NP.rgb(128, 90, 108), bottom: NP.rgb(92, 64, 92))
        NativityPainter.hills(&ctx, s, base: s.ground - 6 * u, amplitude: 16 * u, wavelength: 80 * u, phase: 1.9, scroll: tt * 14 * u, top: NP.rgb(88, 58, 86), bottom: NP.rgb(58, 42, 78))

        // дом, у которого остановится звезда, выплывает справа
        let houseX = nvLerp(s.w * 1.35, s.w * 0.84, nvEase((t - 2) / 9))
        let houseY = s.ground + 14 * u
        let lit = nvEase((t - 6) / 4)
        let body = CGRect(x: houseX - 34 * u, y: houseY - 42 * u, width: 68 * u, height: 42 * u)
        ctx.fill(Path(roundedRect: body, cornerRadius: 3 * u), with: .color(NP.rgb(70, 48, 70)))
        ctx.fill(Path(ellipseIn: CGRect(x: houseX - 20 * u, y: houseY - 58 * u, width: 40 * u, height: 32 * u)), with: .color(NP.rgb(70, 48, 70)))
        ctx.fill(Path(roundedRect: CGRect(x: houseX - 7 * u, y: houseY - 26 * u, width: 14 * u, height: 26 * u), cornerRadius: 6 * u), with: .color(NP.rgb(255, 206, 120, 0.4 + 0.55 * lit)))
        NativityPainter.glow(&ctx, at: CGPoint(x: houseX, y: houseY - 14 * u), radius: 70 * u, color: NP.rgb(255, 200, 120), alpha: 0.7 * lit)
        NativityPainter.beam(&ctx, from: starPoint, topWidth: 8 * u, to: CGPoint(x: houseX, y: houseY - 56 * u), bottomWidth: 56 * u, color: NP.warmLight, alpha: 0.4 * nvEase((t - 8) / 3))

        NativityPainter.hills(&ctx, s, base: s.ground + 34 * u, amplitude: 12 * u, wavelength: 60 * u, phase: 3.7, scroll: tt * 30 * u, top: NP.rgb(44, 34, 70), bottom: NP.rgb(24, 18, 48))

        // караван
        let moving = t < 9.5
        let riders: [(NativityPerson, Color)] = [
            (.magiViolet, NP.rgb(150, 40, 60)),
            (.magiTeal, NP.rgb(40, 110, 120)),
            (.magiRed, NP.rgb(222, 172, 72))
        ]
        let slots: [(CGFloat, CGFloat)] = [(0.20, 6), (0.47, 0), (0.74, -6)]
        for i in 0..<3 {
            let sway = CGFloat(sin(amb * 0.5 + Double(i))) * 3 * u
            let feet = s.ground + 78 * u + slots[i].1 * u
            NativityPainter.camel(&ctx, at: CGPoint(x: s.w * slots[i].0 + sway, y: feet), height: 100 * u, walk: moving ? t * 3.6 + Double(i) * 0.9 : nil, blanket: riders[i].1, rider: riders[i].0)
        }
    }

    // MARK: 5. Поклонение волхвов

    private static func adoration(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        let window = CGPoint(x: s.w * 0.80, y: s.h * 0.14)
        let floorY = interior(&ctx, s, ambient: amb, starStrength: 1, window: window, windowRadius: 24 * u)
        NativityPainter.beam(&ctx, from: window, topWidth: 24 * u, to: CGPoint(x: s.w * 0.58, y: floorY), bottomWidth: 150 * u, color: NP.warmLight, alpha: 0.38)

        // Мария с Младенцем на коленях, Иосиф за ней
        let marySeat = CGPoint(x: s.w * 0.62, y: floorY + 8 * u)
        let babyPoint = CGPoint(x: marySeat.x - 34 * u, y: marySeat.y - 44 * u)
        // сияние Младенца рисуем за людьми, иначе оно выбеливает Марию
        NativityPainter.glow(&ctx, at: babyPoint, radius: 120 * u, color: NP.rgb(255, 230, 168), alpha: 0.55 + 0.08 * sin(amb * 2))
        NativityPainter.person(&ctx, .joseph, at: CGPoint(x: s.w * 0.88, y: floorY - 2 * u), height: 112 * u, facing: -1, lean: 0.03)
        NativityPainter.person(&ctx, .mary, at: marySeat, height: 100 * u, facing: -1, skirt: true)
        bundle(&ctx, at: babyPoint, u: u)

        // волхвы входят слева и преклоняют колени
        let finals: [CGFloat] = [0.15, 0.29, 0.43]
        let people: [NativityPerson] = [.magiViolet, .magiTeal, .magiRed]
        var arrivals: [Double] = []
        for i in 0..<3 {
            let start = 0.3 + Double(i) * 0.7
            let walkProgress = nvEase((t - start) / 4.0)
            let arrived = start + 4.0
            arrivals.append(arrived)
            let kneel = nvEase((t - arrived) / 1.6)
            let x = nvLerp(-0.20 * s.w, finals[i] * s.w, walkProgress)
            let walking = t > start && t < arrived
            let height = (100 - 22 * CGFloat(kneel)) * u
            NativityPainter.person(&ctx, people[i], at: CGPoint(x: x, y: floorY + CGFloat(i) * 5 * u), height: height, facing: 1, walk: walking ? t * 4.4 + Double(i) : nil, lean: 0.30 * CGFloat(kneel), skirt: kneel > 0.4)
        }
        // дары кладут перед ними, ближе к зрителю, чтобы их не закрывали фигуры
        for i in 0..<3 {
            let giftAlpha = nvEase((t - arrivals[i] - 1.6) / 1.2)
            gift(&ctx, kind: i, at: CGPoint(x: finals[i] * s.w + 36 * u, y: floorY + 30 * u + CGFloat(i) * 4 * u), u: u, ambient: amb, alpha: giftAlpha)
        }
        NativityPainter.motes(&ctx, s, ambient: amb, count: 22, color: NP.warmLight, alpha: 0.8, area: CGRect(x: s.w * 0.30, y: s.h * 0.22, width: s.w * 0.5, height: floorY - s.h * 0.22))
    }

    /// Младенец на руках: пелёнки, нимб и золотое сияние
    private static func bundle(_ ctx: inout GraphicsContext, at c: CGPoint, u: CGFloat) {
        ctx.drawLayer { g in
            g.translateBy(x: c.x, y: c.y)
            g.rotate(by: .radians(-0.22))
            g.fill(Path(ellipseIn: CGRect(x: -22 * u, y: -9 * u, width: 46 * u, height: 19 * u)), with: .linearGradient(Gradient(colors: [NP.rgb(255, 252, 240), NP.rgb(240, 222, 188)]), startPoint: CGPoint(x: 0, y: -9 * u), endPoint: CGPoint(x: 0, y: 10 * u)))
            g.fill(Path(ellipseIn: CGRect(x: -34 * u, y: -9 * u, width: 18 * u, height: 18 * u)), with: .color(NP.rgb(246, 208, 172)))
            g.stroke(Path(ellipseIn: CGRect(x: -39 * u, y: -14 * u, width: 28 * u, height: 28 * u)), with: .color(NP.gold.opacity(0.9)), lineWidth: max(1.4, 2 * u))
        }
    }

    /// Дары: золото, ладан, смирна
    private static func gift(_ ctx: inout GraphicsContext, kind: Int, at p: CGPoint, u: CGFloat, ambient: Double, alpha: Double) {
        guard alpha > 0.001 else { return }
        ctx.drawLayer { g in
            g.opacity = alpha
            g.translateBy(x: p.x, y: p.y)
            switch kind {
            case 0:
                // сундучок с золотом
                g.fill(Path(roundedRect: CGRect(x: -15 * u, y: -18 * u, width: 30 * u, height: 18 * u), cornerRadius: 3 * u), with: .color(NP.rgb(150, 104, 56)))
                g.fill(Path(ellipseIn: CGRect(x: -15 * u, y: -26 * u, width: 30 * u, height: 16 * u)), with: .color(NP.gold))
                g.fill(Path(CGRect(x: -2 * u, y: -18 * u, width: 4 * u, height: 8 * u)), with: .color(NP.rgb(255, 236, 170)))
            case 1:
                // кадило с дымком
                g.fill(Path(ellipseIn: CGRect(x: -11 * u, y: -14 * u, width: 22 * u, height: 14 * u)), with: .color(NP.gold))
                for i in 0..<3 {
                    var smoke = Path()
                    let sway = CGFloat(sin(ambient * 1.4 + Double(i))) * 6 * u
                    smoke.move(to: CGPoint(x: CGFloat(i - 1) * 4 * u, y: -14 * u))
                    smoke.addCurve(to: CGPoint(x: CGFloat(i - 1) * 6 * u + sway, y: -50 * u), control1: CGPoint(x: 8 * u + sway, y: -26 * u), control2: CGPoint(x: -8 * u - sway, y: -38 * u))
                    g.stroke(smoke, with: .color(Color.white.opacity(0.35)), lineWidth: max(1, 1.6 * u))
                }
            default:
                // кувшин со смирной
                g.fill(Path(ellipseIn: CGRect(x: -10 * u, y: -22 * u, width: 20 * u, height: 22 * u)), with: .color(NP.rgb(176, 70, 78)))
                g.fill(Path(roundedRect: CGRect(x: -4 * u, y: -32 * u, width: 8 * u, height: 12 * u), cornerRadius: 2 * u), with: .color(NP.rgb(176, 70, 78)))
                g.fill(Path(ellipseIn: CGRect(x: -6 * u, y: -35 * u, width: 12 * u, height: 5 * u)), with: .color(NP.gold))
            }
        }
    }

    // MARK: 6. Финал

    private static func finale(_ ctx: inout GraphicsContext, _ s: NativityStage, _ t: Double, _ amb: Double) {
        let u = s.u
        NativityPainter.sky(&ctx, s, top: NP.rgb(10, 14, 52), middle: NP.rgb(74, 46, 120), horizon: NP.rgb(246, 172, 110))
        NativityPainter.stars(&ctx, s, ambient: amb, seed: 7)
        let grow = nvEase(t / 2.5)
        NativityPainter.glow(&ctx, at: CGPoint(x: s.w * 0.5, y: s.ground - 20 * u), radius: s.w * 0.9, color: NP.rgb(255, 196, 120), alpha: 0.35 * grow)
        NativityPainter.star(&ctx, at: CGPoint(x: s.w * 0.5, y: s.h * 0.22), radius: (14 + 12 * CGFloat(grow)) * u, ambient: amb)
        NativityPainter.hills(&ctx, s, base: s.ground - 56 * u, amplitude: 18 * u, wavelength: 100 * u, phase: 0.5, scroll: 0, top: NP.rgb(112, 70, 124), bottom: NP.rgb(76, 48, 100))
        NativityPainter.town(&ctx, s, baseY: s.ground - 8 * u, scroll: 0, ambient: amb, lit: 1)
        NativityPainter.hills(&ctx, s, base: s.ground + 14 * u, amplitude: 10 * u, wavelength: 70 * u, phase: 2.2, scroll: 0, top: NP.rgb(34, 26, 66), bottom: NP.rgb(18, 14, 42))
        NativityPainter.motes(&ctx, s, ambient: amb, count: 34, color: NP.warmLight, alpha: 0.9, area: CGRect(x: 0, y: s.h * 0.2, width: s.w, height: s.ground - s.h * 0.2))
    }
}
