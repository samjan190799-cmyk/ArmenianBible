import SwiftUI

// MARK: - Виджеты-«постеры»
// Крупная фраза на нарисованном фоне: Арарат на рассвете, золотой хачкар, пергамент, ночь над Вифлеемом.
// Фоны рисуются средствами SwiftUI (кроме рельефа хачкара — одна картинка), поэтому не зависят от фото и лицензий.
// Файл входит и в приложение, и в расширение виджетов: в нём нет ничего, что есть только в одном из них.

enum PosterArt: String, CaseIterable, Identifiable {
    case ararat, khachkar, parchment, night

    var id: String { rawValue }

    /// Цвет основного текста, ссылки и значков на этом фоне
    var mainColor: Color {
        switch self {
        case .ararat, .night: return .white
        case .khachkar: return PosterPalette.rgb(246, 234, 208)
        case .parchment: return PosterPalette.rgb(92, 24, 38)
        }
    }

    var accentColor: Color {
        switch self {
        case .ararat: return PosterPalette.rgb(255, 226, 176)
        case .khachkar: return PosterPalette.rgb(226, 176, 74)
        case .parchment: return PosterPalette.rgb(150, 106, 40)
        case .night: return PosterPalette.rgb(255, 214, 150)
        }
    }

    /// Нужна ли мягкая тень под текстом (на светлом пергаменте не нужна)
    var usesTextShadow: Bool { self != .parchment }
}

enum PosterSize {
    case small, medium, large
}

enum PosterPalette {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}

// MARK: - Стили виджетов: связь с постерами
extension WidgetVisualStyle {
    var posterArt: PosterArt? {
        switch self {
        case .posterArarat: return .ararat
        case .posterKhachkar: return .khachkar
        case .posterParchment: return .parchment
        case .posterNight: return .night
        default: return nil
        }
    }

    var isPoster: Bool { posterArt != nil }

    /// Бесплатные «Арарат» и «Пергамент», остальные с Premium
    var isPremiumRequired: Bool {
        self == .posterKhachkar || self == .posterNight
    }
}

// MARK: - Фон стиля для предпросмотров в настройках
struct WidgetStyleBackground: View {
    let style: WidgetVisualStyle
    let colorScheme: ColorScheme

    var body: some View {
        if let art = style.posterArt {
            PosterBackground(art: art)
        } else {
            Rectangle().fill(style.backgroundGradient(for: colorScheme))
        }
    }
}

