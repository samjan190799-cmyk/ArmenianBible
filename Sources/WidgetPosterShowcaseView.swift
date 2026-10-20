import SwiftUI

// Отладочный экран для съёмки в CI: все три размера виджета-постера на одном экране.
// Запуск: -openTab widgetposters -poster_art ararat|khachkar|parchment|night
struct WidgetPosterShowcaseView: View {
    @ObservedObject private var manager = BibleManager.shared

    private var art: PosterArt {
        PosterArt(rawValue: UserDefaults.standard.string(forKey: "poster_art") ?? "ararat") ?? .ararat
    }

    private func verse(_ refEn: String, in pool: [BibleVerse]) -> BibleVerse {
        pool.first(where: { $0.refEn == refEn }) ?? pool[0]
    }

    var body: some View {
        let language = manager.appLanguage
        let small = verse("John 8:12", in: BibleVerse.shortPearls)
        let medium = verse("Luke 1:37", in: BibleVerse.shortPearls)
        let large = verse("Romans 8:28", in: BibleVerse.database)
        ZStack {
            Color(red: 0.09, green: 0.09, blue: 0.11).ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    PosterWidgetLayout(art: art, size: .small, text: small.text(for: language), reference: small.reference(for: language)) {
                        PosterGlassIcon(symbol: "arrow.clockwise", tint: art.mainColor, size: 30)
                    }
                    .frame(width: 170, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    Spacer(minLength: 0)
                }
                PosterWidgetLayout(art: art, size: .medium, text: medium.text(for: language), reference: medium.reference(for: language)) {
                    PosterGlassIcon(symbol: "arrow.clockwise", tint: art.mainColor, size: 30)
                }
                .frame(width: 364, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                PosterWidgetLayout(art: art, size: .large, text: large.text(for: language), reference: large.reference(for: language)) {
                    HStack(spacing: 8) {
                        PosterGlassIcon(symbol: "hands.sparkles.fill", tint: art.mainColor, size: 34)
                        PosterGlassIcon(symbol: "heart", tint: art.mainColor, size: 34)
                        PosterGlassIcon(symbol: "arrow.clockwise", tint: art.mainColor, size: 34)
                    }
                }
                .frame(width: 364, height: 382)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(width: 364)
            .padding(.top, 48)
        }
    }
}
