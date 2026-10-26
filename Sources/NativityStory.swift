import SwiftUI
import UIKit

// MARK: - Мультфильм «Рождество Христово»
// Рисунок сцен — NativityArt.swift (Canvas, без картинок и видео). Подписи — стихи Евангелия из bible.db на языке приложения,
// поэтому текст всегда совпадает с тем, что читатель найдёт в Библии. Время истории общее: сцена и кадр выводятся из одного числа,
// так пауза, перемотка и возврат к началу сводятся к смене этого числа.

struct NativityCaption {
    /// Секунда сцены, с которой показывается подпись
    let from: Double
    let book: Int
    let chapter: Int
    let verses: ClosedRange<Int>
}

struct NativityScene {
    let duration: Double
    let captions: [NativityCaption]
}

struct NativityCaptionText {
    let reference: String
    let text: String
}

enum NativityStory {
    static let luke = 42
    static let matthew = 40

    static let scenes: [NativityScene] = [
        NativityScene(duration: 12, captions: [
            NativityCaption(from: 0.8, book: luke, chapter: 2, verses: 4...5)
        ]),
        NativityScene(duration: 11, captions: [
            NativityCaption(from: 0.8, book: luke, chapter: 2, verses: 6...6)
        ]),
        NativityScene(duration: 14, captions: [
            NativityCaption(from: 1.0, book: luke, chapter: 2, verses: 7...7)
        ]),
        NativityScene(duration: 15, captions: [
            NativityCaption(from: 0.6, book: luke, chapter: 2, verses: 8...8),
            NativityCaption(from: 5.0, book: luke, chapter: 2, verses: 10...11),
            NativityCaption(from: 10.5, book: luke, chapter: 2, verses: 14...14)
        ]),
        NativityScene(duration: 12, captions: [
            NativityCaption(from: 0.6, book: matthew, chapter: 2, verses: 2...2),
            NativityCaption(from: 6.5, book: matthew, chapter: 2, verses: 9...10)
        ]),
        NativityScene(duration: 13, captions: [
            NativityCaption(from: 0.8, book: matthew, chapter: 2, verses: 11...11)
        ]),
        NativityScene(duration: 7, captions: [
            NativityCaption(from: 0.5, book: luke, chapter: 2, verses: 19...19)
        ])
    ]

    static var total: Double { scenes.reduce(0) { $0 + $1.duration } }

    /// Секунда истории, с которой начинается сцена
    static func start(of index: Int) -> Double {
        scenes.prefix(index).reduce(0) { $0 + $1.duration }
    }

    /// Какая сцена идёт в момент time и сколько секунд от её начала
    static func locate(_ time: Double) -> (index: Int, time: Double) {
        var rest = time
        for (index, scene) in scenes.enumerated() {
            if rest < scene.duration || index == scenes.count - 1 {
                return (index, min(max(rest, 0), scene.duration))
            }
            rest -= scene.duration
        }
        return (0, 0)
    }

