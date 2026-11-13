import SwiftUI

// MARK: - Миниатюры разделов на главном экране
/// Плитка-картинка слева на карточке раздела, как у «Моего Матенадарана» и Гранатового древа.
/// Каждая миниатюра описана списком фигур на поле 68×68 (начало в левом верхнем углу).
/// Строка: «стиль ; фигура».
/// Стиль: `f=` заливка, `s=` обводка, `w=` толщина, `cap` скруглённые концы, `o=` прозрачность.
/// Заливка: `#RRGGBB[@альфа]`, `lg(x0,y0,x1,y1,цвета…)` линейный или `rg(cx,cy,r,цвета…)` круговой градиент.
/// Фигура: `p` путь из команд M L Q C Z, `c cx cy r` круг, `e cx cy rx ry` эллипс, `r x y w h радиус` прямоугольник.
enum HomeTileArt: String, CaseIterable {
    /// Книга скорбных песнопений: переплёт с золотым крестом и застёжками
    case narek
    /// «Нарек утешает»: раскрытый молитвенник и сердце
    case consolation
    /// Рождество: звезда над вертепом
    case nativity
    /// Храмовые свечи в песке
    case candles
    /// План чтения: свиток с отмеченными днями
    case plan
    /// Викторина: лист с вопросом
    case quiz
    /// Церковный календарь: отрывной лист, число дня рисуется поверх
    case calendar
    /// Карта святынь: храм на фоне Арарата
    case map
    /// Premium: золотой венец
    case premium

