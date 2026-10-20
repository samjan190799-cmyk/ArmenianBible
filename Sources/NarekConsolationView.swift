import SwiftUI

// MARK: - Экран «Нарек утешает»
struct NarekConsolationView: View {
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var subscription = SubscriptionManager.shared
    @ObservedObject private var audioPlayer = NarekAudioPlayer.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedThemes: Set<ConsolationTheme> = []
    @State private var text = ""
    @State private var matches: [NarekMatch] = []
    @State private var matchIndex = 0
    @State private var showsFullText = false
    @State private var showsCareNote = false
    @State private var isLimitReached = false
    @State private var isShowingPaywall = false
    @State private var manuscriptLaunch: ManuscriptLaunch?
    @State private var aiWord: String?
    @State private var isAskingAI = false
    @State private var aiFailed = false
    @FocusState private var isTextFocused: Bool

    private static let feature = "narek_consolation"
    private var language: AppLanguage { manager.appLanguage }
    private var isPremium: Bool { subscription.isPremium }
    private var current: NarekMatch? { matches.indices.contains(matchIndex) ? matches[matchIndex] : nil }

    /// Озвучка есть на армянском и русском; англоязычному пользователю читает русский голос
    private var voice: AppLanguage { language == .armenian ? .armenian : .russian }

    private var hasAIKey: Bool {
        switch manager.activeProvider {
        case .gemini: return !manager.geminiApiKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .chatgpt: return !manager.openaiApiKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .claude: return !manager.anthropicApiKey.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        moodChips
                        inputField
                        findButton
                        if showsCareNote { careNote }
                        if isLimitReached { limitCard }
                        if let match = current {
                            resultCard(match)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        if !isPremium { footerNote }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Paper.inkSecondary)
                    }
                    .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .fullScreenCover(item: $manuscriptLaunch) { launch in
            ManuscriptStudioView(source: launch.source)
        }
        .onReceive(audioPlayer.$paywallRequested) { requested in
            if requested {
                audioPlayer.paywallRequested = false
                isShowingPaywall = true
            }
        }
        .onAppear { runLaunchArguments() }
    }

