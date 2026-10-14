import SwiftUI

// MARK: - Отладочный предпросмотр «свечи в острове»
/// В симуляторе нельзя раскрыть остров и заблокировать экран из скрипта, поэтому для проверки вёрстки
/// (-openTab islandpreview) собираем макет из тех же вью, что показывает расширение виджетов.
/// В релизной сборке для устройств модификатор ничего не делает.
struct CandleIslandPreviewHook: ViewModifier {
    #if DEBUG || targetEnvironment(simulator)
    @State private var isShowing = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard UserDefaults.standard.string(forKey: "openTab") == "islandpreview" else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isShowing = true }
            }
            .fullScreenCover(isPresented: $isShowing) {
                if #available(iOS 16.2, *) {
                    CandleIslandPreviewView()
                }
            }
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
}

#if DEBUG || targetEnvironment(simulator)
@available(iOS 16.2, *)
struct CandleIslandPreviewView: View {
    private func sample(_ tier: CandleTier, burn: Double, name: String, intention: CandleIntention) -> CandleActivityAttributes {
        let duration = Double(tier.burnHours) * 3600
        let lit = Date().addingTimeInterval(-duration * burn)
        return CandleActivityAttributes(
            candleId: name,
            personName: name,
            tierRaw: tier.rawValue,
            intentionIcon: intention.icon,
            intentionTitle: intention.title(for: .russian),
            remainingLabel: "Осталось",
            localeIdentifier: AppLanguage.russian.localeCode,
            litDate: lit,
            expirationDate: lit.addingTimeInterval(duration)
        )
    }

    var body: some View {
        let big = sample(.generous, burn: 0.40, name: "Давид", intention: .gratitude)
        let small = sample(.freeDaily, burn: 0.05, name: "Анна", intention: .health)

        ScrollView {
            VStack(spacing: 26) {
                caption("Остров, свёрнутый")
                HStack(spacing: 18) {
                    compactIsland(big)
                    minimalIsland(small)
                }

                caption("Остров, раскрытый")
                expandedIsland(big)

                caption("Экран блокировки")
                CandleLockScreenView(attributes: small)
                    .background(CandleIslandPalette.background)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal, 12)
            }
            .padding(.vertical, 30)
        }
        .background(Color(red: 0.36, green: 0.34, blue: 0.32).ignoresSafeArea())
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
    }

    private func compactIsland(_ a: CandleActivityAttributes) -> some View {
        HStack {
            IslandCandleView(attributes: a).frame(width: 20, height: 30)
            Spacer(minLength: 56)
        }
        .padding(.horizontal, 14)
        .frame(width: 236, height: 37)
        .background(Capsule().fill(.black))
    }

    private func minimalIsland(_ a: CandleActivityAttributes) -> some View {
        IslandCandleView(attributes: a)
            .frame(width: 18, height: 28)
            .frame(width: 37, height: 37)
            .background(Circle().fill(.black))
    }

    private func expandedIsland(_ a: CandleActivityAttributes) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .top) {
                IslandCandleView(attributes: a).frame(width: 54, height: 80)
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    Color.clear.frame(width: 100, height: 22)
                    CandleIslandTitle(attributes: a, alignment: .center)
                }
                Spacer(minLength: 0)
                Color.clear.frame(width: 40, height: 40)
            }
            CandleBurnBar(attributes: a)
            CandleRemainingText(attributes: a)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 371)
        .background(RoundedRectangle(cornerRadius: 44, style: .continuous).fill(.black))
    }
}
#endif
