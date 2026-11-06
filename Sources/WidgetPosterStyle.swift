import SwiftUI

// MARK: - Виды виджетов: «Кадр» и «Святилище»
// «Кадр»: крупная фраза на настоящей фотографии, подобранной по смыслу стиха (QuoteMood.swift), как в карточке стиха дня.
// «Святилище»: та же раскладка на тёмном тёплом фоне без фото (StandBy, OLED, спокойный минимум).
// Файл входит и в приложение, и в расширение виджетов: в нём нет ничего, что есть только в одном из них.

enum PosterArt: String, CaseIterable, Identifiable {
    case frame
    case sanctuary

    var id: String { rawValue }

    /// Цвет основного текста, ссылки и значков на этом фоне
    var mainColor: Color {
        switch self {
        case .frame: return .white
        case .sanctuary: return PosterPalette.rgb(236, 227, 210)
        }
    }

    var accentColor: Color {
        switch self {
        case .frame: return PosterPalette.rgb(244, 212, 142)
        case .sanctuary: return PosterPalette.rgb(198, 166, 107)
        }
    }

    /// Нужна ли мягкая тень под текстом (на фото нужна, на ровном тёмном фоне нет)
    var usesTextShadow: Bool { self == .frame }
}

enum PosterSize {
    case small, medium, large
}

enum PosterPalette {
    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}

// MARK: - Вид виджета и его фон
extension WidgetVisualStyle {
    var posterArt: PosterArt {
        switch self {
        case .posterFrame: return .frame
        case .sanctuary: return .sanctuary
        }
    }
}

// MARK: - Фон вида для предпросмотров в настройках
struct WidgetStyleBackground: View {
    let style: WidgetVisualStyle
    let colorScheme: ColorScheme

    var body: some View {
        // У «Кадра» в предпросмотре — один из кадров из каталога приложения
        PosterBackground(art: style.posterArt, photo: style.posterArt == .frame ? "QuoteLight3" : nil)
    }
}

// MARK: - Фоны
struct PosterBackground: View {
    let art: PosterArt
    /// Имя фотографии в каталоге (только для «Кадра»)
    var photo: String? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch art {
                case .frame: PosterFrameArt(photo: photo, width: geo.size.width, height: geo.size.height)
                case .sanctuary: PosterSanctuaryArt(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

// MARK: Кадр: фотография по смыслу фразы
private struct PosterFrameArt: View {
    let photo: String?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        // Чем светлее кадр, тем плотнее затемнение: белый текст читается и на небе, и на свечах
        let boost = max(0, min(1, QuoteBackdrop.luminance(of: photo)) - 0.30) * 0.55
        ZStack {
            // Запасной фон, если кадра нет в каталоге
            LinearGradient(
                colors: [PosterPalette.rgb(28, 22, 16), PosterPalette.rgb(66, 46, 28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let photo {
                Image(photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            }
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.30 + boost * 0.6), location: 0),
                    .init(color: Color.black.opacity(0.42 + boost), location: 0.45),
                    .init(color: Color.black.opacity(0.62 + boost * 0.6), location: 0.80),
                    .init(color: Color.black.opacity(0.78 + boost * 0.4), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Виньетка: края темнее, взгляд остаётся на тексте
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.30)],
                center: .center,
                startRadius: min(width, height) * 0.30,
                endRadius: max(width, height) * 0.85
            )
        }
    }
}

// MARK: Святилище: тёплая темнота и янтарный свет сверху
private struct PosterSanctuaryArt: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PosterPalette.rgb(18, 15, 12), PosterPalette.rgb(33, 28, 22)],
                startPoint: .top,
                endPoint: .bottom
            )
            // Янтарный свет сверху, как от свечи над страницей
            RadialGradient(
                colors: [PosterPalette.rgb(198, 166, 107, 0.20), PosterPalette.rgb(198, 166, 107, 0)],
                center: UnitPoint(x: 0.5, y: -0.05),
                startRadius: 0,
                endRadius: max(width, height) * 0.75
            )
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.30)],
                center: .center,
                startRadius: min(width, height) * 0.30,
                endRadius: max(width, height) * 0.85
            )
            // Тонкая золотая рамка, как у карточек приложения
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .inset(by: 6)
                .strokeBorder(PosterPalette.rgb(198, 166, 107, 0.22), lineWidth: 0.8)
        }
    }
}

// MARK: - Неброская круглая кнопка поверх фона
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
    let photo: String?
    let controls: Controls

    init(art: PosterArt, size: PosterSize, text: String, reference: String, photo: String? = nil, @ViewBuilder controls: () -> Controls) {
        self.art = art
        self.size = size
        self.text = text
        self.reference = reference
        self.photo = photo
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

    private var padding: CGFloat {
        size == .large ? 20 : (size == .medium ? 16 : 14)
    }

    var body: some View {
        ZStack {
            PosterBackground(art: art, photo: photo)
            VStack(alignment: .leading, spacing: 0) {
                FittedQuoteText(text: text, maxSize: maxFontSize, minScale: size == .large ? 0.42 : 0.55, weight: .bold, design: .serif, lineSpacing: 2)
                    .foregroundColor(art.mainColor)
                    .shadow(color: Color.black.opacity(art.usesTextShadow ? 0.45 : 0), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                footer
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var referenceLabel: some View {
        Text(reference)
            .font(QuoteFont.serif(size: referenceSize, weight: .semibold))
            .italic()
            .foregroundColor(art.accentColor)
            .shadow(color: Color.black.opacity(art.usesTextShadow ? 0.4 : 0), radius: 3, x: 0, y: 1)
    }

    /// Подпись целиком, без многоточия. Длинное название книги («Ա Թեսաղոնիկեցիների 5:16-18») переносится на
    /// вторую строку и только потом сжимается. В малом виджете рядом с кнопкой на подпись остаётся меньше 90 pt, чего
    /// не хватает даже на одно длинное слово, поэтому там кнопка уходит над подписью, когда в одну строку они не помещаются.
    @ViewBuilder
    private var footer: some View {
        if size == .small {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: 8) {
                    referenceLabel.lineLimit(1)
                    Spacer(minLength: 4)
                    controls
                }
                VStack(alignment: .trailing, spacing: 4) {
                    controls
                    referenceLabel
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                referenceLabel
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                controls
            }
        }
    }
}
