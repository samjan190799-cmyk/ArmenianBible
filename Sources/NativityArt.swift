import SwiftUI

// MARK: - Мультфильм «Рождество Христово»: кисти
// Всё нарисовано кодом на Canvas: небо, звезда, холмы, люди, животные, ангелы. Без картинок и видео, поэтому почти ничего не весит.
// Лиц у людей нет: это мягкие силуэты в тёплых красках, чтобы образ Христа и святых не изображался «портретно».
// Длины считаем в единицах u: на телефоне 1 u ≈ 1 pt. Время сцены t идёт от нуля, ambient — часы для мерцания и дыма.

func nvClamp(_ x: Double) -> Double { min(1, max(0, x)) }

func nvEase(_ x: Double) -> Double {
    let c = nvClamp(x)
    return c * c * (3 - 2 * c)
}

func nvLerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }

/// Повторяемый «случайный» числа от 0 до 1: звёзды и пылинки стоят на одних и тех же местах в каждом кадре
func nvNoise(_ n: Int) -> CGFloat {
    var x = UInt64(truncatingIfNeeded: n &+ 7) &* 0x9E37_79B9_7F4A_7C15
    x ^= x >> 29
    x = x &* 0xBF58_476D_1CE4_E5B9
    x ^= x >> 32
    return CGFloat(x % 10_000) / 10_000
}

enum NP {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static let skin = rgb(226, 180, 142)
    static let gold = rgb(238, 192, 98)
    static let warmLight = rgb(255, 226, 154)
    static let straw = rgb(216, 172, 84)
    static let wood = rgb(96, 62, 40)
}

/// Размеры кадра: u — единица длины, ground — линия земли (ниже идёт подпись)
struct NativityStage {
    let size: CGSize
    var w: CGFloat { size.width }
    var h: CGFloat { size.height }
    var u: CGFloat { min(size.width, size.height * 0.5) / 390 }
    var ground: CGFloat { size.height * 0.55 }
}

struct NativityPerson {
    var robe: Color
    var shade: Color
    var cover: Color
    var trim: Color
    var staff = false
}

extension NativityPerson {
    static let mary = NativityPerson(robe: NP.rgb(48, 96, 176), shade: NP.rgb(26, 54, 118), cover: NP.rgb(66, 118, 202), trim: NP.gold)
    static let joseph = NativityPerson(robe: NP.rgb(156, 102, 54), shade: NP.rgb(98, 62, 36), cover: NP.rgb(218, 194, 144), trim: NP.rgb(204, 164, 92), staff: true)
    static let shepherdA = NativityPerson(robe: NP.rgb(142, 92, 62), shade: NP.rgb(88, 56, 40), cover: NP.rgb(196, 170, 128), trim: NP.rgb(180, 140, 84), staff: true)
    static let shepherdB = NativityPerson(robe: NP.rgb(92, 112, 78), shade: NP.rgb(56, 70, 50), cover: NP.rgb(206, 186, 142), trim: NP.rgb(170, 140, 84), staff: false)
    static let shepherdC = NativityPerson(robe: NP.rgb(128, 84, 98), shade: NP.rgb(80, 50, 62), cover: NP.rgb(190, 164, 130), trim: NP.rgb(176, 136, 88), staff: true)
    static let magiRed = NativityPerson(robe: NP.rgb(170, 48, 58), shade: NP.rgb(106, 28, 38), cover: NP.rgb(240, 196, 92), trim: NP.rgb(246, 214, 120))
    static let magiTeal = NativityPerson(robe: NP.rgb(36, 124, 128), shade: NP.rgb(20, 78, 86), cover: NP.rgb(234, 224, 200), trim: NP.rgb(230, 206, 130))
    static let magiViolet = NativityPerson(robe: NP.rgb(112, 70, 150), shade: NP.rgb(70, 42, 104), cover: NP.rgb(238, 188, 86), trim: NP.rgb(240, 208, 120))
}

enum NativityPainter {

    // MARK: Небо, звёзды, свет

