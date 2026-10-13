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
        case .slow: return 0.14
        case .medium: return 0.09
        case .fast: return 0.05
        }
    }

    /// Границы длительности письма всего стиха: короткий не мелькает, длинный не тянется вечность
    var durationRange: ClosedRange<Double> {
        switch self {
        case .slow: return 6.0 ... 16.0
        case .medium: return 4.0 ... 10.0
        case .fast: return 2.8 ... 7.1
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
    let color: Color
    /// Где перо касается буквы в начале и где отрывается в конце
    let startPoint: CGPoint
    let endPoint: CGPoint

    var hasInk: Bool { !path.isEmpty }
}

enum ManuscriptGlyphs {
    private struct Raw {
        let index: Int
        let x: CGFloat
        let path: Path
        let color: Color
    }

    /// Раскладывает набранную строку на буквы вместе с их контурами. Контуры берутся у того шрифта,
    /// которым строка набрана на самом деле (в том числе у запасного шрифта для армянских букв).
    static func make(line: CTLine, indexBase: Int, range: CFRange, ink: Color) -> [ManuscriptGlyph] {
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
                // CoreText даёт контур с осью Y вверх; переворачиваем и сдвигаем на место буквы в строке
                var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: positions[i].x, ty: -positions[i].y)
                var path = Path()
                if let outline = CTFontCreatePathForGlyph(font, glyphs[i], &flip) {
                    path = Path(outline)
                }
                raws.append(Raw(index: indices[i], x: positions[i].x, path: path, color: color))
            }
        }
        guard !raws.isEmpty else { return [] }
        raws.sort { $0.index < $1.index }

        let lineEnd = range.location + range.length
        let lineWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        var result: [ManuscriptGlyph] = []
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
            let startPoint = first ?? CGPoint(x: raw.x, y: 0)
            result.append(ManuscriptGlyph(
                from: from, to: max(to, from + 1), x: raw.x, nextX: nextX,
                path: raw.path, color: raw.color,
                startPoint: startPoint, endPoint: last ?? startPoint
            ))
        }
        return result
    }
}
