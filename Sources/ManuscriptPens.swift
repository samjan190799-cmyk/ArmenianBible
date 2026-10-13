import SwiftUI

// MARK: - Перья «Рукописи»: два бесплатных, три в Premium
/// Перо задаёт и вид пера в руке писца, и цвет чернил, которыми пишется стих.
enum ManuscriptPen: Int, CaseIterable, Identifiable {
    case goose = 0
    case reed = 1
    case peacock = 2
    case gilded = 3
    case cinnabar = 4

    var id: Int { rawValue }

    static let storageKey = "luys_manuscript_pen"
    static let defaultValue = ManuscriptPen.goose

    var isFree: Bool { self == .goose || self == .reed }

    /// Чернила пера; nil — родные чернила выбранного стиля страницы
    var inkOverride: UInt32? {
        switch self {
        case .goose: return nil
        case .reed: return 0x5A3A22
        case .peacock: return 0x1C3A78
        case .gilded: return 0x7A5616
        case .cinnabar: return 0x9E2420
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .goose: return language.pick(hy: "Սագի փետուր", ru: "Гусиное перо", en: "Goose quill")
        case .reed: return language.pick(hy: "Եղեգնյա գրիչ", ru: "Тростниковый калам", en: "Reed pen")
        case .peacock: return language.pick(hy: "Սիրամարգի փետուր", ru: "Павлинье перо", en: "Peacock feather")
        case .gilded: return language.pick(hy: "Ոսկե փետուր", ru: "Золотое перо", en: "Gilded quill")
        case .cinnabar: return language.pick(hy: "Կարմիր փետուր", ru: "Киноварное перо", en: "Cinnabar quill")
        }
    }

    func summary(for language: AppLanguage) -> String {
        switch self {
        case .goose:
            return language.pick(hy: "Գրիչների դասական գործիքը: Մութ թանաք", ru: "Классика переписчиков. Тёмные чернила", en: "The scribes' classic. Dark ink")
        case .reed:
            return language.pick(hy: "Եղեգնյա գրիչ՝ տաք սեպիա թանաքով", ru: "Калам с тёплыми сепиевыми чернилами", en: "A reed pen with warm sepia ink")
        case .peacock:
            return language.pick(hy: "Սիրամարգի փետուր և կապույտ թանաք՝ ինչպես խորանների վրա", ru: "Павлинье перо и синие чернила, как на заставках", en: "Peacock feather and blue ink, as on the headpieces")
        case .gilded:
            return language.pick(hy: "Ոսկե փետուր և հին ոսկու գույնի թանաք", ru: "Золотое перо и чернила цвета старого золота", en: "A gilded quill and ink the colour of old gold")
        case .cinnabar:
            return language.pick(hy: "Կարմիր թանաք՝ տոնական էջերի համար", ru: "Красные чернила киновари для праздничных листов", en: "Cinnabar-red ink for feast pages")
        }
    }
}

