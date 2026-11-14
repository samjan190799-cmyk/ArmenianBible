import SwiftUI

// MARK: - Тексты дуэли онлайн
enum LiveDuelText {
    static func shareMessage(code: String, url: URL, _ language: AppLanguage) -> String {
        let text = language.pick(
            hy: "Խաղանք Աստվածաշնչի վիկտորինա ուղիղ եթերում: Սենյակի կոդը՝ \(code)",
            ru: "Сыграем в библейскую викторину онлайн! Код комнаты: \(code)",
            en: "Let's play a live Bible quiz! Room code: \(code)"
        )
        return text + "\n" + url.absoluteString
    }

    static func error(_ code: String, _ language: AppLanguage) -> String {
        switch code {
        case "not_found":
            return language.pick(hy: "Այդպիսի սենյակ չկա կամ այն արդեն փակվել է", ru: "Такой комнаты нет или она уже закрыта", en: "There is no such room, or it has already closed")
        case "full":
            return language.pick(hy: "Սենյակում արդեն երկու խաղացող կա", ru: "В комнате уже двое игроков", en: "The room already has two players")
        case "exists":
            return language.pick(hy: "Այս կոդը զբաղված է. փորձեք նորից", ru: "Этот код уже занят: попробуйте ещё раз", en: "That code is taken, please try again")
        case "network":
            return language.pick(hy: "Չհաջողվեց միանալ. ստուգեք ինտերնետը", ru: "Не удалось подключиться: проверьте интернет", en: "Could not connect. Check your internet")
        case "mismatch":
            return language.pick(
                hy: "Հարցերի շտեմարանները տարբեր են. երկուսն էլ թող թարմացնեն հավելվածը",
                ru: "У вас разные версии базы вопросов: обновите приложение у обоих",
                en: "The question banks differ: both of you should update the app"
            )
        default:
            return language.pick(hy: "Սխալ տեղի ունեցավ", ru: "Что-то пошло не так", en: "Something went wrong")
        }
    }
}

// MARK: - Вход: создать комнату или войти по коду
struct LiveDuelEntryView: View {
    let language: AppLanguage
    let accentColor: Color
    let primaryTextColor: Color
    let categoryTitle: String
    let onCreate: () -> Void
    let onJoin: (String) -> Void
    let onClose: () -> Void

