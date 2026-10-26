import SwiftUI

// MARK: - Вью свечи для Dynamic Island и экрана блокировки
// Файл подключён и к приложению, и к расширению виджетов: те же вью показывает отладочный
// предпросмотр в симуляторе (CandleIslandPreview), так что вёрстку можно проверить без устройства.
// Live Activity не умеет непрерывной анимации, поэтому пламя здесь — один выразительный кадр
// того же процедурного рендера, что рисует свечу в приложении.

enum CandleIslandPalette {
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.26)
    static let amberSoft = Color(red: 1.0, green: 0.84, blue: 0.52)
    static let background = Color(red: 0.075, green: 0.047, blue: 0.030)
}

@available(iOS 16.2, *)
struct IslandCandleView: View {
    let attributes: CandleActivityAttributes
    var showsNiche = false

    var body: some View {
        // Свечение рисуется до самых границ кадра; на чёрном фоне острова это даёт видимый прямоугольник,
        // поэтому по краям гасим его плавно (в нише у экрана блокировки рамка и так есть)
        if showsNiche {
            canvas
        } else {
            canvas.mask(edgeFade)
        }
    }

    private var canvas: some View {
        Canvas { context, size in
            CandleRenderer.draw(
                context,
                size: size,
                scene: CandleScene(
                    tier: attributes.tier,
                    time: 3.2 + attributes.flameSeed * 0.01,
                    seed: attributes.flameSeed,
                    burn: attributes.burn(),
                    isLit: attributes.burn() < 0.99,
                    showsNiche: showsNiche,
                    ignitionAge: nil,
                    quality: .compact
                )
            )
        }
    }

    private var edgeFade: some View {
        LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .white, location: 0.22),
                               .init(color: .white, location: 0.78), .init(color: .clear, location: 1)],
                       startPoint: .leading, endPoint: .trailing)
            .mask(
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .white, location: 0.14),
                                       .init(color: .white, location: 0.86), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            )
    }
}

/// Круговой индикатор «сколько ещё гореть»: система сама обновляет его по таймеру
@available(iOS 16.2, *)
struct CandleBurnRing: View {
    let attributes: CandleActivityAttributes

    var body: some View {
        ProgressView(
            timerInterval: attributes.litDate...max(attributes.litDate, attributes.expirationDate),
            countsDown: true,
            label: { EmptyView() },
            currentValueLabel: { EmptyView() }
        )
        .progressViewStyle(.circular)
        .tint(CandleIslandPalette.amber)
    }
}

/// Линейный индикатор для расширенного острова и экрана блокировки
@available(iOS 16.2, *)
struct CandleBurnBar: View {
    let attributes: CandleActivityAttributes

    var body: some View {
        ProgressView(
            timerInterval: attributes.litDate...max(attributes.litDate, attributes.expirationDate),
            countsDown: true,
            label: { EmptyView() },
            currentValueLabel: { EmptyView() }
        )
        .progressViewStyle(.linear)
        .tint(CandleIslandPalette.amber)
    }
}

/// Имя и намерение свечи
@available(iOS 16.2, *)
struct CandleIslandTitle: View {
    let attributes: CandleActivityAttributes
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(attributes.personName)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 5) {
                Image(systemName: attributes.intentionIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text(attributes.intentionTitle)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(CandleIslandPalette.amberSoft.opacity(0.9))
        }
    }
}

/// «Осталось 6 дн., 22 ч.» — формат и язык числа задаёт система, она же обновляет текст сама
@available(iOS 16.2, *)
struct CandleRemainingText: View {
    let attributes: CandleActivityAttributes

    var body: some View {
        HStack(spacing: 5) {
            Text(attributes.remainingLabel)
                .foregroundColor(.white.opacity(0.6))
            Text(attributes.expirationDate, style: .relative)
                .environment(\.locale, Locale(identifier: attributes.localeIdentifier))
                .foregroundColor(CandleIslandPalette.amberSoft)
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Экран блокировки (и баннер на устройствах без острова)
@available(iOS 16.2, *)
struct CandleLockScreenView: View {
    let attributes: CandleActivityAttributes

    var body: some View {
        HStack(spacing: 14) {
            IslandCandleView(attributes: attributes, showsNiche: true)
                .frame(width: 64, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(CandleIslandPalette.amber.opacity(0.28), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 9) {
                CandleIslandTitle(attributes: attributes)
                CandleBurnBar(attributes: attributes)
                CandleRemainingText(attributes: attributes)
                if let line = attributes.prayerLine, !line.isEmpty {
                    Text(line)
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
    }
}
