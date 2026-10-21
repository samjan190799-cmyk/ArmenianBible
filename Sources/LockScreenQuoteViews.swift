import SwiftUI
import WidgetKit

// MARK: - Виджеты экрана блокировки: рамка манускрипта, хачкар-водяной знак, подпись с линейкой
// Экран блокировки рисует виджет одним цветом (vibrant): важна только яркость, поэтому украшения сделаны
// белым с разной прозрачностью, а хачкар — картинкой в оттенках серого. В цветном режиме (StandBy, предпросмотр) появляется золото.

/// Цвета украшений: белый с прозрачностью в режиме экрана блокировки, золото и слоновая кость в цветном
private struct LockPalette {
    let mono: Bool

    var ink: Color { mono ? .white : Color(red: 0.97, green: 0.93, blue: 0.84) }
    var rule: Color { mono ? .white : Color(red: 0.88, green: 0.70, blue: 0.36) }
    var caption: Color { ink.opacity(0.78) }
}

/// Прямоугольный виджет (около 160×72 pt): цитата максимально крупно, снизу подпись с тонкой линейкой
struct LockQuoteCard: View {
    let text: String
    let reference: String
    var design: Font.Design = .serif
    /// Системная полупрозрачная плита; в макете внутри приложения рисуется своя
    var systemPlate: Bool = true
    /// Макет внутри приложения: рисуем так, как увидит экран блокировки (белым), хотя среда цветная
    var forceMono: Bool = false

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var palette: LockPalette {
        LockPalette(mono: forceMono || renderingMode != .fullColor)
    }

    private var khachkar: some View {
        Image("KhachkarRelief")
            .resizable()
            .scaledToFit()
            .grayscale(palette.mono ? 1 : 0)
    }

    var body: some View {
        ZStack {
            if systemPlate {
                AccessoryWidgetBackground()
            }

            // Хачкар справа, едва заметный: текст идёт поверх и остаётся читаемым
            khachkar
                .frame(height: 64)
                .opacity(0.24)
                .widgetAccentable()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 6)

            // Тонкая рамка, как поля листа рукописи
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(palette.rule.opacity(palette.mono ? 0.30 : 0.55), lineWidth: 0.7)
                .padding(2.5)
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 1.5) {
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

                HStack(spacing: 4) {
                    khachkar
                        .frame(height: 10)
                        .widgetAccentable()
                    Text(reference)
                        .font(.system(size: 9.5, weight: .semibold, design: design))
                        .italic()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(palette.caption)
                        .layoutPriority(1)
                    Rectangle()
                        .fill(palette.rule.opacity(palette.mono ? 0.35 : 0.6))
                        .frame(height: 0.6)
                        .widgetAccentable()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Круглый виджет: хачкар в кольце, а когда молитва прочитана — галочка
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
            Circle()
                .strokeBorder(palette.rule.opacity(palette.mono ? 0.40 : 0.65), lineWidth: 0.8)
                .padding(2.5)
                .widgetAccentable()
            if prayerDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(palette.ink)
            } else {
                Image("KhachkarRelief")
                    .resizable()
                    .scaledToFit()
                    .grayscale(palette.mono ? 1 : 0)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .widgetAccentable()
            }
        }
    }
}

/// Макет виджета на экране блокировки внутри приложения: обои, часы и сам виджет на полупрозрачной плите
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
                        .font(.system(size: 46, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.88))
                }
                LockQuoteCard(text: text, reference: reference, design: design, systemPlate: false, forceMono: true)
                    .frame(width: 160, height: 72)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.16)))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.vertical, 14)
        }
    }
}
