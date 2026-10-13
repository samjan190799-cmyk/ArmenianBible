import Foundation
import CoreGraphics
import CoreText

// Проверка планировщика письма на настоящем шрифте приложения. Запускается в CI на macOS:
//   swiftc -O Sources/ManuscriptStrokePlanner.swift Tools/StrokePlannerTest/main.swift -o stroke_test
//   ./stroke_test Sources/Fonts/NotoSerifArmenian-Regular.ttf
// Печатает таблицу по буквам и ASCII-кадры письма; код возврата 1, если покрытие или скорость плохи.

func loadFont(path: String, size: CGFloat) -> CTFont? {
    guard let provider = CGDataProvider(url: URL(fileURLWithPath: path) as CFURL),
          let cgFont = CGFont(provider) else { return nil }
    return CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
}

func outline(of character: Character, font: CTFont) -> CGPath? {
    let units = Array(String(character).utf16)
    var glyphs = [CGGlyph](repeating: 0, count: units.count)
    guard CTFontGetGlyphsForCharacters(font, units, &glyphs, units.count), glyphs[0] != 0 else { return nil }
    var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
    return CTFontCreatePathForGlyph(font, glyphs[0], &flip)
}

/// Заливка контура (и, если задано, только внутри clip) в серый растр; возвращает пиксели
func fill(_ path: CGPath, clip: CGPath?, box: CGRect, scale: CGFloat, width: Int, height: Int) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: width * height)
    pixels.withUnsafeMutableBytes { buffer in
        guard let context = CGContext(
            data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return }
        var t = CGAffineTransform(a: scale, b: 0, c: 0, d: -scale,
                                  tx: 4 - box.minX * scale, ty: CGFloat(height) - 4 + box.minY * scale)
        context.setFillColor(gray: 1, alpha: 1)
        if let clip, let placedClip = clip.copy(using: &t), let placed = path.copy(using: &t) {
            context.addPath(placed)
            context.clip()
            context.addPath(placedClip)
            context.fillPath()
        } else if let placed = path.copy(using: &t) {
            context.addPath(placed)
            context.fillPath()
        }
    }
    return pixels
}

func coverage(of plan: ManuscriptStrokePlan, outline: CGPath, progress: CGFloat) -> Double {
    let box = outline.boundingBoxOfPath
    let scale = 240 / max(box.width, box.height)
    let width = Int(box.width * scale) + 8
    let height = Int(box.height * scale) + 8
    let whole = fill(outline, clip: nil, box: box, scale: scale, width: width, height: height)
    // Заливка маски ограничивается контуром буквы: так рисует приложение
    let inked = fill(outline, clip: plan.inkMask(at: progress), box: box, scale: scale, width: width, height: height)
    let total = whole.reduce(0) { $0 + Int($1) }
    let part = inked.reduce(0) { $0 + Int($1) }
    return total > 0 ? Double(part) / Double(total) : 1
}

func ascii(plan: ManuscriptStrokePlan, outline: CGPath, progress: CGFloat, columns: Int = 34) -> [String] {
    let box = outline.boundingBoxOfPath
    let scale = CGFloat(columns) / max(box.width, box.height)
    let width = Int(box.width * scale) + 8
    let height = Int(box.height * scale / 2) + 8
    // Растр вдвое сжат по высоте: символы выше, чем шире
    let whole = fill(outline, clip: nil, box: box, scale: scale, width: width, height: Int(box.height * scale) + 8)
    let inked = fill(outline, clip: plan.inkMask(at: progress), box: box, scale: scale, width: width, height: Int(box.height * scale) + 8)
    var rows: [String] = []
    let fullHeight = Int(box.height * scale) + 8
    _ = height
    var y = 0
    while y + 1 < fullHeight {
        var line = ""
        for x in 0 ..< width {
            let a = Int(whole[y * width + x]) + Int(whole[(y + 1) * width + x])
            let b = Int(inked[y * width + x]) + Int(inked[(y + 1) * width + x])
            line += a == 0 ? " " : (b * 2 >= a ? "#" : ".")
        }
        rows.append(line)
        y += 2
    }
    return rows
}

let args = CommandLine.arguments
guard args.count >= 2, let font = loadFont(path: args[1], size: 100) else {
    print("нет шрифта")
    exit(2)
}

let armenian = "ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖաբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆ"
var results: [(Character, Int, Double, Int)] = []
var failures: [String] = []
let started = Date()
var plans: [Character: (ManuscriptStrokePlan, CGPath)] = [:]

for character in armenian {
    guard let path = outline(of: character, font: font) else {
        failures.append("нет контура \(character)")
        continue
    }
    let t0 = Date()
    guard let plan = ManuscriptStrokePlanner.plan(outline: path) else {
        failures.append("нет плана \(character)")
        continue
    }
    let ms = Int(Date().timeIntervalSince(t0) * 1000)
    let full = coverage(of: plan, outline: path, progress: 1)
    let strokes = 1 + plan.inked.dropFirst().filter { !$0 }.count
    results.append((character, strokes, full, ms))
    plans[character] = (plan, path)
    if full < 0.97 { failures.append("покрытие \(character) = \(String(format: "%.3f", full))") }
}
let elapsed = Date().timeIntervalSince(started)

for r in results {
    print("\(r.0) штрихов \(r.1) покрытие \(String(format: "%.3f", r.2)) \(r.3) мс")
}
let mean = results.map { $0.2 }.reduce(0, +) / Double(max(1, results.count))
let strokeMean = Double(results.map { $0.1 }.reduce(0, +)) / Double(max(1, results.count))
print("букв: \(results.count), среднее покрытие \(String(format: "%.4f", mean)), штрихов в среднем \(String(format: "%.2f", strokeMean)), всего \(Int(elapsed * 1000)) мс")

// Кадры письма: покрытие растёт монотонно, перо идёт по штриху
for sample in ["Ա", "ա", "թ"] {
    guard let character = sample.first, let (plan, path) = plans[character] else { continue }
    var last = 0.0
    var monotonic = true
    for step in 0 ... 20 {
        let c = coverage(of: plan, outline: path, progress: CGFloat(step) / 20)
        if c + 0.001 < last { monotonic = false }
        last = c
    }
    if !monotonic { failures.append("покрытие \(sample) не растёт монотонно") }
    for progress in [0.25, 0.5, 0.75, 1.0] {
        print("--- \(sample) \(Int(progress * 100))% ---")
        for row in ascii(plan: plan, outline: path, progress: CGFloat(progress)) { print(row) }
    }
}

// Скорость: вся страница на ~250 уникальных букв считается мгновенно благодаря кэшу
if elapsed > 3 { failures.append("слишком медленно: \(elapsed) с") }
if mean < 0.99 { failures.append("среднее покрытие \(mean) ниже 0.99") }

if failures.isEmpty {
    print("ИТОГ: всё хорошо")
} else {
    print("ИТОГ: ошибки")
    failures.forEach { print(" - \($0)") }
    exit(1)
}
