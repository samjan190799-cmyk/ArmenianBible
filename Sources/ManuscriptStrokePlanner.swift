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
    /// «Время» к каждой точке: длина пути в пикселях растра с поправкой на скорость руки (разгон, изгибы),
    /// перелёты считаются дешевле, чем письмо
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

    /// Положение кончика, высота пера над листом и направление движения к моменту progress (0…1).
    /// На перелётах перо поднято дугой: чем длиннее перелёт, тем выше.
    func pose(at progress: CGFloat) -> (tip: CGPoint, hover: CGFloat, heading: CGPoint) {
        let reached = position(at: progress)
        guard reached.index + 1 < points.count else { return (reached.tip, 0, .zero) }

        let from = points[reached.index]
        let to = points[reached.index + 1]
        let length = hypot(to.x - from.x, to.y - from.y)
        let heading = length > 0.0001 ? CGPoint(x: (to.x - from.x) / length, y: (to.y - from.y) / length) : CGPoint.zero

        var hover: CGFloat = 0
        if !inked[reached.index + 1] {
            let span = timeline[reached.index + 1] - timeline[reached.index]
            let k = span > 0 ? (min(1, max(0, progress)) * totalTime - timeline[reached.index]) / span : 0
            hover = sin(CGFloat.pi * min(1, max(0, k))) * min(1, length / (10 * pixel))
        }
        return (reached.tip, hover, heading)
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
/// Контур рисуется в маленький растр, скелетизуется (Жанг–Суэн), по скелету перо ведётся обходом,
/// как у руки (см. `walk`), а толщина штриха берётся из карты расстояний до края (дискретная медиальная ось).
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

        // Пиксели растра → точки пути; соседние точки усредняются, чтобы убрать «ступеньки»
        var rasterPoints: [CGPoint] = []
        var radii: [CGFloat] = []
        var inked: [Bool] = []
        for step in order {
            rasterPoints.append(CGPoint(x: CGFloat(step.x) + 0.5, y: CGFloat(step.y) + 0.5))
            radii.append(CGFloat(distance[step.y * width + step.x]) / scale)
            inked.append(!step.lifted)
        }
        rasterPoints = smoothed(rasterPoints, inked: inked)
        let timeline = handwritingTimeline(points: rasterPoints, inked: inked)
        // Растр → координаты контура
        let points = rasterPoints.map { point in
            CGPoint(x: box.minX + (point.x - CGFloat(padding)) / scale,
                    y: box.minY + (point.y - CGFloat(padding)) / scale)
        }
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

    /// Возвращаться по уже написанному можно, если путь по скелету не длиннее этого (в пикселях растра)
    private static let retraceLimit = 10.0
    /// … или если он не длиннее прямого перелёта больше чем в столько раз
    private static let retraceRatio = 1.3

    /// Обход как у руки: старт сверху слева (замкнутая линия — сверху и против часовой стрелки),
    /// дальше прямо, пока есть куда. Упёрлись: короткую ветку (засечку, ушко) рука пишет туда и обратно,
    /// не отрывая пера; далёкую — отрывает перо и садится на конец следующей ветки.
    private static func walk(_ skeleton: [UInt8], width: Int, height: Int) -> [Step] {
        var cells: [Int] = []
        for i in 0 ..< skeleton.count where skeleton[i] != 0 { cells.append(i) }
        guard !cells.isEmpty else { return [] }

        // Соседи каждой клетки скелета
        var adjacency = [[Int]](repeating: [], count: skeleton.count)
        for index in cells {
            let x = index % width, y = index / width
            for n in neighbours {
                let nx = x + n.dx, ny = y + n.dy
                if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                let j = ny * width + nx
                if skeleton[j] != 0 { adjacency[index].append(j) }
            }
        }

        var heading: (dy: Int, dx: Int)?
        var current = cells[0]
        let ends = cells.filter { adjacency[$0].count == 1 }
        if ends.isEmpty {
            // Замкнутая линия («о», «О»): начинаем сверху у середины и идём влево, против часовой стрелки
            let top = cells.map { $0 / width }.min() ?? 0
            let middle = Double(cells.map { $0 % width }.reduce(0, +)) / Double(cells.count)
            let topRow = cells.filter { $0 / width <= top + 1 }
            current = topRow.min { abs(Double($0 % width) - middle) < abs(Double($1 % width) - middle) } ?? cells[0]
            heading = (0, -1)
        } else {
            func startRank(_ i: Int) -> Double { Double(i / width) + 0.35 * Double(i % width) }
            current = ends.min { startRank($0) < startRank($1) } ?? cells[0]
        }

        var visited = [Bool](repeating: false, count: skeleton.count)
        visited[current] = true
        var steps: [Step] = [Step(x: current % width, y: current / width, lifted: false)]
        var left = cells.count - 1

        // Локальные функции объявлены после visited: они его захватывают
        func unvisitedNeighbours(of index: Int) -> [Int] {
            adjacency[index].filter { !visited[$0] }
        }
        /// Связный кусок ненаписанного скелета, в котором лежит start
        func unvisitedPiece(from start: Int) -> [Int] {
            var seen: Set<Int> = [start]
            var piece = [start]
            var stack = [start]
            while let head = stack.popLast() {
                for j in unvisitedNeighbours(of: head) where !seen.contains(j) {
                    seen.insert(j)
                    piece.append(j)
                    stack.append(j)
                }
            }
            return piece
        }
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
        /// Кратчайший путь по скелету (в том числе по написанному) до ближайшей ненаписанной клетки
        func pathToUnvisited(from source: Int) -> (length: Double, path: [Int])? {
            var best = [Double](repeating: .infinity, count: skeleton.count)
            var previous = [Int](repeating: -1, count: skeleton.count)
            var done = [Bool](repeating: false, count: skeleton.count)
            best[source] = 0
            while true {
                var pick = -1
                var pickDistance = Double.infinity
                for c in cells where !done[c] && best[c] < pickDistance {
                    pick = c
                    pickDistance = best[c]
                }
                if pick < 0 { return nil }
                if pick != source && !visited[pick] {
                    var path = [pick]
                    while path[path.count - 1] != source { path.append(previous[path[path.count - 1]]) }
                    path.reverse()
                    return (pickDistance, path)
                }
                done[pick] = true
                for n in adjacency[pick] {
                    let sideways = n % width == pick % width || n / width == pick / width
                    let candidate = pickDistance + (sideways ? 1 : 1.4142)
                    if candidate < best[n] {
                        best[n] = candidate
                        previous[n] = pick
                    }
                }
            }
        }

        while left > 0 {
            let options = unvisitedNeighbours(of: current)
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

            // Упёрлись. Ближайшее ненаписанное место достижимо по скелету?
            if let found = pathToUnvisited(from: current) {
                let target = found.path[found.path.count - 1]
                // Обрывок в один-два пикселя возле пройденного пути — мусор от утончения; такой же обрывок
                // вдали от пути — самостоятельная точка (над «i», в двоеточии), её надо писать
                let piece = unvisitedPiece(from: target)
                if piece.count < 3 && touchesVisited(piece) {
                    for j in piece { visited[j] = true }
                    left -= piece.count
                    continue
                }
                let straight = hypot(Double(target % width - current % width), Double(target / width - current / width))
                if found.length <= retraceLimit || found.length <= retraceRatio * straight + 2 {
                    // Возвращаемся по уже написанному, перо не отрывается
                    for index in found.path.dropFirst() {
                        steps.append(Step(x: index % width, y: index / width, lifted: false))
                    }
                    current = target
                    visited[current] = true
                    left -= 1
                    heading = nil
                    continue
                }
            }

            // Перо отрывается и садится на конец ближайшей ненаписанной ветки: посадка в середину
            // ветки потребовала бы ещё одного перелёта
            let pending = cells.filter { !visited[$0] }
            let chainEnds = pending.filter { unvisitedNeighbours(of: $0).count <= 1 }
            let pool = chainEnds.isEmpty ? pending : chainEnds
            func landingCost(_ i: Int) -> Double {
                let dx = Double(i % width - current % width)
                let dy = Double(i / width - current / width)
                return (dx * dx + dy * dy).squareRoot() + 0.04 * (Double(i / width) + 0.35 * Double(i % width))
            }
            guard let chosen = pool.min(by: { landingCost($0) < landingCost($1) }) else { break }
            let piece = unvisitedPiece(from: chosen)
            if piece.count < 3 && touchesVisited(piece) {
                for j in piece { visited[j] = true }
                left -= piece.count
                continue
            }
            current = chosen
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

    // MARK: Время письма
    /// Время к каждой точке в единицах длины растра при ровной скорости руки. Рука идёт неравномерно:
    /// в начале и в конце штриха медленнее (разгон и торможение), на крутых изгибах тоже — скорость
    /// обратна кривизне в степени 1/3 («закон двух третей» из исследований почерка). Перелёты быстрее письма.
    private static func handwritingTimeline(points: [CGPoint], inked: [Bool]) -> [CGFloat] {
        let count = points.count
        var timeline = [CGFloat](repeating: 0, count: count)
        guard count > 1 else { return timeline }

        // Штрих — подряд идущие точки на бумаге; новый штрих начинается с посадки после перелёта
        var strokeStart = [Int](repeating: 0, count: count)
        var strokeEnd = [Int](repeating: count - 1, count: count)
        var begin = 0
        for i in 0 ..< count {
            if i > 0 && !inked[i] { begin = i }
            strokeStart[i] = begin
        }
        var finish = count - 1
        for i in stride(from: count - 1, through: 0, by: -1) {
            strokeEnd[i] = finish
            if !inked[i] { finish = i - 1 }
        }

        // Длина штриха от его начала до каждой точки
        var arc = [CGFloat](repeating: 0, count: count)
        for i in 1 ..< count where strokeStart[i] != i {
            arc[i] = arc[i - 1] + hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
        }

        func speed(at i: Int) -> CGFloat {
            let total = arc[strokeEnd[i]]
            // Разгон и торможение на краях штриха: перо трогается с места не мгновенно
            var easing: CGFloat = 1
            let ramp = min(8, total / 2)
            if ramp > 0.001 {
                let edge = min(1, max(0, min(arc[i], total - arc[i]) / ramp))
                easing = 0.55 + 0.45 * (edge * edge * (3 - 2 * edge))
            }
            // Кривизна по точкам через одну-две в стороне, в пределах штриха
            var curve: CGFloat = 1
            let a = max(strokeStart[i], i - 2)
            let b = min(strokeEnd[i], i + 2)
            if a < i && i < b {
                let ux = points[i].x - points[a].x, uy = points[i].y - points[a].y
                let vx = points[b].x - points[i].x, vy = points[b].y - points[i].y
                let lu = hypot(ux, uy), lv = hypot(vx, vy)
                if lu > 0.01 && lv > 0.01 {
                    let turn = abs(atan2(ux * vy - uy * vx, ux * vx + uy * vy))
                    let curvature = turn / ((lu + lv) / 2)
                    curve = min(1, max(0.5, pow(1 + 8 * curvature, -1.0 / 3.0)))
                }
            }
            return easing * curve
        }

        var clock: CGFloat = 0
        for i in 1 ..< count {
            let length = hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
            if inked[i] {
                clock += length / max(0.3, (speed(at: i - 1) + speed(at: i)) / 2)
            } else {
                // Перелёт: перо в воздухе, вдвое быстрее письма, плюс короткая пауза на подъём
                clock += 0.5 * length + 4
            }
            timeline[i] = clock
        }
        return timeline
    }
}
