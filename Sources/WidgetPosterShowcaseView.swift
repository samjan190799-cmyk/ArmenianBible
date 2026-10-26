import SwiftUI

// Отладочный экран для съёмки в CI: все три размера виджета-постера на одном экране.
// Запуск: -openTab widgetposters -poster_art ararat|khachkar|parchment|night [-poster_extreme short|long]
// С -poster_extreme берутся самая короткая или самая длинная цитата каждого размера: так видно, помещается ли худший случай.
// Справа от малого постера — два макета виджета экрана блокировки (самая короткая и самая длинная фраза).
// С -poster_ref long под всеми тремя постерами подставляется самая длинная подпись стиха на языке показа:
// так видно, что подпись не обрезается многоточием (на виджете нет ни короны, ни PRO, место занимают только кнопки).
struct WidgetPosterShowcaseView: View {
    @ObservedObject private var manager = BibleManager.shared

    private var art: PosterArt {
        PosterArt(rawValue: UserDefaults.standard.string(forKey: "poster_art") ?? "ararat") ?? .ararat
    }

    private var extreme: String {
        UserDefaults.standard.string(forKey: "poster_extreme") ?? ""
    }

    private var longReference: Bool {
        UserDefaults.standard.string(forKey: "poster_ref") == "long"
    }

    /// Подпись под постером: обычная или, с -poster_ref long, самая длинная среди всех цитат
    private func reference(of verse: BibleVerse, language: AppLanguage) -> String {
        guard longReference else { return verse.reference(for: language) }
        return BibleVerse.database
            .map { $0.reference(for: language) }
            .max { $0.count < $1.count } ?? verse.reference(for: language)
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
                    PosterWidgetLayout(art: art, size: .small, text: small.text(for: language), reference: reference(of: small, language: language)) {
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
                PosterWidgetLayout(art: art, size: .medium, text: medium.text(for: language), reference: reference(of: medium, language: language)) {
                    PosterGlassIcon(symbol: "arrow.clockwise", tint: art.mainColor, size: 30)
                }
                .frame(width: 364, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                PosterWidgetLayout(art: art, size: .large, text: large.text(for: language), reference: reference(of: large, language: language)) {
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

/// Макет прямоугольного виджета экрана блокировки (160×72): тот же LockQuoteCard, что в BibleWidget.swift, на обоях
private struct LockWidgetMock: View {
    let verse: BibleVerse
    let language: AppLanguage

    var body: some View {
        LockQuoteCard(
            text: verse.text(for: language),
            reference: verse.reference(for: language),
            design: .serif,
            forceMono: true
        )
        .frame(width: 160, height: 72)
        .background(
            LinearGradient(colors: [Color(red: 0.09, green: 0.10, blue: 0.24), Color(red: 0.55, green: 0.25, blue: 0.35)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(-6)
        )
    }
}
