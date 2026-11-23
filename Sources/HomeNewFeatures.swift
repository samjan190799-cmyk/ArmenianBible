import SwiftUI

// MARK: - Плитка с символом для карточек главного экрана
/// Тёмная плитка 68×68, как у остальных карточек, но с системным символом вместо нарисованной картинки.
struct HomeSymbolTile: View {
    let symbol: String
    var tint: Color = Paper.gold
    var side: CGFloat = 68

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.sRGB, red: 0x2A / 255.0, green: 0x1D / 255.0, blue: 0x12 / 255.0, opacity: 1),
                            Color(.sRGB, red: 0x15 / 255.0, green: 0x10 / 255.0, blue: 0x0B / 255.0, opacity: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Image(systemName: symbol)
                .font(.system(size: side * 0.42, weight: .semibold))
                .foregroundColor(tint)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

// MARK: - Карточка раздела на главном экране (общий вид для головоломки, молитв по часам и итогов)
struct HomeFeatureCard: View {
    let symbol: String
    let label: String
    let labelColor: Color
    let title: String
    let subtitle: String
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let onOpen: () -> Void

    var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: 14) {
                HomeSymbolTile(symbol: symbol)

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(PaperFont.font(size: 10, weight: .semibold))
                        .foregroundColor(labelColor)
                        .tracking(1.2)
                    Text(title)
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(PaperFont.font(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
            .padding(14)
            .paperSheet(cornerRadius: 18)
            .padding(.horizontal, 20)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
    }
}

// MARK: - Окна новых разделов главного экрана
/// Три окна одним модификатором: цепочка модификаторов главного экрана и так длинная
struct HomeNewFeatureSheets: ViewModifier {
    @Binding var isShowingPuzzle: Bool
    @Binding var isShowingPrayerHours: Bool
    @Binding var isShowingRecap: Bool
    let colorScheme: ColorScheme?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingPuzzle) {
                VersePuzzleView()
                    .preferredColorScheme(colorScheme)
            }
            .sheet(isPresented: $isShowingPrayerHours) {
                PrayerHoursView()
                    .preferredColorScheme(colorScheme)
            }
            .sheet(isPresented: $isShowingRecap) {
                LuysRecapView()
                    .preferredColorScheme(colorScheme)
            }
    }
}