    var script: String {
        switch self {
        case .narek:
            return """
            f=rg(34,34,36,#C9A45C@0.26,#C9A45C@0) ; r 0 0 68 68 0
            f=#1A0D0A@0.55 ; e 36 59 19 3
            f=lg(22,14,52,58,#F1E3C2,#C9B58A) s=#2B241D@0.55 w=0.6 ; r 22 15 31 43 2
            s=#2B241D@0.28 w=0.5 ; p M 50.6 18 L 50.6 55
            s=#2B241D@0.28 w=0.5 ; p M 51.8 18 L 51.8 55
            s=#2B241D@0.28 w=0.5 ; p M 24 56.6 L 51 56.6
            f=lg(18,12,48,56,#9A2E25,#5A1712) s=#2B120E w=0.7 ; r 18 12 31 43 2.5
            f=#3D0F0B@0.75 ; r 18 12 5.5 43 2.5
            s=#E9CF93@0.5 w=0.5 ; p M 23.5 13 L 23.5 54
            s=#E9CF93 w=0.8 ; r 26.5 16 19 35 1.6
            s=#C9A45C@0.6 w=0.4 ; r 28 17.5 16 32 1
            s=#F1DDA4 w=2.2 cap ; p M 36 23.5 L 36 44.5
            s=#F1DDA4 w=2.2 cap ; p M 30 30.5 L 42 30.5
            f=#F1DDA4 ; c 36 22.4 1.5
            f=#F1DDA4 ; c 36 45.6 1.5
            f=#F1DDA4 ; c 28.9 30.5 1.5
            f=#F1DDA4 ; c 43.1 30.5 1.5
            f=#B2352A s=#6A1A13 w=0.4 ; c 36 30.5 1.5
            f=lg(46,21,46,24,#F1DDA4,#B88A32) s=#6B4E1C w=0.4 ; r 46 21.5 7.5 2.6 1.2
            f=lg(46,41,46,44,#F1DDA4,#B88A32) s=#6B4E1C w=0.4 ; r 46 41.5 7.5 2.6 1.2
            """
        case .consolation:
            return """
            f=rg(34,22,30,#E27462@0.30,#E27462@0) ; r 0 0 68 68 0
            f=#1A0D0A@0.5 ; e 34 58.5 23 2.8
            f=lg(10,34,10,58,#7A2019,#4A120E) s=#2B120E w=0.6 ; p M 9 34 L 34 37.5 L 59 34 L 59 55 L 34 58.5 L 9 55 Z
            f=lg(12,30,34,54,#F6EACB,#D8C598) s=#2B241D@0.5 w=0.6 ; p M 34 35 Q 23 29 11.5 32 L 11.5 52.5 Q 23 49.5 34 55.5 Z
            f=lg(56,30,34,54,#F6EACB,#D1BD8E) s=#2B241D@0.5 w=0.6 ; p M 34 35 Q 45 29 56.5 32 L 56.5 52.5 Q 45 49.5 34 55.5 Z
            s=#2B241D@0.38 w=0.7 cap ; p M 15 36 Q 23 34 30.5 37.5
            s=#2B241D@0.38 w=0.7 cap ; p M 15 40 Q 23 38 30.5 41.5
            s=#2B241D@0.38 w=0.7 cap ; p M 15 44 Q 23 42 30.5 45.5
            s=#2B241D@0.38 w=0.7 cap ; p M 15 48 Q 21 46.5 26 48
            s=#2B241D@0.38 w=0.7 cap ; p M 53 36 Q 45 34 37.5 37.5
            s=#2B241D@0.38 w=0.7 cap ; p M 53 40 Q 45 38 37.5 41.5
            s=#2B241D@0.38 w=0.7 cap ; p M 53 44 Q 45 42 37.5 45.5
            f=#B2352A ; r 37.6 35.4 2.8 2.8 0.6
            s=#2B241D@0.45 w=0.6 ; p M 34 35 L 34 55.5
            f=#B2352A s=#6A1A13 w=0.4 ; p M 32.4 55 L 32.4 63 L 34.2 61.2 L 36 63 L 36 55.8 Z
            f=rg(34,17,13,#FFE9B8@0.55,#FFE9B8@0) ; c 34 17 13
            f=lg(27,9,41,26,#F08C78,#B2352A) s=#6A1A13 w=0.6 ; p M 34 27 C 25.5 20.5 24.5 10.5 30 10.5 C 32.6 10.5 34 12.6 34 14.2 C 34 12.6 35.4 10.5 38 10.5 C 43.5 10.5 42.5 20.5 34 27 Z
            f=#FFFFFF@0.55 ; e 29.8 14.2 1.6 1
            """
        case .nativity:
            return """
            f=lg(0,0,0,68,#141B33,#2B2146) ; r 0 0 68 68 0
            f=#FFFFFF@0.75 ; c 10 9 0.6
            f=#FFFFFF@0.6 ; c 19 20 0.5
            f=#FFFFFF@0.7 ; c 55 8 0.6
            f=#FFFFFF@0.5 ; c 60 22 0.5
            f=#FFFFFF@0.6 ; c 48 16 0.45
            f=#FFFFFF@0.5 ; c 8 30 0.45
            f=rg(34,14,17,#FFF3C4@0.55,#FFF3C4@0) ; c 34 14 17
            f=lg(34,16,34,46,#FFF3C4@0.34,#FFF3C4@0.03) ; p M 33 16 L 35 16 L 46 46 L 22 46 Z
            f=#FFF3C4 ; p M 34 3.5 L 35.3 13 L 34 33 L 32.7 13 Z
            f=#FFF3C4 ; p M 24 14 L 34 12.8 L 44 14 L 34 15.2 Z
            f=#FFE9A8 ; p M 29.2 9.2 L 34.7 13.3 L 38.8 18.8 L 33.3 14.7 Z
            f=#FFE9A8 ; p M 38.8 9.2 L 34.7 14.7 L 29.2 18.8 L 33.3 13.3 Z
            f=#FFFFFF ; c 34 14 2.2
            f=#0E1426 ; p M 0 51 Q 16 44 34 49 Q 52 54 68 46 L 68 68 L 0 68 Z
            f=#3A2A1C s=#1A120C w=0.5 ; r 21.5 45 25 14 0
            f=rg(34,55,12,#FFD27A,#C27A2A@0.75) ; p M 26 59 L 26 49.5 Q 34 44 42 49.5 L 42 59 Z
            f=#6E4F33 s=#1A120C w=0.6 ; p M 17.5 45.5 L 34 34 L 50.5 45.5 L 47.5 46.5 L 34 37.6 L 20.5 46.5 Z
            f=#5C4530 s=#1A120C w=0.4 ; p M 30 54.5 L 38 54.5 L 37 58.6 L 31 58.6 Z
            f=rg(34,52.6,4,#FFFFFF,#FFF3C4@0) ; c 34 52.6 4
            f=#FFF8DC ; c 34 52.8 1.5
            f=#0B0F1C ; p M 0 59 Q 34 56 68 59 L 68 68 L 0 68 Z
            """
        case .candles:
            return """
            f=rg(34,24,36,#F5B54A@0.38,#F5B54A@0) ; r 0 0 68 68 0
            f=lg(10,54,10,63,#B88A32,#6B4E1C) s=#3A2A12 w=0.5 ; p M 9 53.5 Q 9 63 34 63 Q 59 63 59 53.5 Z
            f=lg(12,50,12,57,#E2D0A4,#B9A374) s=#3A2A12@0.6 w=0.5 ; e 34 53.5 25 4.6
            f=lg(20,30,25,30,#FBF1D5,#D6C293) s=#2B241D@0.35 w=0.4 ; r 20.2 31 3.6 23 1
            f=lg(32,20,37,20,#FBF1D5,#D6C293) s=#2B241D@0.35 w=0.4 ; r 32.2 21 3.6 33 1
            f=lg(44,36,49,36,#FBF1D5,#D6C293) s=#2B241D@0.35 w=0.4 ; r 44.2 36 3.6 18 1
            s=#2B241D w=0.6 cap ; p M 22 31 L 22 29
            s=#2B241D w=0.6 cap ; p M 34 21 L 34 19
            s=#2B241D w=0.6 cap ; p M 46 36 L 46 34
            f=rg(22,26,8,#FFE9A8@0.6,#FFE9A8@0) ; c 22 26 8
            f=rg(34,16,9,#FFE9A8@0.7,#FFE9A8@0) ; c 34 16 9
            f=rg(46,31,8,#FFE9A8@0.6,#FFE9A8@0) ; c 46 31 8
            f=lg(22,21,22,30,#FFF6D0,#F29A1F) ; p M 22 20.6 C 25.4 25.4 24.8 29.6 22 29.6 C 19.2 29.6 18.6 25.4 22 20.6 Z
            f=lg(34,10,34,20,#FFF6D0,#F29A1F) ; p M 34 9.6 C 37.8 15 37.1 19.6 34 19.6 C 30.9 19.6 30.2 15 34 9.6 Z
            f=lg(46,26,46,35,#FFF6D0,#F29A1F) ; p M 46 25.6 C 49.4 30.4 48.8 34.6 46 34.6 C 43.2 34.6 42.6 30.4 46 25.6 Z
            f=#FFFFFF@0.9 ; p M 22 24.6 C 23.4 26.8 23.1 28.8 22 28.8 C 20.9 28.8 20.6 26.8 22 24.6 Z
            f=#FFFFFF@0.9 ; p M 34 13.8 C 35.6 16.3 35.3 18.7 34 18.7 C 32.7 18.7 32.4 16.3 34 13.8 Z
            f=#FFFFFF@0.9 ; p M 46 29.6 C 47.4 31.8 47.1 33.8 46 33.8 C 44.9 33.8 44.6 31.8 46 29.6 Z
            """
        case .plan:
            return """
            f=rg(34,34,36,#C9A45C@0.22,#C9A45C@0) ; r 0 0 68 68 0
            f=lg(18,16,50,54,#F6EACB,#D8C598) s=#2B241D@0.5 w=0.6 ; r 17.5 14 33 40 0
            f=lg(13,10,13,18,#E2D0A4,#A8905E) s=#2B241D@0.6 w=0.6 ; r 13 10.5 42 7.4 3.7
            f=lg(13,50,13,58,#E2D0A4,#A8905E) s=#2B241D@0.6 w=0.6 ; r 13 50.5 42 7.4 3.7
            f=#C9A45C s=#6B4E1C w=0.4 ; c 13 14.2 2.3
            f=#C9A45C s=#6B4E1C w=0.4 ; c 55 14.2 2.3
            f=#C9A45C s=#6B4E1C w=0.4 ; c 13 54.2 2.3
            f=#C9A45C s=#6B4E1C w=0.4 ; c 55 54.2 2.3
            s=#4F7A43 w=1.5 cap ; p M 21.5 25.5 L 23.7 27.8 L 27.3 23
            s=#2B241D@0.5 w=1.1 cap ; p M 31 25.5 L 46.5 25.5
            s=#4F7A43 w=1.5 cap ; p M 21.5 33.5 L 23.7 35.8 L 27.3 31
            s=#2B241D@0.5 w=1.1 cap ; p M 31 33.5 L 46.5 33.5
            s=#B2352A w=1 ; c 24.4 41.5 2.4
            s=#2B241D@0.5 w=1.1 cap ; p M 31 41.5 L 42 41.5
            """
        case .quiz:
            return """
            f=rg(34,34,36,#C9A45C@0.22,#C9A45C@0) ; r 0 0 68 68 0
            f=#1A0D0A@0.5 ; e 35 59.5 18 2.6
            f=lg(14,10,54,58,#F6EACB,#D8C598) s=#2B241D@0.5 w=0.6 ; r 14.5 9.5 39 49 4
            s=#C9A45C w=0.8 ; r 17.5 12.5 33 43 2.4
            f=#C9A45C ; c 21 16 1
            f=#C9A45C ; c 47 16 1
            f=#C9A45C ; c 21 52 1
            f=#C9A45C ; c 47 52 1
            s=#6A1A13 w=5.6 cap ; p M 26.8 25.5 C 26.8 16.5 41.4 16.5 41.4 25.8 C 41.4 32 34 32.2 34 39
            s=#B2352A w=4 cap ; p M 26.8 25.5 C 26.8 16.5 41.4 16.5 41.4 25.8 C 41.4 32 34 32.2 34 39
            f=#B2352A s=#6A1A13 w=0.8 ; c 34 47.2 2.8
            """
        case .calendar:
            return """
            f=rg(34,34,36,#C9A45C@0.22,#C9A45C@0) ; r 0 0 68 68 0
            f=#1A0D0A@0.5 ; e 35 59.5 19 2.6
            f=#D8C598 s=#2B241D@0.5 w=0.6 ; r 16.5 16 38 43 4
            f=lg(14,13,52,56,#F6EACB,#DCCB9F) s=#2B241D@0.5 w=0.6 ; r 14 13.5 38 43 4
            f=lg(14,13,14,26,#C24236,#8E2A22) s=#6A1A13 w=0.5 ; p M 14 26 L 14 17.5 Q 14 13.5 18 13.5 L 48 13.5 Q 52 13.5 52 17.5 L 52 26 Z
            f=lg(22,9,25,9,#F1DDA4,#B88A32) s=#6B4E1C w=0.4 ; r 22.4 9.5 2.6 8 1.3
            f=lg(41,9,44,9,#F1DDA4,#B88A32) s=#6B4E1C w=0.4 ; r 41 9.5 2.6 8 1.3
            s=#F1DDA4 w=1.3 cap ; p M 33 17 L 33 23.4
            s=#F1DDA4 w=1.3 cap ; p M 30.3 19.4 L 35.7 19.4
            """
        case .map:
            return """
            f=lg(0,0,0,68,#1A2140,#4A3447) ; r 0 0 68 68 0
            f=rg(50,13,12,#FFE9B8@0.55,#FFE9B8@0) ; c 50 13 12
            f=#FFF3D0 ; c 50 13 3.4
            f=#394766 ; p M -2 47 L 17 20.5 Q 20.5 16.5 24 20.5 L 34.5 34.5 L 41.5 27.5 Q 44 25 46.5 27.5 L 70 47 Z
            f=#EDF1F8 ; p M 12.6 26.6 L 17 20.5 Q 20.5 16.5 24 20.5 L 28.2 26.2 L 25.2 24.6 L 22.6 28.4 L 20.2 24.8 L 16.6 28.6 L 15.2 25.2 Z
            f=#EDF1F8 ; p M 38.4 30.6 L 41.5 27.5 Q 44 25 46.5 27.5 L 50 30.4 L 47.2 29.6 L 45.2 31.8 L 43.2 29.4 L 40.8 31.6 Z
            f=lg(0,44,0,68,#3C4A30,#1F2A1B) ; p M 0 47.5 Q 34 41 68 47.5 L 68 68 L 0 68 Z
            f=lg(25,45,43,59,#E0A27E,#B8785A) s=#2B1A12 w=0.6 ; r 25.5 46 17 13.5 0
            f=#8E4A36 s=#2B1A12 w=0.6 ; p M 23.5 46.6 L 34 40.4 L 44.5 46.6 Z
            f=lg(30,35,38,44,#E0A27E,#B8785A) s=#2B1A12 w=0.6 ; r 30.2 35.5 7.6 8.5 0
            f=#8E4A36 s=#2B1A12 w=0.6 ; p M 28.6 36 L 34 23.5 L 39.4 36 Z
            s=#F1DDA4 w=1 cap ; p M 34 23.6 L 34 18.2
            s=#F1DDA4 w=1 cap ; p M 32 20.2 L 36 20.2
            f=#2B1A12 ; p M 32 59.5 L 32 53.6 Q 34 50.6 36 53.6 L 36 59.5 Z
            f=#2B1A12 ; r 33.3 38 1.4 4 0.7
            f=#2B1A12 ; r 28 49.5 1.4 3.6 0.7
            f=#2B1A12 ; r 38.6 49.5 1.4 3.6 0.7
            """
        case .premium:
            return """
            f=rg(34,32,36,#E9CF93@0.34,#E9CF93@0) ; r 0 0 68 68 0
            f=#1A0D0A@0.5 ; e 34 56.5 20 2.6
            f=lg(16,18,52,46,#F6E3A6,#B88A32) s=#6B4E1C w=0.7 ; p M 17 44 L 13.5 23.5 L 25.5 33.5 L 34 17.5 L 42.5 33.5 L 54.5 23.5 L 51 44 Z
            f=#FFFFFF@0.35 ; p M 18.6 42 L 16.4 28.6 L 25.9 36.4 L 34 21.4 L 34 42 Z
            f=lg(16,44,16,52,#E9CF93,#A87B2A) s=#6B4E1C w=0.7 ; r 15.5 43.5 37 8 2.4
            f=#F6E3A6 s=#6B4E1C w=0.5 ; c 13.5 22.8 2.4
            f=#F6E3A6 s=#6B4E1C w=0.5 ; c 34 16.6 2.8
            f=#F6E3A6 s=#6B4E1C w=0.5 ; c 54.5 22.8 2.4
            f=#C24236 s=#6A1A13 w=0.5 ; c 34 47.5 2.3
            f=#5B7DB1 s=#22365C w=0.5 ; c 24 47.5 1.7
            f=#5B7DB1 s=#22365C w=0.5 ; c 44 47.5 1.7
            f=#FFFFFF@0.7 ; c 33.3 46.8 0.7
            """
        }
    }
}