    @AppStorage("luys_manuscript_name") private var name = ""
    @State private var codeText = ""

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(primaryTextColor.opacity(0.6))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, 16)

                    Image(systemName: "bolt.horizontal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(accentColor)
                    Text(language.pick(hy: "Ուղիղ մենամարտ", ru: "Дуэль онлайн", en: "Live duel"))
                        .font(PaperFont.font(size: 22, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Text(language.pick(
                        hy: "Երկուսով միաժամանակ պատասխանեք նույն հարցերին. ով ավելի շատ ճիշտ պատասխան տա՝ հաղթում է:",
                        ru: "Вдвоём одновременно отвечайте на одни и те же вопросы: побеждает тот, у кого больше верных ответов.",
                        en: "You both answer the same questions at the same time: whoever gets more right wins."
                    ))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                    TextField(
                        language.pick(hy: "Ձեր անունը", ru: "Ваше имя", en: "Your name"),
                        text: $name
                    )
                    .font(PaperFont.font(size: 15))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .paperField(cornerRadius: 12)

                    VStack(spacing: 8) {
                        Button {
                            Haptics.impact(.soft)
                            onCreate()
                        } label: {
                            Text(language.pick(hy: "Ստեղծել սենյակ", ru: "Создать комнату", en: "Create a room"))
                                .font(PaperFont.font(size: 16, weight: .semibold))
                                .foregroundColor(Paper.onAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Paper.accentFill)
                                .cornerRadius(16)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        Text(categoryTitle)
                            .font(PaperFont.font(size: 12))
                            .foregroundColor(Paper.inkSecondary)
                    }

                    Text(language.pick(hy: "կամ", ru: "или", en: "or"))
                        .font(PaperFont.font(size: 13))
                        .foregroundColor(Paper.inkSecondary)

                    TextField(
                        language.pick(hy: "Սենյակի կոդ", ru: "Код комнаты", en: "Room code"),
                        text: $codeText
                    )
                    .font(PaperFont.font(size: 22, weight: .semibold).monospaced())
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .padding(.vertical, 12)
                    .paperField(cornerRadius: 12)
                    .onChange(of: codeText) { value in
                        let normalized = LiveDuelCode.normalize(value)
                        if normalized != value { codeText = normalized }
                    }

                    Button {
                        Haptics.impact(.soft)
                        onJoin(codeText)
                    } label: {
                        Text(language.pick(hy: "Միանալ", ru: "Войти", en: "Join"))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(accentColor.opacity(0.6), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!LiveDuelCode.isValid(codeText))
                    .opacity(LiveDuelCode.isValid(codeText) ? 1 : 0.45)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: 680)
        }
    }
}

// MARK: - Экран дуэли онлайн
struct LiveDuelView: View {
    let launch: LiveDuelLaunch

    @ObservedObject private var manager = BibleManager.shared
    @StateObject private var client: LiveDuelClient
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [QuizQuestion] = []
    @State private var questionsSeed = 0
    @State private var mismatch = false
    @State private var share: PairShareItem?
    @State private var reported = false

    init(launch: LiveDuelLaunch) {
        self.launch = launch
        _client = StateObject(wrappedValue: LiveDuelClient(
            code: launch.code,
            name: ManuscriptPage.rememberedName,
            config: launch.config
        ))
    }

    private var language: AppLanguage { manager.appLanguage }
    private var accentColor: Color { manager.accentTheme.color }

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                topBar
                content
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            Funnel.track("feature_used", ["feature": launch.config == nil ? "live_join" : "live_create"])
            client.connect()
        }
        .onReceive(client.$state) { syncQuestions($0) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            client.reconnectNow()
        }
        .sheet(item: $share) { item in
            ActivityView(activityItems: item.items)
        }
    }

    // MARK: Верхняя полоса
    private var topBar: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                leaveAndClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Paper.ink.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
            Text(language.pick(hy: "Ուղիղ մենամարտ", ru: "Дуэль онлайн", en: "Live duel"))
                .font(PaperFont.font(size: 18, weight: .semibold))
                .foregroundColor(Paper.ink)
            Spacer()

            if client.link != .online && client.failure == nil {
                ProgressView().frame(width: 24, height: 24)
            } else {
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Содержимое по фазам
    @ViewBuilder
    private var content: some View {
        if let failure = client.failure {
            messageView(icon: "wifi.exclamationmark", text: LiveDuelText.error(failure, language))
        } else if mismatch {
            messageView(icon: "exclamationmark.triangle.fill", text: LiveDuelText.error("mismatch", language))
        } else if let state = client.state {
            switch state.phase {
            case "lobby":
                lobby(state)
            case "countdown":
                countdown(state)
            case "playing":
                LiveDuelPlayView(
                    state: state,
                    questions: questions,
                    language: language,
                    accentColor: accentColor,
                    serverNow: { client.serverNow() },
                    onAnswer: { q, correct, ms in client.answer(q: q, correct: correct, ms: ms) }
                )
            default:
                finished(state)
            }
        } else {
            VStack(spacing: 14) {
                Spacer()
                ProgressView()
                Text(language.pick(hy: "Միանում ենք սենյակին…", ru: "Подключаемся к комнате…", en: "Connecting to the room…"))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)
                Spacer()
            }
        }
    }

    private func messageView(icon: String, text: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(accentColor)
            Text(text)
                .font(PaperFont.font(size: 16))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                leaveAndClose()
            } label: {
                Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close"))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            Spacer()
        }
    }

    // MARK: Лобби
    private func lobby(_ state: LiveDuelState) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Text(language.pick(hy: "Սենյակի կոդ", ru: "Код комнаты", en: "Room code"))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(Paper.inkSecondary)
                    .padding(.top, 8)
                Text(state.code)
                    .font(PaperFont.font(size: 44, weight: .semibold).monospaced())
                    .tracking(6)
                    .foregroundColor(Paper.gold)
                if let config = state.config {
                    Text(QuizDuelText.categoryLine(config.asDuel, language))
                        .font(PaperFont.font(size: 13, weight: .medium))
                        .foregroundColor(Paper.inkSecondary)
                }

                Button {
                    Haptics.impact(.soft)
                    shareRoom(code: state.code)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text(language.pick(hy: "Ուղարկել հրավերը", ru: "Отправить приглашение", en: "Send the invite"))
                            .font(PaperFont.font(size: 15, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.6), lineWidth: 1.2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(spacing: 10) {
                    ForEach(Array(state.players.enumerated()), id: \.offset) { _, player in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(player.connected ? Paper.moss : Paper.inkSecondary.opacity(0.4))
                                .frame(width: 9, height: 9)
                            Text(displayName(player))
                                .font(PaperFont.font(size: 16, weight: .medium))
                                .foregroundColor(Paper.ink)
                            Spacer()
                            if !player.connected {
                                Text(language.pick(hy: "կապից դուրս է", ru: "не в сети", en: "offline"))
                                    .font(PaperFont.font(size: 12))
                                    .foregroundColor(Paper.inkSecondary)
                            }
                        }
                    }
                    if state.players.count < 2 {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(language.pick(hy: "Սպասում ենք ընկերոջը…", ru: "Ждём друга…", en: "Waiting for your friend…"))
                                .font(PaperFont.font(size: 15))
                                .foregroundColor(Paper.inkSecondary)
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .paperSheet(cornerRadius: 16)

                if state.isHost {
                    let ready = state.players.count == 2 && state.players.allSatisfy { $0.connected }
                    Button {
                        Haptics.impact(.medium)
                        client.startGame()
                    } label: {
                        Text(language.pick(hy: "Սկսել", ru: "Начать", en: "Start"))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(Paper.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Paper.accentFill)
                            .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!ready)
                    .opacity(ready ? 1 : 0.45)
                } else {
                    Text(language.pick(
                        hy: "Սպասում ենք, որ սենյակը ստեղծողը սկսի խաղը",
                        ru: "Ждём, пока создатель комнаты начнёт игру",
                        en: "Waiting for the room's host to start the game"
                    ))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: Обратный отсчёт
    private func countdown(_ state: LiveDuelState) -> some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let remaining = max(0, ((state.startsAt ?? 0) - client.serverNow()) / 1000)
            VStack(spacing: 16) {
                Spacer()
                Text(language.pick(hy: "Պատրաստվեք", ru: "Приготовьтесь", en: "Get ready"))
                    .font(PaperFont.font(size: 18, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
                Text("\(max(1, Int(remaining.rounded(.up))))")
                    .font(PaperFont.font(size: 96, weight: .semibold).monospacedDigit())
                    .foregroundColor(accentColor)
                if let config = state.config {
                    Text(QuizDuelText.categoryLine(config.asDuel, language))
                        .font(PaperFont.font(size: 13, weight: .medium))
                        .foregroundColor(Paper.inkSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: Итог
    private func finished(_ state: LiveDuelState) -> some View {
        let mine = state.me?.score ?? 0
        let theirs = state.opponent?.score ?? 0
        let total = state.config?.n ?? 0
        let opponentName = state.opponent.map { displayName($0) } ?? QuizDuelText.opponent(nil, language)
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 46))
                    .foregroundColor(accentColor)
                    .padding(.top, 8)

                if state.abandoned == "opponent" {
                    Text(language.pick(hy: "Մրցակիցը դուրս եկավ խաղից", ru: "Соперник вышел из игры", en: "Your opponent left the game"))
                        .font(PaperFont.font(size: 18, weight: .semibold))
                        .foregroundColor(Paper.gold)
                        .multilineTextAlignment(.center)
                } else {
                    Text(QuizDuelText.verdict(mine: mine, theirs: theirs, language))
                        .font(PaperFont.font(size: 20, weight: .semibold))
                        .foregroundColor(Paper.gold)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 24) {
                    scoreColumn(title: language.pick(hy: "Դուք", ru: "Вы", en: "You"), score: mine, total: total)
                    Text(":")
                        .font(PaperFont.font(size: 30, weight: .semibold))
                        .foregroundColor(Paper.inkSecondary)
                    scoreColumn(title: opponentName, score: theirs, total: total)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .paperSheet(cornerRadius: 16)
                .onAppear { reportFinish() }

                let canRematch = state.opponent != nil && state.abandoned == nil
                if canRematch {
                    let iAsked = state.me?.rematch ?? false
                    Button {
                        Haptics.impact(.soft)
                        client.rematch()
                    } label: {
                        Text(iAsked
                             ? language.pick(hy: "Սպասում ենք մրցակցին…", ru: "Ждём соперника…", en: "Waiting for your opponent…")
                             : language.pick(hy: "Ռեվանշ", ru: "Реванш", en: "Rematch"))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(Paper.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Paper.accentFill)
                            .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(iAsked)
                    .opacity(iAsked ? 0.6 : 1)
                    if state.opponent?.rematch == true && !iAsked {
                        Text(language.pick(hy: "Մրցակիցը ռեվանշ է ուզում", ru: "Соперник хочет реванш", en: "Your opponent wants a rematch"))
                            .font(PaperFont.font(size: 13))
                            .foregroundColor(Paper.inkSecondary)
                    }
                }

                Button {
                    leaveAndClose()
                } label: {
                    Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close"))
                        .font(PaperFont.font(size: 14, weight: .medium))
                        .foregroundColor(Paper.inkSecondary)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    private func scoreColumn(title: String, score: Int, total: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(score) / \(total)")
                .font(PaperFont.font(size: 30, weight: .semibold).monospacedDigit())
                .foregroundColor(Paper.ink)
            Text(title)
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .lineLimit(1)
        }
    }

    // MARK: Помощники
    private func displayName(_ player: LiveDuelPlayer) -> String {
        if player.you {
            let suffix = language.pick(hy: " (Դուք)", ru: " (вы)", en: " (you)")
            return (player.name.isEmpty ? language.pick(hy: "Դուք", ru: "Вы", en: "You") : player.name + suffix)
        }
        return player.name.isEmpty ? QuizDuelText.opponent(nil, language) : player.name
    }

    private func shareRoom(code: String) {
        guard let url = LiveDuelCode.inviteURL(code) else { return }
        share = PairShareItem(items: [LiveDuelText.shareMessage(code: code, url: url, language)])
    }

    private func reportFinish() {
        guard !reported else { return }
        reported = true
        Funnel.track("feature_used", ["feature": "live_finish"])
    }

    /// Вопросы получаются из «семени» комнаты; при реванше «семя» новое, и вопросы собираются заново
    private func syncQuestions(_ state: LiveDuelState?) {
        guard let config = state?.config else { return }
        guard config.s != questionsSeed || questions.isEmpty else { return }
        questionsSeed = config.s
        if let ready = QuizDuelEngine.questions(for: config.asDuel) {
            questions = ready
            mismatch = false
        } else {
            questions = []
            mismatch = true
        }
    }

    private func leaveAndClose() {
        client.leave()
        dismiss()
    }
}

// MARK: - Сам вопрос: оба отвечают одновременно
struct LiveDuelPlayView: View {
    let state: LiveDuelState
    let questions: [QuizQuestion]
    let language: AppLanguage
    let accentColor: Color
    let serverNow: () -> Double
    /// Номер вопроса, верен ли ответ, сколько миллисекунд ушло на ответ
    let onAnswer: (Int, Bool, Int) -> Void

    @State private var picked: [Int: Int] = [:]

    var body: some View {
        if state.q < questions.count {
            let question = questions[state.q]
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    scoreboard
                    timerBar
                    VStack(spacing: 12) {
                        Text("\(state.q + 1) / \(state.config?.n ?? questions.count)")
                            .font(PaperFont.font(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundColor(Paper.inkSecondary)
                        Text(question.question(for: language))
                            .font(PaperFont.font(size: 18, weight: .semibold))
                            .foregroundColor(Paper.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .paperSheet(cornerRadius: 22)

                    let options = question.options(for: language)
                    VStack(spacing: 10) {
                        ForEach(0..<options.count, id: \.self) { index in
                            optionButton(index: index, text: options[index], question: question)
                        }
                    }

                    opponentLine
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        } else {
            VStack { Spacer(); ProgressView(); Spacer() }
        }
    }

    // MARK: Счёт
    private var scoreboard: some View {
        HStack {
            scoreCell(name: language.pick(hy: "Դուք", ru: "Вы", en: "You"), score: state.me?.score ?? 0, alignment: .leading)
            Spacer()
            scoreCell(
                name: (state.opponent?.name.isEmpty ?? true) ? QuizDuelText.opponent(nil, language) : (state.opponent?.name ?? ""),
                score: state.opponent?.score ?? 0,
                alignment: .trailing
            )
        }
        .padding(.top, 4)
    }

    private func scoreCell(name: String, score: Int, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text("\(score)")
                .font(PaperFont.font(size: 26, weight: .semibold).monospacedDigit())
                .foregroundColor(Paper.ink)
            Text(name)
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .lineLimit(1)
        }
    }

    // MARK: Время вопроса
    private var timerBar: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let total = max(1, state.questionMs / 1000)
            let left = state.isRevealing
                ? 0
                : max(0, ((state.qStart ?? 0) + state.questionMs - serverNow()) / 1000)
            let urgent = left <= 5 && !state.isRevealing
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(urgent ? Paper.cinnabar : Paper.inkSecondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Paper.ink.opacity(0.08))
                        Capsule()
                            .fill(urgent ? Paper.cinnabar : accentColor)
                            .frame(width: max(0, geo.size.width * CGFloat(left / total)))
                    }
                }
                .frame(height: 6)
                Text("\(Int(left.rounded(.up)))s")
                    .font(PaperFont.font(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundColor(urgent ? Paper.cinnabar : Paper.ink)
                    .frame(minWidth: 30, alignment: .trailing)
            }
        }
    }

    // MARK: Варианты ответа
    private func optionButton(index: Int, text: String, question: QuizQuestion) -> some View {
        let mine = picked[state.q]
        let revealing = state.isRevealing
        let isCorrect = index == question.correctAnswerIndex
        let isPicked = mine == index
        return Button {
            choose(index, question: question)
        } label: {
            HStack {
                Text(text)
                    .font(PaperFont.font(size: 15, weight: .medium))
                    .foregroundColor(Paper.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if revealing {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Paper.moss)
                    } else if isPicked {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Paper.cinnabar)
                    }
                } else if isPicked {
                    Image(systemName: "circle.inset.filled").foregroundColor(accentColor)
                }
            }
            .padding(16)
            .paperSheet(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isPicked && !revealing ? accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(mine != nil || revealing)
    }

    private func choose(_ index: Int, question: QuizQuestion) {
        guard picked[state.q] == nil, !state.isRevealing else { return }
        picked[state.q] = index
        Haptics.impact(.soft)
        let now = serverNow()
        let spent = Int(max(0, now - (state.qStart ?? now)))
        onAnswer(state.q, index == question.correctAnswerIndex, spent)
    }

    // MARK: Что делает соперник
    private var opponentLine: some View {
        let opponent = state.opponent
        let text: String
        if opponent?.connected == false {
            text = language.pick(hy: "Մրցակիցը կապից դուրս է…", ru: "Соперник потерял связь…", en: "Your opponent lost connection…")
        } else if state.isRevealing {
            if opponent?.answered != true {
                text = language.pick(hy: "Մրցակիցը չհասցրեց պատասխանել", ru: "Соперник не успел ответить", en: "Your opponent ran out of time")
            } else if opponent?.correct == true {
                text = language.pick(hy: "Մրցակիցը ճիշտ պատասխանեց", ru: "Соперник ответил верно", en: "Your opponent got it right")
            } else {
                text = language.pick(hy: "Մրցակիցը սխալվեց", ru: "Соперник ошибся", en: "Your opponent got it wrong")
            }
        } else if opponent?.answered == true {
            text = language.pick(hy: "Մրցակիցը պատասխանել է", ru: "Соперник уже ответил", en: "Your opponent has answered")
        } else {
            text = language.pick(hy: "Մրցակիցը մտածում է…", ru: "Соперник думает…", en: "Your opponent is thinking…")
        }
        return Text(text)
            .font(PaperFont.font(size: 13))
            .foregroundColor(Paper.inkSecondary)
            .padding(.top, 2)
    }
}