    // MARK: Шапка
    private var header: some View {
        VStack(spacing: 10) {
            PaperOrnament(width: 44)
            Text(language.pick(hy: "Նարեկը մխիթարում է", ru: "Нарек утешает", en: "Narek Consoles"))
                .font(PaperFont.font(size: 30, weight: .semibold))
                .foregroundColor(Paper.ink)
            Text(language.pick(
                hy: "Մեկ նախադասությամբ ասեք՝ ինչ կա սրտում: Հավելվածը կգտնի ձեզ համար աղոթք Գրիգոր Նարեկացու ոգով:",
                ru: "Скажите одной фразой, что на сердце. Приложение найдёт для вас молитву в духе Григора Нарекаци.",
                en: "Say in a single sentence what is on your heart. The app will find a prayer in the spirit of Grigor Narekatsi for you."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        .padding(.top, 4)
    }

    // MARK: Состояния души
    private var moodChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(ConsolationTheme.allCases) { theme in
                let isSelected = selectedThemes.contains(theme)
                Button {
                    Haptics.selection()
                    if isSelected { selectedThemes.remove(theme) } else { selectedThemes.insert(theme) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: theme.symbol)
                            .font(.system(size: 12))
                        Text(theme.title(for: language))
                            .font(PaperFont.font(size: 13, weight: .medium))
                    }
                    .foregroundColor(isSelected ? Paper.onAccent : Paper.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(isSelected ? Paper.cinnabar : Paper.sheet))
                    .overlay(Capsule().strokeBorder(isSelected ? Paper.cinnabar : Paper.hairline, lineWidth: 1))
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.95))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputField: some View {
        TextField(
            language.pick(
                hy: "Ինչ կա սրտում: Օրինակ՝ «Վախենում եմ մերձավորիս համար»",
                ru: "Что на сердце? Например: «Мне страшно за близкого»",
                en: "What is on your heart? For example: \"I am afraid for someone I love\""
            ),
            text: $text,
            axis: .vertical
        )
        .lineLimit(2...5)
        .font(PaperFont.font(size: 16))
        .foregroundColor(Paper.ink)
        .padding(14)
        .paperField(cornerRadius: 14)
        .focused($isTextFocused)
        .submitLabel(.done)
    }

    private var findButton: some View {
        let canSearch = !selectedThemes.isEmpty || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            search()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "leaf")
                Text(language.pick(hy: "Գտնել մխիթարանքի խոսք", ru: "Найти слово утешения", en: "Find a word of comfort"))
                    .font(PaperFont.font(size: 16, weight: .semibold))
            }
            .foregroundColor(Paper.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Paper.ink))
            .opacity(canSearch ? 1 : 0.4)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.97))
        .disabled(!canSearch)
    }

    // MARK: Бережное слово
    private var careNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "heart")
                    .foregroundColor(Paper.cinnabar)
                Text(language.pick(hy: "Դուք մենակ չեք", ru: "Вы не одни", en: "You are not alone"))
                    .font(PaperFont.font(size: 16, weight: .semibold))
                    .foregroundColor(Paper.ink)
            }
            Text(language.pick(
                hy: "Խոսեք մտերիմ մարդու հետ հենց հիմա: Վտանգի դեպքում զանգահարեք շտապ օգնության ծառայություն՝ 112:",
                ru: "Поговорите с близким человеком прямо сейчас. Если вам грозит опасность, позвоните в службу экстренной помощи: 112.",
                en: "Please talk to someone close to you right now. If you are in danger, call your local emergency number (112 in Armenia and across Europe)."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSheet(cornerRadius: 16)
    }

    // MARK: Дневной лимит
    private var limitCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 22))
                .foregroundColor(Paper.gold)
            Text(language.pick(
                hy: "Այսօրվա անվճար խոսքը արդեն ստացել եք",
                ru: "Бесплатное слово на сегодня уже получено",
                en: "You have already received today's free word"
            ))
            .font(PaperFont.font(size: 16, weight: .semibold))
            .foregroundColor(Paper.ink)
            .multilineTextAlignment(.center)
            Text(language.pick(
                hy: "Premium-ով՝ անսահմանափակ խոսքեր և այլ աղոթքներ:",
                ru: "С Premium — без ограничений и с подбором других молитв.",
                en: "With Premium: unlimited words and other prayers."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            Button {
                Haptics.impact(.soft)
                isShowingPaywall = true
            } label: {
                Text(language.pick(hy: "Բացել Premium", ru: "Открыть Premium", en: "Unlock Premium"))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(Paper.onAccent)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Paper.cinnabar))
            }
            .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.95))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 18)
    }

    private var footerNote: some View {
        Text(language.pick(
            hy: "Անվճար՝ օրը մեկ խոսք: Premium՝ առանց սահմանափակման:",
            ru: "Бесплатно — одно слово в день. Premium — без ограничений.",
            en: "Free: one word a day. Premium: unlimited."
        ))
        .font(PaperFont.font(size: 12))
        .foregroundColor(Paper.inkTertiary)
        .multilineTextAlignment(.center)
    }

    // MARK: Найденная глава
    private func resultCard(_ match: NarekMatch) -> some View {
        let stanza = match.firstStanza(for: language)
        let rest = match.restOfText(for: language)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(language.pick(hy: "ԱՂՈԹՔ ՆԱՐԵԿԱՑՈՒ ՈԳՈՎ", ru: "МОЛИТВА В ДУХЕ НАРЕКАЦИ", en: "A PRAYER IN THE SPIRIT OF NAREKATSI"))
                    .font(PaperFont.font(size: 11, weight: .semibold))
                    .foregroundColor(Paper.cinnabar)
                    .tracking(1.4)
                Spacer()
            }

            Text(match.prayer.inspiredTitle(for: language))
                .font(PaperFont.font(size: 19, weight: .semibold))
                .foregroundColor(Paper.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(stanza)
                .font(PaperFont.font(size: 17))
                .foregroundColor(Paper.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 14)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Paper.gold.opacity(0.7))
                        .frame(width: 2)
                }

            if !rest.isEmpty {
                if showsFullText {
                    Text(rest)
                        .font(PaperFont.font(size: 16))
                        .foregroundColor(Paper.ink.opacity(0.9))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
                Button {
                    Haptics.selection()
                    withAnimation(PaperMotion.swap) { showsFullText.toggle() }
                } label: {
                    Text(showsFullText
                         ? language.pick(hy: "Թաքցնել", ru: "Свернуть", en: "Collapse")
                         : language.pick(hy: "Կարդալ ամբողջ աղոթքը", ru: "Читать молитву целиком", en: "Read the whole prayer"))
                        .font(PaperFont.font(size: 14, weight: .medium))
                        .foregroundColor(Paper.gold)
                }
            }

            if let aiWord {
                VStack(alignment: .leading, spacing: 6) {
                    Text(language.pick(hy: "ԽՈՍՔ ՁԵԶ ՀԱՄԱՐ", ru: "СЛОВО ДЛЯ ВАС", en: "A WORD FOR YOU"))
                        .font(PaperFont.font(size: 10, weight: .semibold))
                        .foregroundColor(Paper.inkTertiary)
                        .tracking(1.2)
                    Text(aiWord)
                        .font(PaperFont.font(size: 15))
                        .foregroundColor(Paper.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.fillSubtle))
            }

            actionButtons(match)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSheet(cornerRadius: 20)
    }

    private func actionButtons(_ match: NarekMatch) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                resultButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: language.pick(hy: "Այլ աղոթք", ru: "Другая молитва", en: "Another prayer"),
                    isLocked: !isPremium,
                    isProminent: true
                ) {
                    nextMatch()
                }
            }
            HStack(spacing: 10) {
                resultButton(
                    icon: "scroll",
                    title: language.pick(hy: "Ձեռագրի վրա", ru: "На рукопись", en: "To manuscript"),
                    isLocked: false,
                    isProminent: false
                ) {
                    openManuscript(match)
                }
                if hasAIKey {
                    resultButton(
                        icon: isAskingAI ? "hourglass" : "sparkles",
                        title: language.pick(hy: "Անձնական խոսք", ru: "Личное слово", en: "Personal word"),
                        isLocked: false,
                        isProminent: false
                    ) {
                        askAI(match)
                    }
                }
            }
            if aiFailed {
                Text(language.pick(
                    hy: "ԱԲ-ն հիմա չպատասխանեց: Փորձեք ավելի ուշ:",
                    ru: "ИИ сейчас не ответил. Попробуйте позже.",
                    en: "The AI did not answer right now. Please try again later."
                ))
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkTertiary)
            }
        }
    }

    private func resultButton(icon: String, title: String, isLocked: Bool, isProminent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: isLocked ? "lock" : icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isProminent ? Paper.onAccent : Paper.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isProminent ? Paper.cinnabar : Paper.fillSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isProminent ? Color.clear : Paper.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.95))
    }

    // MARK: Логика
    private func search() {
        isTextFocused = false
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard PremiumTaste.isAllowed(Self.feature, freePerDay: 1) else {
            Haptics.notify(.warning)
            withAnimation(PaperMotion.appear) { isLimitReached = true }
            return
        }
        isLimitReached = false
        showsCareNote = NarekConsolationEngine.needsGentleCare(trimmed)
        let ranked = NarekConsolationEngine.rank(text: trimmed, chips: selectedThemes, language: language)
        guard !ranked.isEmpty else { return }
        PremiumTaste.record(Self.feature)
        Haptics.notify(.success)
        aiWord = nil
        aiFailed = false
        showsFullText = false
        withAnimation(PaperMotion.appear) {
            matches = ranked
            matchIndex = 0
        }
    }

    private func nextMatch() {
        guard isPremium else {
            Haptics.impact(.soft)
            isShowingPaywall = true
            return
        }
        guard !matches.isEmpty else { return }
        Haptics.selection()
        aiWord = nil
        aiFailed = false
        showsFullText = false
        withAnimation(PaperMotion.appear) {
            matchIndex = (matchIndex + 1) % matches.count
        }
    }

    private func listen(_ match: NarekMatch) {
        guard subscription.canPlayNarekAudio(prayerId: match.prayer.id) else {
            Haptics.impact(.soft)
            isShowingPaywall = true
            return
        }
        Haptics.impact(.soft)
        audioPlayer.togglePlay(prayer: match.prayer, language: voice)
    }

    private func openManuscript(_ match: NarekMatch) {
        Haptics.impact(.soft)
        let line = match.firstStanza(for: language)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let page = ManuscriptPage(
            text: line,
            reference: language.pick(hy: "Նարեկացու ոգով", ru: "В духе Нарекаци", en: "In the spirit of Narekatsi"),
            language: language,
            style: ManuscriptPage.preferredStyle,
            name: ManuscriptPage.rememberedName
        )
        manuscriptLaunch = ManuscriptLaunch(source: .curated(first: page))
    }

    /// Личное слово пишет ИИ по ключу самого человека и только по нажатию кнопки
    private func askAI(_ match: NarekMatch) {
        guard !isAskingAI else { return }
        guard subscription.canAskAI() else {
            isShowingPaywall = true
            return
        }
        isAskingAI = true
        aiFailed = false
        let prompt = Self.aiPrompt(
            language: language,
            feeling: text.trimmingCharacters(in: .whitespacesAndNewlines),
            themes: selectedThemes.map { $0.title(for: language) },
            chapterTitle: match.prayer.inspiredTitle(for: language)
        )
        manager.generateTextFromAI(prompt: prompt) { result in
            isAskingAI = false
            switch result {
            case .success(let answer):
                let cleaned = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.isEmpty {
                    aiFailed = true
                } else {
                    subscription.recordAiQuestionUsed()
                    withAnimation(PaperMotion.appear) { aiWord = cleaned }
                    Haptics.notify(.success)
                }
            case .failure:
                aiFailed = true
            }
        }
    }

    private static func aiPrompt(language: AppLanguage, feeling: String, themes: [String], chapterTitle: String) -> String {
        let state = ([feeling] + themes).filter { !$0.isEmpty }.joined(separator: "; ")
        switch language {
        case .russian:
            return "Ты тихий духовный собеседник в духе святого Григора Нарекаци. Человек говорит о себе: «\(state)». Ему предложена молитва «\(chapterTitle)». Напиши два коротких тёплых предложения утешения на русском: без цитат, без медицинских советов, без обещаний чудес и без поучений. Если в словах человека слышна мысль о самоубийстве, мягко посоветуй поговорить с близким человеком и обратиться в службу экстренной помощи. Больше ничего не пиши."
        case .armenian:
            return "Դու լուռ հոգևոր զրուցակից ես՝ Գրիգոր Նարեկացու ոգով: Մարդը ասում է իր մասին՝ «\(state)»: Նրան առաջարկվել է «\(chapterTitle)» աղոթքը: Գրիր մխիթարանքի երկու կարճ, ջերմ նախադասություն հայերենով՝ առանց մեջբերումների, բժշկական խորհուրդների, հրաշքների խոստումների և խրատների: Եթե խոսքերում ինքնասպանության միտք է զգացվում, մեղմորեն խորհուրդ տուր խոսել մտերիմի հետ և դիմել շտապ օգնության: Ուրիշ ոչինչ մի գրիր:"
        case .english:
            return "You are a quiet spiritual companion in the spirit of St. Grigor Narekatsi. A person says about themselves: \"\(state)\". The prayer \"\(chapterTitle)\" has been offered to them. Write two short, warm sentences of consolation in English: no quotations, no medical advice, no promises of miracles and no moralizing. If the words hint at suicide, gently suggest talking to someone close and contacting emergency services. Write nothing else."
        }
    }

    /// Аргументы запуска для скриншотов в CI: -consolation_text "..." -consolation_chips sorrow,fear
    private func runLaunchArguments() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "consolation_reset") { PremiumTaste.reset(Self.feature) }
        let launchText = defaults.string(forKey: "consolation_text")
        let launchChips = defaults.string(forKey: "consolation_chips")
        guard launchText != nil || launchChips != nil else { return }
        if let launchText { text = launchText }
        if let launchChips {
            selectedThemes = Set(launchChips.split(separator: ",").compactMap { ConsolationTheme(rawValue: String($0)) })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            search()
            if defaults.bool(forKey: "consolation_full") { showsFullText = true }
        }
    }
}

