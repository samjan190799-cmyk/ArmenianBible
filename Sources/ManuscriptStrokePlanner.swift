import Foundation
import CoreGraphics

// MARK: - План письма одной буквы
/// Путь кончика пера внутри контура буквы. Перо идёт вдоль осевой линии штрихов, а чернила
/// ложатся кругами по толщине контура в каждой точке, поэтому буква проступает ровно там,
/// где перо уже прошло.
struct ManuscriptStrokePlan {
    /// Точки пути пера в координатах контура (ось Y вниз)
    var points: [CGPoint]
    /// Половина толщины контура в каждой точке
    var radii: [CGFloat]
    /// true: от предыдущей точки перо идёт по бумаге и оставляет след; false: перо поднято и перелетает
    var inked: [Bool]
    /// «Время» к каждой точке: длина пути в пикселях растра, перелёты считаются дешевле, чем письмо
    var timeline: [CGFloat]
    /// Размер одного пикселя растра в координатах контура
    var pixel: CGFloat

    var totalTime: CGFloat { timeline.last ?? 0 }

    func translated(dx: CGFloat, dy: CGFloat) -> ManuscriptStrokePlan {
        var copy = self
        copy.points = points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
        return copy
    }

    /// Номер последней точки, до которой перо дошло к моменту progress (0…1), и положение кончика
    func position(at progress: CGFloat) -> (index: Int, tip: CGPoint) {
        guard !points.isEmpty else { return (0, .zero) }
        let target = min(1, max(0, progress)) * totalTime
        var index = 0
        while index + 1 < points.count && timeline[index + 1] <= target { index += 1 }
        guard index + 1 < points.count else { return (index, points[index]) }
        let span = timeline[index + 1] - timeline[index]
        let k = span > 0 ? (target - timeline[index]) / span : 0
        let from = points[index]
        let to = points[index + 1]
        return (index, CGPoint(x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k))
    }

    /// Область, уже закрашенная пером: круги вдоль пройденных участков. Буква рисуется только внутри неё.
    /// Круги чуть шире штриха (в 1.25 раза и ещё на 0.7 пикселя), чтобы между ними не оставалось щелей.
    func inkMask(at progress: CGFloat) -> CGPath {
        let growth: CGFloat = 1.25
        let extra = 0.7 * pixel
        let mask = CGMutablePath()
        guard !points.isEmpty else { return mask }
        let reached = position(at: progress)
        func dab(_ center: CGPoint, _ radius: CGFloat) {
            let r = radius * growth + extra
            mask.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        }
        // Перо ставит круг в каждой точке, куда уже пришло: в том числе в начале штриха после перелёта.
        // Одиночная точка (над «i», в двоеточии) состоит только из такого круга.
        var i = 0
        while i <= reached.index {
            dab(points[i], radii[i])
            i += 1
        }
        if reached.index + 1 < points.count, inked[reached.index + 1] {
            let next = reached.index + 1
            let span = timeline[next] - timeline[reached.index]
            let k = span > 0 ? (min(1, max(0, progress)) * totalTime - timeline[reached.index]) / span : 0
            dab(reached.tip, radii[reached.index] + (radii[next] - radii[reached.index]) * k)
        }
        return mask
    }
}

// MARK: - Построение плана
/// Контур рисуется в маленький растр, скелетизуется (Жанг–Суэн), по скелету перо ведётся жадным
/// обходом, а толщина штриха берётся из карты расстояний до края (дискретная медиальная ось).
enum ManuscriptStrokePlanner {
    static let rasterSize = 64
    private static let padding = 3

    private static let neighbours: [(dy: Int, dx: Int)] = [
        (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)
    ]

    private static let cacheLock = NSLock()
    private static var cache: [String: ManuscriptStrokePlan] = [:]
    private static var emptyKeys: Set<String> = []

    /// План для буквы, посчитанный один раз на сочетание шрифта, размера и номера глифа
    static func cachedPlan(key: String, outline: @autoclosure () -> CGPath) -> ManuscriptStrokePlan? {
        cacheLock.lock()
        if let hit = cache[key] {
            cacheLock.unlock()
            return hit
        }
        if emptyKeys.contains(key) {
            cacheLock.unlock()
            return nil
        }
        cacheLock.unlock()

        let made = plan(outline: outline())
        cacheLock.lock()
        if cache.count > 600 { cache.removeAll() }
        if let made { cache[key] = made } else { emptyKeys.insert(key) }
        cacheLock.unlock()
        return made
    }