// MARK: - Одна фигура миниатюры
struct HomeTileShape {
    enum Paint {
        case solid(Color)
        case linear(Gradient, CGPoint, CGPoint)
        case radial(Gradient, CGPoint, CGFloat)
    }

    let path: Path
    let fill: Paint?
    let stroke: Color?
    let lineWidth: CGFloat
    let roundCap: Bool
    let opacity: Double
}

// MARK: - Разбор описания в фигуры
/// Описание разбирается один раз на миниатюру и хранится: при прокрутке главного экрана пути не строятся заново.
enum HomeTileArtParser {
    /// Сторона поля, в котором заданы координаты
    static let side: CGFloat = 68

    private static let lock = NSLock()
    private static var cache: [HomeTileArt: [HomeTileShape]] = [:]

    static func shapes(for art: HomeTileArt) -> [HomeTileShape] {
        lock.lock()
        if let hit = cache[art] {
            lock.unlock()
            return hit
        }
        lock.unlock()
        let made = parse(art.script)
        lock.lock()
        cache[art] = made
        lock.unlock()
        return made
    }

    static func parse(_ script: String) -> [HomeTileShape] {
        var shapes: [HomeTileShape] = []
        for rawLine in script.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("//") { continue }
            let halves = line.split(separator: ";", maxSplits: 1)
            guard halves.count == 2 else { continue }
            let styleTokens = halves[0].split(separator: " ").map { String($0) }
            let shapeTokens = halves[1].split(separator: " ").map { String($0) }
            guard let path = path(from: shapeTokens) else { continue }

            var fill: HomeTileShape.Paint?
            var stroke: Color?
            var lineWidth: CGFloat = 1
            var roundCap = false
            var opacity: Double = 1
            for token in styleTokens {
                if token.hasPrefix("f=") {
                    fill = paint(String(token.dropFirst(2)))
                } else if token.hasPrefix("s=") {
                    stroke = color(String(token.dropFirst(2)))
                } else if token.hasPrefix("w=") {
                    lineWidth = CGFloat(Double(token.dropFirst(2)) ?? 1)
                } else if token == "cap" {
                    roundCap = true
                } else if token.hasPrefix("o=") {
                    opacity = Double(token.dropFirst(2)) ?? 1
                }
            }
            shapes.append(HomeTileShape(path: path, fill: fill, stroke: stroke, lineWidth: lineWidth, roundCap: roundCap, opacity: opacity))
        }
        return shapes
    }

    /// Цвет вида #RRGGBB или #RRGGBB@0.5
    private static func color(_ token: String) -> Color {
        let parts = token.split(separator: "@")
        let hexText = parts.first.map { String($0.dropFirst()) } ?? "000000"
        let hex = UInt32(hexText, radix: 16) ?? 0
        let alpha: Double = parts.count > 1 ? (Double(parts[1]) ?? 1) : 1
        return Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    private static func paint(_ token: String) -> HomeTileShape.Paint? {
        let isLinear = token.hasPrefix("lg(")
        let isRadial = token.hasPrefix("rg(")
        guard isLinear || isRadial else { return .solid(color(token)) }
        guard token.hasSuffix(")") else { return nil }
        let arguments = token.dropFirst(3).dropLast().split(separator: ",").map { String($0) }
        let numberCount = isLinear ? 4 : 3
        guard arguments.count > numberCount else { return nil }
        let numbers = arguments.prefix(numberCount).map { CGFloat(Double($0) ?? 0) }
        let gradient = Gradient(colors: arguments.dropFirst(numberCount).map { color($0) })
        if isLinear {
            return .linear(gradient, CGPoint(x: numbers[0], y: numbers[1]), CGPoint(x: numbers[2], y: numbers[3]))
        }
        return .radial(gradient, CGPoint(x: numbers[0], y: numbers[1]), numbers[2])
    }

    private static func path(from tokens: [String]) -> Path? {
        guard let kind = tokens.first else { return nil }
        let rest = Array(tokens.dropFirst())
        if kind == "p" {
            return curve(from: rest)
        }
        let n = rest.map { CGFloat(Double($0) ?? 0) }
        switch kind {
        case "c":
            guard n.count >= 3 else { return nil }
            return Path(ellipseIn: CGRect(x: n[0] - n[2], y: n[1] - n[2], width: n[2] * 2, height: n[2] * 2))
        case "e":
            guard n.count >= 4 else { return nil }
            return Path(ellipseIn: CGRect(x: n[0] - n[2], y: n[1] - n[3], width: n[2] * 2, height: n[3] * 2))
        case "r":
            guard n.count >= 4 else { return nil }
            let rect = CGRect(x: n[0], y: n[1], width: n[2], height: n[3])
            let radius = n.count >= 5 ? min(n[4], min(n[2], n[3]) / 2) : 0
            return radius > 0 ? Path(roundedRect: rect, cornerRadius: radius) : Path(rect)
        default:
            return nil
        }
    }

    /// Путь из команд M L Q C Z с абсолютными координатами
    private static func curve(from tokens: [String]) -> Path {
        var path = Path()
        var index = 0
        func point(at offset: Int) -> CGPoint? {
            guard offset + 1 < tokens.count, let x = Double(tokens[offset]), let y = Double(tokens[offset + 1]) else { return nil }
            return CGPoint(x: x, y: y)
        }
        while index < tokens.count {
            let command = tokens[index]
            index += 1
            switch command {
            case "M":
                guard let to = point(at: index) else { return path }
                path.move(to: to)
                index += 2
            case "L":
                guard let to = point(at: index) else { return path }
                path.addLine(to: to)
                index += 2
            case "Q":
                guard let control = point(at: index), let to = point(at: index + 2) else { return path }
                path.addQuadCurve(to: to, control: control)
                index += 4
            case "C":
                guard let control1 = point(at: index), let control2 = point(at: index + 2), let to = point(at: index + 4) else { return path }
                path.addCurve(to: to, control1: control1, control2: control2)
                index += 6
            case "Z":
                path.closeSubpath()
            default:
                break
            }
        }
        return path
    }
}

