import SwiftUI

// MARK: - Основы листа: пергамент бесплатно, пурпур и камень в Premium
/// Основа — материал, на котором написана страница: от неё зависят цвета, чернила и инструмент в руке.
enum ManuscriptSurface: String, CaseIterable, Identifiable, Codable {
    /// Тёплый пергамент: чернила тёмные, перо пишет по коже
    case parchment
    /// Пурпурный кодекс: золотые и серебряные буквы на багряной коже, как в царских рукописях
    case purple
    /// Хачкар: текст высечен в туфе, вместо пера в руке резец
    case khachkar

    var id: String { rawValue }

    static let storageKey = "luys_manuscript_surface"
    static let defaultValue = ManuscriptSurface.parchment

    var isFree: Bool { self == .parchment }

    /// Основа, выбранная в прошлый раз; без Premium платная заменяется пергаментом.
    /// Читается и вне главного потока, поэтому подходит для значения по умолчанию у новых страниц.
    static var effective: ManuscriptSurface {
        let chosen = ManuscriptSurface(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? defaultValue
        return chosen.isFree || SubscriptionManager.premiumSnapshot ? chosen : defaultValue
    }

    /// Буквы высечены: у каждой светлая кромка, как на камне при боковом свете
    var isCarved: Bool { self == .khachkar }

    /// Звёздочки блика на золоте; на камне свет играет только по рельефу
    var glintScale: CGFloat { self == .khachkar ? 0 : 1 }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .parchment: return language.pick(hy: "Մագաղաթ", ru: "Пергамент", en: "Parchment")
        case .purple: return language.pick(hy: "Ծիրանի ոսկով", ru: "Пурпур с золотом", en: "Purple and gold")
        case .khachkar: return language.pick(hy: "Խաչքար", ru: "Хачкар", en: "Khachkar")
        }
    }

    func summary(for language: AppLanguage) -> String {
        switch self {
        case .parchment:
            return language.pick(
                hy: "Տաք մագաղաթ՝ ոսկով և կինովարով",
                ru: "Тёплый пергамент с золотом и киноварью",
                en: "Warm vellum with gold and cinnabar"
            )
        case .purple:
            return language.pick(
                hy: "Ծիրանագույն մատյան. ոսկե և արծաթե տառեր, ինչպես արքայական ձեռագրերում",
                ru: "Пурпурный кодекс: золотые и серебряные буквы на багряной коже, как в царских рукописях",
                en: "A purple codex: gold and silver letters on crimson vellum, as in royal manuscripts"
            )
        case .khachkar:
            return language.pick(
                hy: "Փորագրված քար. տեքստը փորագրվում է, ինչպես խաչքարերի վրա",
                ru: "Резной камень: текст высекается резцом, как на армянских крест-камнях",
                en: "Carved tuff: the text is cut with a chisel, as on Armenian cross-stones"
            )
        }
    }

    /// Пигменты основы; поле заставки зависит от стиля миниатюры
    func palette(for style: ManuscriptStyle) -> ManuscriptPalette {
        switch self {
        case .parchment:
            return style.palette
        case .purple:
            let field: UInt32
            let accent: UInt32
            switch style {
            case .roslin: field = 0x23378A; accent = 0xE0685A
            case .cilicia: field = 0x8E1F2E; accent = 0x2F5AA8
            case .narek: field = 0x1F5A45; accent = 0xE0685A
            }
            return ManuscriptPalette(
                parchment: 0x4A2368, parchmentEdge: 0x1C0B2B, ink: 0xF0DC9C, rubric: 0xDCDFEE,
                field: field, fieldAccent: accent, leaf: 0x6FA680,
                goldDark: 0x7A5616, gold: 0xD0A23C, goldLight: 0xF3D987, goldHighlight: 0xFFF0B8, pearl: 0xF6EEFB
            )
        case .khachkar:
            let field: UInt32
            switch style {
            case .roslin: field = 0x3D4658
            case .cilicia: field = 0x5A3430
            case .narek: field = 0x3F4A3C
            }
            return ManuscriptPalette(
                parchment: 0xBFB099, parchmentEdge: 0x7A6A55, ink: 0x1F160E, rubric: 0x5C1D12,
                field: field, fieldAccent: 0xCDBFA6, leaf: 0x8E7E68,
                goldDark: 0x4E4335, gold: 0x948872, goldLight: 0xCDC1AA, goldHighlight: 0xF1E8D5, pearl: 0xDED2BC
            )
        }
    }
}

