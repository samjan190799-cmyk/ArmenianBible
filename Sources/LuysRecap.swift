import SwiftUI
import UIKit

// MARK: - «Мой путь с Luys»: итоги одной карточкой
// Собирает то, что уже считает приложение (чтение, викторины, серия у Древа, головоломки, избранное),
// и рисует красивую карточку, которой можно поделиться. Ничего нового не отправляется и не хранится.

/// Одна цифра на карточке
struct RecapStat: Identifiable {
    let id: String
    let value: String
    let caption: String
    let symbol: String
}

/// Всё, что нужно для показа и для картинки
struct LuysRecapSnapshot {
    var items: [RecapStat] = []
    var favoriteBook: String? = nil

    /// Карточка осмысленна, когда есть хотя бы две цифры
    var hasEnoughToShow: Bool { items.count >= 2 }
}

// MARK: Сбор данных
@MainActor
enum LuysRecapData {
    static func snapshot(manager: BibleManager, language: AppLanguage) -> LuysRecapSnapshot {
        var items: [RecapStat] = []

        func add(_ id: String, _ number: Int, _ symbol: String, hy: String, ru: String, en: String) {
            guard number > 0 else { return }
            items.append(RecapStat(id: id, value: "\(number)", caption: language.pick(hy: hy, ru: ru, en: en), symbol: symbol))
        }

        // Главы Писания и дни чтения
        let chapters = manager.readChaptersByBook.values.reduce(0) { $0 + $1.count }
        add("chapters", chapters, "book.closed.fill", hy: "գլուխ ընթերցված", ru: "глав прочитано", en: "chapters read")

        let calendar = Calendar.current
        var readingDays = Set<Date>()
        for book in manager.readingProgress.books.values {
            for stamp in book.read.values where stamp > 0 {
                readingDays.insert(calendar.startOfDay(for: Date(timeIntervalSince1970: stamp)))
            }
        }
        add("readingDays", readingDays.count, "calendar", hy: "օր ընթերցանություն", ru: "дней с чтением", en: "days of reading")

        // Сколько дней с приложением (дата первого запуска хранится воронкой, только на телефоне)
        if let first = UserDefaults.standard.object(forKey: "funnel_first_open") as? Date {
            let days = (calendar.dateComponents([.day], from: calendar.startOfDay(for: first), to: calendar.startOfDay(for: Date())).day ?? 0) + 1
            add("daysWithLuys", days, "sparkles", hy: "օր Luys-ի հետ", ru: "дней с Luys", en: "days with Luys")
        }

        // Викторина
        let achievements = AchievementsManager.shared
        add("quizRounds", achievements.completedRoundsCount, "questionmark.circle.fill", hy: "վիկտորինա խաղացված", ru: "викторин сыграно", en: "quizzes played")
        add("correct", achievements.totalCorrectAnswers, "checkmark.circle.fill", hy: "ճիշտ պատասխան", ru: "верных ответов", en: "correct answers")

        // Древо, головоломки, избранное
        add("tree", PomegranateTreeManager.shared.daysStreak, "leaf.fill", hy: "օր անընդմեջ", ru: "дней подряд у Древа", en: "days in a row")
        add("puzzles", VersePuzzleStore.shared.totalSolved, "puzzlepiece.extension.fill", hy: "հանելուկ լուծված", ru: "головоломок решено", en: "puzzles solved")
        add("favorites", manager.favoriteVerses.count, "heart.fill", hy: "սիրելի համար", ru: "стихов в избранном", en: "favorite verses")

        // Любимая книга: где прочитано больше всего глав
        var favoriteBook: String? = nil
        if let top = manager.readChaptersByBook.max(by: { $0.value.count < $1.value.count }), top.value.count > 0,
           let book = ScriptureReferenceParser.book(id: top.key) {
            switch language {
            case .armenian: favoriteBook = book.nameHy
            case .russian: favoriteBook = book.nameRu
            case .english: favoriteBook = book.nameEn
            }
        }

        return LuysRecapSnapshot(items: items, favoriteBook: favoriteBook)
    }
}