// MARK: - Плитка с миниатюрой
/// Тёмная плитка 68×68 с миниатюрой раздела. Размер и скругление такие же, как у плитки «Моего Матенадарана».
struct HomeArtTile: View {
    let art: HomeTileArt
    var side: CGFloat = 68

    var body: some View {
        let shapes = HomeTileArtParser.shapes(for: art)
        let scale = side / HomeTileArtParser.side
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.sRGB, red: 0x15 / 255.0, green: 0x10 / 255.0, blue: 0x0B / 255.0, opacity: 1))
            Canvas { context, _ in
                var scaled = context
                scaled.scaleBy(x: scale, y: scale)
                for shape in shapes {
                    HomeArtTile.draw(shape, in: scaled)
                }
            }
            if art == .calendar {
                // Сегодняшнее число на листе календаря
                Text("\(Calendar.current.component(.day, from: Date()))")
                    .font(PaperFont.font(size: 19 * scale, weight: .semibold))
                    .foregroundColor(Color(.sRGB, red: 0x2B / 255.0, green: 0x24 / 255.0, blue: 0x1D / 255.0, opacity: 1))
                    .offset(x: -1 * scale, y: 8 * scale)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityHidden(true)
    }

    private static func draw(_ shape: HomeTileShape, in context: GraphicsContext) {
        var ctx = context
        if shape.opacity < 1 {
            ctx.opacity = shape.opacity
        }
        if let fill = shape.fill {
            switch fill {
            case .solid(let color):
                ctx.fill(shape.path, with: .color(color))
            case .linear(let gradient, let start, let end):
                ctx.fill(shape.path, with: .linearGradient(gradient, startPoint: start, endPoint: end))
            case .radial(let gradient, let center, let radius):
                ctx.fill(shape.path, with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius))
            }
        }
        if let stroke = shape.stroke {
            ctx.stroke(
                shape.path,
                with: .color(stroke),
                style: StrokeStyle(
                    lineWidth: shape.lineWidth,
                    lineCap: shape.roundCap ? .round : .butt,
                    lineJoin: shape.roundCap ? .round : .miter
                )
            )
        }
    }
}
