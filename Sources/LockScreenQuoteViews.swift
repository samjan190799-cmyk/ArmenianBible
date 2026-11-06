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
/// цитата максимально крупно на всю высоту, до трёх строк (подписи с номером нет: она отнимала место у третьей строки)
struct LockQuoteCard: View {
    let text: String
    let reference: String
    var design: Font.Design = .serif
    /// Макет внутри приложения: рисуем так, как увидит экран блокировки (белым), хотя среда цветная
    var forceMono: Bool = false

    // Размеры карточки. Их же использует подбор цитат в виджете (`quoteArea`, `fitsAtSmallestSize`),
    // поэтому менять их надо здесь, а не в разметке ниже: иначе подбор будет считать место по-старому.
    static let barWidth: CGFloat = 2.5
    static let columnSpacing: CGFloat = 7
    static let verticalPadding: CGFloat = 2
    static let maxFontSize: CGFloat = 24
    /// 0,5 даёт 12 pt: при таком размере в виджет высотой около 55 pt помещаются три строки (при 14 pt только две)
    static let minScale: CGFloat = 0.5
    static let lineSpacing: CGFloat = -0.5

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var palette: LockPalette {
        LockPalette(mono: forceMono || renderingMode != .fullColor)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Self.columnSpacing) {
            Capsule()
                .fill(palette.rule.opacity(palette.mono ? 0.65 : 0.95))
                .frame(width: Self.barWidth)
                .padding(.vertical, 1)
                .widgetAccentable()

            // Номер цитаты с экрана убран: место отдано третьей строке. Ссылка остаётся в описании для VoiceOver
            FittedQuoteText(
                text: text,
                maxSize: Self.maxFontSize,
                minScale: Self.minScale,
                weight: .semibold,
                design: design,
                lineSpacing: Self.lineSpacing
            )
            .foregroundColor(palette.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.vertical, Self.verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("(text) (reference)"))
    }
}

// MARK: - Сколько места у цитаты в прямоугольном виджете
extension LockQuoteCard {
    /// Область под цитату внутри виджета заданного размера: без вертикальной черты и отступов
    static func quoteArea(in widget: CGSize) -> CGSize {
        CGSize(
            width: widget.width - barWidth - columnSpacing,
            height: widget.height - verticalPadding * 2
        )
    }

    /// Помещается ли цитата в виджет самым мелким из допустимых размеров, то есть целиком при любом выборе шрифта.
    /// По числу знаков этого не понять: армянские слова длинные и широкие, а места по высоте на две-три строки.
    static func fitsAtSmallestSize(_ text: String, design: Font.Design, widget: CGSize) -> Bool {
        let size = (maxFontSize * minScale).rounded()
        let font = QuoteFont.uiFont(size: size, weight: .semibold, design: design)
        return QuoteFit.fits(text, font: font, lineSpacing: lineSpacing * minScale, in: quoteArea(in: widget))
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