// MARK: Карточка-плакат (из неё делается картинка)
struct LuysRecapPoster: View {
    let items: [RecapStat]
    let favoriteBook: String?
    let language: AppLanguage

    private let gold = Color(.sRGB, red: 0xC9 / 255.0, green: 0xA4 / 255.0, blue: 0x5C / 255.0, opacity: 1)
    private let cream = Color(.sRGB, red: 0xF1 / 255.0, green: 0xE3 / 255.0, blue: 0xC2 / 255.0, opacity: 1)
    private let darkTop = Color(.sRGB, red: 0x2B / 255.0, green: 0x1A / 255.0, blue: 0x10 / 255.0, opacity: 1)
    private let darkBottom = Color(.sRGB, red: 0x15 / 255.0, green: 0x10 / 255.0, blue: 0x0B / 255.0, opacity: 1)

    static let width: CGFloat = 360
    static let height: CGFloat = 450

    private var tileRows: [[RecapStat]] {
        let tiles = Array(items.dropFirst().prefix(4))
        return stride(from: 0, to: tiles.count, by: 2).map { start in
            Array(tiles[start..<min(start + 2, tiles.count)])
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [darkTop, darkBottom], startPoint: .top, endPoint: .bottom)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(gold.opacity(0.35), lineWidth: 1)
                .padding(12)

            VStack(spacing: 0) {
                Text("LUYS")
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .tracking(5)
                    .foregroundColor(gold)

                Text(language.pick(hy: "Իմ ճանապարհը Luys-ի հետ", ru: "Мой путь с Luys", en: "My journey with Luys"))
                    .font(PaperFont.font(size: 25, weight: .semibold))
                    .foregroundColor(cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 6)

                Spacer(minLength: 10)

                if let hero = items.first {
                    VStack(spacing: 4) {
                        Image(systemName: hero.symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(gold.opacity(0.9))
                        Text(hero.value)
                            .font(PaperFont.font(size: 62, weight: .semibold))
                            .foregroundColor(gold)
                        Text(hero.caption)
                            .font(PaperFont.font(size: 15, weight: .medium))
                            .foregroundColor(cream.opacity(0.85))
                    }
                }

                Spacer(minLength: 14)

                VStack(spacing: 10) {
                    ForEach(tileRows.indices, id: \.self) { index in
                        HStack(spacing: 10) {
                            ForEach(tileRows[index]) { stat in
                                statTile(stat)
                            }
                            if tileRows[index].count == 1 {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                if let favoriteBook {
                    Text(language.pick(
                        hy: "Սիրելի գիրք՝ \(favoriteBook)",
                        ru: "Любимая книга: \(favoriteBook)",
                        en: "Favorite book: \(favoriteBook)"
                    ))
                    .font(PaperFont.font(size: 12, weight: .medium))
                    .foregroundColor(cream.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 12)
                }

                Spacer(minLength: 12)

                Text("Luys · Armenian Bible & AI")
                    .font(PaperFont.font(size: 11, weight: .medium))
                    .foregroundColor(cream.opacity(0.55))
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 32)
        }
        .frame(width: Self.width, height: Self.height)
    }

    private func statTile(_ stat: RecapStat) -> some View {
        VStack(spacing: 2) {
            Text(stat.value)
                .font(PaperFont.font(size: 26, weight: .semibold))
                .foregroundColor(gold)
            Text(stat.caption)
                .font(PaperFont.font(size: 11, weight: .medium))
                .foregroundColor(cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(gold.opacity(0.25), lineWidth: 1))
    }
}

// MARK: Экран итогов
struct LuysRecapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared

    @State private var snapshot = LuysRecapSnapshot()
    @State private var shareItems: [Any] = []
    @State private var isSharing = false

    private var language: AppLanguage { manager.appLanguage }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if snapshot.hasEnoughToShow {
                            posterPreview
                            shareButton
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            reload()
            Funnel.track("feature_used", ["feature": "recap_opened"])
        }
        .onChange(of: manager.appLanguage) { _ in reload() }
        .sheet(isPresented: $isSharing) {
            ActivityView(activityItems: shareItems)
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Paper.ink.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Text(language.pick(hy: "Իմ ճանապարհը", ru: "Мой путь", en: "My journey"))
                .font(PaperFont.font(size: 18, weight: .semibold))
                .foregroundColor(Paper.ink)

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var posterPreview: some View {
        let scale = min(1.0, (UIScreen.main.bounds.width - 40) / LuysRecapPoster.width)
        return LuysRecapPoster(items: snapshot.items, favoriteBook: snapshot.favoriteBook, language: language)
            .scaleEffect(scale, anchor: .top)
            .frame(width: LuysRecapPoster.width * scale, height: LuysRecapPoster.height * scale)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Paper.shadow, radius: 14, y: 6)
    }

    private var shareButton: some View {
        Button {
            share()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up.fill")
                Text(language.pick(hy: "Կիսվել քարտով", ru: "Поделиться карточкой", en: "Share the card"))
                    .font(PaperFont.font(size: 16, weight: .semibold))
            }
            .foregroundColor(Paper.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Paper.accentFill)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 34))
                .foregroundColor(Paper.gold)
            Text(language.pick(
                hy: "Այստեղ կհայտնվի ձեր ճանապարհը",
                ru: "Здесь появится ваш путь",
                en: "Your journey will appear here"
            ))
            .font(PaperFont.font(size: 17, weight: .semibold))
            .foregroundColor(Paper.ink)
            Text(language.pick(
                hy: "Կարդացեք մի քանի գլուխ, խաղացեք վիկտորինա կամ լուծեք օրվա հանելուկը, և այստեղ կերևա ձեր վիճակագրությունը",
                ru: "Прочитайте несколько глав, сыграйте в викторину или решите головоломку дня, и здесь появится ваша статистика",
                en: "Read a few chapters, play a quiz or solve the puzzle of the day, and your stats will appear here"
            ))
            .font(PaperFont.font(size: 13))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
        .padding(.top, 20)
    }

    private func reload() {
        snapshot = LuysRecapData.snapshot(manager: manager, language: language)
    }

    /// Картинка 1080×1350 из карточки и подпись со ссылкой на приложение
    private func share() {
        let poster = LuysRecapPoster(items: snapshot.items, favoriteBook: snapshot.favoriteBook, language: language)
        let renderer = ImageRenderer(content: poster)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        let text = language.pick(hy: "Իմ ճանապարհը Luys-ի հետ", ru: "Мой путь с Luys", en: "My journey with Luys")
            + " https://apps.apple.com/app/id\(ReviewManager.shared.appStoreID)"
        shareItems = [image, text]
        isSharing = true
        Funnel.track("feature_used", ["feature": "recap_shared"])
    }
}

// MARK: Карточка на главном экране
struct LuysRecapBannerCardView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    let onOpen: () -> Void

    var body: some View {
        HomeFeatureCard(
            symbol: "rosette",
            label: language.pick(hy: "ՁԵՐ ԱՄՓՈՓԸ", ru: "ВАШИ ИТОГИ", en: "YOUR RECAP"),
            labelColor: Paper.terracotta,
            title: language.pick(hy: "Իմ ճանապարհը Luys-ի հետ", ru: "Мой путь с Luys", en: "My journey with Luys"),
            subtitle: language.pick(
                hy: "Ձեր վիճակագրությունը մեկ քարտով",
                ru: "Ваша статистика одной карточкой",
                en: "Your stats on one card"
            ),
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryAccentColor,
            onOpen: onOpen
        )
    }
}
