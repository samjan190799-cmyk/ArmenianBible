import SwiftUI
import CoreText

// MARK: - Ход анимации: какая часть страницы уже «написана»
/// Каждое поле — от 0 (ещё нет) до 1 (готово). Порядок как у переписчика: пергамент, рамка,
/// заставка, буквица, текст пером, украшение на полях и в конце памятная запись.
struct ManuscriptReveal {
    var parchment: CGFloat = 1
    var frame: CGFloat = 1
    var headpiece: CGFloat = 1
    var initial: CGFloat = 1
    var text: CGFloat = 1
    var margin: CGFloat = 1
    var colophon: CGFloat = 1

    static let complete = ManuscriptReveal()

    /// Чистый лист с заставкой: так выглядит соседняя страница, пока её листают
    static let leaf = ManuscriptReveal(parchment: 1, frame: 1, headpiece: 1, initial: 0, text: 0, margin: 0, colophon: 0)

    /// Сколько перо пишет весь стих: скорость выбирается в настройках
    static func textDuration(for length: Int, speed: ManuscriptWritingSpeed = .current) -> Double {
        let range = speed.durationRange
        return min(range.upperBound, max(range.lowerBound, Double(length) * speed.secondsPerCharacter))
    }

    /// Полная запись начинается с пустого пергамента; на перевёрнутом листе рамка и заставка уже есть
    static func totalDuration(textLength: Int, turned: Bool = false, speed: ManuscriptWritingSpeed = .current) -> Double {
        let writing = textDuration(for: textLength, speed: speed)
        return turned ? 0.5 + writing + 1.4 : 2.2 + writing + 1.4
    }

    static func at(time t: Double, textLength: Int, turned: Bool = false,
                   speed: ManuscriptWritingSpeed = .current) -> ManuscriptReveal {
        let writing = textDuration(for: textLength, speed: speed)
        func phase(_ start: Double, _ duration: Double) -> CGFloat {
            CGFloat(min(1, max(0, (t - start) / duration)))
        }
        if turned {
            return ManuscriptReveal(
                parchment: 1, frame: 1, headpiece: 1,
                initial: phase(0, 0.9),
                text: phase(0.5, writing),
                margin: phase(0.5 + writing * 0.45, 1.6),
                colophon: phase(0.5 + writing, 1.2)
            )
        }
        return ManuscriptReveal(
            parchment: ManuscriptRenderer.smooth(phase(0, 0.7)),
            frame: ManuscriptRenderer.smooth(phase(0.25, 1.0)),
            headpiece: phase(0.6, 1.6),
            initial: phase(1.4, 1.1),
            text: phase(2.2, writing),
            margin: phase(2.2 + writing * 0.45, 1.6),
            colophon: phase(2.2 + writing, 1.2)
        )
    }
}

// MARK: - Разметка страницы
/// Страница рисуется в постоянных координатах 360×640 (9:16) и масштабируется целиком,
/// поэтому на экране и в экспортированной картинке переносы строк совпадают.
enum ManuscriptGeometry {
    static let size = CGSize(width: 360, height: 640)
    static let frameInset: CGFloat = 16
    static let headpiece = CGRect(x: 44, y: 66, width: 272, height: 60)
    static let initialBox = CGRect(x: 44, y: 150, width: 70, height: 70)
    static let textRect = CGRect(x: 44, y: 150, width: 262, height: 318)
    static let exclusion = CGSize(width: 80, height: 76)
    static let marginX: CGFloat = 326
    static let marginTop: CGFloat = 178
    static let marginBottom: CGFloat = 442
    static let colophonDividerY: CGFloat = 532
}

// MARK: - Золото, которое бликует
/// Светлая полоса идёт по диагонали страницы; наклон телефона двигает её по всем золотым
/// деталям сразу, как блик лампы на сусальном золоте.
struct ManuscriptGold {
    let palette: ManuscriptPalette
    let sheen: CGPoint
    /// 0 — звёздочки блика не рисуются (камень), 1 — как на золоте
    var glintScale: CGFloat = 1

    var center: CGFloat {
        min(0.96, max(0.04, 0.5 + 0.38 * sheen.x + 0.2 * sheen.y))
    }

    var shading: GraphicsContext.Shading {
        let c = center
        let P = palette
        let stops: [Gradient.Stop] = [
            .init(color: ManuscriptPalette.color(P.goldDark), location: 0),
            .init(color: ManuscriptPalette.color(P.gold), location: max(0.01, c - 0.30)),
            .init(color: ManuscriptPalette.color(P.goldLight), location: max(0.02, c - 0.08)),
            .init(color: ManuscriptPalette.color(P.goldHighlight), location: c),
            .init(color: ManuscriptPalette.color(P.goldLight), location: min(0.98, c + 0.08)),
            .init(color: ManuscriptPalette.color(P.gold), location: min(0.99, c + 0.30)),
            .init(color: ManuscriptPalette.color(P.goldDark), location: 1)
        ]
        return .linearGradient(
            Gradient(stops: stops),
            startPoint: .zero,
            endPoint: CGPoint(x: ManuscriptGeometry.size.width, y: ManuscriptGeometry.size.height)
        )
    }

    /// Яркость искры в точке: вспыхивает, когда через неё проходит блик
    func glint(at point: CGPoint) -> CGFloat {
        let w = ManuscriptGeometry.size.width, h = ManuscriptGeometry.size.height
        let t = (point.x * w + point.y * h) / (w * w + h * h)
        return max(0, 1 - abs(t - center) / 0.07) * glintScale
    }
}

// MARK: - Вёрстка текста (CoreText): обтекание буквицы, перо идёт по строкам
/// Строки набираются вручную через CTTypesetter: первые строки уже, рядом с буквицей;
/// по ширине выравниваются только полные строки, поэтому короткий стих не растягивается по буквам.
final class ManuscriptTextLayout {
    struct Line {
        let line: CTLine
        let range: CFRange
        /// Строка набрана заново из своего куска текста: её индексы начинаются с range.location
        let indexBase: Int
        /// Левый край строки от левого края области текста
        let x: CGFloat
        /// Базовая линия от верха области текста (ось Y вниз)
        let baseline: CGFloat
        let ascent: CGFloat
        let descent: CGFloat
        /// Буквы строки с контурами: по ним идёт перо. Заполняются только у итоговой вёрстки
        var glyphs: [ManuscriptGlyph] = []
    }

    let lines: [Line]
    let length: Int
    /// Сдвиг всего блока (буквица и текст) вниз, чтобы короткий стих не прилипал к заставке
    let offsetY: CGFloat
    /// Низ текста в координатах страницы
    let bottomY: CGFloat

    private init(lines: [Line], length: Int, offsetY: CGFloat, bottomY: CGFloat) {
        self.lines = lines
        self.length = length
        self.offsetY = offsetY
        self.bottomY = bottomY
    }

    // Подбор кегля — десяток пробных вёрсток, поэтому результат кэшируется
    private static let cacheLock = NSLock()
    private static var cache: [String: ManuscriptTextLayout] = [:]

