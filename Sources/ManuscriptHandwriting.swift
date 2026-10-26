import SwiftUI
import CoreText

// MARK: - Скорость письма пера (выбирается в настройках)
enum ManuscriptWritingSpeed: Int, CaseIterable, Identifiable {
    case slow = 0
    case medium = 1
    case fast = 2

    var id: Int { rawValue }

    static let storageKey = "luys_manuscript_writing_speed"
    static let defaultValue = ManuscriptWritingSpeed.medium

    static var current: ManuscriptWritingSpeed {
        guard let stored = UserDefaults.standard.object(forKey: storageKey) as? Int,
              let speed = ManuscriptWritingSpeed(rawValue: stored) else { return defaultValue }
        return speed
    }

    /// Секунд на один знак: столько перо выводит одну букву
    var secondsPerCharacter: Double {
        switch self {
        case .slow: return 0.20
        case .medium: return 0.12
        case .fast: return 0.07
        }
    }

    /// Границы длительности письма всего стиха: короткий не мелькает, длинный не тянется вечность
    var durationRange: ClosedRange<Double> {
        switch self {
        case .slow: return 8.0 ... 22.0
        case .medium: return 5.0 ... 13.0
        case .fast: return 3.5 ... 8.0
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .slow: return "manuscript_speed_slow".localized(for: language)
        case .medium: return "manuscript_speed_medium".localized(for: language)
        case .fast: return "manuscript_speed_fast".localized(for: language)
        }
    }
}

// MARK: - Строка настроек: скорость письма в «Рукописи»
struct ManuscriptSpeedSettingsRow: View {
    let language: AppLanguage
    let primaryTextColor: Color