// MARK: - Карточка на главном экране
struct NarekConsolationBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let primaryTextColor: Color
    let onOpen: () -> Void

    @ObservedObject private var subscription = SubscriptionManager.shared

    var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: 16) {
                PaperIconBadge(tint: Paper.cinnabar) {
                    Image(systemName: "leaf")
                        .font(.system(size: 19, weight: .light))
                        .foregroundColor(Paper.cinnabar)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(language.pick(hy: "ՆԱՐԵԿԸ ՄԽԻԹԱՐՈՒՄ Է", ru: "НАРЕК УТЕШАЕТ", en: "NAREK CONSOLES"))
                            .font(PaperFont.font(size: 10, weight: .semibold))
                            .foregroundColor(Paper.cinnabar)
                            .tracking(1.2)
                        if !subscription.isPremium {
                            Text("PREMIUM")
                                .font(PaperFont.font(size: 8, weight: .semibold))
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .overlay(Capsule().strokeBorder(Paper.gold.opacity(0.6), lineWidth: 0.8))
                        }
                    }
                    Text(language.pick(hy: "Ասացեք, ինչ կա սրտում", ru: "Скажите, что на сердце", en: "Tell what is on your heart"))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(language.pick(
                        hy: "Կգտնենք ձեզ համար աղոթք Նարեկացու ոգով",
                        ru: "Найдём для вас молитву в духе Нарекаци",
                        en: "We will find a prayer in the spirit of Narekatsi for you"
                    ))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(secondaryAccentColor)
                    .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
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