// MARK: - Вид страницы: стиль миниатюры и основа вместе
/// Всё, от чего зависят цвета страницы. Рисование берёт палитру отсюда, а не у стиля.
struct ManuscriptLook: Hashable {
    let style: ManuscriptStyle
    let surface: ManuscriptSurface

    var palette: ManuscriptPalette { surface.palette(for: style) }
    var hasBirds: Bool { style.hasBirds }
}

// MARK: - Чернила пера на разных основах
extension ManuscriptPen {
    /// Цвет, которым это перо пишет на данной основе. На пергаменте это родные чернила пера,
    /// на пурпуре — золото и серебро, на камне — краска, которой залиты борозды резьбы.
    func ink(on look: ManuscriptLook) -> UInt32 {
        switch look.surface {
        case .parchment:
            return inkOverride ?? look.palette.ink
        case .purple:
            switch self {
            case .goose: return look.palette.ink
            case .reed: return 0xD8C08A
            case .peacock: return 0xA8CBEF
            case .gilded: return 0xFFD76A
            case .cinnabar: return 0xF5A092
            }
        case .khachkar:
            switch self {
            case .goose: return look.palette.ink
            case .reed: return 0x39291C
            case .peacock: return 0x162B4E
            case .gilded: return 0x3A290A
            case .cinnabar: return 0x521812
            }
        }
    }
}