    static func plan(outline: CGPath) -> ManuscriptStrokePlan? {
        let box = outline.boundingBoxOfPath
        guard !box.isNull, !box.isInfinite, box.width > 0.001 || box.height > 0.001 else { return nil }
        let scale = CGFloat(rasterSize) / max(box.width, box.height)
        let width = Int((box.width * scale).rounded(.up)) + 2 * padding
        let height = Int((box.height * scale).rounded(.up)) + 2 * padding

        guard var ink = rasterize(outline, box: box, scale: scale, width: width, height: height) else { return nil }
        let distance = distances(ink, width: width, height: height)
        let original = ink
        thin(&ink, width: width, height: height)
        keepVanishedShapes(original: original, skeleton: &ink, distance: distance, width: width, height: height)
        let order = walk(ink, width: width, height: height)
        guard !order.isEmpty else { return nil }

        // Пиксели растра → координаты контура; соседние точки усредняются, чтобы убрать «ступеньки»
        var points: [CGPoint] = []
        var radii: [CGFloat] = []
        var inked: [Bool] = []
        var timeline: [CGFloat] = []
        var clock: CGFloat = 0
        var previous: (x: Int, y: Int)?
        for step in order {
            if let before = previous {
                let length = hypot(CGFloat(step.x - before.x), CGFloat(step.y - before.y))
                // Перелёт: перо в воздухе, вдвое быстрее письма, плюс короткая пауза на подъём
                clock += step.lifted ? 0.5 * length + 4 : length
            }
            previous = (step.x, step.y)
            let px = CGFloat(step.x) + 0.5
            let py = CGFloat(step.y) + 0.5
            points.append(CGPoint(x: box.minX + (px - CGFloat(padding)) / scale,
                                  y: box.minY + (py - CGFloat(padding)) / scale))
            radii.append(CGFloat(distance[step.y * width + step.x]) / scale)
            inked.append(!step.lifted)
            timeline.append(clock)
        }
        points = smoothed(points, inked: inked)
        return ManuscriptStrokePlan(points: points, radii: radii, inked: inked, timeline: timeline, pixel: 1 / scale)
    }