// MARK: - Фоны
struct PosterBackground: View {
    let art: PosterArt

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch art {
                case .ararat: PosterAraratArt(width: geo.size.width, height: geo.size.height)
                case .khachkar: PosterKhachkarArt(width: geo.size.width, height: geo.size.height)
                case .parchment: PosterParchmentArt(width: geo.size.width, height: geo.size.height)
                case .night: PosterNightArt(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

/// Детерминированный «случайный» число 0…1 по номеру: звёзды и крапинки не прыгают между перерисовками
private func posterHash(_ i: Int, _ salt: Int) -> CGFloat {
    let v = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
    return CGFloat(v - floor(v))
}

// MARK: Арарат на рассвете
private struct PosterAraratArt: View {
    let width: CGFloat
    let height: CGFloat

    private var wide: Bool { width / height > 1.5 }
    private var horizon: CGFloat { height < 200 ? 0.95 : 0.92 }

    /// Две вершины: Масис (большая, слева) и Сис (малая); y в долях высоты
    private var peaks: [(x: CGFloat, top: CGFloat, half: CGFloat, q: CGFloat)] {
        wide
            ? [(0.20, 0.66, 0.30, 0.80), (0.62, 0.78, 0.20, 0.85)]
            : [(0.28, 0.68, 0.52, 0.80), (0.78, 0.80, 0.34, 0.85)]
    }

    private func ridgeY(_ x: CGFloat) -> CGFloat {
        var y = CGFloat.greatestFiniteMagnitude
        for p in peaks {
            let d = min(abs(x - p.x * width) / (p.half * width), 1)
            y = min(y, p.top * height + (horizon * height - p.top * height) * pow(d, p.q))
        }
        return y
    }

    var body: some View {
        let steps = 96
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: PosterPalette.rgb(16, 20, 62), location: 0),
                    .init(color: PosterPalette.rgb(52, 40, 112), location: 0.38),
                    .init(color: PosterPalette.rgb(150, 66, 120), location: 0.60),
                    .init(color: PosterPalette.rgb(236, 112, 94), location: 0.76),
                    .init(color: PosterPalette.rgb(255, 172, 86), location: 0.90),
                    .init(color: PosterPalette.rgb(255, 214, 136), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [PosterPalette.rgb(255, 214, 150, 0.5), .clear],
                center: UnitPoint(x: 0.68, y: 0.86),
                startRadius: 0,
                endRadius: width * 0.55
            )
            // Горы
            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                for i in 0...steps {
                    let x = width * CGFloat(i) / CGFloat(steps)
                    path.addLine(to: CGPoint(x: x, y: ridgeY(x)))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(LinearGradient(
                colors: [PosterPalette.rgb(62, 32, 98), PosterPalette.rgb(40, 22, 70)],
                startPoint: .top,
                endPoint: .bottom
            ))
            // Снежная шапка Масиса: граница по высоте, неровная
            Path { path in
                let snowY = height * (wide ? 0.74 : 0.77)
                var xs: [CGFloat] = []
                for i in 0...steps {
                    let x = width * CGFloat(i) / CGFloat(steps)
                    if ridgeY(x) < snowY && x < width * 0.62 { xs.append(x) }
                }
                guard let first = xs.first else { return }
                path.move(to: CGPoint(x: first, y: ridgeY(first)))
                for x in xs { path.addLine(to: CGPoint(x: x, y: ridgeY(x))) }
                for x in xs.reversed() {
                    let jag = sin(x * 0.11) * height * 0.012 + sin(x * 0.27) * height * 0.008
                    path.addLine(to: CGPoint(x: x, y: snowY + jag))
                }
                path.closeSubpath()
            }
            .fill(PosterPalette.rgb(255, 228, 216, 0.95))
            // Дымка у подножия
            LinearGradient(
                colors: [.clear, PosterPalette.rgb(226, 112, 118, 0.35)],
                startPoint: UnitPoint(x: 0.5, y: 0.6),
                endPoint: .bottom
            )
        }
    }
}

// MARK: Золотой хачкар на тёмном камне
private struct PosterKhachkarArt: View {
    let width: CGFloat
    let height: CGFloat

    private var wide: Bool { width / height > 1.5 }
    private var tall: Bool { height > 300 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PosterPalette.rgb(22, 20, 22), PosterPalette.rgb(38, 31, 27), PosterPalette.rgb(58, 44, 30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image("KhachkarRelief")
                .resizable()
                .scaledToFit()
                .frame(height: height * (tall ? 0.55 : (wide ? 1.12 : 0.95)))
                .opacity(tall ? 0.45 : 0.62)
                .shadow(color: PosterPalette.rgb(210, 150, 60, 0.45), radius: 12)
                .offset(x: tall ? 0 : (wide ? width * 0.03 : width * 0.20), y: tall ? height * 0.16 : (wide ? height * 0.08 : height * 0.22))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: tall ? .bottom : .bottomTrailing)
        }
    }
}

// MARK: Пергамент
private struct PosterParchmentArt: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let inset = min(width, height) * 0.07
        ZStack {
            LinearGradient(
                colors: [PosterPalette.rgb(240, 222, 178), PosterPalette.rgb(214, 186, 132)],
                startPoint: .top,
                endPoint: .bottom
            )
            // Выгоревшие края
            RadialGradient(
                colors: [.clear, PosterPalette.rgb(128, 82, 40, 0.45)],
                center: .center,
                startRadius: min(width, height) * 0.35,
                endRadius: max(width, height) * 0.75
            )
            // Крапинки пергамента
            Canvas { context, size in
                let count = Int(size.width * size.height / 700)
                for i in 0..<count {
                    let x = posterHash(i, 1) * size.width
                    let y = posterHash(i, 2) * size.height
                    let r = 0.6 + posterHash(i, 3) * 1.6
                    let a = 0.04 + Double(posterHash(i, 4)) * 0.08
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(PosterPalette.rgb(150, 110, 60, a))
                    )
                }
            }
            // Двойная золотая рамка
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .inset(by: inset)
                .strokeBorder(PosterPalette.rgb(196, 146, 52, 0.9), lineWidth: 1.6)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .inset(by: inset + 6)
                .strokeBorder(PosterPalette.rgb(196, 146, 52, 0.5), lineWidth: 0.8)
        }
    }
}

// MARK: Ночь над Вифлеемом
private struct PosterNightArt: View {
    let width: CGFloat
    let height: CGFloat

    private var wide: Bool { width / height > 1.5 }

