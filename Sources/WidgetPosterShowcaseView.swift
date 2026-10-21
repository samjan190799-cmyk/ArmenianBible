import SwiftUI

// Отладочный экран для съёмки в CI: все три размера виджета-постера на одном экране.
// Запуск: -openTab widgetposters -poster_art ararat|khachkar|parchment|night [-poster_extreme short|long]
// С -poster_extreme берутся самая короткая или самая длинная цитата каждого размера: так видно, помещается ли худший случай.
// Справа от малого постера — два макета виджета экрана блокировки (самая короткая и самая длинная фраза).
struct WidgetPosterShowcaseView: View {
    @ObservedObject private var manager = BibleManager.shared

    private var art: PosterArt {
        PosterArt(rawValue: UserDefaults.standard.string(forKey: "poster_art") ?? "ararat") ?? .ararat
    }

    private var extreme: String {
        UserDefaults.standard.string(forKey: "poster_extreme") ?? ""
    }

    private func verse(_ refEn: String, in pool: [BibleVerse]) -> BibleVerse {
        pool.first(where: { $0.refEn == refEn }) ?? pool[0]
    }

    /// Самая короткая или самая длинная цитата размера на языке показа
    private func sample(_ tier: QuoteTier, mode: String, language: AppLanguage, fallback: BibleVerse) -> BibleVerse {
        let pool = BibleVerse.quotes(for: tier, lang: language, isPremium: true, lockCategory: .pearls, homeCategory: .all)
        let ordered = pool.sorted { QuoteLength.of($0, lang: language) < QuoteLength.of($1, lang: language) }
        return (mode == "long" ? ordered.last : ordered.first) ?? fallback
    }

    var body: some View {
        let language = manager.appLanguage
        let small = extreme.isEmpty ? verse("John 8:12", in: BibleVerse.shortPearls) : sample(.small, mode: extreme, language: language, fallback: BibleVerse.shortPearls[0])
        let medium = extreme.isEmpty ? verse("Luke 1:37", in: BibleVerse.shortPearls) : sample(.medium, mode: extreme, language: language, fallback: BibleVerse.shortPearls[0])
        let large = extreme.isEmpty ? verse("Romans 8:28", in: BibleVerse.database) : sample(.large, mode: extreme, language: language, fallback: BibleVerse.database[0])
        let lockShort = sample(.lockScreen, mode: "short", language: language, fallback: BibleVerse.shortPearls[0])
        let lockLong = sample(.lockScreen, mode: "long", language: language, fallback: BibleVerse.shortPearls[0])
        ZStack {
            Color(red: 0.09, green: 0.09, blue: 0.11).ignoresSafeArea()
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    PosterWidgetLayout(art: art, size: .small, text: small.text(for: language), reference: small.reference(for: language)) {
                        PosterGlassIcon(symbol: "arrow.clockwise", tint: art.mainColor, size: 30)
                    }
                    .frame(width: 170, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    VStack(spacing: 12) {
                        LockWidgetMock(verse: lockShort, language: language)
                        LockWidgetMock(verse: lockLong, language: language)
                    }
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

/// Макет прямоугольного виджета экрана блокировки (160×72) с той же раскладкой, что в BibleWidget.swift
private struct LockWidgetMock: View {
    let verse: BibleVerse
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            FittedQuoteText(text: verse.text(for: language), maxSize: 24, minScale: 0.6, weight: .semibold, design: .default, lineSpacing: -0.5)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack(spacing: 3) {
                Text("✝")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(verse.reference(for: language))
                    .font(.system(size: 9.5, weight: .semibold))
                    .italic()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundColor(.white.opacity(0.7))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(4)
        .frame(width: 160, height: 72)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.14)))
    }
}