// MARK: - Рисунок пера
/// Перо рисуется в локальных координатах: кончик в (0, 0), ось пера идёт вверх (−Y), затем весь
/// рисунок поворачивается так, чтобы перо наклонялось вправо, как в руке писца.
enum ManuscriptQuillArt {
    private struct Feather {
        let vane: UInt32
        let shade: UInt32
        let barb: UInt32
        let outline: UInt32
        let shaft: UInt32
        let barrel: UInt32
        let nib: UInt32
        let hasEye: Bool
    }

    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        ManuscriptPalette.color(hex, alpha)
    }

    private static func feather(for pen: ManuscriptPen, palette P: ManuscriptPalette) -> Feather? {
        switch pen {
        case .goose:
            return Feather(vane: P.pearl, shade: P.parchmentEdge, barb: P.parchmentEdge, outline: P.goldDark,
                           shaft: P.goldDark, barrel: P.pearl, nib: P.ink, hasEye: false)
        case .reed:
            return nil
        case .peacock:
            return Feather(vane: 0x3E8E77, shade: 0x1F5F6B, barb: 0x1F5F6B, outline: 0x1B4F55,
                           shaft: 0x7A5616, barrel: 0xE9DFC4, nib: 0x2A1C12, hasEye: true)
        case .gilded:
            return Feather(vane: P.pearl, shade: P.goldLight, barb: 0xD9B867, outline: P.goldDark,
                           shaft: P.gold, barrel: P.goldLight, nib: P.goldDark, hasEye: false)
        case .cinnabar:
            return Feather(vane: 0xB5382C, shade: 0x7A1A22, barb: 0xE08A78, outline: 0x6E1A16,
                           shaft: 0x4A1410, barrel: 0xE9D2C8, nib: 0x2A1C12, hasEye: false)
        }
    }

    /// `time` оживляет искры золотого пера; `lift` — отрыв пера от листа в конце письма (0…1)
    static func draw(pen: ManuscriptPen, tip: CGPoint, sway: Double, lift: CGFloat, time: Double,
                     palette P: ManuscriptPalette, in ctx: GraphicsContext) {
        var quill = ctx
        quill.opacity = Double(1 - lift)
        quill.translateBy(x: tip.x + 14 * lift, y: tip.y - 34 * lift)
        quill.rotate(by: .degrees(30 + sway))

        if let look = feather(for: pen, palette: P) {
            drawFeather(look, in: quill)
        } else {
            drawReed(in: quill)
        }

        if pen == .gilded {
            drawSparkles(around: CGPoint(x: tip.x + 14 * lift, y: tip.y - 34 * lift), time: time, opacity: Double(1 - lift), in: ctx)
        }
    }

    private static func edgePoint(_ from: CGPoint, _ control: CGPoint, _ to: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = u * u * from.x + 2 * u * t * control.x + t * t * to.x
        let y = u * u * from.y + 2 * u * t * control.y + t * t * to.y
        return CGPoint(x: x, y: y)
    }

    private static func drawFeather(_ look: Feather, in quill: GraphicsContext) {
        let length: CGFloat = 66
        let leftStart = CGPoint(x: 0, y: -17)
        let leftControl = CGPoint(x: -18, y: -36)
        let end = CGPoint(x: 1.5, y: -length)
        let rightControl = CGPoint(x: 15, y: -40)

        // Опахало: две дуги от основания к острию, справа шире
        var vane = Path()
        vane.move(to: leftStart)
        vane.addQuadCurve(to: end, control: leftControl)
        vane.addQuadCurve(to: leftStart, control: rightControl)
        vane.closeSubpath()

        // Бородки идут от стержня к краям, скошены к острию
        var barbs = Path()
        for i in 1 ... 8 {
            let t = CGFloat(i) / 9
            let left = edgePoint(leftStart, leftControl, end, t)
            let right = edgePoint(end, rightControl, leftStart, 1 - t)
            barbs.move(to: CGPoint(x: 0.5 * t, y: left.y + 5))
            barbs.addLine(to: left)
            barbs.move(to: CGPoint(x: 0.5 * t, y: right.y + 5))
            barbs.addLine(to: right)
        }

        var shaft = Path()
        shaft.move(to: CGPoint(x: 0, y: -8))
        shaft.addLine(to: end)

        var barrel = Path()
        barrel.move(to: CGPoint(x: 0, y: -5))
        barrel.addLine(to: CGPoint(x: 0, y: -21))

        // Срез кончика: тёмный клин, в него «стекают» чернила
        var nib = Path()
        nib.move(to: CGPoint(x: 0.2, y: 0))
        nib.addLine(to: CGPoint(x: -1.6, y: -6))
        nib.addLine(to: CGPoint(x: 1.8, y: -6.5))
        nib.closeSubpath()

        // Мягкая тень на пергаменте: то же перо, смещённое вниз и вправо
        var shadow = quill
        shadow.translateBy(x: 2.5, y: 3.5)
        shadow.fill(vane, with: .color(Color.black.opacity(0.14)))
        shadow.stroke(barrel, with: .color(Color.black.opacity(0.14)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        quill.fill(vane, with: .color(c(look.vane, 0.97)))
        quill.fill(vane, with: .color(c(look.shade, 0.28)))
        quill.stroke(barbs, with: .color(c(look.barb, 0.95)), lineWidth: 0.5)
        quill.stroke(vane, with: .color(c(look.outline, 0.55)), lineWidth: 0.6)

        if look.hasEye {
            // «Глаз» павлиньего пера: золотое кольцо, синее поле, тёмная сердцевина
            let eye = CGPoint(x: 1.8, y: -44)
            quill.fill(Path(ellipseIn: CGRect(x: eye.x - 6.5, y: eye.y - 8.5, width: 13, height: 17)), with: .color(c(0xC1902F, 0.95)))
            quill.fill(Path(ellipseIn: CGRect(x: eye.x - 5, y: eye.y - 7, width: 10, height: 14)), with: .color(c(0x2D7FA8)))
            quill.fill(Path(ellipseIn: CGRect(x: eye.x - 2.6, y: eye.y - 3.8, width: 5.2, height: 7.6)), with: .color(c(0x0F2A55)))
        }

        quill.stroke(barrel, with: .color(c(look.outline, 0.65)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        quill.stroke(barrel, with: .color(c(look.barrel)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        quill.stroke(shaft, with: .color(c(look.shaft, 0.9)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        quill.fill(nib, with: .color(c(look.nib)))
    }

    /// Тростниковый калам: гладкий стебель с узлами и косым срезом на конце
    private static func drawReed(in quill: GraphicsContext) {
        var body = Path()
        body.move(to: CGPoint(x: -2.2, y: -6))
        body.addLine(to: CGPoint(x: 0.4, y: 0))
        body.addLine(to: CGPoint(x: 2.8, y: -5))
        body.addLine(to: CGPoint(x: 3.4, y: -72))
        body.addQuadCurve(to: CGPoint(x: -3.4, y: -72), control: CGPoint(x: 0, y: -77))
        body.closeSubpath()

        var lightSide = Path()
        lightSide.move(to: CGPoint(x: 0.6, y: -5))
        lightSide.addLine(to: CGPoint(x: 2.8, y: -5))
        lightSide.addLine(to: CGPoint(x: 3.4, y: -72))
        lightSide.addLine(to: CGPoint(x: 0.8, y: -73))
        lightSide.closeSubpath()

        var nodes = Path()
        for y in [-24.0, -49.0] {
            nodes.move(to: CGPoint(x: -3.2, y: y))
            nodes.addLine(to: CGPoint(x: 3.2, y: y))
        }

        var nib = Path()
        nib.move(to: CGPoint(x: 0.4, y: 0))
        nib.addLine(to: CGPoint(x: -1.9, y: -5.2))
        nib.addLine(to: CGPoint(x: 2.6, y: -4.6))
        nib.closeSubpath()

        var slit = Path()
        slit.move(to: CGPoint(x: 0.3, y: -0.5))
        slit.addLine(to: CGPoint(x: 0.3, y: -9))

        var shadow = quill
        shadow.translateBy(x: 2.5, y: 3.5)
        shadow.fill(body, with: .color(Color.black.opacity(0.14)))

        quill.fill(body, with: .color(c(0xC9A96A)))
        quill.fill(lightSide, with: .color(c(0x6B4E22, 0.28)))
        quill.stroke(nodes, with: .color(c(0x6B4E22, 0.75)), lineWidth: 1.2)
        quill.stroke(body, with: .color(c(0x6B4E22, 0.7)), lineWidth: 0.6)
        quill.fill(nib, with: .color(c(0x2A1C12)))
        quill.stroke(slit, with: .color(c(0x2A1C12, 0.8)), lineWidth: 0.5)
    }

    /// Золотое перо оставляет в воздухе искры
    private static func drawSparkles(around center: CGPoint, time: Double, opacity: Double, in ctx: GraphicsContext) {
        for k in 0 ..< 3 {
            let phase = (time * 1.6 + Double(k) * 0.37).truncatingRemainder(dividingBy: 1)
            let angle = Double(k) * 2.1 + time * 0.7
            let distance = CGFloat(6 + 10 * phase)
            let spot = CGPoint(x: center.x + CGFloat(cos(angle)) * distance,
                               y: center.y + CGFloat(sin(angle)) * distance - 4)
            let size = CGFloat(2.6 * (1 - phase))
            guard size > 0.2 else { continue }
            var star = Path()
            star.move(to: CGPoint(x: spot.x, y: spot.y - size))
            star.addLine(to: CGPoint(x: spot.x + size * 0.28, y: spot.y - size * 0.28))
            star.addLine(to: CGPoint(x: spot.x + size, y: spot.y))
            star.addLine(to: CGPoint(x: spot.x + size * 0.28, y: spot.y + size * 0.28))
            star.addLine(to: CGPoint(x: spot.x, y: spot.y + size))
            star.addLine(to: CGPoint(x: spot.x - size * 0.28, y: spot.y + size * 0.28))
            star.addLine(to: CGPoint(x: spot.x - size, y: spot.y))
            star.addLine(to: CGPoint(x: spot.x - size * 0.28, y: spot.y - size * 0.28))
            star.closeSubpath()
            ctx.fill(star, with: .color(c(0xFAE6A6, 0.9 * (1 - phase) * opacity)))
        }
    }
}

// MARK: - Превью пера: перо и образец штриха его чернилами
struct ManuscriptPenPreview: View {
    let pen: ManuscriptPen

    var body: some View {
        Canvas { context, size in
            let P = ManuscriptPalette.roslin
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                with: .color(ManuscriptPalette.color(P.parchment))
            )
            let ink = ManuscriptPalette.color(pen.inkOverride ?? P.ink)
            var sample = Path()
            sample.move(to: CGPoint(x: 8, y: size.height - 14))
            sample.addCurve(
                to: CGPoint(x: 32, y: size.height - 12),
                control1: CGPoint(x: 14, y: size.height - 30),
                control2: CGPoint(x: 22, y: size.height - 2)
            )
            context.stroke(sample, with: .color(ink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

            var scaled = context
            scaled.translateBy(x: 32, y: size.height - 12)
            scaled.scaleBy(x: 0.72, y: 0.72)
            ManuscriptQuillArt.draw(pen: pen, tip: .zero, sway: 0, lift: 0, time: 0.4, palette: P, in: scaled)
        }
    }
}

// MARK: - Выбор пера
struct ManuscriptPenSheet: View {
    let language: AppLanguage
    @Binding var selectedRaw: Int

    @ObservedObject private var subscription = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPaywall = false

    var body: some View {
        ZStack {
            Paper.page.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(language.pick(hy: "Գրիչ", ru: "Перо", en: "Pen"))
                        .font(PaperFont.font(size: 20, weight: .semibold))
                        .foregroundColor(Paper.ink)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Paper.inkTertiary)
                    }
                    .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(ManuscriptPen.allCases) { pen in
                            row(pen)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }

    private func row(_ pen: ManuscriptPen) -> some View {
        let locked = !pen.isFree && !subscription.isPremium
        let isSelected = pen.rawValue == selectedRaw && !locked
        return Button {
            if locked {
                isShowingPaywall = true
            } else {
                Haptics.selection()
                selectedRaw = pen.rawValue
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                ManuscriptPenPreview(pen: pen)
                    .frame(width: 84, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pen.title(for: language))
                            .font(PaperFont.font(size: 15, weight: .semibold))
                            .foregroundColor(Paper.ink)
                        if !pen.isFree {
                            Text("Premium")
                                .font(PaperFont.font(size: 10, weight: .semibold))
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().strokeBorder(Paper.gold.opacity(0.7), lineWidth: 1))
                        }
                    }
                    Text(pen.summary(for: language))
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Paper.inkTertiary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Paper.gold)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperSheet(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Paper.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.98))
    }
}