    static func sky(_ ctx: inout GraphicsContext, _ s: NativityStage, top: Color, middle: Color, horizon: Color) {
        let gradient = Gradient(stops: [
            Gradient.Stop(color: top, location: 0),
            Gradient.Stop(color: middle, location: 0.34),
            Gradient.Stop(color: horizon, location: 0.55)
        ])
        ctx.fill(
            Path(CGRect(origin: .zero, size: s.size)),
            with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: s.h))
        )
    }

    static func stars(_ ctx: inout GraphicsContext, _ s: NativityStage, ambient: Double, count: Int = 80, seed: Int = 1, depth: CGFloat = 0.5, alpha: Double = 1) {
        for i in 0..<count {
            let x = nvNoise(seed * 997 + i * 4) * s.w
            let y = nvNoise(seed * 997 + i * 4 + 1) * s.h * depth
            let size = (0.7 + nvNoise(seed * 997 + i * 4 + 2) * 1.5) * s.u
            let phase = Double(nvNoise(seed * 997 + i * 4 + 3)) * 6.2832
            let twinkle = 0.5 + 0.5 * sin(ambient * 1.3 + phase)
            let r = size * CGFloat(0.75 + 0.25 * twinkle)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity((0.30 + 0.70 * twinkle) * alpha)))
        }
    }

    static func glow(_ ctx: inout GraphicsContext, at c: CGPoint, radius r: CGFloat, color: Color, alpha: Double) {
        guard alpha > 0.001 else { return }
        ctx.drawLayer { g in
            g.blendMode = .plusLighter
            let gradient = Gradient(colors: [color.opacity(alpha), color.opacity(alpha * 0.35), color.opacity(0)])
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            g.fill(Path(ellipseIn: rect), with: .radialGradient(gradient, center: c, startRadius: 0, endRadius: r))
        }
    }

    /// Вифлеемская звезда: мягкое сияние, восемь лучей и яркое ядро
    static func star(_ ctx: inout GraphicsContext, at c: CGPoint, radius: CGFloat, ambient: Double, strength: Double = 1) {
        guard strength > 0.001 else { return }
        let pulse = CGFloat(1 + 0.06 * sin(ambient * 2.1))
        let r = radius * pulse
        ctx.drawLayer { g in
            g.blendMode = .plusLighter
            let halo = Gradient(colors: [
                NP.rgb(255, 238, 176, 0.85 * strength),
                NP.rgb(255, 204, 116, 0.28 * strength),
                NP.rgb(255, 184, 96, 0)
            ])
            let haloRect = CGRect(x: c.x - r * 5, y: c.y - r * 5, width: r * 10, height: r * 10)
            g.fill(Path(ellipseIn: haloRect), with: .radialGradient(halo, center: c, startRadius: 0, endRadius: r * 5))
            for k in 0..<8 {
                let angle = CGFloat(k) * CGFloat.pi / 4 + CGFloat(ambient) * 0.03
                let long: CGFloat = (k % 2 == 0) ? r * 7 : r * 3.6
                let half: CGFloat = (k % 2 == 0) ? r * 0.30 : r * 0.18
                let dx = cos(angle)
                let dy = sin(angle)
                var ray = Path()
                ray.move(to: CGPoint(x: c.x - dy * half, y: c.y + dx * half))
                ray.addLine(to: CGPoint(x: c.x + dx * long, y: c.y + dy * long))
                ray.addLine(to: CGPoint(x: c.x + dy * half, y: c.y - dx * half))
                ray.closeSubpath()
                g.fill(ray, with: .color(NP.rgb(255, 240, 192, 0.55 * strength)))
            }
            let coreRect = CGRect(x: c.x - r * 0.5, y: c.y - r * 0.5, width: r, height: r)
            g.fill(Path(ellipseIn: coreRect), with: .color(Color.white.opacity(strength)))
        }
    }

    /// Луч света сверху вниз
    static func beam(_ ctx: inout GraphicsContext, from top: CGPoint, topWidth: CGFloat, to bottom: CGPoint, bottomWidth: CGFloat, color: Color, alpha: Double) {
        guard alpha > 0.001 else { return }
        var path = Path()
        path.move(to: CGPoint(x: top.x - topWidth / 2, y: top.y))
        path.addLine(to: CGPoint(x: top.x + topWidth / 2, y: top.y))
        path.addLine(to: CGPoint(x: bottom.x + bottomWidth / 2, y: bottom.y))
        path.addLine(to: CGPoint(x: bottom.x - bottomWidth / 2, y: bottom.y))
        path.closeSubpath()
        ctx.drawLayer { g in
            g.blendMode = .plusLighter
            let gradient = Gradient(colors: [color.opacity(alpha), color.opacity(0)])
            g.fill(path, with: .linearGradient(gradient, startPoint: top, endPoint: bottom))
        }
    }

    /// Золотые пылинки, плывущие вверх
    static func motes(_ ctx: inout GraphicsContext, _ s: NativityStage, ambient: Double, count: Int, color: Color, alpha: Double, area: CGRect, seed: Int = 5) {
        guard alpha > 0.001 else { return }
        for i in 0..<count {
            let speed = 6 + Double(nvNoise(seed * 31 + i * 3)) * 10
            let cycle = Double(area.height) / speed
            let phase = Double(nvNoise(seed * 31 + i * 3 + 1)) * cycle
            let k = (ambient + phase).truncatingRemainder(dividingBy: cycle) / cycle
            let sway = CGFloat(sin(ambient * 0.7 + Double(i))) * 6 * s.u
            let x = area.minX + nvNoise(seed * 31 + i * 3 + 2) * area.width + sway
            let y = area.maxY - CGFloat(k) * area.height
            let r = (1.0 + nvNoise(i * 13 + seed)) * 1.4 * s.u
            let fade = sin(k * Double.pi)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha * fade)))
        }
    }

    // MARK: Земля

    static func hills(_ ctx: inout GraphicsContext, _ s: NativityStage, base: CGFloat, amplitude: CGFloat, wavelength: CGFloat, phase: CGFloat, scroll: CGFloat, top: Color, bottom: Color) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: s.h))
        var x: CGFloat = 0
        while x <= s.w + 8 {
            let a = (x + scroll) / wavelength
            let w1 = sin(a + phase)
            let w2 = sin(a * 2.3 + phase * 1.7)
            let y = base + amplitude * (w1 + 0.45 * w2)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 8
        }
        path.addLine(to: CGPoint(x: s.w + 8, y: s.h))
        path.closeSubpath()
        let gradient = Gradient(colors: [top, bottom])
        ctx.fill(path, with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: base - amplitude * 1.5), endPoint: CGPoint(x: 0, y: s.h)))
    }

    /// Дорога: светлая лента, по ней с прокруткой бегут камешки
    static func road(_ ctx: inout GraphicsContext, _ s: NativityStage, top: CGFloat, thickness: CGFloat, scroll: CGFloat, color: Color, stone: Color) {
        var path = Path()
        path.move(to: CGPoint(x: -8, y: top + thickness))
        var x: CGFloat = -8
        while x <= s.w + 8 {
            path.addLine(to: CGPoint(x: x, y: top + 3 * s.u * sin((x + scroll) / (60 * s.u))))
            x += 8
        }
        path.addLine(to: CGPoint(x: s.w + 8, y: top + thickness))
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
        let gap = 53 * s.u
        for i in 0..<10 {
            let raw = CGFloat(i) * gap - scroll
            var px = raw.truncatingRemainder(dividingBy: gap * 10)
            if px < 0 { px += gap * 10 }
            px -= gap
            let py = top + thickness * (0.35 + 0.5 * nvNoise(i * 7))
            let r = (1.5 + nvNoise(i * 11) * 2) * s.u
            ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r * 0.6, width: r * 2, height: r * 1.2)), with: .color(stone))
        }
    }

    // MARK: Люди

    /// Человек мягким силуэтом без лица. base — точка на земле под ногами, H — рост
    static func person(_ ctx: inout GraphicsContext, _ p: NativityPerson, at base: CGPoint, height H: CGFloat, facing: CGFloat = 1, walk: Double? = nil, lean: CGFloat = 0, skirt: Bool = false, alpha: Double = 1) {
        ctx.drawLayer { g in
            g.opacity = alpha
            g.translateBy(x: base.x, y: base.y)
            g.scaleBy(x: facing, y: 1)
            g.rotate(by: .radians(Double(lean)))

            var swing = 0.0
            if let w = walk { swing = sin(w) }
            let step = CGFloat(swing) * H * 0.09
            let bob = -CGFloat(abs(swing)) * H * 0.02
            let lift1 = CGFloat(max(0, swing)) * H * 0.04
            let lift2 = CGFloat(max(0, -swing)) * H * 0.04

            // ступни
            let footColor = Color.black.opacity(0.55)
            let foot1x = -0.13 * H + step
            let foot2x = 0.02 * H - step
            g.fill(Path(ellipseIn: CGRect(x: foot1x, y: -0.02 * H - lift1, width: 0.11 * H, height: 0.04 * H)), with: .color(footColor))
            g.fill(Path(ellipseIn: CGRect(x: foot2x, y: -0.02 * H - lift2, width: 0.11 * H, height: 0.04 * H)), with: .color(footColor))

            g.translateBy(x: 0, y: bob)

            // посох за спиной
            if p.staff {
                var staff = Path()
                staff.move(to: CGPoint(x: 0.19 * H, y: -1.0 * H))
                staff.addLine(to: CGPoint(x: 0.19 * H, y: 0.02 * H))
                g.stroke(staff, with: .color(NP.wood), lineWidth: max(1.6, 0.025 * H))
            }

            // подол и платье
            var robe = Path()
            robe.move(to: CGPoint(x: -0.13 * H, y: -0.78 * H))
            robe.addQuadCurve(to: CGPoint(x: -0.23 * H, y: -0.02 * H), control: CGPoint(x: -0.20 * H, y: -0.40 * H))
            robe.addLine(to: CGPoint(x: 0.23 * H, y: -0.02 * H))
            robe.addQuadCurve(to: CGPoint(x: 0.13 * H, y: -0.78 * H), control: CGPoint(x: 0.20 * H, y: -0.40 * H))
            robe.closeSubpath()
            let robeGradient = Gradient(colors: [p.robe, p.shade])
            g.fill(robe, with: .linearGradient(robeGradient, startPoint: CGPoint(x: 0, y: -0.78 * H), endPoint: CGPoint(x: 0, y: 0)))
            let hem = CGRect(x: -0.23 * H, y: -0.065 * H, width: 0.46 * H, height: 0.045 * H)
            g.fill(Path(roundedRect: hem, cornerRadius: 0.02 * H), with: .color(p.trim.opacity(0.9)))

            // подол сидящего или преклонившего колени
            if skirt {
                let lap = CGRect(x: -0.30 * H, y: -0.24 * H, width: 0.74 * H, height: 0.26 * H)
                g.fill(Path(ellipseIn: lap), with: .linearGradient(Gradient(colors: [p.robe, p.shade]), startPoint: CGPoint(x: 0, y: -0.24 * H), endPoint: CGPoint(x: 0, y: 0.02 * H)))
                let lapTrim = CGRect(x: -0.28 * H, y: -0.075 * H, width: 0.70 * H, height: 0.035 * H)
                g.fill(Path(roundedRect: lapTrim, cornerRadius: 0.015 * H), with: .color(p.trim.opacity(0.85)))
            }

            // рука с посохом или просто рукав
            let sleeve = CGRect(x: 0.04 * H, y: -0.70 * H, width: 0.11 * H, height: 0.26 * H)
            g.fill(Path(roundedRect: sleeve, cornerRadius: 0.05 * H), with: .color(p.shade))
            if p.staff {
                let hand = CGRect(x: 0.14 * H, y: -0.50 * H, width: 0.07 * H, height: 0.07 * H)
                g.fill(Path(ellipseIn: hand), with: .color(NP.skin))
            }

            // покрывало или головной убор: за головой и поверх неё, лицо открыто спереди
            let coverRect = CGRect(x: -0.115 * H, y: -1.0 * H, width: 0.20 * H, height: 0.20 * H)
            g.fill(Path(ellipseIn: coverRect), with: .color(p.cover))
            let headRect = CGRect(x: -0.045 * H, y: -0.955 * H, width: 0.12 * H, height: 0.125 * H)
            g.fill(Path(ellipseIn: headRect), with: .color(NP.skin))
            var band = Path()
            band.move(to: CGPoint(x: -0.10 * H, y: -0.93 * H))
            band.addQuadCurve(to: CGPoint(x: 0.055 * H, y: -0.985 * H), control: CGPoint(x: -0.02 * H, y: -1.03 * H))
            g.stroke(band, with: .color(p.trim), lineWidth: max(1.2, 0.018 * H))
        }
    }

    // MARK: Животные

    static func donkey(_ ctx: inout GraphicsContext, at base: CGPoint, length L: CGFloat, facing: CGFloat = 1, walk: Double? = nil, fur: Color = NP.rgb(132, 114, 108), dark: Color = NP.rgb(88, 74, 76), headDown: CGFloat = 0) {
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            g.scaleBy(x: facing, y: 1)
            let w = walk ?? 0
            let moving = walk != nil
            let legs: [(CGFloat, Double, Bool)] = [(-0.34, 0, true), (0.30, .pi, true), (-0.22, .pi, false), (0.40, 0, false)]
            for far in [true, false] {
                for leg in legs where leg.2 == far {
                    g.drawLayer { l in
                        l.translateBy(x: leg.0 * L, y: -0.46 * L)
                        let angle = moving ? sin(w + leg.1) * 0.38 : 0
                        l.rotate(by: .radians(angle))
                        let shape = CGRect(x: -0.035 * L, y: 0, width: 0.07 * L, height: 0.46 * L)
                        l.fill(Path(roundedRect: shape, cornerRadius: 0.03 * L), with: .color(far ? dark : fur))
                        let hoof = CGRect(x: -0.045 * L, y: 0.43 * L, width: 0.10 * L, height: 0.05 * L)
                        l.fill(Path(ellipseIn: hoof), with: .color(Color.black.opacity(0.6)))
                    }
                }
                if far {
                    // хвост и туловище между дальними и ближними ногами
                    var tail = Path()
                    tail.move(to: CGPoint(x: -0.48 * L, y: -0.72 * L))
                    tail.addQuadCurve(to: CGPoint(x: -0.58 * L, y: -0.42 * L), control: CGPoint(x: -0.62 * L, y: -0.66 * L))
                    g.stroke(tail, with: .color(dark), lineWidth: max(1.5, 0.03 * L))
                    let body = CGRect(x: -0.50 * L, y: -0.83 * L, width: 1.0 * L, height: 0.42 * L)
                    g.fill(Path(ellipseIn: body), with: .linearGradient(Gradient(colors: [fur, dark]), startPoint: CGPoint(x: 0, y: -0.83 * L), endPoint: CGPoint(x: 0, y: -0.41 * L)))
                }
            }
            // шея и голова
            var neck = Path()
            neck.move(to: CGPoint(x: 0.28 * L, y: -0.80 * L))
            neck.addLine(to: CGPoint(x: 0.56 * L, y: -1.06 * L + headDown * 0.3 * L))
            neck.addLine(to: CGPoint(x: 0.70 * L, y: -0.98 * L + headDown * 0.4 * L))
            neck.addLine(to: CGPoint(x: 0.46 * L, y: -0.62 * L))
            neck.closeSubpath()
            g.fill(neck, with: .color(fur))
            g.drawLayer { h in
                h.translateBy(x: 0.72 * L, y: -1.01 * L + headDown * 0.4 * L)
                h.rotate(by: .radians(0.45 + Double(headDown)))
                h.fill(Path(ellipseIn: CGRect(x: -0.16 * L, y: -0.085 * L, width: 0.32 * L, height: 0.17 * L)), with: .color(fur))
                h.fill(Path(ellipseIn: CGRect(x: 0.06 * L, y: -0.05 * L, width: 0.13 * L, height: 0.10 * L)), with: .color(NP.rgb(196, 176, 164)))
                h.fill(Path(ellipseIn: CGRect(x: -0.12 * L, y: -0.20 * L, width: 0.06 * L, height: 0.15 * L)), with: .color(dark))
                h.fill(Path(ellipseIn: CGRect(x: -0.06 * L, y: -0.21 * L, width: 0.06 * L, height: 0.15 * L)), with: .color(fur))
            }
        }
    }

    static func ox(_ ctx: inout GraphicsContext, at base: CGPoint, length L: CGFloat, facing: CGFloat = 1, ambient: Double) {
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            g.scaleBy(x: facing, y: 1 + 0.012 * CGFloat(sin(ambient * 1.4)))
            let hide = NP.rgb(112, 72, 52)
            let darkHide = NP.rgb(70, 44, 36)
            for lx in [-0.34, -0.20, 0.24, 0.36] {
                let leg = CGRect(x: CGFloat(lx) * L - 0.04 * L, y: -0.42 * L, width: 0.08 * L, height: 0.42 * L)
                g.fill(Path(roundedRect: leg, cornerRadius: 0.03 * L), with: .color(darkHide))
            }
            let body = CGRect(x: -0.50 * L, y: -0.82 * L, width: 1.0 * L, height: 0.50 * L)
            g.fill(Path(ellipseIn: body), with: .linearGradient(Gradient(colors: [hide, darkHide]), startPoint: CGPoint(x: 0, y: -0.82 * L), endPoint: CGPoint(x: 0, y: -0.32 * L)))
            g.fill(Path(ellipseIn: CGRect(x: 0.34 * L, y: -0.66 * L, width: 0.30 * L, height: 0.26 * L)), with: .color(hide))
            g.fill(Path(ellipseIn: CGRect(x: 0.52 * L, y: -0.52 * L, width: 0.16 * L, height: 0.12 * L)), with: .color(NP.rgb(176, 140, 124)))
            var horn = Path()
            horn.move(to: CGPoint(x: 0.42 * L, y: -0.66 * L))
            horn.addQuadCurve(to: CGPoint(x: 0.50 * L, y: -0.84 * L), control: CGPoint(x: 0.36 * L, y: -0.80 * L))
            g.stroke(horn, with: .color(NP.rgb(230, 218, 190)), lineWidth: max(1.5, 0.035 * L))
        }
    }

    static func sheep(_ ctx: inout GraphicsContext, at base: CGPoint, size k: CGFloat, facing: CGFloat = 1, lying: Bool = false, ambient: Double = 0) {
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            g.scaleBy(x: facing, y: 1 + 0.015 * CGFloat(sin(ambient * 1.6 + Double(base.x))))
            let wool = NP.rgb(240, 232, 216)
            let woolShade = NP.rgb(188, 178, 172)
            let face = NP.rgb(66, 54, 58)
            if !lying {
                for lx in [-0.16, 0.16] {
                    let leg = CGRect(x: CGFloat(lx) * k - 0.025 * k, y: -0.16 * k, width: 0.05 * k, height: 0.16 * k)
                    g.fill(Path(roundedRect: leg, cornerRadius: 0.02 * k), with: .color(face))
                }
            }
            let lift: CGFloat = lying ? 0.0 : 0.1
            let puffs: [(CGFloat, CGFloat)] = [(-0.26, -0.30), (0.0, -0.40), (0.26, -0.30), (-0.12, -0.22), (0.14, -0.22), (-0.34, -0.18), (0.34, -0.18)]
            for puff in puffs {
                let r = 0.21 * k
                let rect = CGRect(x: puff.0 * k - r, y: (puff.1 - lift) * k - r + 0.04 * k, width: r * 2, height: r * 2)
                g.fill(Path(ellipseIn: rect), with: .color(woolShade))
            }
            for puff in puffs {
                let r = 0.21 * k
                let rect = CGRect(x: puff.0 * k - r, y: (puff.1 - lift) * k - r, width: r * 2, height: r * 2)
                g.fill(Path(ellipseIn: rect), with: .color(wool))
            }
            let head = CGRect(x: 0.36 * k, y: (-0.34 - lift) * k, width: 0.20 * k, height: 0.17 * k)
            g.fill(Path(ellipseIn: head), with: .color(face))
            let ear = CGRect(x: 0.34 * k, y: (-0.38 - lift) * k, width: 0.09 * k, height: 0.05 * k)
            g.fill(Path(ellipseIn: ear), with: .color(face))
        }
    }

    static func camel(_ ctx: inout GraphicsContext, at base: CGPoint, height C: CGFloat, facing: CGFloat = 1, walk: Double? = nil, fur: Color = NP.rgb(150, 112, 78), dark: Color = NP.rgb(98, 70, 54), blanket: Color, rider: NativityPerson) {
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            g.scaleBy(x: facing, y: 1)
            let w = walk ?? 0
            let moving = walk != nil
            let legs: [(CGFloat, Double, Bool)] = [(-0.34, 0, true), (0.30, .pi, true), (-0.22, .pi, false), (0.40, 0, false)]
            for far in [true, false] {
                for leg in legs where leg.2 == far {
                    g.drawLayer { l in
                        l.translateBy(x: leg.0 * C, y: -0.50 * C)
                        let angle = moving ? sin(w + leg.1) * 0.30 : 0
                        l.rotate(by: .radians(angle))
                        let shape = CGRect(x: -0.032 * C, y: 0, width: 0.064 * C, height: 0.50 * C)
                        l.fill(Path(roundedRect: shape, cornerRadius: 0.028 * C), with: .color(far ? dark : fur))
                        let pad = CGRect(x: -0.045 * C, y: 0.47 * C, width: 0.10 * C, height: 0.045 * C)
                        l.fill(Path(ellipseIn: pad), with: .color(Color.black.opacity(0.55)))
                    }
                }
                if far {
                    let body = CGRect(x: -0.50 * C, y: -0.80 * C, width: 1.0 * C, height: 0.34 * C)
                    g.fill(Path(ellipseIn: body), with: .linearGradient(Gradient(colors: [fur, dark]), startPoint: CGPoint(x: 0, y: -0.80 * C), endPoint: CGPoint(x: 0, y: -0.46 * C)))
                    let hump = CGRect(x: -0.22 * C, y: -1.00 * C, width: 0.30 * C, height: 0.30 * C)
                    g.fill(Path(ellipseIn: hump), with: .color(fur))
                }
            }
            // шея и голова
            var neck = Path()
            neck.move(to: CGPoint(x: 0.30 * C, y: -0.78 * C))
            neck.addQuadCurve(to: CGPoint(x: 0.50 * C, y: -1.12 * C), control: CGPoint(x: 0.34 * C, y: -1.02 * C))
            neck.addLine(to: CGPoint(x: 0.60 * C, y: -1.06 * C))
            neck.addQuadCurve(to: CGPoint(x: 0.46 * C, y: -0.66 * C), control: CGPoint(x: 0.48 * C, y: -0.94 * C))
            neck.closeSubpath()
            g.fill(neck, with: .color(fur))
            g.drawLayer { h in
                h.translateBy(x: 0.58 * C, y: -1.13 * C)
                h.rotate(by: .radians(0.35))
                h.fill(Path(ellipseIn: CGRect(x: -0.13 * C, y: -0.055 * C, width: 0.28 * C, height: 0.11 * C)), with: .color(fur))
                h.fill(Path(ellipseIn: CGRect(x: -0.10 * C, y: -0.09 * C, width: 0.05 * C, height: 0.07 * C)), with: .color(dark))
            }
            // всадник и попона
            person(&g, rider, at: CGPoint(x: -0.08 * C, y: -0.86 * C), height: 0.62 * C, facing: 1, skirt: true)
            var drape = Path()
            drape.move(to: CGPoint(x: -0.30 * C, y: -0.86 * C))
            drape.addQuadCurve(to: CGPoint(x: -0.26 * C, y: -0.56 * C), control: CGPoint(x: -0.34 * C, y: -0.70 * C))
            drape.addLine(to: CGPoint(x: 0.12 * C, y: -0.58 * C))
            drape.addQuadCurve(to: CGPoint(x: 0.14 * C, y: -0.86 * C), control: CGPoint(x: 0.18 * C, y: -0.72 * C))
            drape.closeSubpath()
            g.fill(drape, with: .color(blanket))
            g.fill(Path(CGRect(x: -0.27 * C, y: -0.60 * C, width: 0.38 * C, height: 0.03 * C)), with: .color(NP.gold.opacity(0.9)))
        }
    }

    // MARK: Ангел

    /// Ангел света: белая фигура с крыльями, нимбом и лучами. Рост около 130 единиц при k = 1
    static func angel(_ ctx: inout GraphicsContext, at c: CGPoint, scale k: CGFloat, ambient: Double, strength: Double) {
        guard strength > 0.001 else { return }
        glow(&ctx, at: c, radius: 190 * k, color: NP.rgb(255, 232, 170), alpha: 0.55 * strength)
        ctx.drawLayer { g in
            g.opacity = strength
            g.translateBy(x: c.x, y: c.y)
            g.scaleBy(x: k, y: k)

            // лучи
            g.drawLayer { r in
                r.blendMode = .plusLighter
                r.rotate(by: .radians(ambient * 0.05))
                for i in 0..<14 {
                    let a = CGFloat(i) * CGFloat.pi * 2 / 14
                    let dx = cos(a)
                    let dy = sin(a)
                    var ray = Path()
                    ray.move(to: CGPoint(x: -dy * 5, y: -60 + dx * 5))
                    ray.addLine(to: CGPoint(x: dx * 260, y: -60 + dy * 260))
                    ray.addLine(to: CGPoint(x: dy * 5, y: -60 - dx * 5))
                    ray.closeSubpath()
                    r.fill(ray, with: .color(NP.rgb(255, 238, 190, 0.16)))
                }
            }

            // крылья
            let flap = sin(ambient * 1.5) * 0.05
            for side in [-1.0, 1.0] {
                g.drawLayer { wing in
                    wing.translateBy(x: CGFloat(side) * 16, y: -78)
                    wing.scaleBy(x: CGFloat(side), y: 1)
                    wing.rotate(by: .radians(flap * side * -1))
                    var shape = Path()
                    shape.move(to: CGPoint(x: 0, y: 6))
                    shape.addCurve(to: CGPoint(x: 96, y: -44), control1: CGPoint(x: 30, y: -6), control2: CGPoint(x: 78, y: -10))
                    shape.addCurve(to: CGPoint(x: 84, y: 8), control1: CGPoint(x: 104, y: -22), control2: CGPoint(x: 98, y: -2))
                    shape.addCurve(to: CGPoint(x: 66, y: 36), control1: CGPoint(x: 86, y: 18), control2: CGPoint(x: 78, y: 28))
                    shape.addCurve(to: CGPoint(x: 30, y: 52), control1: CGPoint(x: 54, y: 46), control2: CGPoint(x: 44, y: 52))
                    shape.addCurve(to: CGPoint(x: 0, y: 40), control1: CGPoint(x: 18, y: 52), control2: CGPoint(x: 6, y: 48))
                    shape.closeSubpath()
                    let feathers = Gradient(colors: [NP.rgb(255, 250, 236), NP.rgb(246, 226, 176)])
                    wing.fill(shape, with: .linearGradient(feathers, startPoint: CGPoint(x: 0, y: -40), endPoint: CGPoint(x: 70, y: 50)))
                    for j in 0..<4 {
                        var line = Path()
                        let y0 = CGFloat(j) * 11 + 4
                        line.move(to: CGPoint(x: 8, y: y0))
                        line.addQuadCurve(to: CGPoint(x: 80 - CGFloat(j) * 12, y: y0 + 4 - CGFloat(j) * 11), control: CGPoint(x: 44, y: y0 - 10))
                        wing.stroke(line, with: .color(NP.rgb(214, 186, 128, 0.6)), lineWidth: 1.2)
                    }
                }
            }

            // одеяние
            var robe = Path()
            robe.move(to: CGPoint(x: -15, y: -88))
            robe.addQuadCurve(to: CGPoint(x: -34, y: 46), control: CGPoint(x: -30, y: -20))
            robe.addQuadCurve(to: CGPoint(x: -12, y: 56), control: CGPoint(x: -24, y: 58))
            robe.addQuadCurve(to: CGPoint(x: 8, y: 48), control: CGPoint(x: -2, y: 62))
            robe.addQuadCurve(to: CGPoint(x: 34, y: 46), control: CGPoint(x: 24, y: 60))
            robe.addQuadCurve(to: CGPoint(x: 15, y: -88), control: CGPoint(x: 30, y: -20))
            robe.closeSubpath()
            g.fill(robe, with: .linearGradient(Gradient(colors: [NP.rgb(255, 255, 246), NP.rgb(250, 230, 184)]), startPoint: CGPoint(x: 0, y: -88), endPoint: CGPoint(x: 0, y: 56)))
            g.fill(Path(CGRect(x: -22, y: -60, width: 44, height: 4)), with: .color(NP.gold.opacity(0.85)))
            // руки, раскрытые в стороны
            for side in [-1.0, 1.0] {
                var arm = Path()
                arm.move(to: CGPoint(x: CGFloat(side) * 12, y: -80))
                arm.addQuadCurve(to: CGPoint(x: CGFloat(side) * 48, y: -66), control: CGPoint(x: CGFloat(side) * 30, y: -84))
                g.stroke(arm, with: .color(NP.rgb(255, 246, 224)), lineWidth: 9)
            }
            // голова и нимб
            g.fill(Path(ellipseIn: CGRect(x: -13, y: -113, width: 26, height: 28)), with: .color(NP.rgb(255, 238, 210)))
            let halo = CGRect(x: -22, y: -135, width: 44, height: 14)
            g.stroke(Path(ellipseIn: halo), with: .color(NP.gold), lineWidth: 3)
        }
    }

    // MARK: Ясли

    /// Ясли с Младенцем. Лица нет: пелёнки и золотое сияние. W — ширина яслей
    static func manger(_ ctx: inout GraphicsContext, at base: CGPoint, width W: CGFloat, ambient: Double, baby: Double, glowStrength: Double) {
        glow(&ctx, at: CGPoint(x: base.x, y: base.y - 0.40 * W), radius: 2.6 * W, color: NP.rgb(255, 214, 140), alpha: 0.75 * glowStrength)
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            // ножки крест-накрест
            for side in [-1.0, 1.0] {
                var legs = Path()
                legs.move(to: CGPoint(x: CGFloat(side) * 0.30 * W, y: -0.16 * W))
                legs.addLine(to: CGPoint(x: CGFloat(side) * 0.46 * W, y: 0))
                legs.move(to: CGPoint(x: CGFloat(side) * 0.46 * W, y: -0.16 * W))
                legs.addLine(to: CGPoint(x: CGFloat(side) * 0.30 * W, y: 0))
                g.stroke(legs, with: .color(NP.wood), lineWidth: max(2, 0.05 * W))
            }
            // корыто
            var trough = Path()
            trough.move(to: CGPoint(x: -0.52 * W, y: -0.38 * W))
            trough.addLine(to: CGPoint(x: 0.52 * W, y: -0.38 * W))
            trough.addLine(to: CGPoint(x: 0.38 * W, y: -0.12 * W))
            trough.addLine(to: CGPoint(x: -0.38 * W, y: -0.12 * W))
            trough.closeSubpath()
            g.fill(trough, with: .linearGradient(Gradient(colors: [NP.rgb(132, 88, 54), NP.wood]), startPoint: CGPoint(x: 0, y: -0.38 * W), endPoint: CGPoint(x: 0, y: -0.12 * W)))
            // солома
            g.fill(Path(ellipseIn: CGRect(x: -0.50 * W, y: -0.46 * W, width: 1.0 * W, height: 0.17 * W)), with: .color(NP.straw))
            // Младенец в пелёнках
            if baby > 0.001 {
                g.drawLayer { b in
                    b.opacity = baby
                    let swaddle = CGRect(x: -0.28 * W, y: -0.50 * W, width: 0.58 * W, height: 0.18 * W)
                    b.fill(Path(ellipseIn: swaddle), with: .linearGradient(Gradient(colors: [NP.rgb(255, 250, 238), NP.rgb(240, 222, 188)]), startPoint: CGPoint(x: 0, y: -0.50 * W), endPoint: CGPoint(x: 0, y: -0.32 * W)))
                    var bands = Path()
                    bands.move(to: CGPoint(x: -0.05 * W, y: -0.49 * W))
                    bands.addLine(to: CGPoint(x: -0.10 * W, y: -0.34 * W))
                    bands.move(to: CGPoint(x: 0.10 * W, y: -0.49 * W))
                    bands.addLine(to: CGPoint(x: 0.05 * W, y: -0.34 * W))
                    b.stroke(bands, with: .color(NP.rgb(214, 186, 140, 0.8)), lineWidth: 1.2)
                    let head = CGRect(x: -0.37 * W, y: -0.54 * W, width: 0.16 * W, height: 0.16 * W)
                    b.fill(Path(ellipseIn: head), with: .color(NP.rgb(246, 208, 172)))
                    let halo = CGRect(x: -0.42 * W, y: -0.59 * W, width: 0.26 * W, height: 0.26 * W)
                    b.stroke(Path(ellipseIn: halo), with: .color(NP.gold.opacity(0.9)), lineWidth: max(1.4, 0.02 * W))
                }
                glow(&g, at: CGPoint(x: -0.29 * W, y: -0.46 * W), radius: 0.9 * W, color: NP.rgb(255, 232, 170), alpha: 0.6 * baby)
            }
        }
    }

    // MARK: Вифлеем и огонь

    /// Дома города на склоне: двумя рядами, окна мерцают
    static func town(_ ctx: inout GraphicsContext, _ s: NativityStage, baseY: CGFloat, scroll: CGFloat, ambient: Double, lit: Double) {
        let u = s.u
        for row in 0..<2 {
            let depth = CGFloat(row)
            let tone = row == 0 ? NP.rgb(54, 40, 86) : NP.rgb(34, 26, 62)
            let step = (row == 0 ? 46 : 62) * u
            let count = Int(s.w / step) + 3
            let shift = scroll * (row == 0 ? 0.6 : 1.0)
            for i in 0..<count {
                let seed = i + row * 100
                let width = (30 + nvNoise(seed * 3) * 26) * u * (1 + depth * 0.25)
                let height = (30 + nvNoise(seed * 3 + 1) * 34) * u * (1 + depth * 0.25)
                let x = CGFloat(i) * step - shift.truncatingRemainder(dividingBy: step) - step + (nvNoise(seed * 3 + 2) - 0.5) * 8 * u
                let y = baseY + depth * 14 * u + (nvNoise(seed) - 0.5) * 6 * u
                let body = CGRect(x: x, y: y - height, width: width, height: height)
                ctx.fill(Path(roundedRect: body, cornerRadius: 2 * u), with: .color(tone))
                if nvNoise(seed * 5) > 0.55 {
                    let dome = CGRect(x: x + width * 0.2, y: y - height - width * 0.2, width: width * 0.6, height: width * 0.4)
                    ctx.fill(Path(ellipseIn: dome), with: .color(tone))
                }
                // окна
                let flicker = 0.75 + 0.25 * sin(ambient * 3 + Double(seed))
                let windows = nvNoise(seed * 7) > 0.35 ? 2 : 1
                for k in 0..<windows {
                    let wx = x + width * (0.2 + 0.4 * CGFloat(k))
                    let wy = y - height * (0.35 + 0.25 * nvNoise(seed * 9 + k))
                    let window = CGRect(x: wx, y: wy, width: 5 * u, height: 7 * u)
                    ctx.fill(Path(roundedRect: window, cornerRadius: 2 * u), with: .color(NP.rgb(255, 204, 110, 0.95 * lit * flicker)))
                }
            }
        }
    }

    static func fire(_ ctx: inout GraphicsContext, at base: CGPoint, size k: CGFloat, ambient: Double) {
        glow(&ctx, at: CGPoint(x: base.x, y: base.y - 0.4 * k), radius: 3.6 * k, color: NP.rgb(255, 168, 80), alpha: 0.55 + 0.1 * sin(ambient * 9))
        // поленья
        ctx.drawLayer { g in
            g.translateBy(x: base.x, y: base.y)
            for side in [-1.0, 1.0] {
                g.drawLayer { l in
                    l.rotate(by: .radians(side * 0.28))
                    l.fill(Path(roundedRect: CGRect(x: -0.55 * k, y: -0.10 * k, width: 1.1 * k, height: 0.18 * k), cornerRadius: 0.08 * k), with: .color(NP.wood))
                }
            }
            // языки пламени
            let flames: [(CGFloat, CGFloat, Double)] = [(-0.18, 0.62, 0), (0.0, 0.92, 1.7), (0.18, 0.66, 3.1)]
            for flame in flames {
                let sway = CGFloat(sin(ambient * 7 + flame.2)) * 0.06 * k
                let top = CGPoint(x: flame.0 * k + sway, y: -flame.1 * k * CGFloat(0.9 + 0.1 * sin(ambient * 11 + flame.2)))
                var path = Path()
                path.move(to: CGPoint(x: flame.0 * k - 0.16 * k, y: 0))
                path.addQuadCurve(to: top, control: CGPoint(x: flame.0 * k - 0.20 * k, y: -0.4 * k))
                path.addQuadCurve(to: CGPoint(x: flame.0 * k + 0.16 * k, y: 0), control: CGPoint(x: flame.0 * k + 0.20 * k, y: -0.4 * k))
                path.closeSubpath()
                g.fill(path, with: .linearGradient(Gradient(colors: [NP.rgb(255, 232, 130), NP.rgb(255, 120, 40)]), startPoint: top, endPoint: CGPoint(x: 0, y: 0)))
            }
        }
        // искры
        for i in 0..<7 {
            let speed = 22 + Double(nvNoise(i * 5)) * 20
            let cycle = 90.0 / speed
            let kk = (ambient + Double(nvNoise(i * 5 + 1)) * cycle).truncatingRemainder(dividingBy: cycle) / cycle
            let x = base.x + (nvNoise(i * 5 + 2) - 0.5) * 0.7 * k + CGFloat(sin(ambient * 2 + Double(i))) * 0.1 * k
            let y = base.y - 0.5 * k - CGFloat(kk) * 1.8 * k
            let r = max(1, 0.035 * k)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(NP.rgb(255, 214, 120, 0.9 * (1 - kk))))
        }
    }
}
