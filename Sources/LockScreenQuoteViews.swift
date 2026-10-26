import SwiftUI
import WidgetKit

// MARK: - Виджеты экрана блокировки: цитата с вертикальной чертой и подписью с линейкой
// Экран блокировки красит виджет одним цветом (vibrant): важна только яркость, поэтому украшения сделаны белым
// с разной прозрачностью. В цветном режиме (StandBy, предпросмотр) появляется золото.
// Своей плиты, рамки и хачкара у прямоугольного виджета нет: на экране блокировки они выглядели чужеродно
// рядом с часами и чужими виджетами, а хачкар ложился на конец строк и подпись.

/// Цвета украшений: белый с прозрачностью в режиме экрана блокировки, золото и слоновая кость в цветном
private struct LockPalette {
    let mono: Bool

    var ink: Color { mono ? .white : Color(red: 0.97, green: 0.93, blue: 0.84) }
    var rule: Color { mono ? .white : Color(red: 0.88, green: 0.70, blue: 0.36) }
    var caption: Color { ink.opacity(0.80) }
}

/// Прямоугольный виджет (около 160×72 pt): слева тонкая вертикальная черта, как у цитаты в заметках,
/// цитата максимально крупно, снизу подпись и тонкая линия
struct LockQuoteCard: View {
    let text: String
    let reference: String
    var design: Font.Design = .serif
    /// Макет внутри приложения: рисуем так, как увидит экран блокировки (белым), хотя среда цветная
    var forceMono: Bool = false

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var palette: LockPalette {
        LockPalette(mono: forceMono || renderingMode != .fullColor)
    }

    private var captionFont: Font {
        design == .serif
            ? QuoteFont.serif(size: 10, weight: .semibold)
            : .system(size: 10, weight: .semibold, design: design)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Capsule()
                .fill(palette.rule.opacity(palette.mono ? 0.65 : 0.95))
                .frame(width: 2.5)
                .padding(.vertical, 1)
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                FittedQuoteText(
                    text: text,
                    maxSize: 24,
                    minScale: 0.6,
                    weight: .semibold,
                    design: design,
                    lineSpacing: -0.5
                )
                .foregroundColor(palette.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                HStack(spacing: 6) {
                    Text(reference)
                        .font(captionFont)
                        .italic()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(palette.caption)
                        .layoutPriority(1)
                    Rectangle()
                        .fill(palette.rule.opacity(palette.mono ? 0.45 : 0.7))
                        .frame(height: 0.6)
                        .widgetAccentable()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Круглый виджет: хачкар на системной плите, а когда молитва прочитана — галочка
struct LockQuoteCircle: View {
    let prayerDone: Bool
    var systemPlate: Bool = true
    var forceMono: Bool = false

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var palette: LockPalette {
        LockPalette(mono: forceMono || renderingMode != .fullColor)
    }

    var body: some View {
        ZStack {
            if systemPlate {
                AccessoryWidgetBackground()
            }
            if prayerDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(palette.ink)
            } else {
                Image("KhachkarRelief")
                    .resizable()
                    .scaledToFit()
                    .grayscale(palette.mono ? 1 : 0)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .widgetAccentable()
            }
        }
    }
}

/// Макет виджета на экране блокировки внутри приложения: обои, часы и сам виджет
struct LockWidgetPreviewScene: View {
    let text: String
    let reference: String
    var design: Font.Design = .serif
    var showsClock: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.10, blue: 0.24),
                    Color(red: 0.33, green: 0.16, blue: 0.34),
                    Color(red: 0.88, green: 0.47, blue: 0.33)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: showsClock ? 10 : 0) {
                if showsClock {
                    Text("9:41")
                        .font(.system(size: 46, weight: .semibold, design: .serif))
                        .foregroundColor(.white.opacity(0.88))
                }
                LockQuoteCard(text: text, reference: reference, design: design, forceMono: true)
                    .frame(width: 160, height: 72)
            }
            .padding(.vertical, 14)
        }
    }
}