// MARK: - Рисунок основы
enum ManuscriptSurfaceArt {
    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        ManuscriptPalette.color(hex, alpha)
    }

    private static func circle(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    static func draw(surface: ManuscriptSurface, seed: UInt32, palette P: ManuscriptPalette, size: CGSize, in ctx: GraphicsContext) {
        switch surface {
        case .parchment: ManuscriptRenderer.drawParchment(seed: seed, palette: P, size: size, in: ctx)
        case .purple: drawPurple(seed: seed, palette: P, size: size, in: ctx)
        case .khachkar: drawStone(seed: seed, palette: P, size: size, in: ctx)
        }
    }

    // MARK: Пурпурная кожа
    private static func drawPurple(seed: UInt32, palette P: ManuscriptPalette, size: CGSize, in ctx: GraphicsContext) {
        let rect = CGRect(origin: .zero, size: size)
        ctx.fill(Path(rect), with: .color(c(P.parchment)))
        var rng = PomegranateRandom(seed: seed)

        // Краситель лёг неровно: светлые и тёмные облака
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 16))
            for index in 0 ..< 9 {
                let r = 28 + rng.next() * 44
                let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
                let cloud = index % 2 == 0 ? c(0x6B3D8E, 0.34) : c(P.parchmentEdge, 0.30)
                layer.fill(Path(ellipseIn: circle(center, r)), with: .color(cloud))
            }
        }

        // Края темнее, как у старого листа
        ctx.fill(Path(rect), with: .radialGradient(
            Gradient(colors: [c(P.parchmentEdge, 0), c(P.parchmentEdge, 0.35), c(P.parchmentEdge, 0.9)]),
            center: CGPoint(x: size.width / 2, y: size.height * 0.46),
            startRadius: size.width * 0.30,
            endRadius: size.height * 0.64
        ))

        // Зерно кожи
        for _ in 0 ..< 420 {
            let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let r = 0.25 + rng.next() * 0.6
            let isLight = rng.next() > 0.45
            let grain = isLight
                ? c(0xB88AD6, 0.10 + Double(rng.next()) * 0.12)
                : c(0x12041E, 0.14 + Double(rng.next()) * 0.14)
            ctx.fill(Path(ellipseIn: circle(center, r)), with: .color(grain))
        }

        // Золотая пыль от переписчиков
        for _ in 0 ..< 46 {
            let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let r = 0.3 + rng.next() * 0.6
            ctx.fill(Path(ellipseIn: circle(center, r)), with: .color(c(P.goldLight, 0.18 + Double(rng.next()) * 0.3)))
        }

        // Волокна
        for _ in 0 ..< 30 {
            let start = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let length = 8 + rng.next() * 30
            let angle = (rng.next() - 0.5) * 0.9
            let end = CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
            var fiber = Path()
            fiber.move(to: start)
            fiber.addQuadCurve(
                to: end,
                control: CGPoint(x: (start.x + end.x) / 2 + (rng.next() - 0.5) * 6, y: (start.y + end.y) / 2 + (rng.next() - 0.5) * 6)
            )
            ctx.stroke(fiber, with: .color(c(0xD6B8EE, 0.06)), lineWidth: 0.35)
        }
        ctx.stroke(Path(rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(c(P.parchmentEdge, 0.9)), lineWidth: 1)
    }

    // MARK: Туф хачкара
    private static func drawStone(seed: UInt32, palette P: ManuscriptPalette, size: CGSize, in ctx: GraphicsContext) {
        let rect = CGRect(origin: .zero, size: size)
        ctx.fill(Path(rect), with: .color(c(P.parchment)))
        var rng = PomegranateRandom(seed: seed)

        // Тон камня неровный: светлые и тёмные пятна
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 14))
            for index in 0 ..< 12 {
                let r = 22 + rng.next() * 46
                let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
                let patch = index % 3 == 0 ? c(P.goldLight, 0.22) : c(P.parchmentEdge, 0.22)
                layer.fill(Path(ellipseIn: circle(center, r)), with: .color(patch))
            }
        }

        // Лишайник
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 3.2))
            for _ in 0 ..< 7 {
                let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
                let r = 3 + rng.next() * 7
                layer.fill(Path(ellipseIn: circle(center, r)), with: .color(c(0x7F8460, 0.20)))
            }
        }

        // Края темнее
        ctx.fill(Path(rect), with: .radialGradient(
            Gradient(colors: [c(P.parchmentEdge, 0), c(P.parchmentEdge, 0.25), c(P.parchmentEdge, 0.8)]),
            center: CGPoint(x: size.width / 2, y: size.height * 0.46),
            startRadius: size.width * 0.34,
            endRadius: size.height * 0.64
        ))

        // Зерно туфа
        for _ in 0 ..< 900 {
            let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let r = 0.2 + rng.next() * 0.55
            let isDark = rng.next() > 0.5
            let grain = isDark
                ? c(P.parchmentEdge, 0.12 + Double(rng.next()) * 0.16)
                : c(P.goldHighlight, 0.12 + Double(rng.next()) * 0.18)
            ctx.fill(Path(ellipseIn: circle(center, r)), with: .color(grain))
        }

        // Поры: тёмная ямка и светлый блик на нижнем краю
        for _ in 0 ..< 64 {
            let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let r = 0.6 + rng.next() * 1.5
            ctx.fill(Path(ellipseIn: circle(CGPoint(x: center.x + 0.5, y: center.y + 0.7), r)), with: .color(c(P.goldHighlight, 0.28)))
            ctx.fill(Path(ellipseIn: circle(center, r)), with: .color(c(P.parchmentEdge, 0.42)))
        }

        // Трещинки: ломаные волоски с бликом рядом
        for _ in 0 ..< 5 {
            var crack = Path()
            var point = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            crack.move(to: point)
            var direction = rng.next() * 2 * CGFloat.pi
            for _ in 0 ..< 9 {
                direction += (rng.next() - 0.5) * 0.9
                let step = 5 + rng.next() * 9
                point = CGPoint(x: point.x + cos(direction) * step, y: point.y + sin(direction) * step)
                crack.addLine(to: point)
            }
            ctx.stroke(crack, with: .color(c(P.parchmentEdge, 0.32)), lineWidth: 0.5)
            var lit = ctx
            lit.translateBy(x: 0.5, y: 0.6)
            lit.stroke(crack, with: .color(c(P.goldHighlight, 0.22)), lineWidth: 0.4)
        }

        // Следы резца: короткие косые штрихи
        for _ in 0 ..< 70 {
            let start = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let length = 6 + rng.next() * 8
            let angle = -0.7 + (rng.next() - 0.5) * 0.3
            var mark = Path()
            mark.move(to: start)
            mark.addLine(to: CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length))
            ctx.stroke(mark, with: .color(c(P.parchmentEdge, 0.07)), lineWidth: 0.6)
        }

        // Скошенная кромка плиты: свет сверху слева, тень снизу справа
        var lightEdge = Path()
        lightEdge.move(to: CGPoint(x: 0.5, y: size.height))
        lightEdge.addLine(to: CGPoint(x: 0.5, y: 0.5))
        lightEdge.addLine(to: CGPoint(x: size.width, y: 0.5))
        var darkEdge = Path()
        darkEdge.move(to: CGPoint(x: size.width - 0.5, y: 0))
        darkEdge.addLine(to: CGPoint(x: size.width - 0.5, y: size.height - 0.5))
        darkEdge.addLine(to: CGPoint(x: 0, y: size.height - 0.5))
        ctx.stroke(lightEdge, with: .color(c(P.goldHighlight, 0.6)), lineWidth: 1.2)
        ctx.stroke(darkEdge, with: .color(c(P.parchmentEdge, 0.9)), lineWidth: 1.2)
    }
}