    // MARK: Растр
    private static func rasterize(_ outline: CGPath, box: CGRect, scale: CGFloat, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            // Контур с осью Y вниз кладётся в растр так, чтобы верх буквы был в первой строке памяти
            var transform = CGAffineTransform(
                a: scale, b: 0, c: 0, d: -scale,
                tx: CGFloat(padding) - box.minX * scale,
                ty: CGFloat(height) - CGFloat(padding) + box.minY * scale
            )
            guard let placed = outline.copy(using: &transform) else { return false }
            context.setFillColor(gray: 1, alpha: 1)
            context.addPath(placed)
            context.fillPath()
            return true
        }
        guard drawn else { return nil }
        return pixels.map { $0 > 127 ? 1 : 0 }
    }

    /// Расстояние до фона (хэмфер 3-4), в пикселях
    private static func distances(_ ink: [UInt8], width: Int, height: Int) -> [Float] {
        let far: Int32 = 1_000_000
        var d = ink.map { $0 > 0 ? far : 0 }
        for y in 0 ..< height {
            for x in 0 ..< width {
                let i = y * width + x
                if d[i] == 0 { continue }
                var v = d[i]
                if x > 0 { v = min(v, d[i - 1] + 3) }
                if y > 0 {
                    v = min(v, d[i - width] + 3)
                    if x > 0 { v = min(v, d[i - width - 1] + 4) }
                    if x < width - 1 { v = min(v, d[i - width + 1] + 4) }
                }
                d[i] = v
            }
        }
        for y in stride(from: height - 1, through: 0, by: -1) {
            for x in stride(from: width - 1, through: 0, by: -1) {
                let i = y * width + x
                if d[i] == 0 { continue }
                var v = d[i]
                if x < width - 1 { v = min(v, d[i + 1] + 3) }
                if y < height - 1 {
                    v = min(v, d[i + width] + 3)
                    if x < width - 1 { v = min(v, d[i + width + 1] + 4) }
                    if x > 0 { v = min(v, d[i + width - 1] + 4) }
                }
                d[i] = v
            }
        }
        return d.map { Float($0) / 3 }
    }

    // MARK: Скелет (Жанг–Суэн)
    private static func thin(_ ink: inout [UInt8], width: Int, height: Int) {
        func rise(_ a: UInt8, _ b: UInt8) -> Int { a == 0 && b == 1 ? 1 : 0 }
        var removal: [Int] = []
        var changed = true
        while changed {
            changed = false
            for step in 0 ..< 2 {
                removal.removeAll(keepingCapacity: true)
                for y in 1 ..< height - 1 {
                    for x in 1 ..< width - 1 {
                        let i = y * width + x
                        if ink[i] == 0 { continue }
                        let p2 = ink[i - width], p3 = ink[i - width + 1], p4 = ink[i + 1], p5 = ink[i + width + 1]
                        let p6 = ink[i + width], p7 = ink[i + width - 1], p8 = ink[i - 1], p9 = ink[i - width - 1]
                        let around = Int(p2) + Int(p3) + Int(p4) + Int(p5) + Int(p6) + Int(p7) + Int(p8) + Int(p9)
                        if around < 2 || around > 6 { continue }
                        let turns = rise(p2, p3) + rise(p3, p4) + rise(p4, p5) + rise(p5, p6)
                            + rise(p6, p7) + rise(p7, p8) + rise(p8, p9) + rise(p9, p2)
                        if turns != 1 { continue }
                        if step == 0 {
                            if (p2 & p4 & p6) != 0 || (p4 & p6 & p8) != 0 { continue }
                        } else {
                            if (p2 & p4 & p8) != 0 || (p2 & p6 & p8) != 0 { continue }
                        }
                        removal.append(i)
                    }
                }
                if !removal.isEmpty { changed = true }
                for i in removal { ink[i] = 0 }
            }
        }
    }

    /// Точка над «i», двоеточие, диерезис: маленькое пятно при утончении может исчезнуть целиком.
    /// В каждом связном куске, где скелета не осталось, оставляем пиксель, самый далёкий от края.
    private static func keepVanishedShapes(original: [UInt8], skeleton: inout [UInt8], distance: [Float],
                                           width: Int, height: Int) {
        var seen = [Bool](repeating: false, count: original.count)
        for start in 0 ..< original.count where original[start] != 0 && !seen[start] {
            var stack = [start]
            seen[start] = true
            var hasSkeleton = false
            var deepest = start
            while let index = stack.popLast() {
                if skeleton[index] != 0 { hasSkeleton = true }
                if distance[index] > distance[deepest] { deepest = index }
                let x = index % width, y = index / width
                for n in neighbours {
                    let nx = x + n.dx, ny = y + n.dy
                    if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                    let j = ny * width + nx
                    if original[j] != 0 && !seen[j] {
                        seen[j] = true
                        stack.append(j)
                    }
                }
            }
            if !hasSkeleton { skeleton[deepest] = 1 }
        }
    }

    // MARK: Обход скелета
    private struct Step {
        let x: Int
        let y: Int
        /// Перо поднято: к этой точке оно перелетело
        let lifted: Bool
    }

    /// Жадный обход: идём прямо, пока есть куда; упёрлись, поднимаем перо и ставим его
    /// у ближайшего ненаписанного места. Начало: верхний левый конец скелета.
    private static func walk(_ skeleton: [UInt8], width: Int, height: Int) -> [Step] {
        var cells: [Int] = []
        for i in 0 ..< skeleton.count where skeleton[i] != 0 { cells.append(i) }
        guard !cells.isEmpty else { return [] }

        func unvisitedNeighbours(of index: Int, _ visited: [Bool]) -> [Int] {
            let x = index % width, y = index / width
            var found: [Int] = []
            for n in neighbours {
                let nx = x + n.dx, ny = y + n.dy
                if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                let j = ny * width + nx
                if skeleton[j] != 0 && !visited[j] { found.append(j) }
            }
            return found
        }
        func neighbourCount(of index: Int) -> Int {
            let x = index % width, y = index / width
            var count = 0
            for n in neighbours {
                let nx = x + n.dx, ny = y + n.dy
                if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                if skeleton[ny * width + nx] != 0 { count += 1 }
            }
            return count
        }

        let ends = cells.filter { neighbourCount(of: $0) == 1 }
        let candidates = ends.isEmpty ? cells : ends
        func startRank(_ i: Int) -> Double { Double(i / width) + 0.35 * Double(i % width) }
        var current = candidates.min { startRank($0) < startRank($1) } ?? cells[0]

        var visited = [Bool](repeating: false, count: skeleton.count)
        // Объявлена после visited: локальная функция не может захватить переменную раньше её объявления
        func touchesVisited(_ pixels: [Int]) -> Bool {
            for p in pixels {
                let x = p % width, y = p / width
                for dy in -2 ... 2 {
                    for dx in -2 ... 2 {
                        let nx = x + dx, ny = y + dy
                        if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                        if visited[ny * width + nx] { return true }
                    }
                }
            }
            return false
        }
        var steps: [Step] = [Step(x: current % width, y: current / width, lifted: false)]
        visited[current] = true
        var heading: (dy: Int, dx: Int)?
        var left = cells.count - 1

        while left > 0 {
            let options = unvisitedNeighbours(of: current, visited)
            if !options.isEmpty {
                var best = options[0]
                var bestScore = -Double.infinity
                for option in options {
                    let dy = option / width - current / width
                    let dx = option % width - current % width
                    let length = (Double(dy * dy + dx * dx)).squareRoot()
                    var score = 0.0
                    if let h = heading {
                        score = (Double(dy * h.dy + dx * h.dx)) / (length * (Double(h.dy * h.dy + h.dx * h.dx)).squareRoot())
                    }
                    if length > 1 { score -= 0.05 }   // прямые шаги чище диагональных
                    if score > bestScore { bestScore = score; best = option }
                }
                heading = (best / width - current / width, best % width - current % width)
                current = best
                visited[current] = true
                left -= 1
                steps.append(Step(x: current % width, y: current / width, lifted: false))
                continue
            }

            // Упёрлись: ближайший ненаписанный пиксель; крошечные обрывки возле пути пропускаем
            let cx = current % width, cy = current / width
            var nearest = -1
            var nearestDistance = Int.max
            for i in cells where !visited[i] {
                let dx = i % width - cx, dy = i / width - cy
                let d2 = dx * dx + dy * dy
                if d2 < nearestDistance { nearestDistance = d2; nearest = i }
            }
            if nearest < 0 { break }

            var crumb = [nearest]
            var seen: Set<Int> = [nearest]
            var queue = [nearest]
            while let head = queue.popLast() {
                for j in unvisitedNeighbours(of: head, visited) where !seen.contains(j) {
                    seen.insert(j)
                    crumb.append(j)
                    queue.append(j)
                }
            }
            // Обрывок в один-два пикселя возле пройденного пути — мусор от утончения; такой же обрывок
            // вдали от пути — самостоятельная точка (над «i», в двоеточии), её надо писать
            if crumb.count < 3 && touchesVisited(crumb) {
                for j in crumb { visited[j] = true }
                left -= crumb.count
                continue
            }
            current = nearest
            visited[current] = true
            left -= 1
            heading = nil
            steps.append(Step(x: current % width, y: current / width, lifted: true))
        }
        return steps
    }

    /// Пятиточечное скользящее среднее по каждому штриху (на перелётах точки не трогаем)
    private static func smoothed(_ points: [CGPoint], inked: [Bool]) -> [CGPoint] {
        guard points.count > 4 else { return points }
        var result = points
        for i in 0 ..< points.count {
            var sx: CGFloat = 0, sy: CGFloat = 0, n: CGFloat = 0
            for j in max(0, i - 2) ... min(points.count - 1, i + 2) {
                // Окно не переходит через перелёт: у такой точки inked == false на границе
                if j != i {
                    let lo = min(i, j), hi = max(i, j)
                    var crosses = false
                    for k in (lo + 1) ... hi where !inked[k] { crosses = true }
                    if crosses { continue }
                }
                sx += points[j].x
                sy += points[j].y
                n += 1
            }
            result[i] = CGPoint(x: sx / n, y: sy / n)
        }
        return result
    }
}