    var body: some View {
        let large = height > 300
        let starX = width * (large ? 0.78 : (wide ? 0.90 : 0.84))
        let starY = height * (large ? 0.72 : 0.17)
        let radius = min(width, height) * 0.24
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: PosterPalette.rgb(6, 10, 38), location: 0),
                    .init(color: PosterPalette.rgb(20, 28, 84), location: 0.45),
                    .init(color: PosterPalette.rgb(66, 50, 116), location: 0.72),
                    .init(color: PosterPalette.rgb(210, 126, 74), location: 0.90),
                    .init(color: PosterPalette.rgb(255, 176, 96), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Звёзды
            Canvas { context, size in
                let count = Int(size.width * size.height / 4500)
                for i in 0..<count {
                    let x = posterHash(i, 11) * size.width
                    let y = posterHash(i, 12) * size.height * 0.7
                    let r = 0.9 + posterHash(i, 13) * 1.6
                    let a = 0.4 + Double(posterHash(i, 14)) * 0.6
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(PosterPalette.rgb(255, 244, 220, a))
                    )
                }
            }
            // Вифлеемская звезда
            RadialGradient(
                colors: [PosterPalette.rgb(255, 226, 160, 0.85), .clear],
                center: UnitPoint(x: starX / width, y: starY / height),
                startRadius: 0,
                endRadius: radius * 0.9
            )
            Capsule()
                .fill(PosterPalette.rgb(255, 244, 220, 0.85))
                .frame(width: 1.6, height: radius * 1.6)
                .position(x: starX, y: starY)
            Capsule()
                .fill(PosterPalette.rgb(255, 244, 220, 0.85))
                .frame(width: radius * 1.6, height: 1.6)
                .position(x: starX, y: starY)
            Circle()
                .fill(PosterPalette.rgb(255, 252, 240))
                .frame(width: radius * 0.22, height: radius * 0.22)
                .position(x: starX, y: starY)
            // Холмы
            Path { path in
                let base = height * 0.90
                path.move(to: CGPoint(x: 0, y: height))
                let steps = 64
                for i in 0...steps {
                    let x = width * CGFloat(i) / CGFloat(steps)
                    let t = x / width
                    let y = base - height * 0.05 * sin(t * 5.0 + 0.6) - height * 0.03 * sin(t * 11.0 + 2.0)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(PosterPalette.rgb(12, 12, 34))
        }
    }
}

// MARK: - Неброская круглая кнопка поверх постера
struct PosterGlassIcon: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(Circle().fill(tint.opacity(0.18)))
            .overlay(Circle().strokeBorder(tint.opacity(0.35), lineWidth: 0.8))
    }
}

// MARK: - Раскладка: крупная фраза, ссылка внизу, кнопки в углу
struct PosterWidgetLayout<Controls: View>: View {
    let art: PosterArt
    let size: PosterSize
    let text: String
    let reference: String
    let locked: Bool
    let controls: Controls

    init(art: PosterArt, size: PosterSize, text: String, reference: String, locked: Bool = false, @ViewBuilder controls: () -> Controls) {
        self.art = art
        self.size = size
        self.text = text
        self.reference = reference
        self.locked = locked
        self.controls = controls()
    }

    /// Самый крупный размер: фраза сама уменьшается до тех пор, пока не поместится целиком
    private var maxFontSize: CGFloat {
        switch size {
        case .small: return 34
        case .medium: return 32
        case .large: return 40
        }
    }

    private var referenceSize: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 13
        case .large: return 15
        }
    }

    /// Отступ: на пергаменте текст не должен налезать на рамку
    private var padding: CGFloat {
        let base: CGFloat = size == .large ? 20 : (size == .medium ? 16 : 14)
        return art == .parchment ? base + 10 : base
    }

    /// Справа от текста оставляем место под хачкар в среднем виджете
    private var trailingInset: CGFloat {
        art == .khachkar && size == .medium ? 96 : 0
    }

    var body: some View {
        ZStack {
            PosterBackground(art: art)
            VStack(alignment: .leading, spacing: 0) {
                FittedQuoteText(text: text, maxSize: maxFontSize, minScale: size == .large ? 0.42 : 0.55, weight: .bold, design: .serif, lineSpacing: 2)
                    .foregroundColor(art.mainColor)
                    .shadow(color: Color.black.opacity(art.usesTextShadow ? 0.45 : 0), radius: 4, x: 0, y: 2)
                    .padding(.trailing, trailingInset)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                HStack(alignment: .bottom, spacing: 8) {
                    Text(reference)
                        .font(.system(size: referenceSize, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundColor(art.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: Color.black.opacity(art.usesTextShadow ? 0.4 : 0), radius: 3, x: 0, y: 1)
                    Spacer(minLength: 4)
                    if locked {
                        PosterLockBadge(compact: size == .small)
                    }
                    controls
                }
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Пометка «нужен Premium» на постере
struct PosterLockBadge: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .bold))
            if !compact {
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundColor(PosterPalette.rgb(255, 214, 120))
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(Capsule().strokeBorder(PosterPalette.rgb(255, 214, 120, 0.7), lineWidth: 0.8))
    }
}