// MARK: - Резец в руке мастера (вместо пера на камне)
/// Резец рисуется так же, как перо: кончик в (0, 0), ось уходит вверх, затем всё поворачивается.
enum ManuscriptChiselArt {
    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        ManuscriptPalette.color(hex, alpha)
    }

    /// `time` оживляет молоток и каменную пыль; `lift` — отрыв инструмента от камня в конце письма (0…1)
    static func draw(tip: CGPoint, sway: Double, lift: CGFloat, time: Double, in ctx: GraphicsContext) {
        var tool = ctx
        tool.opacity = Double(1 - lift)
        tool.translateBy(x: tip.x + 14 * lift, y: tip.y - 34 * lift)
        tool.rotate(by: .degrees(24 + sway))

        var body = Path()
        body.move(to: CGPoint(x: 0, y: 0))
        body.addLine(to: CGPoint(x: -2.4, y: -14))
        body.addLine(to: CGPoint(x: -3.4, y: -58))
        body.addLine(to: CGPoint(x: 3.4, y: -58))
        body.addLine(to: CGPoint(x: 2.4, y: -14))
        body.closeSubpath()

        var bevel = Path()
        bevel.move(to: CGPoint(x: 0, y: 0))
        bevel.addLine(to: CGPoint(x: -2.4, y: -14))
        bevel.addLine(to: CGPoint(x: 2.4, y: -14))
        bevel.closeSubpath()

        var shine = Path()
        shine.move(to: CGPoint(x: -1.4, y: -16))
        shine.addLine(to: CGPoint(x: -2.0, y: -56))

        let head = Path(ellipseIn: CGRect(x: -4.4, y: -61.5, width: 8.8, height: 5))

        var shadow = tool
        shadow.translateBy(x: 2.5, y: 3.5)
        shadow.fill(body, with: .color(Color.black.opacity(0.16)))

        tool.fill(body, with: .color(c(0xA7ACB3)))
        tool.fill(bevel, with: .color(c(0x5B6066)))
        tool.stroke(body, with: .color(c(0x4A4F55, 0.8)), lineWidth: 0.6)
        tool.stroke(shine, with: .color(Color.white.opacity(0.55)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        tool.fill(head, with: .color(c(0x6F747B)))
        tool.stroke(head, with: .color(c(0x3F4348, 0.8)), lineWidth: 0.5)

        // Деревянный молоток покачивается над шляпкой резца
        var mallet = tool
        mallet.translateBy(x: 6, y: -62)
        mallet.rotate(by: .radians(-0.35 + sin(time * 10) * 0.28))
        var handle = Path()
        handle.move(to: CGPoint(x: 0, y: -10))
        handle.addLine(to: CGPoint(x: 1, y: -40))
        let mallHead = Path(roundedRect: CGRect(x: -9, y: -11, width: 18, height: 11), cornerRadius: 2.4)
        mallet.stroke(handle, with: .color(c(0x8A5B2C)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        mallet.fill(mallHead, with: .color(c(0xA06B36)))
        mallet.stroke(mallHead, with: .color(c(0x5B3A1B, 0.8)), lineWidth: 0.7)

        // Каменная пыль разлетается из-под кончика
        for k in 0 ..< 4 {
            let phase = (time * 2.2 + Double(k) * 0.29).truncatingRemainder(dividingBy: 1)
            let angle = -Double.pi * (0.2 + 0.6 * Double(k) / 3)
            let distance = CGFloat(3 + 12 * phase)
            let spot = CGPoint(x: tip.x + CGFloat(cos(angle)) * distance, y: tip.y + CGFloat(sin(angle)) * distance)
            let radius = CGFloat(1.1 * (1 - phase))
            guard radius > 0.1 else { continue }
            let rect = CGRect(x: spot.x - radius, y: spot.y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(c(0xE9E0CC, 0.7 * (1 - phase) * Double(1 - lift))))
        }
    }
}

// MARK: - Превью основы: маленький готовый лист
struct ManuscriptSurfacePreview: View {
    let surface: ManuscriptSurface
    let language: AppLanguage

    private var page: ManuscriptPage {
        ManuscriptPage(
            text: language.pick(hy: "Աստված սեր է", ru: "Бог есть любовь", en: "God is love"),
            reference: language.pick(hy: "Ա Հովհ. 4:8", ru: "1 Ин. 4:8", en: "1 John 4:8"),
            language: language,
            style: .roslin,
            surface: surface,
            name: ""
        )
    }

    var body: some View {
        ManuscriptPageView(page: page, sheen: CGPoint(x: 0.2, y: -0.15))
            .scaleEffect(0.15, anchor: .topLeading)
            .frame(width: 54, height: 96, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Выбор основы
struct ManuscriptSurfaceSheet: View {
    let language: AppLanguage
    @Binding var selection: ManuscriptSurface

    @ObservedObject private var subscription = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPaywall = false

    var body: some View {
        ZStack {
            Paper.page.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(language.pick(hy: "Էջի հիմք", ru: "Основа листа", en: "Page surface"))
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
                        ForEach(ManuscriptSurface.allCases) { surface in
                            row(surface)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(source: "manuscript_surface")
        }
    }

    private func row(_ surface: ManuscriptSurface) -> some View {
        let locked = !surface.isFree && !subscription.isPremium
        let isSelected = surface == selection && !locked
        return Button {
            if locked {
                isShowingPaywall = true
            } else {
                Haptics.selection()
                selection = surface
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                ManuscriptSurfacePreview(surface: surface, language: language)
                    .frame(width: 54, height: 96)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(surface.title(for: language))
                            .font(PaperFont.font(size: 15, weight: .semibold))
                            .foregroundColor(Paper.ink)
                        if !surface.isFree {
                            Text("Premium")
                                .font(PaperFont.font(size: 10, weight: .semibold))
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().strokeBorder(Paper.gold.opacity(0.7), lineWidth: 1))
                        }
                    }
                    Text(surface.summary(for: language))
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
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