    @AppStorage(ManuscriptWritingSpeed.storageKey) private var speedRaw = ManuscriptWritingSpeed.defaultValue.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Paper.gold.opacity(0.18))
                        .frame(width: 34, height: 34)

                    Image(systemName: "signature")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Paper.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("manuscript_speed_title".localized(for: language))
                        .font(PaperFont.font(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)

                    Text("manuscript_speed_desc".localized(for: language))
                        .font(PaperFont.font(size: 11.5))
                        .foregroundColor(Paper.inkSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            Picker("manuscript_speed_title".localized(for: language), selection: $speedRaw) {
                ForEach(ManuscriptWritingSpeed.allCases) { speed in
                    Text(speed.title(for: language)).tag(speed.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Буква строки: контур, по которому идёт перо
/// Контур лежит в координатах строки: начало на базовой линии у левого края строки, ось Y вниз.
struct ManuscriptGlyph {
    /// Знаки полного текста [from, to), которые пишутся этой буквой (у пробела контура нет)
    let from: Int
    let to: Int
    /// Левый край буквы и левый край следующей, чтобы вести перо по пробелу
    let x: CGFloat
    let nextX: CGFloat
    let path: Path
    /// Как перо пишет эту букву: путь вдоль штрихов и их толщина. nil — не удалось построить, буква проступает целиком
    let plan: ManuscriptStrokePlan?
    let color: Color
    /// Где перо касается буквы в начале и где отрывается в конце
    let startPoint: CGPoint
    let endPoint: CGPoint
    /// Сколько времени рука тратит на знак: длина штрихов, подход, пауза (в пунктах при ровной скорости).
    /// Сложная буква пишется дольше простой, запятая и точка заканчиваются паузой.
    let weight: CGFloat
    /// Доля времени знака на подход к первой точке (перо перелетает от прошлой буквы)
    let approachShare: CGFloat
    /// Доля времени знака в самом конце, когда перо уже оторвалось от штриха и замерло (после запятой, точки)
    let dwellShare: CGFloat

    var hasInk: Bool { !path.isEmpty }
}

/// Где и как стоит перо: кончик на странице, высота над листом (0 — пишет, 1 — высоко) и направление движения
struct ManuscriptPenPose {
    var tip: CGPoint
    var hover: CGFloat
    var heading: CGPoint
}

/// Как перо ведёт себя между буквами и на пробелах
enum ManuscriptPenRhythm {
    /// Пауза после знака препинания в пунктах пути при ровной скорости
    static func dwell(after character: unichar) -> CGFloat {
        switch character {
        case 0x2E, 0x21, 0x3F, 0x2026, 0x0589, 0x055C, 0x055E: return 14   // . ! ? … ։ ՜ ՞
        case 0x2C, 0x3B, 0x3A, 0x2013, 0x2014, 0x055D: return 8            // , ; : – — ՝
        default: return 0
        }
    }

    /// Высота скольжения пера над строкой на пробелах в долях подъёма строки
    static let glideHeight: CGFloat = 0.15
}

enum ManuscriptGlyphs {
    private struct Raw {
        let index: Int
        let x: CGFloat
        let path: Path
        let plan: ManuscriptStrokePlan?
        let color: Color
    }

    /// Раскладывает набранную строку на буквы вместе с их контурами. Контуры берутся у того шрифта,
    /// которым строка набрана на самом деле (в том числе у запасного шрифта для армянских букв).
    /// `text` — полный текст стиха: по нему видно, где знаки препинания и перо делает паузу
    static func make(line: CTLine, indexBase: Int, range: CFRange, ink: Color, text: NSString? = nil) -> [ManuscriptGlyph] {
        var raws: [Raw] = []
        let runs = (CTLineGetGlyphRuns(line) as? [CTRun]) ?? []
        for run in runs {
            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }
            let attributes = CTRunGetAttributes(run) as NSDictionary
            guard let fontValue = attributes[kCTFontAttributeName as String],
                  CFGetTypeID(fontValue as AnyObject) == CTFontGetTypeID() else { continue }
            let font = fontValue as! CTFont

            var color = ink
            if let colorValue = attributes[kCTForegroundColorAttributeName as String],
               CFGetTypeID(colorValue as AnyObject) == CGColor.typeID {
                color = Color(cgColor: colorValue as! CGColor)
            }

            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            var indices = [CFIndex](repeating: 0, count: count)
            let whole = CFRange(location: 0, length: 0)
            CTRunGetGlyphs(run, whole, &glyphs)
            CTRunGetPositions(run, whole, &positions)
            CTRunGetStringIndices(run, whole, &indices)

            for i in 0 ..< count {
                // CoreText даёт контур с осью Y вверх; переворачиваем (ось Y вниз) и сдвигаем на место буквы в строке
                var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
                var path = Path()
                var plan: ManuscriptStrokePlan?
                if let outline = CTFontCreatePathForGlyph(font, glyphs[i], &flip), !outline.isEmpty {
                    var shift = CGAffineTransform(translationX: positions[i].x, y: -positions[i].y)
                    if let placed = outline.copy(using: &shift) { path = Path(placed) }
                    // План письма зависит только от шрифта и номера глифа, поэтому считается один раз на букву
                    let key = "\(CTFontCopyPostScriptName(font) as String)|\(CTFontGetSize(font))|\(glyphs[i])"
                    plan = ManuscriptStrokePlanner.cachedPlan(key: key, outline: outline)?
                        .translated(dx: positions[i].x, dy: -positions[i].y)
                }
                raws.append(Raw(index: indices[i], x: positions[i].x, path: path, plan: plan, color: color))
            }
        }
        guard !raws.isEmpty else { return [] }
        raws.sort { $0.index < $1.index }

        let lineEnd = range.location + range.length
        var lineAscent: CGFloat = 0
        let lineWidth = CGFloat(CTLineGetTypographicBounds(line, &lineAscent, nil, nil))
        var result: [ManuscriptGlyph] = []
        // Где кончик пера после предыдущего знака: так считается длина подхода к следующей букве
        var restPoint: CGPoint?
        for (n, raw) in raws.enumerated() {
            let from = raw.index + indexBase
            // Буква пишется до тех пор, пока не начнётся следующая (буквы с общим знаком — одновременно)
            var to = lineEnd
            var nextX = lineWidth
            var m = n + 1
            while m < raws.count {
                if raws[m].index + indexBase > from {
                    to = raws[m].index + indexBase
                    nextX = raws[m].x
                    break
                }
                m += 1
            }

            var first: CGPoint?
            var last: CGPoint?
            raw.path.forEach { element in
                switch element {
                case .move(let point):
                    if first == nil { first = point }
                    last = point
                case .line(let point):
                    last = point
                case .quadCurve(let point, _):
                    last = point
                case .curve(let point, _, _):
                    last = point
                case .closeSubpath:
                    break
                @unknown default:
                    break
                }
            }
            let startPoint = raw.plan?.points.first ?? first ?? CGPoint(x: raw.x, y: 0)
            let endPoint = raw.plan?.points.last ?? last ?? startPoint

            // Время знака: подход + штрихи (+ пауза). Простая буква быстрее сложной, пробел — перелёт над строкой
            let isInked = !raw.path.isEmpty
            var approach: CGFloat = 0
            let stroke: CGFloat
            if isInked {
                let travel = restPoint.map { hypot(startPoint.x - $0.x, startPoint.y - $0.y) } ?? 12
                approach = 0.5 * travel + 4
                if let plan = raw.plan {
                    stroke = max(3, plan.totalTime * plan.pixel)
                } else {
                    stroke = 14
                }
            } else {
                // Между словами рука чуть медлит: перелёт через пробел занимает треть буквы
                stroke = 12 + 0.6 * max(0, nextX - raw.x)
            }
            var dwell: CGFloat = 0
            if let text, from >= 0, from < text.length {
                dwell = ManuscriptPenRhythm.dwell(after: text.character(at: from))
            }
            // Рука не метроном: у каждой буквы чуть своя скорость (одна и та же при каждой отрисовке)
            let rhythm = 1 + 0.07 * CGFloat(sin(Double(from) * 12.9898 + 1.3))
            let whole = approach + stroke + dwell

            result.append(ManuscriptGlyph(
                from: from, to: max(to, from + 1), x: raw.x, nextX: nextX,
                path: raw.path, plan: raw.plan, color: raw.color,
                startPoint: startPoint, endPoint: endPoint,
                weight: whole * rhythm,
                approachShare: isInked ? min(0.6, max(0.05, approach / whole)) : 0,
                dwellShare: dwell / whole
            ))
            restPoint = isInked ? endPoint : CGPoint(x: nextX, y: -lineAscent * ManuscriptPenRhythm.glideHeight)
        }
        return result
    }
}