    /// `prayer` — вёрстка для текста, который набирают прямо сейчас: ступенчатый кегль и неподвижный блок,
    /// чтобы строки не прыгали от каждой буквы
    static func cached(for page: ManuscriptPage, pen: ManuscriptPen = .defaultValue, prayer: Bool = false) -> ManuscriptTextLayout {
        let ink = pen.ink(on: page.look)
        let key = "\(page.style.rawValue)|\(page.surface.rawValue)|\(page.language.rawValue)|\(ink)|\(prayer)|\(page.text)"
        cacheLock.lock()
        if let hit = cache[key] {
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()
        let made = make(for: page, ink: ink, prayer: prayer)
        cacheLock.lock()
        if cache.count > 48 { cache.removeAll() }
        cache[key] = made
        cacheLock.unlock()
        return made
    }

    private static func make(for page: ManuscriptPage, ink: UInt32, prayer: Bool) -> ManuscriptTextLayout {
        let body = page.initialAndBody.body
        let palette = page.look.palette
        let rect = ManuscriptGeometry.textRect
        let exclusion = ManuscriptGeometry.exclusion
        let isShort = !prayer && (body as NSString).length < 60

        func setLines(_ size: CGFloat) -> (lines: [Line], height: CGFloat, breaksWord: Bool) {
            typeset(body: body, size: size, palette: palette, ink: ink, isShort: isShort, width: rect.width, exclusion: exclusion)
        }

        // Длинному стиху разрешаем занять чуть больше места вниз
        var height = rect.height
        var low: CGFloat = 11.5
        // Крупный кегль только у короткого стиха: в длинном строка должна вмещать несколько слов
        let bodyLength = (body as NSString).length
        var high: CGFloat = bodyLength < 60 ? 40 : (bodyLength < 130 ? 28 : 22)
        if setLines(low).height > height {
            height = rect.height + 24
        }
        var best = low
        if prayer {
            // Набираемый текст: берём первый из ступенчатых кеглей, в который он влезает
            for size in [24, 20, 17, 14.5, 12.5] as [CGFloat] {
                let attempt = setLines(size)
                if attempt.height <= height && !attempt.breaksWord {
                    best = size
                    break
                }
            }
        } else {
            for _ in 0..<10 {
                let mid = (low + high) / 2
                // Кегль подходит, если текст влез по высоте и ни одно слово не разорвано посередине
                let attempt = setLines(mid)
                if attempt.height <= height && !attempt.breaksWord {
                    best = mid
                    low = mid
                } else {
                    high = mid
                }
            }
        }

        // Строки, которые не поместились даже мелким кеглем, отбрасываются
        let inkColor = ManuscriptPalette.color(ink)
        let visible = setLines(best).lines.filter { $0.baseline + $0.descent <= height + 2 }.map { item -> Line in
            var inked = item
            inked.glyphs = ManuscriptGlyphs.make(line: item.line, indexBase: item.indexBase, range: item.range, ink: inkColor)
            return inked
        }
        let length = visible.last.map { $0.range.location + $0.range.length } ?? 0
        let textBottom = max(exclusion.height, visible.last.map { $0.baseline + $0.descent } ?? 0)
        // Короткий стих: блок опускается ближе к середине свободного места под заставкой
        let free = (500 - rect.minY) - (textBottom + 30)
        let offsetY = (!prayer && free > 0) ? free * 0.42 : 0
        return ManuscriptTextLayout(lines: visible, length: length, offsetY: offsetY, bottomY: rect.minY + offsetY + textBottom)
    }

    private static func typeset(body: String, size: CGFloat, palette: ManuscriptPalette, ink: UInt32, isShort: Bool,
                                width: CGFloat, exclusion: CGSize) -> (lines: [Line], height: CGFloat, breaksWord: Bool) {
        let text = attributed(body: body, size: size, palette: palette, ink: ink, isShort: isShort)
        let total = text.length
        guard total > 0 else { return ([], 0, false) }
        let typesetter = CTTypesetterCreateWithAttributedString(text as CFAttributedString)
        let font = PaperFont.uiFont(size: size)
        let lineHeight = font.lineHeight * 1.1
        let string = text.string as NSString

        var lines: [Line] = []
        var start = 0
        var top: CGFloat = 0
        var breaksWord = false
        while start < total {
            // Строка, которая хоть немного заходит на высоту буквицы, начинается правее неё
            let x: CGFloat = top < exclusion.height ? exclusion.width : 0
            let available = width - x
            let count = max(1, CTTypesetterSuggestLineBreak(typesetter, start, Double(available)))
            let range = CFRange(location: start, length: count)
            var line = CTTypesetterCreateLine(typesetter, range)
            var indexBase = 0

            let isLast = start + count >= total
            // Слово не влезло в строку целиком и разорвано посередине
            if !isLast {
                let before = string.character(at: start + count - 1)
                let after = string.character(at: start + count)
                let isBreakable: (unichar) -> Bool = { $0 == 32 || $0 == 0x00A0 || $0 == 10 || $0 == 45 || $0 == 0x2013 || $0 == 0x2014 }
                if !isBreakable(before) && !isBreakable(after) {
                    breaksWord = true
                }
            }
            let natural = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil) - CTLineGetTrailingWhitespaceWidth(line))
            let spaces = string.substring(with: NSRange(location: start, length: count))
                .trimmingCharacters(in: .whitespaces)
                .filter { $0 == " " }
                .count
            // По ширине — только за счёт пробелов между словами и только если они не станут дырами;
            // буквы не разгоняются (CTLineCreateJustifiedLine растягивал бы и их)
            let extra = available - natural
            if !isLast, spaces >= 2, extra > 0, extra / CGFloat(spaces) <= size * 0.55 {
                let piece = NSMutableAttributedString(attributedString: text.attributedSubstring(from: NSRange(location: start, length: count)))
                let pieceString = piece.string as NSString
                var lastLetter = pieceString.length - 1
                while lastLetter >= 0 && pieceString.character(at: lastLetter) == 32 { lastLetter -= 1 }
                let kernKey = NSAttributedString.Key(kCTKernAttributeName as String)
                let perGap = extra / CGFloat(spaces)
                var index = 0
                while index < lastLetter {
                    if pieceString.character(at: index) == 32 {
                        piece.addAttribute(kernKey, value: perGap, range: NSRange(location: index, length: 1))
                    }
                    index += 1
                }
                line = CTLineCreateWithAttributedString(piece as CFAttributedString)
                indexBase = start
            }

            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            _ = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            lines.append(Line(line: line, range: range, indexBase: indexBase, x: x, baseline: top + font.ascender, ascent: ascent, descent: descent))
            top += lineHeight
            start += count
        }
        let height = lines.last.map { $0.baseline + $0.descent } ?? 0
        return (lines, height, breaksWord)
    }

    private static func attributed(body: String, size: CGFloat, palette: ManuscriptPalette, ink: UInt32, isShort: Bool) -> NSAttributedString {
        let colorKey = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
        let result = NSMutableAttributedString(string: body, attributes: [
            .font: PaperFont.uiFont(size: size, weight: .regular),
            colorKey: ManuscriptPalette.uiColor(ink).cgColor
        ])
        // Слова сразу после буквицы — киноварью, как рубрика в рукописи
        let rubric = rubricLength(in: body, words: isShort ? 1 : 2)
        if rubric > 0 {
            result.addAttributes([
                .font: PaperFont.uiFont(size: size, weight: .medium),
                colorKey: ManuscriptPalette.uiColor(palette.rubric).cgColor
            ], range: NSRange(location: 0, length: rubric))
        }
        return result
    }

    /// Остаток первого слова (и следующее слово у длинного стиха), не длиннее 28 знаков
    private static func rubricLength(in body: String, words: Int) -> Int {
        let string = body as NSString
        var end = 0
        var spaces = 0
        var seenLetter = false
        while end < string.length && end < 28 {
            if string.character(at: end) == 32 {
                if seenLetter {
                    spaces += 1
                    if spaces >= words || end >= 14 { break }
                }
            } else {
                seenLetter = true
            }
            end += 1
        }
        return end
    }
}