    /// Стих Евангелия: подпись «Луки 2:7» и текст на языке приложения. Сноски переводчика в фигурных скобках убираем
    static func text(for caption: NativityCaption, language: AppLanguage) -> NativityCaptionText {
        let database = BibleDatabase.shared
        let parts = caption.verses.compactMap { verse in
            database.getVerseText(bookId: caption.book, chapter: caption.chapter, verse: verse)?.text(for: language)
        }
        let cleaned = parts
            .map { $0.replacingOccurrences(of: "\\{[^}]*\\}", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
        let name = database.getBook(id: caption.book)?.name ?? ""
        let low = caption.verses.lowerBound
        let high = caption.verses.upperBound
        let range = low == high ? "\(low)" : "\(low)–\(high)"
        return NativityCaptionText(reference: "\(name) \(caption.chapter):\(range)", text: cleaned)
    }
}

// MARK: - Экран мультфильма

struct NativityStoryView: View {
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var subscription = SubscriptionManager.shared

    /// Секунда истории на момент последнего запуска или паузы
    @State private var baseTime: Double
    /// Когда историю запустили; nil — пауза
    @State private var resumeDate: Date?

    /// Конец истории: сначала предложение Premium, потом окно оценки
    @State private var isShowingOffer = false
    @State private var isShowingPaywall = false
    @State private var isShowingReview = false

    private let captionTexts: [[NativityCaptionText]]
    private let crossfade = 0.9

    /// debugScene и debugSecond нужны для съёмки кадров в CI: история встаёт на паузу в заданной сцене и секунде
    init(debugScene: Int? = nil, debugSecond: Double = 0) {
        let language = BibleManager.shared.appLanguage
        captionTexts = NativityStory.scenes.map { scene in
            scene.captions.map { NativityStory.text(for: $0, language: language) }
        }
        if let index = debugScene, NativityStory.scenes.indices.contains(index) {
            _baseTime = State(initialValue: NativityStory.start(of: index) + debugSecond)
            _resumeDate = State(initialValue: nil)
        } else if UserDefaults.standard.bool(forKey: "nativity_finish") {
            _baseTime = State(initialValue: NativityStory.total - 0.5)
            _resumeDate = State(initialValue: Date())
        } else {
            _baseTime = State(initialValue: 0)
            _resumeDate = State(initialValue: Date())
        }
    }

    private func storyTime(at date: Date) -> Double {
        let running = resumeDate.map { date.timeIntervalSince($0) } ?? 0
        return min(NativityStory.total, max(0, baseTime + running))
    }

    private func seek(to time: Double) {
        baseTime = min(max(0, time), NativityStory.total - 0.01)
        if resumeDate != nil { resumeDate = Date() }
    }

    private func togglePlay(at time: Double) {
        if resumeDate == nil {
            baseTime = time >= NativityStory.total - 0.05 ? 0 : time
            resumeDate = Date()
        } else {
            baseTime = time
            resumeDate = nil
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = storyTime(at: timeline.date)
            let place = NativityStory.locate(t)
            let ambient = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Color.black.ignoresSafeArea()

                Canvas { context, size in
                    if place.index > 0 && place.time < crossfade {
                        let previous = place.index - 1
                        NativityArt.render(scene: previous, time: NativityStory.scenes[previous].duration, ambient: ambient, size: size, in: &context)
                        context.drawLayer { layer in
                            layer.opacity = place.time / crossfade
                            NativityArt.render(scene: place.index, time: place.time, ambient: ambient, size: size, in: &layer)
                        }
                    } else {
                        NativityArt.render(scene: place.index, time: place.time, ambient: ambient, size: size, in: &context)
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.80)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 380)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    header(time: t)
                    Spacer(minLength: 0)
                    captionView(index: place.index, time: place.time)
                    controls(time: t, index: place.index, sceneTime: place.time)
                }

                titleView(time: t)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Funnel.track("feature_used", ["feature": "nativity"])
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .task(id: resumeDate) {
            // Ждём конца истории: пауза или перемотка перезапускают этот ожидатель, закрытие экрана отменяет его
            guard let started = resumeDate else { return }
            let remaining = NativityStory.total - storyTime(at: started)
            guard remaining > 0 else { return }
            // Последний кадр задерживается на секунду, чтобы человек успел его увидеть
            try? await Task.sleep(nanoseconds: UInt64((remaining + 1.2) * 1_000_000_000))
            guard !Task.isCancelled, resumeDate == started else { return }
            finishStory()
        }
        .overlay {
            if isShowingOffer { offerOverlay }
        }
        .sheet(isPresented: $isShowingPaywall, onDismiss: {
            // Купил — самое время спросить об оценке; закрыл подписку без покупки — второй раз не беспокоим
            if subscription.isPremium { askForReview() }
        }) {
            PaywallView(source: "nativity_end")
        }
        .sheet(isPresented: $isShowingReview) {
            ReviewPromptSheetView()
        }
        .onChange(of: scenePhase) { phase in
            // Свернули приложение: останавливаем историю там, где она была
            if phase != .active, resumeDate != nil {
                baseTime = storyTime(at: Date())
                resumeDate = nil
            }
        }
    }

    // MARK: Конец истории: предложение Premium и окно оценки

    /// Предложение показываем не чаще раза в сутки; в TestFlight и отладке всегда, чтобы его можно было проверить
    private var offerAllowed: Bool {
        if Bundle.isTestFlightOrDebug { return true }
        guard let last = UserDefaults.standard.object(forKey: "nativity_offer_last") as? Date else { return true }
        return Date().timeIntervalSince(last) > 86_400
    }

    private func finishStory() {
        Funnel.track("feature_used", ["feature": "nativity_finished"])
        if !subscription.isPremium, offerAllowed {
            UserDefaults.standard.set(Date(), forKey: "nativity_offer_last")
            Funnel.track("feature_used", ["feature": "nativity_offer_shown"])
            Haptics.notify(.success)
            withAnimation(.easeInOut(duration: 0.35)) { isShowingOffer = true }
        } else {
            askForReview()
        }
    }

    private func acceptOffer() {
        Funnel.track("feature_used", ["feature": "nativity_offer_accepted"])
        withAnimation(.easeInOut(duration: 0.25)) { isShowingOffer = false }
        isShowingPaywall = true
    }

    private func declineOffer() {
        Funnel.track("feature_used", ["feature": "nativity_offer_declined"])
        withAnimation(.easeInOut(duration: 0.25)) { isShowingOffer = false }
        askForReview()
    }

    /// Окно оценки: не чаще раза в неделю и только тому, кто ещё не оценил
    private func askForReview() {
        guard ReviewManager.shared.canPromptNow else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            ReviewManager.shared.markPromptShown()
            isShowingReview = true
        }
    }

    private var offerOverlay: some View {
        let language = manager.appLanguage
        return ZStack {
            Color.black.opacity(0.66).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundColor(NP.gold)
                Text(language.pick(hy: "Բացեք Luys-ը ամբողջությամբ", ru: "Откройте Luys целиком", en: "Unlock all of Luys"))
                    .font(PaperFont.font(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(language.pick(
                    hy: "Ձեռագիր և կոդեքս, աղոթքի մոմեր, ամբողջ Նարեկացին, սրբավայրերի քարտեզ և անսահմանափակ AI: Չեղարկումը՝ ցանկացած պահի:",
                    ru: "Рукопись и кодекс, молитвенные свечи, весь Нарекаци, карта святынь и безлимитный ИИ. Отмена в любой момент.",
                    en: "Manuscript and codex, prayer candles, all of Narekatsi, the map of sanctuaries and unlimited AI. Cancel anytime."
                ))
                .font(PaperFont.font(size: 15))
                .foregroundColor(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                Button {
                    Haptics.impact(.medium)
                    acceptOffer()
                } label: {
                    Text(language.pick(hy: "Ձեռք բերել Premium", ru: "Оформить Premium", en: "Get Premium"))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(NP.gold))
                }
                .padding(.top, 4)
                Button {
                    Haptics.impact(.light)
                    declineOffer()
                } label: {
                    Text(language.pick(hy: "Հիմա ոչ", ru: "Не сейчас", en: "Not now"))
                        .font(PaperFont.font(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.vertical, 6)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(white: 0.09).opacity(0.96)))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }

    // MARK: Верх: полоски сцен и закрытие

    private func header(time: Double) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<NativityStory.scenes.count, id: \.self) { index in
                    let fill = nvClamp((time - NativityStory.start(of: index)) / NativityStory.scenes[index].duration)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.28))
                            Capsule().fill(Color.white.opacity(0.92)).frame(width: geo.size.width * CGFloat(fill))
                        }
                    }
                    .frame(height: 3)
                }
            }
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                }
                .accessibilityLabel(Text(manager.appLanguage.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Название в начале

    @ViewBuilder
    private func titleView(time: Double) -> some View {
        let alpha = nvEase(time / 1.2) * (1 - nvEase((time - 3.4) / 1.2))
        if alpha > 0.001 {
            VStack(spacing: 10) {
                Text(manager.appLanguage.pick(hy: "Քրիստոսի ծնունդը", ru: "Рождество Христово", en: "The Nativity"))
                    .font(PaperFont.font(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)
                Text(manager.appLanguage.pick(hy: "Ըստ Ղուկասի և Մատթեոսի Ավետարանների", ru: "По Евангелиям от Луки и Матфея", en: "From the Gospels of Luke and Matthew"))
                    .font(PaperFont.font(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 1)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 92)
            .opacity(alpha)
            .allowsHitTesting(false)
        }
    }

    // MARK: Подпись: стих Евангелия

    @ViewBuilder
    private func captionView(index: Int, time: Double) -> some View {
        let captions = NativityStory.scenes[index].captions
        VStack(spacing: 10) {
            if let current = captions.lastIndex(where: { $0.from <= time }) {
                let end = current + 1 < captions.count ? captions[current + 1].from : NativityStory.scenes[index].duration
                let fadeIn = min(1, (time - captions[current].from) / 0.7)
                let fadeOut = min(1, (end - time) / 0.6)
                let alpha = max(0, min(fadeIn, fadeOut))
                let content = captionTexts[index][current]
                Text(content.text)
                    .font(PaperFont.font(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .lineLimit(9)
                    .minimumScaleFactor(0.7)
                    .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 1)
                    .opacity(alpha)
                Text(content.reference.uppercased())
                    .font(PaperFont.font(size: 12, weight: .semibold))
                    .tracking(1.6)
                    .foregroundColor(NP.gold)
                    .opacity(alpha)
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
    }

    // MARK: Управление

    private func controls(time: Double, index: Int, sceneTime: Double) -> some View {
        let finished = time >= NativityStory.total - 0.05
        let playing = resumeDate != nil
        return HStack(spacing: 40) {
            Button {
                Haptics.impact(.light)
                let start = NativityStory.start(of: index)
                seek(to: sceneTime > 2 || index == 0 ? start : NativityStory.start(of: index - 1))
            } label: {
                controlIcon("backward.end.fill", size: 20)
            }
            Button {
                Haptics.impact(.light)
                togglePlay(at: time)
            } label: {
                controlIcon(finished ? "arrow.counterclockwise" : (playing ? "pause.fill" : "play.fill"), size: 26)
            }
            Button {
                Haptics.impact(.light)
                if index + 1 < NativityStory.scenes.count {
                    seek(to: NativityStory.start(of: index + 1))
                } else {
                    seek(to: NativityStory.total)
                }
            } label: {
                controlIcon("forward.end.fill", size: 20)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 22)
    }

    private func controlIcon(_ name: String, size: CGFloat) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color.white.opacity(0.14)))
    }
}

// MARK: - Карточка на главном экране

struct NativityBannerCardView: View {
    let language: AppLanguage
    let secondaryAccentColor: Color
    let primaryTextColor: Color
    let onOpen: () -> Void

    var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: 16) {
                PaperIconBadge(tint: Paper.gold) {
                    Image(systemName: "film")
                        .font(.system(size: 19, weight: .light))
                        .foregroundColor(Paper.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.pick(hy: "ՄՈՒԼՏՖԻԼՄ", ru: "МУЛЬТФИЛЬМ", en: "ANIMATION"))
                        .font(PaperFont.font(size: 10, weight: .semibold))
                        .foregroundColor(Paper.cinnabar)
                        .tracking(1.2)
                    Text(language.pick(hy: "Քրիստոսի ծնունդը", ru: "Рождество Христово", en: "The Nativity"))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(language.pick(
                        hy: "Ավետարանական պատմություն շարժման մեջ՝ Ղուկասի և Մատթեոսի խոսքերով",
                        ru: "Евангельская история в движении, словами Луки и Матфея",
                        en: "The Gospel story in motion, in the words of Luke and Matthew"
                    ))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(secondaryAccentColor)
                    .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
            .padding(16)
            .paperSheet(cornerRadius: 18)
            .padding(.horizontal, 20)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
    }
}