// MARK: - Страница рукописи
struct ManuscriptPageView: View {
    let page: ManuscriptPage
    var reveal: ManuscriptReveal = .complete
    /// Наклон телефона в диапазоне −1…1 по обеим осям
    var sheen: CGPoint = CGPoint(x: 0.2, y: -0.1)
    /// Подпись Luys внизу — только в картинке для соцсетей
    var showsWatermark = false
    /// Перо задаёт чернила и вид пера в руке писца
    var pen: ManuscriptPen = .defaultValue
    /// Набираемая молитва: вёрстка со ступенчатым кеглем, зерно пергамента не меняется от каждой буквы,
    /// а перо остаётся у конца текста, пока человек думает
    var isLiveWriting = false
    var parchmentSeed: UInt32?
    var quillLift: CGFloat?

    var body: some View {
        let layout = ManuscriptTextLayout.cached(for: page, pen: pen, prayer: isLiveWriting)
        let initial = page.initialAndBody.initial
        ZStack {
            ManuscriptParchment(seed: parchmentSeed ?? page.seed, look: page.look)
                .equatable()
                .opacity(Double(reveal.parchment))
            Canvas { context, _ in
                let look = page.look
                let gold = ManuscriptGold(palette: look.palette, sheen: sheen, glintScale: look.surface.glintScale)
                ManuscriptRenderer.drawFrame(progress: reveal.frame, palette: look.palette, gold: gold, in: context)
                ManuscriptRenderer.drawHeadpiece(progress: reveal.headpiece, style: look, gold: gold, in: context)
                ManuscriptRenderer.drawInitial(initial, progress: reveal.initial, offsetY: layout.offsetY, style: look, gold: gold, in: context)
                ManuscriptRenderer.drawText(layout, progress: reveal.text, lift: quillLift ?? reveal.colophon, pen: pen, look: look, in: context)
                ManuscriptRenderer.drawMarginOrnament(progress: reveal.margin, style: look, gold: gold, in: context)
                ManuscriptRenderer.drawEnding(page: page, layout: layout, progress: reveal.colophon, gold: gold, in: context)
                ManuscriptRenderer.drawGlints(reveal: reveal, initialOffsetY: layout.offsetY, gold: gold, in: context)
                if showsWatermark {
                    ManuscriptRenderer.drawWatermark(palette: page.look.palette, in: context)
                }
            }
        }
        .frame(width: ManuscriptGeometry.size.width, height: ManuscriptGeometry.size.height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(page.text) — \(page.reference)"))
    }
}

// MARK: - Пергамент: рисуется один раз, а не каждый кадр анимации
struct ManuscriptParchment: View, Equatable {
    let seed: UInt32
    let look: ManuscriptLook

    var body: some View {
        Canvas { context, size in
            ManuscriptSurfaceArt.draw(surface: look.surface, seed: seed, palette: look.palette, size: size, in: context)
        }
    }
}

// MARK: - Рисование
enum ManuscriptRenderer {
    static func smooth(_ x: CGFloat) -> CGFloat {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    static func clamp(_ x: CGFloat) -> CGFloat {
        min(1, max(0, x))
    }

    private static func c(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        ManuscriptPalette.color(hex, alpha)
    }

    private static func circle(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    // Золото прямо на пергаменте обводится тёмной охрой, как в рукописях: иначе в момент блика
    // светлое золото сливается с листом
    private static func strokeGold(_ path: Path, width: CGFloat, gold: ManuscriptGold, in ctx: GraphicsContext) {
        ctx.stroke(path, with: .color(c(gold.palette.goldDark, 0.5)), style: StrokeStyle(lineWidth: width + 0.9, lineCap: .round))
        ctx.stroke(path, with: gold.shading, style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private static func fillGold(_ path: Path, gold: ManuscriptGold, in ctx: GraphicsContext) {
        ctx.fill(path, with: gold.shading)
        ctx.stroke(path, with: .color(c(gold.palette.goldDark, 0.75)), lineWidth: 0.5)
    }

    // MARK: Пергамент
    static func drawParchment(seed: UInt32, palette P: ManuscriptPalette, size: CGSize, in ctx: GraphicsContext) {
        let rect = CGRect(origin: .zero, size: size)
        ctx.fill(Path(rect), with: .color(c(P.parchment)))
        // Края темнее, как у старого листа
        ctx.fill(Path(rect), with: .radialGradient(
            Gradient(colors: [c(P.parchmentEdge, 0), c(P.parchmentEdge, 0.2), c(P.parchmentEdge, 0.8)]),
            center: CGPoint(x: size.width / 2, y: size.height * 0.46),
            startRadius: size.width * 0.32,
            endRadius: size.height * 0.64
        ))

        var rng = PomegranateRandom(seed: seed)
        // Рыжие пятна времени
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 7))
            for _ in 0..<6 {
                let r = 6 + rng.next() * 18
                let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
                layer.fill(Path(ellipseIn: circle(center, r)), with: .color(c(P.parchmentEdge, 0.28)))
            }
        }
        // Крапинки
        for _ in 0..<380 {
            let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let r = 0.25 + rng.next() * 0.7
            let isDark = rng.next() > 0.72
            let alpha = isDark ? 0.05 + Double(rng.next()) * 0.05 : 0.22 + Double(rng.next()) * 0.22
            ctx.fill(Path(ellipseIn: circle(center, r)), with: .color(c(isDark ? P.ink : P.parchmentEdge, alpha)))
        }
        // Волокна
        for _ in 0..<36 {
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
            ctx.stroke(fiber, with: .color(c(P.ink, 0.05)), lineWidth: 0.35)
        }
        ctx.stroke(Path(rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(c(P.parchmentEdge, 0.9)), lineWidth: 1)
    }

    // MARK: Рамка страницы
    static func drawFrame(progress p: CGFloat, palette P: ManuscriptPalette, gold: ManuscriptGold, in ctx: GraphicsContext) {
        guard p > 0 else { return }
        let page = CGRect(origin: .zero, size: ManuscriptGeometry.size)
        let outer = page.insetBy(dx: ManuscriptGeometry.frameInset, dy: ManuscriptGeometry.frameInset)
        let inner = outer.insetBy(dx: 4.5, dy: 4.5)
        strokeGold(Path(outer).trimmedPath(from: 0, to: p), width: 2.2, gold: gold, in: ctx)
        ctx.stroke(Path(inner).trimmedPath(from: 0, to: p), with: .color(c(P.rubric, 0.8)), lineWidth: 0.7)

        let cornerAlpha = clamp((p - 0.85) / 0.15)
        guard cornerAlpha > 0 else { return }
        var layer = ctx
        layer.opacity = cornerAlpha
        for corner in [CGPoint(x: outer.minX, y: outer.minY), CGPoint(x: outer.maxX, y: outer.minY),
                       CGPoint(x: outer.minX, y: outer.maxY), CGPoint(x: outer.maxX, y: outer.maxY)] {
            var quatrefoil = Path()
            for offset in [CGPoint(x: 2.7, y: 0), CGPoint(x: -2.7, y: 0), CGPoint(x: 0, y: 2.7), CGPoint(x: 0, y: -2.7)] {
                quatrefoil.addEllipse(in: circle(CGPoint(x: corner.x + offset.x, y: corner.y + offset.y), 2.4))
            }
            fillGold(quatrefoil, gold: gold, in: layer)
            layer.fill(Path(ellipseIn: circle(corner, 1.2)), with: .color(c(P.rubric)))
        }
    }

    // MARK: Жемчуг по золотой раме (белые точки армянских заставок)
    private static func drawPearls(along r: CGRect, spacing: CGFloat, radius: CGFloat, palette P: ManuscriptPalette, in ctx: GraphicsContext) {
        let perimeter = 2 * (r.width + r.height)
        let count = max(4, Int(perimeter / spacing))
        var path = Path()
        for i in 0..<count {
            let point = pointOnRect(r, distance: CGFloat(i) * perimeter / CGFloat(count))
            path.addEllipse(in: circle(point, radius))
        }
        ctx.fill(path, with: .color(c(P.pearl, 0.92)))
    }

    private static func pointOnRect(_ r: CGRect, distance: CGFloat) -> CGPoint {
        var d = distance
        if d < r.width { return CGPoint(x: r.minX + d, y: r.minY) }
        d -= r.width
        if d < r.height { return CGPoint(x: r.maxX, y: r.minY + d) }
        d -= r.height
        if d < r.width { return CGPoint(x: r.maxX - d, y: r.maxY) }
        d -= r.width
        return CGPoint(x: r.minX, y: r.maxY - d)
    }

    // MARK: Лист: миндалевидный, с золотой жилкой
    private static func leafPath(at base: CGPoint, angle: CGFloat, length: CGFloat, width: CGFloat) -> Path {
        let tip = CGPoint(x: base.x + cos(angle) * length, y: base.y + sin(angle) * length)
        let normal = CGPoint(x: -sin(angle) * width, y: cos(angle) * width)
        let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
        var path = Path()
        path.move(to: base)
        path.addQuadCurve(to: tip, control: CGPoint(x: mid.x + normal.x, y: mid.y + normal.y))
        path.addQuadCurve(to: base, control: CGPoint(x: mid.x - normal.x, y: mid.y - normal.y))
        return path
    }

    private static func drawLeaf(at base: CGPoint, angle: CGFloat, length: CGFloat, width: CGFloat,
                                 color: Color, gold: ManuscriptGold, in ctx: GraphicsContext) {
        let leaf = leafPath(at: base, angle: angle, length: length, width: width)
        ctx.fill(leaf, with: .color(color))
        var vein = Path()
        vein.move(to: base)
        vein.addLine(to: CGPoint(x: base.x + cos(angle) * length * 0.85, y: base.y + sin(angle) * length * 0.85))
        ctx.stroke(vein, with: gold.shading, lineWidth: 0.5)
    }

    // MARK: Армянский «цветущий» крест: раздвоенные концы и розетка в центре
    static func blossomCross(center c0: CGPoint, size s: CGFloat) -> Path {
        var path = Path()
        let t = s * 0.15
        let half = s / 2
        path.addRect(CGRect(x: c0.x - t / 2, y: c0.y - half + t * 0.6, width: t, height: s - t * 1.2))
        path.addRect(CGRect(x: c0.x - half + t * 0.6, y: c0.y - t / 2, width: s - t * 1.2, height: t))
        let r = t * 0.62
        let ends: [(CGPoint, CGPoint)] = [
            (CGPoint(x: c0.x, y: c0.y - half + r), CGPoint(x: 1, y: 0)),
            (CGPoint(x: c0.x, y: c0.y + half - r), CGPoint(x: 1, y: 0)),
            (CGPoint(x: c0.x - half + r, y: c0.y), CGPoint(x: 0, y: 1)),
            (CGPoint(x: c0.x + half - r, y: c0.y), CGPoint(x: 0, y: 1))
        ]
        for (end, normal) in ends {
            path.addEllipse(in: circle(CGPoint(x: end.x + normal.x * r * 0.85, y: end.y + normal.y * r * 0.85), r))
            path.addEllipse(in: circle(CGPoint(x: end.x - normal.x * r * 0.85, y: end.y - normal.y * r * 0.85), r))
        }
        path.addEllipse(in: circle(c0, t * 0.9))
        return path
    }

    // MARK: Заставка (хоран): золотая рама, поле, лоза, крест с павлинами
    static func drawHeadpiece(progress p: CGFloat, style: ManuscriptLook, gold: ManuscriptGold, in ctx: GraphicsContext) {
        guard p > 0 else { return }
        let P = style.palette
        let band = ManuscriptGeometry.headpiece
        let outline = Path(roundedRect: band, cornerRadius: 3)

        // 1. Контур золотом
        strokeGold(outline.trimmedPath(from: 0, to: smooth(p / 0.3)), width: 1.2, gold: gold, in: ctx)

        // 2. Рама и поле
        let fill = smooth((p - 0.2) / 0.25)
        if fill > 0 {
            var layer = ctx
            layer.opacity = fill
            layer.fill(outline, with: gold.shading)
            layer.fill(Path(roundedRect: band.insetBy(dx: 5, dy: 5), cornerRadius: 1.5), with: .color(c(P.field)))
            layer.stroke(Path(roundedRect: band.insetBy(dx: 7.5, dy: 7.5), cornerRadius: 1), with: gold.shading, lineWidth: 0.6)
            drawPearls(along: band.insetBy(dx: 2.5, dy: 2.5), spacing: 5.5, radius: 0.75, palette: P, in: layer)
        }

        // 3. Лоза с розетками и листьями
        let vine = clamp((p - 0.35) / 0.35)
        if vine > 0 {
            drawVine(in: band.insetBy(dx: 9, dy: 8), progress: vine, palette: P, gold: gold, in: ctx)
        }

        // 4. Навершия, купол с крестом, павлины или гранаты
        let crown = smooth((p - 0.62) / 0.38)
        guard crown > 0 else { return }
        var layer = ctx
        layer.opacity = crown
        for corner in [CGPoint(x: band.minX + 1, y: band.minY), CGPoint(x: band.maxX - 1, y: band.minY)] {
            for angle in [-CGFloat.pi / 2, -CGFloat.pi / 2 - 0.55, -CGFloat.pi / 2 + 0.55] {
                fillGold(leafPath(at: corner, angle: angle, length: 11, width: 3), gold: gold, in: layer)
            }
            layer.fill(Path(ellipseIn: circle(CGPoint(x: corner.x, y: corner.y - 1), 1.3)), with: .color(c(P.rubric)))
        }

        let cx = band.midX
        var dome = Path()
        dome.addArc(center: CGPoint(x: cx, y: band.minY), radius: 8, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        dome.closeSubpath()
        fillGold(dome, gold: gold, in: layer)
        let lift = (1 - crown) * 6
        let cross = blossomCross(center: CGPoint(x: cx, y: 45 + lift), size: 26)
        layer.fill(cross, with: gold.shading)
        layer.stroke(cross, with: .color(c(P.goldDark, 0.55)), lineWidth: 0.5)
        layer.fill(Path(ellipseIn: circle(CGPoint(x: cx, y: 45 + lift), 1.4)), with: .color(c(P.rubric)))

        if style.hasBirds {
            drawPeacock(foot: CGPoint(x: cx - 38, y: band.minY), facingRight: true, palette: P, gold: gold, in: layer)
            drawPeacock(foot: CGPoint(x: cx + 38, y: band.minY), facingRight: false, palette: P, gold: gold, in: layer)
        } else {
            for side in [-1.0, 1.0] as [CGFloat] {
                let x = cx + side * 40
                drawLeaf(at: CGPoint(x: x, y: band.minY), angle: -CGFloat.pi / 2 - side * 1.0, length: 12, width: 3.4,
                         color: c(P.leaf), gold: gold, in: layer)
                let fruit = PomegranateTreeLayout.Fruit(x: x, y: band.minY - 13, r: 9, stemX: x, stemY: band.minY - 22, isOpen: true)
                PomegranateRenderer.drawFruit(fruit, palette: .light, lineWidth: 0.6, withStem: false, in: layer)
            }
        }
    }

    private static func drawVine(in field: CGRect, progress p: CGFloat, palette P: ManuscriptPalette,
                                 gold: ManuscriptGold, in ctx: GraphicsContext) {
        let waves: CGFloat = 6
        let period = field.width / waves
        let amplitude = field.height * 0.2
        let mid = field.midY
        func y(at x: CGFloat) -> CGFloat {
            mid + amplitude * sin((x - field.minX) / period * 2 * .pi)
        }
        var path = Path()
        var x = field.minX
        path.move(to: CGPoint(x: x, y: y(at: x)))
        while x < field.maxX {
            x = min(field.maxX, x + 2)
            path.addLine(to: CGPoint(x: x, y: y(at: x)))
        }
        ctx.stroke(path.trimmedPath(from: 0, to: p), with: gold.shading, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))

        let reach = field.minX + field.width * p
        for k in 0..<Int(waves) {
            // Под гребнем волны (лоза внизу) — розетка сверху
            let lowX = field.minX + period * (CGFloat(k) + 0.25)
            if lowX < reach {
                drawRosette(at: CGPoint(x: lowX, y: field.minY + field.height * 0.27), radius: 4.4, palette: P, gold: gold, in: ctx)
            }
            // Под верхней точкой лозы свисает пара листьев
            let highX = field.minX + period * (CGFloat(k) + 0.75)
            if highX < reach {
                let base = CGPoint(x: highX, y: y(at: highX))
                drawLeaf(at: base, angle: .pi / 2 + 0.6, length: 11, width: 3.1, color: c(P.leaf), gold: gold, in: ctx)
                drawLeaf(at: base, angle: .pi / 2 - 0.6, length: 11, width: 3.1, color: c(P.leaf), gold: gold, in: ctx)
            }
        }
    }

    private static func drawRosette(at center: CGPoint, radius r: CGFloat, palette P: ManuscriptPalette,
                                    gold: ManuscriptGold, in ctx: GraphicsContext) {
        let disc = Path(ellipseIn: circle(center, r))
        ctx.fill(disc, with: .color(c(P.fieldAccent)))
        ctx.stroke(disc, with: gold.shading, lineWidth: 0.9)
        var dots = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * 2 * .pi
            dots.addEllipse(in: circle(CGPoint(x: center.x + cos(angle) * r * 0.62, y: center.y + sin(angle) * r * 0.62), 0.7))
        }
        ctx.fill(dots, with: .color(c(P.pearl, 0.95)))
        ctx.fill(Path(ellipseIn: circle(center, r * 0.3)), with: gold.shading)
    }

    // MARK: Павлин у креста (повёрнут к центру)
    private static func drawPeacock(foot: CGPoint, facingRight: Bool, palette P: ManuscriptPalette,
                                    gold: ManuscriptGold, in ctx: GraphicsContext) {
        var bird = ctx
        bird.translateBy(x: foot.x, y: foot.y)
        if !facingRight { bird.scaleBy(x: -1, y: 1) }

        var tail = Path()
        tail.move(to: CGPoint(x: -4, y: -9))
        tail.addCurve(to: CGPoint(x: -31, y: -3), control1: CGPoint(x: -12, y: -17), control2: CGPoint(x: -27, y: -15))
        tail.addCurve(to: CGPoint(x: -3, y: -4), control1: CGPoint(x: -26, y: 3), control2: CGPoint(x: -12, y: 1))
        tail.closeSubpath()
        bird.fill(tail, with: gold.shading)
        bird.stroke(tail, with: .color(c(P.goldDark, 0.6)), lineWidth: 0.4)
        for eye in [CGPoint(x: -25, y: -6), CGPoint(x: -18, y: -8.5), CGPoint(x: -11, y: -6)] {
            bird.fill(Path(ellipseIn: circle(eye, 1.9)), with: .color(c(P.fieldAccent)))
            bird.fill(Path(ellipseIn: circle(eye, 0.8)), with: .color(c(P.field)))
        }

        var legs = Path()
        legs.move(to: CGPoint(x: 0, y: -6))
        legs.addLine(to: CGPoint(x: -1, y: 0))
        legs.move(to: CGPoint(x: 3, y: -6))
        legs.addLine(to: CGPoint(x: 3.5, y: 0))
        bird.stroke(legs, with: .color(c(P.goldDark)), lineWidth: 0.8)

        let body = Path(ellipseIn: CGRect(x: -8, y: -16, width: 17, height: 11))
        bird.fill(body, with: .color(c(P.field)))
        bird.stroke(body, with: .color(c(P.goldDark, 0.55)), lineWidth: 0.5)

        var wing = Path()
        wing.move(to: CGPoint(x: -6, y: -11.5))
        wing.addQuadCurve(to: CGPoint(x: 4, y: -12), control: CGPoint(x: -1, y: -17))
        wing.addQuadCurve(to: CGPoint(x: -6, y: -11.5), control: CGPoint(x: -1, y: -8))
        bird.fill(wing, with: .color(c(P.fieldAccent)))
        bird.stroke(wing, with: gold.shading, lineWidth: 0.5)

        var neck = Path()
        neck.move(to: CGPoint(x: 5, y: -14))
        neck.addQuadCurve(to: CGPoint(x: 9, y: -27), control: CGPoint(x: 10.5, y: -19))
        bird.stroke(neck, with: .color(c(P.field)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        bird.fill(Path(ellipseIn: circle(CGPoint(x: 9.5, y: -28), 3)), with: .color(c(P.field)))

        var beak = Path()
        beak.move(to: CGPoint(x: 12, y: -29.2))
        beak.addLine(to: CGPoint(x: 15.6, y: -27.8))
        beak.addLine(to: CGPoint(x: 12, y: -26.8))
        beak.closeSubpath()
        bird.fill(beak, with: gold.shading)
        bird.fill(Path(ellipseIn: circle(CGPoint(x: 10.4, y: -28.7), 0.75)), with: .color(c(P.pearl)))

        var crest = Path()
        var crestDots = Path()
        for i in 0..<3 {
            let tip = CGPoint(x: 7 + CGFloat(i) * 2.2, y: -36 + abs(CGFloat(i) - 1) * 0.8)
            crest.move(to: CGPoint(x: 9, y: -31))
            crest.addLine(to: tip)
            crestDots.addEllipse(in: circle(tip, 0.85))
        }
        bird.stroke(crest, with: .color(c(P.goldDark)), lineWidth: 0.5)
        bird.fill(crestDots, with: gold.shading)
    }

    // MARK: Буквица: золотая буква на цветном поле в золотой раме
    static func drawInitial(_ letter: String, progress p: CGFloat, offsetY: CGFloat, style: ManuscriptLook,
                            gold: ManuscriptGold, in ctx: GraphicsContext) {
        guard p > 0 else { return }
        let P = style.palette
        let box = ManuscriptGeometry.initialBox.offsetBy(dx: 0, dy: offsetY)
        let appear = smooth(p / 0.4)

        var layer = ctx
        layer.opacity = appear
        let scale = 0.7 + 0.3 * appear
        layer.translateBy(x: box.midX, y: box.midY)
        layer.scaleBy(x: scale, y: scale)
        layer.translateBy(x: -box.midX, y: -box.midY)

        layer.fill(Path(roundedRect: box, cornerRadius: 3), with: gold.shading)
        let field = box.insetBy(dx: 4, dy: 4)
        layer.fill(Path(roundedRect: field, cornerRadius: 1.5), with: .color(c(P.field)))
        layer.stroke(Path(roundedRect: box.insetBy(dx: 6.5, dy: 6.5), cornerRadius: 1), with: gold.shading, lineWidth: 0.6)
        drawPearls(along: box.insetBy(dx: 2, dy: 2), spacing: 5, radius: 0.7, palette: P, in: layer)
        let inset = field.insetBy(dx: 5.5, dy: 5.5)
        for corner in [CGPoint(x: inset.minX, y: inset.minY), CGPoint(x: inset.maxX, y: inset.minY),
                       CGPoint(x: inset.minX, y: inset.maxY), CGPoint(x: inset.maxX, y: inset.maxY)] {
            layer.fill(Path(ellipseIn: circle(corner, 1.7)), with: .color(c(P.fieldAccent)))
            layer.fill(Path(ellipseIn: circle(corner, 0.6)), with: .color(c(P.pearl)))
        }

        let letterAppear = smooth((p - 0.3) / 0.5)
        if letterAppear > 0, !letter.isEmpty {
            let center = CGPoint(x: box.midX, y: box.midY + 1.5)
            let font = PaperFont.font(size: 50, weight: .semibold)
            var glyph = layer
            glyph.opacity = appear * letterAppear
            let shadow = ctx.resolve(Text(letter).font(font).foregroundColor(c(P.goldDark)))
            glyph.draw(shadow, at: CGPoint(x: center.x + 0.9, y: center.y + 1.1), anchor: .center)
            let mask = ctx.resolve(Text(letter).font(font).foregroundColor(.white))
            glyph.drawLayer { gilded in
                gilded.clipToLayer { clip in
                    clip.draw(mask, at: center, anchor: .center)
                }
                gilded.fill(Path(box), with: gold.shading)
            }
        }

        // Веточка на левом поле под буквицей
        let sprig = clamp((p - 0.55) / 0.45)
        guard sprig > 0 else { return }
        let x: CGFloat = 32
        var stem = Path()
        stem.move(to: CGPoint(x: x, y: box.maxY - 8))
        stem.addQuadCurve(to: CGPoint(x: x + 1, y: box.maxY + 36), control: CGPoint(x: x - 4, y: box.maxY + 14))
        strokeGold(stem.trimmedPath(from: 0, to: sprig), width: 0.9, gold: gold, in: ctx)
        let leaves: [(CGFloat, CGFloat, CGFloat)] = [(0.3, -2.4, 0.35), (0.55, 2.1, 0.6), (0.8, -2.4, 0.85)]
        for (yFactor, side, threshold) in leaves where sprig > threshold {
            let base = CGPoint(x: x - 1, y: box.maxY - 8 + 44 * yFactor)
            drawLeaf(at: base, angle: side > 0 ? -0.5 : .pi + 0.5, length: 7.5, width: 2.3, color: c(P.leaf), gold: gold, in: ctx)
        }
        if sprig > 0.97 {
            ctx.fill(Path(ellipseIn: circle(CGPoint(x: x + 1, y: box.maxY + 38), 2.2)), with: .color(c(P.rubric)))
        }
    }

    // MARK: Текст: перо проходит строку за строкой
    /// `lift` — отрыв пера от листа после последней строки: 0 — перо ещё на странице, 1 — улетело
    static func drawText(_ layout: ManuscriptTextLayout, progress p: CGFloat, lift: CGFloat = 1,
                         pen penStyle: ManuscriptPen = .defaultValue,
                         look: ManuscriptLook, in ctx: GraphicsContext) {
        let P = look.palette
        let inkHex = penStyle.ink(on: look)
        guard p > 0, !layout.lines.isEmpty else { return }
        let rect = ManuscriptGeometry.textRect
        let top = rect.minY + layout.offsetY
        let written = p * CGFloat(layout.length)
        var pen: CGPoint?
        var lastLineEnd: CGPoint?
        // Строка и буква, которые перо выводит прямо сейчас, и где оно оторвалось от предыдущей буквы
        var writing: (line: ManuscriptTextLayout.Line, glyph: Int)?
        var previousInk: CGPoint?

        if look.surface.isCarved {
            drawCarvedRims(layout, written: written, rect: rect, top: top, rim: c(P.goldHighlight, 0.8), in: ctx)
        }

        ctx.withCGContext { cg in
            for item in layout.lines {
                let start = CGFloat(item.range.location)
                let end = CGFloat(item.range.location + item.range.length)
                if written <= start { break }
                // Начало координат — на базовой линии строки, ось Y вверх (как ждёт CoreText)
                cg.saveGState()
                cg.translateBy(x: rect.minX + item.x, y: top + item.baseline)
                cg.scaleBy(x: 1, y: -1)
                cg.textMatrix = .identity
                if written >= end {
                    cg.textPosition = .zero
                    CTLineDraw(item.line, cg)
                    cg.restoreGState()
                    let lineWidth = CGFloat(CTLineGetTypographicBounds(item.line, nil, nil, nil))
                    lastLineEnd = CGPoint(x: rect.minX + item.x + lineWidth + 1.5,
                                          y: top + item.baseline - item.ascent * 0.32)
                    if let lastInked = item.glyphs.last(where: { $0.hasInk }) {
                        previousInk = CGPoint(x: rect.minX + item.x + lastInked.endPoint.x,
                                              y: top + item.baseline + lastInked.endPoint.y)
                    }
                    continue
                }
                // Строка пишется прямо сейчас. Слева от текущей буквы всё написано целиком, а сама
                // буква рисуется ниже по контуру: перо обводит её, и чернила заливают контур
                if let index = item.glyphs.firstIndex(where: { CGFloat($0.from) <= written && written < CGFloat($0.to) }) {
                    let glyph = item.glyphs[index]
                    let done = CGRect(x: -2, y: -item.descent - 2, width: max(0, glyph.x + 2), height: item.ascent + item.descent + 4)
                    cg.saveGState()
                    cg.clip(to: done)
                    cg.textPosition = .zero
                    CTLineDraw(item.line, cg)
                    cg.restoreGState()
                    cg.restoreGState()
                    writing = (item, index)
                    break
                }
                // Запасной путь, если контуров нет: открываем строку до кончика пера
                let character = Int(written)
                let fraction = written - CGFloat(character)
                let x0 = CTLineGetOffsetForStringIndex(item.line, character - item.indexBase, nil)
                let x1 = CTLineGetOffsetForStringIndex(item.line, min(character + 1, item.range.location + item.range.length) - item.indexBase, nil)
                let tipX = x0 + (x1 - x0) * fraction
                let band = CGRect(x: -2, y: -item.descent - 2, width: max(0, tipX + 2), height: item.ascent + item.descent + 4)

                cg.saveGState()
                cg.clip(to: band)
                cg.textPosition = .zero
                CTLineDraw(item.line, cg)
                cg.restoreGState()

                // Мягкий край: чернила ещё не впитались
                cg.saveGState()
                cg.clip(to: CGRect(x: tipX, y: band.minY, width: 5, height: band.height))
                cg.setAlpha(0.3)
                cg.textPosition = .zero
                CTLineDraw(item.line, cg)
                cg.restoreGState()

                cg.restoreGState()
                pen = CGPoint(x: rect.minX + item.x + tipX + 1.5, y: top + item.baseline - item.ascent * 0.32)
                break
            }
        }

        if let writing {
            pen = drawWritingGlyph(writing.line, glyphIndex: writing.glyph, written: written,
                                   previousInk: previousInk, rect: rect, top: top, in: ctx)
        }

        if let pen, p < 1 {
            ctx.fill(Path(ellipseIn: circle(pen, 1.8)), with: .color(c(inkHex, 0.8)))
            ctx.fill(Path(ellipseIn: circle(pen, 3.6)), with: .color(c(inkHex, 0.12)))
            // Рука чуть покачивает перо в такт письму
            let sway = Double(sin(written * 0.9)) * 2.5
            ManuscriptQuillArt.draw(pen: penStyle, tip: pen, sway: sway, lift: 0, time: Double(written) * 0.5, palette: P, surface: look.surface, in: ctx)
        } else if p >= 1, lift < 1, let restingTip = previousInk ?? lastLineEnd {
            ManuscriptQuillArt.draw(pen: penStyle, tip: restingTip, sway: 0, lift: lift, time: Double(written) * 0.5, palette: P, surface: look.surface, in: ctx)
        }
    }

    /// Доля времени буквы, которую перо тратит на подход к ней
    private static let writeApproach: CGFloat = 0.12

    /// Резьба: светлая кромка по нижнему правому краю каждой буквы, как у борозды в камне при боковом свете.
    /// Рисуется под чернилами, поэтому видна только там, где борозда выходит за контур буквы.
    private static func drawCarvedRims(_ layout: ManuscriptTextLayout, written: CGFloat, rect: CGRect, top: CGFloat,
                                       rim: Color, in ctx: GraphicsContext) {
        for item in layout.lines {
            if written <= CGFloat(item.range.location) { break }
            var layer = ctx
            layer.translateBy(x: rect.minX + item.x + 0.55, y: top + item.baseline + 0.75)
            for glyph in item.glyphs where glyph.hasInk && CGFloat(glyph.from) < written {
                if CGFloat(glyph.to) <= written {
                    layer.fill(glyph.path, with: .color(rim))
                } else if let plan = glyph.plan {
                    let span = CGFloat(max(1, glyph.to - glyph.from))
                    let fraction = clamp((written - CGFloat(glyph.from)) / span)
                    let stroke = clamp((fraction - writeApproach) / (1 - writeApproach))
                    var partial = layer
                    partial.clip(to: Path(plan.inkMask(at: stroke)))
                    partial.fill(glyph.path, with: .color(rim))
                }
            }
        }
    }

    /// Буква, которую перо пишет сейчас. Перо подходит к началу буквы и ведёт кончик по её штрихам
    /// в том порядке, в каком их выводит рука: чернила проступают только там, где перо уже прошло.
    /// Возвращает, где стоит кончик пера на странице.
    private static func drawWritingGlyph(_ item: ManuscriptTextLayout.Line, glyphIndex: Int, written: CGFloat,
                                         previousInk: CGPoint?, rect: CGRect, top: CGFloat,
                                         in ctx: GraphicsContext) -> CGPoint {
        let glyph = item.glyphs[glyphIndex]
        let originX = rect.minX + item.x
        let originY = top + item.baseline
        let span = CGFloat(max(1, glyph.to - glyph.from))
        let fraction = clamp((written - CGFloat(glyph.from)) / span)

        guard glyph.hasInk else {
            // Пробел и знаки без контура: перо просто скользит над строкой
            let x = glyph.x + (glyph.nextX - glyph.x) * fraction
            return CGPoint(x: originX + x, y: originY - item.ascent * 0.15)
        }

        // Начало времени буквы перо тратит на подход к ней, остальное на письмо
        let approach = writeApproach
        let stroke = clamp((fraction - approach) / (1 - approach))

        var layer = ctx
        layer.translateBy(x: originX, y: originY)
        var tip = glyph.startPoint

        if let plan = glyph.plan {
            var inked = layer
            inked.clip(to: Path(plan.inkMask(at: stroke)))
            inked.fill(glyph.path, with: .color(glyph.color))
            // Под самый конец буква заливается целиком, чтобы между кругами не осталось щелей
            let settle = smooth((fraction - 0.92) / 0.08)
            if settle > 0 {
                layer.fill(glyph.path, with: .color(glyph.color.opacity(Double(settle))))
            }
            if fraction >= approach {
                tip = plan.position(at: stroke).tip
            }
        } else {
            // Контуры штрихов построить не удалось: буква просто проступает
            layer.fill(glyph.path, with: .color(glyph.color.opacity(Double(smooth(fraction)))))
        }

        if fraction < approach {
            // Перо переходит от конца предыдущей буквы к началу этой
            var from = glyph.startPoint
            if let before = item.glyphs[..<glyphIndex].last(where: { $0.hasInk }) {
                from = before.endPoint
            } else if let carried = previousInk {
                from = CGPoint(x: carried.x - originX, y: carried.y - originY)
            }
            let k = smooth(fraction / approach)
            tip = CGPoint(x: from.x + (glyph.startPoint.x - from.x) * k,
                          y: from.y + (glyph.startPoint.y - from.y) * k)
        }
        return CGPoint(x: originX + tip.x, y: originY + tip.y)
    }

    // MARK: Украшение на внешнем поле: стебель растёт снизу вверх, наверху крест
    static func drawMarginOrnament(progress p: CGFloat, style: ManuscriptLook, gold: ManuscriptGold, in ctx: GraphicsContext) {
        guard p > 0 else { return }
        let P = style.palette
        let x0 = ManuscriptGeometry.marginX
        let top = ManuscriptGeometry.marginTop
        let bottom = ManuscriptGeometry.marginBottom
        func x(at y: CGFloat) -> CGFloat {
            x0 + 2.2 * sin((bottom - y) / 26)
        }

        var stem = Path()
        stem.move(to: CGPoint(x: x0, y: bottom))
        var y = bottom
        while y > top {
            y = max(top, y - 3)
            stem.addLine(to: CGPoint(x: x(at: y), y: y))
        }
        strokeGold(stem.trimmedPath(from: 0, to: p), width: 1.2, gold: gold, in: ctx)

        // Основание: золотой трилистник
        var base = Path()
        for offset in [CGPoint(x: -3, y: 2), CGPoint(x: 3, y: 2), CGPoint(x: 0, y: 5)] {
            base.addEllipse(in: circle(CGPoint(x: x0 + offset.x, y: bottom + offset.y), 2.3))
        }
        fillGold(base, gold: gold, in: ctx)

        let reachY = bottom - (bottom - top) * p
        var node = 0
        var nodeY = bottom - 16
        while nodeY > top + 14 {
            if nodeY > reachY {
                let stemX = x(at: nodeY)
                let side: CGFloat = node % 2 == 0 ? 1 : -1
                if node % 3 == 2 {
                    let bud = CGPoint(x: stemX + side * 5.5, y: nodeY - 3)
                    var calyx = Path()
                    calyx.move(to: CGPoint(x: stemX, y: nodeY))
                    calyx.addLine(to: bud)
                    ctx.stroke(calyx, with: gold.shading, lineWidth: 0.7)
                    ctx.fill(Path(ellipseIn: circle(bud, 2.5)), with: .color(c(P.rubric)))
                    ctx.fill(Path(ellipseIn: circle(CGPoint(x: bud.x - side * 0.6, y: bud.y - 0.8), 0.8)), with: .color(c(P.pearl, 0.85)))
                } else {
                    drawLeaf(at: CGPoint(x: stemX, y: nodeY), angle: side > 0 ? -0.5 : .pi + 0.5,
                             length: 9, width: 2.8, color: c(node % 4 == 0 ? P.leaf : P.field), gold: gold, in: ctx)
                }
            }
            nodeY -= 20
            node += 1
        }

        let finial = clamp((p - 0.92) / 0.08)
        guard finial > 0 else { return }
        var layer = ctx
        layer.opacity = finial
        let topX = x(at: top)
        layer.fill(Path(ellipseIn: circle(CGPoint(x: topX, y: top - 2), 3.6)), with: .color(c(P.field)))
        layer.stroke(Path(ellipseIn: circle(CGPoint(x: topX, y: top - 2), 3.6)), with: gold.shading, lineWidth: 0.7)
        fillGold(blossomCross(center: CGPoint(x: topX, y: top - 13), size: 14), gold: gold, in: layer)
    }

    // MARK: Ссылка, концовка и памятная запись
    static func drawEnding(page: ManuscriptPage, layout: ManuscriptTextLayout, progress p: CGFloat,
                           gold: ManuscriptGold, in ctx: GraphicsContext) {
        guard p > 0 else { return }
        let P = page.look.palette
        let cx = ManuscriptGeometry.textRect.midX
        let dividerY = ManuscriptGeometry.colophonDividerY

        // Ссылка киноварью сразу под текстом, по бокам золотые ромбы
        var refLayer = ctx
        refLayer.opacity = smooth(p / 0.5)
        let refY = min(layout.bottomY + 18, 500)
        let reference = ctx.resolve(Text(page.reference).font(PaperFont.font(size: 13, weight: .semibold)).foregroundColor(c(P.rubric)))
        let refWidth = reference.measure(in: CGSize(width: 280, height: 40)).width
        refLayer.draw(reference, at: CGPoint(x: cx, y: refY), anchor: .center)
        for side in [-1.0, 1.0] as [CGFloat] {
            let center = CGPoint(x: cx + side * (refWidth / 2 + 10), y: refY)
            var diamond = Path()
            diamond.move(to: CGPoint(x: center.x, y: center.y - 3.2))
            diamond.addLine(to: CGPoint(x: center.x + 2.4, y: center.y))
            diamond.addLine(to: CGPoint(x: center.x, y: center.y + 3.2))
            diamond.addLine(to: CGPoint(x: center.x - 2.4, y: center.y))
            diamond.closeSubpath()
            fillGold(diamond, gold: gold, in: refLayer)
        }

        // Концовка: гранат с лозами — если под текстом осталось место
        let tailTop = refY + 16
        let tailBottom = dividerY - 16
        if tailBottom - tailTop >= 64 {
            var tail = ctx
            tail.opacity = smooth((p - 0.15) / 0.5)
            drawTailpiece(center: CGPoint(x: cx, y: (tailTop + tailBottom) / 2), palette: P, gold: gold, in: tail)
        }

        // Памятная запись
        var colophon = ctx
        colophon.opacity = smooth((p - 0.3) / 0.6)
        var rule = Path()
        rule.move(to: CGPoint(x: cx - 58, y: dividerY))
        rule.addLine(to: CGPoint(x: cx - 13, y: dividerY))
        rule.move(to: CGPoint(x: cx + 13, y: dividerY))
        rule.addLine(to: CGPoint(x: cx + 58, y: dividerY))
        strokeGold(rule, width: 0.8, gold: gold, in: colophon)
        fillGold(blossomCross(center: CGPoint(x: cx, y: dividerY), size: 13), gold: gold, in: colophon)

        let lines = page.colophonLines
        var y = dividerY + 21
        let opening = ctx.resolve(Text(lines.opening).font(PaperFont.font(size: 12.5, weight: .medium)).foregroundColor(c(P.rubric)))
        colophon.draw(opening, at: CGPoint(x: cx, y: y), anchor: .center)
        y += 19
        if !lines.name.isEmpty {
            let name = ctx.resolve(Text(lines.name).font(PaperFont.font(size: 16, weight: .semibold)).foregroundColor(c(P.ink)))
            colophon.draw(name, at: CGPoint(x: cx, y: y), anchor: .center)
            y += 20
        }
        let date = ctx.resolve(Text(lines.date).font(PaperFont.font(size: 11.5)).foregroundColor(c(P.ink, 0.72)))
        colophon.draw(date, at: CGPoint(x: cx, y: y), anchor: .center)
    }

    private static func drawTailpiece(center: CGPoint, palette P: ManuscriptPalette, gold: ManuscriptGold, in ctx: GraphicsContext) {
        for side in [-1.0, 1.0] as [CGFloat] {
            var vine = Path()
            vine.move(to: CGPoint(x: center.x + side * 9, y: center.y + 2))
            vine.addCurve(
                to: CGPoint(x: center.x + side * 64, y: center.y + 1),
                control1: CGPoint(x: center.x + side * 26, y: center.y + 14),
                control2: CGPoint(x: center.x + side * 44, y: center.y - 12)
            )
            strokeGold(vine, width: 1.1, gold: gold, in: ctx)
            drawLeaf(at: CGPoint(x: center.x + side * 26, y: center.y + 8), angle: side > 0 ? 0.9 : .pi - 0.9,
                     length: 9, width: 2.7, color: c(P.leaf), gold: gold, in: ctx)
            drawLeaf(at: CGPoint(x: center.x + side * 44, y: center.y - 4), angle: side > 0 ? -0.9 : .pi + 0.9,
                     length: 9, width: 2.7, color: c(P.leaf), gold: gold, in: ctx)
            drawRosette(at: CGPoint(x: center.x + side * 68, y: center.y + 1), radius: 3.6, palette: P, gold: gold, in: ctx)
        }
        let fruit = PomegranateTreeLayout.Fruit(x: center.x, y: center.y, r: 8.5, stemX: center.x, stemY: center.y - 9, isOpen: true)
        PomegranateRenderer.drawFruit(fruit, palette: .light, lineWidth: 0.6, withStem: false, in: ctx)
    }

    // MARK: Искры на золоте
    static func drawGlints(reveal: ManuscriptReveal, initialOffsetY: CGFloat, gold: ManuscriptGold, in ctx: GraphicsContext) {
        var points: [(CGPoint, CGFloat)] = []
        let band = ManuscriptGeometry.headpiece
        if reveal.headpiece > 0.5 {
            points.append((CGPoint(x: band.midX, y: 45), 4.5))
            points.append((CGPoint(x: band.minX + 4, y: band.minY + 4), 3))
            points.append((CGPoint(x: band.maxX - 4, y: band.maxY - 4), 3))
            points.append((CGPoint(x: band.midX - 52, y: band.maxY - 2), 2.6))
            points.append((CGPoint(x: band.midX + 70, y: band.minY + 2), 2.6))
        }
        if reveal.initial > 0.6 {
            let box = ManuscriptGeometry.initialBox.offsetBy(dx: 0, dy: initialOffsetY)
            points.append((CGPoint(x: box.midX - 6, y: box.midY - 10), 4))
            points.append((CGPoint(x: box.maxX - 2, y: box.minY + 2), 2.8))
        }
        if reveal.frame > 0.95 {
            let inset = ManuscriptGeometry.frameInset
            points.append((CGPoint(x: inset, y: inset), 3.2))
            points.append((CGPoint(x: ManuscriptGeometry.size.width - inset, y: ManuscriptGeometry.size.height - inset), 3.2))
        }
        if reveal.margin > 0.95 {
            points.append((CGPoint(x: ManuscriptGeometry.marginX, y: ManuscriptGeometry.marginTop - 13), 3))
        }
        for (point, size) in points {
            let intensity = gold.glint(at: point)
            guard intensity > 0.03 else { continue }
            let s = size * (0.55 + 0.45 * intensity)
            var star = Path()
            star.move(to: CGPoint(x: point.x, y: point.y - s))
            star.addLine(to: CGPoint(x: point.x + s * 0.15, y: point.y - s * 0.15))
            star.addLine(to: CGPoint(x: point.x + s, y: point.y))
            star.addLine(to: CGPoint(x: point.x + s * 0.15, y: point.y + s * 0.15))
            star.addLine(to: CGPoint(x: point.x, y: point.y + s))
            star.addLine(to: CGPoint(x: point.x - s * 0.15, y: point.y + s * 0.15))
            star.addLine(to: CGPoint(x: point.x - s, y: point.y))
            star.addLine(to: CGPoint(x: point.x - s * 0.15, y: point.y - s * 0.15))
            star.closeSubpath()
            ctx.fill(Path(ellipseIn: circle(point, s * 0.45)), with: .color(Color.white.opacity(0.3 * intensity)))
            ctx.fill(star, with: .color(Color.white.opacity(0.9 * intensity)))
        }
    }

    // MARK: Подпись для соцсетей
    static func drawWatermark(palette P: ManuscriptPalette, in ctx: GraphicsContext) {
        let mark = ctx.resolve(Text("Luys · Armenian Bible").font(PaperFont.font(size: 8.5, weight: .semibold)).foregroundColor(c(P.ink, 0.45)))
        ctx.draw(mark, at: CGPoint(x: ManuscriptGeometry.size.width / 2, y: ManuscriptGeometry.size.height - 8), anchor: .center)
    }
}
