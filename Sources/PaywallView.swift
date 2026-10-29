import SwiftUI
import StoreKit

// MARK: - Экран подписки
/// Тарифы и кнопка закреплены внизу, заголовок подстроен под то место, откуда человек пришёл, три главные выгоды вместо длинного списка.
/// Цена за месяц, процент выгоды и пробный период считаются из тарифов App Store, а не написаны вручную: обещать можно только то, что есть.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccessAlert: Bool = false
    @State private var showAllFeatures: Bool = false
    /// Для каких тарифов этому человеку доступен бесплатный пробный период (Apple даёт его не каждому)
    @State private var trialEligible: [String: Bool] = [:]

    private var language: AppLanguage {
        bibleManager.appLanguage
    }

    private var accentColor: Color {
        bibleManager.accentTheme.color
    }

    /// Откуда открыт экран: попадает в воронку, чтобы видеть, какие замки приводят к подписке, и выбирает заголовок
    private let source: String
    @State private var appearedAt = Date()

    init(source: String = "unknown") {
        self.source = source
    }

    private func planCode(_ plan: SubscriptionPlan) -> String {
        plan == .yearly ? "yearly" : "monthly"
    }

    /// Есть ли у годового тарифа бесплатный пробный период в App Store (пока тарифы не загрузились, неизвестно)
    private var trialStatus: String {
        guard let yearly = product(for: .yearly) else { return "unknown" }
        return yearly.subscription?.introductoryOffer?.paymentMode == .freeTrial ? "yes" : "no"
    }

    private func product(for plan: SubscriptionPlan) -> Product? {
        subscriptionManager.products.first(where: { $0.id == plan.rawValue })
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PaperBackground()

            ScrollView(showsIndicators: true) {
                VStack(spacing: 22) {
                    header
                    benefitsCard
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            // Всегда видимая кнопка закрытия (Apple HIG / 2.1.0 App Completeness)
            Button {
                triggerHaptic(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Paper.inkSecondary, Paper.fillMuted)
                    .background(Circle().fill(Paper.page.opacity(0.9)))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Paper.hairline, lineWidth: 1))
            }
            .frame(width: 44, height: 44)
            .padding(.top, 14)
            .padding(.trailing, 16)
            .zIndex(999)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            purchaseBar
        }
        .onAppear {
            appearedAt = Date()
            Funnel.track("paywall_shown", ["source": source, "trial": trialStatus])
            Task {
                await subscriptionManager.requestProducts()
                Funnel.track("products_loaded", ["result": subscriptionManager.products.isEmpty ? "none" : "ok"])
                await refreshTrialEligibility()
            }
        }
        .onDisappear {
            Funnel.track("paywall_closed", ["source": source, "secs": Funnel.secondsBucket(Date().timeIntervalSince(appearedAt))])
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("alert_error_title".localized(for: language)),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("alert_success_title".localized(for: language)),
                message: Text(successMessage),
                dismissButton: .default(Text("alert_amen".localized(for: language)), action: {
                    dismiss()
                })
            )
        }
    }

    // MARK: - Заголовок

    private var header: some View {
        let focus = focusFeature
        let tint = focus?.color ?? Paper.gold
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 84, height: 84)
                    .overlay(Circle().stroke(tint.opacity(0.4), lineWidth: 1.5))

                Image(systemName: focus?.icon ?? "crown.fill")
                    .font(.system(size: 38))
                    .foregroundColor(tint)
            }

            Text("PREMIUM")
                .font(PaperFont.font(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(Paper.gold)

            Text(focus?.title ?? headerTitle)
                .font(PaperFont.font(size: 26, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)

            Text(focus?.subtitle ?? headerSubtitle)
                .font(PaperFont.font(size: 14))
                .foregroundColor(Paper.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Главные выгоды

    private var benefitsCard: some View {
        let focus = focusFeature
        let others = features.filter { $0.id != focus?.id }
        let visibleCount = focus == nil ? 3 : 2
        let shown = showAllFeatures ? others : Array(others.prefix(visibleCount))
        let hidden = others.count - shown.count

        return VStack(alignment: .leading, spacing: 14) {
            Text(benefitsTitle(hasFocus: focus != nil))
                .font(PaperFont.font(size: 12, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Paper.inkSecondary)

            ForEach(shown) { feature in
                featureRow(icon: feature.icon, iconColor: feature.color, title: feature.title, subtitle: feature.subtitle)
            }

            if hidden > 0 {
                Button {
                    triggerHaptic(.light)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAllFeatures = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(showMoreTitle(hidden))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Paper.gold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSheet(cornerRadius: 22)
        .padding(.horizontal, 20)
    }

    private func featureRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .foregroundColor(Paper.ink)

                Text(subtitle)
                    .font(PaperFont.font(size: 12))
                    .foregroundColor(Paper.inkSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Закреплённая панель: тарифы, кнопка, условия

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                planCard(plan: .yearly)
                planCard(plan: .monthly)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedPlan)

            Button {
                triggerHaptic(.medium)
                executePurchase()
            } label: {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView().tint(Paper.onAccent)
                    } else {
                        Text(ctaButtonTitle)
                            .font(PaperFont.font(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(Paper.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(accentColor)
                .cornerRadius(16)
                .shadow(color: Paper.shadow, radius: 10, y: 3)
            }
            .disabled(isPurchasing)
            .buttonStyle(ScaleButtonStyle())

            Text(legalLine)
                .font(PaperFont.font(size: 11))
                .foregroundColor(Paper.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button {
                    triggerHaptic(.light)
                    executeRestore()
                } label: {
                    Text(restoreTitle)
                        .font(PaperFont.font(size: 12, weight: .medium))
                        .foregroundColor(Paper.inkSecondary)
                }

                Text("•")
                    .foregroundColor(Paper.inkTertiary)

                Link(termsTitle, destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(PaperFont.font(size: 12, weight: .medium))
                    .foregroundColor(Paper.inkSecondary)

                Text("•")
                    .foregroundColor(Paper.inkTertiary)

                Link(privacyTitle, destination: URL(string: "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html")!)
                    .font(PaperFont.font(size: 12, weight: .medium))
                    .foregroundColor(Paper.inkSecondary)
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(
            Paper.page
                .overlay(Rectangle().fill(Paper.hairline).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func planCard(plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            triggerHaptic(.selection)
            Funnel.track("paywall_plan", ["plan": planCode(plan)])
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(plan.localizedTitle(for: language))
                        .font(PaperFont.font(size: 14, weight: .semibold))
                        .foregroundColor(Paper.ink)

                    if let badge = plan.localizedBadge(for: language, savingsPercent: savingsPercent) {
                        Text(badge)
                            .font(PaperFont.font(size: 10, weight: .semibold))
                            .foregroundColor(Paper.gold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Paper.gold.opacity(0.18))
                            .cornerRadius(7)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text(displayPrice(for: plan))
                    .font(PaperFont.font(size: 19, weight: .semibold).monospacedDigit())
                    .foregroundColor(isSelected ? Paper.gold : Paper.ink)

                Text(planCaption(plan))
                    .font(PaperFont.font(size: 11))
                    .foregroundColor(Paper.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Paper.gold.opacity(0.10) : Paper.sheet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Paper.gold : Paper.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Цены, выгода и пробный период (всё из тарифов App Store)

    private func displayPrice(for plan: SubscriptionPlan) -> String {
        if let p = product(for: plan) {
            return p.displayPrice
        }
        return plan.fallbackPrice(for: language)
    }

    /// Сколько в месяц выходит годовой тариф
    private var yearlyPerMonthText: String {
        if let yearly = product(for: .yearly) {
            return yearly.priceFormatStyle.format(yearly.price / 12)
        }
        return "$0.83"
    }

    private func planCaption(_ plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            return language.pick(hy: "\(yearlyPerMonthText) ամսական", ru: "\(yearlyPerMonthText) в месяц", en: "\(yearlyPerMonthText) / month")
        case .monthly:
            return language.pick(hy: "ամսական վճարում", ru: "списывается раз в месяц", en: "billed monthly")
        }
    }

    /// На сколько процентов год дешевле двенадцати месяцев; нет заметной выгоды (меньше 5%), значок не показываем
    private var savingsPercent: Int? {
        let monthlyPrice: Decimal
        let yearlyPrice: Decimal
        if let monthly = product(for: .monthly), let yearly = product(for: .yearly) {
            monthlyPrice = monthly.price
            yearlyPrice = yearly.price
        } else {
            monthlyPrice = Decimal(string: "0.99") ?? 0
            yearlyPrice = Decimal(string: "9.99") ?? 0
        }
        let full = monthlyPrice * 12
        guard full > 0, yearlyPrice < full else { return nil }
        let saved = NSDecimalNumber(decimal: (full - yearlyPrice) / full * 100).doubleValue.rounded()
        return saved >= 5 ? Int(saved) : nil
    }

    /// Бесплатный пробный период тарифа, если он настроен в App Store и доступен этому человеку
    private func trialOffer(for plan: SubscriptionPlan) -> (count: Int, unit: Product.SubscriptionPeriod.Unit)? {
        guard let found = product(for: plan),
              trialEligible[found.id] == true,
              let offer = found.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return (offer.period.value * offer.periodCount, offer.period.unit)
    }

    private func refreshTrialEligibility() async {
        var result: [String: Bool] = [:]
        for item in subscriptionManager.products {
            guard let info = item.subscription, info.introductoryOffer?.paymentMode == .freeTrial else { continue }
            result[item.id] = await info.isEligibleForIntroOffer
        }
        trialEligible = result
    }

    private func durationText(_ count: Int, _ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch language {
        case .english:
            let word: String
            switch unit {
            case .day: word = "day"
            case .week: word = "week"
            case .month: word = "month"
            case .year: word = "year"
            @unknown default: word = "day"
            }
            return "\(count) \(word)\(count == 1 ? "" : "s")"
        case .russian:
            switch unit {
            case .day: return "\(count) " + russianPlural(count, "день", "дня", "дней")
            case .week: return "\(count) " + russianPlural(count, "неделя", "недели", "недель")
            case .month: return "\(count) " + russianPlural(count, "месяц", "месяца", "месяцев")
            case .year: return "\(count) " + russianPlural(count, "год", "года", "лет")
            @unknown default: return "\(count) " + russianPlural(count, "день", "дня", "дней")
            }
        case .armenian:
            switch unit {
            case .day: return "\(count) օր"
            case .week: return "\(count) շաբաթ"
            case .month: return "\(count) ամիս"
            case .year: return "\(count) տարի"
            @unknown default: return "\(count) օր"
            }
        }
    }

    private func russianPlural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let lastTwo = n % 100
        let last = n % 10
        if lastTwo >= 11 && lastTwo <= 14 { return many }
        if last == 1 { return one }
        if last >= 2 && last <= 4 { return few }
        return many
    }

    /// Условия выбранного тарифа: сумма, срок, автопродление, отмена (то, что обязаны показывать правила App Store)
    private var legalLine: String {
        let plan = selectedPlan
        let price = displayPrice(for: plan)
        let period: String = plan == .yearly
            ? language.pick(hy: "տարեկան", ru: "в год", en: "per year")
            : language.pick(hy: "ամսական", ru: "в месяц", en: "per month")
        let tail = language.pick(
            hy: " Ավտոմատ կերպով երկարաձգվում է. կարող եք չեղարկել ցանկացած պահի Apple ID-ի կարգավորումներում:",
            ru: " Продлевается автоматически, отмена в любой момент в настройках Apple ID.",
            en: " Renews automatically. Cancel anytime in your Apple ID settings."
        )
        if let trial = trialOffer(for: plan) {
            let duration = durationText(trial.count, trial.unit)
            return language.pick(
                hy: "\(duration) անվճար, ապա \(price) \(period):",
                ru: "\(duration) бесплатно, затем \(price) \(period).",
                en: "\(duration) free, then \(price) \(period)."
            ) + tail
        }
        return language.pick(hy: "\(price) \(period):", ru: "\(price) \(period).", en: "\(price) \(period).") + tail
    }

    private var ctaButtonTitle: String {
        if let trial = trialOffer(for: selectedPlan) {
            let duration = durationText(trial.count, trial.unit)
            return language.pick(hy: "Փորձել \(duration) անվճար", ru: "Попробовать \(duration) бесплатно", en: "Try \(duration) free")
        }
        return language.pick(hy: "Շարունակել", ru: "Продолжить", en: "Continue")
    }

    // MARK: - Логика покупок

    private func executePurchase() {
        isPurchasing = true
        Funnel.track("purchase_started", ["plan": planCode(selectedPlan), "source": source])
        Task {
            let success = await subscriptionManager.purchase(plan: selectedPlan)
            isPurchasing = false
            let outcome = success ? "success" : (subscriptionManager.wasCancelled ? "cancelled" : (subscriptionManager.products.isEmpty ? "unavailable" : "failed"))
            Funnel.track("purchase_result", ["result": outcome, "plan": planCode(selectedPlan)])
            if success {
                triggerHaptic(.success)
                showSuccessAlert = true
            } else if !subscriptionManager.wasCancelled {
                triggerHaptic(.error)
                let fallbackError: String = {
                    switch language {
                    case .armenian: return "Բաժանորդագրության տվյալները հասանելի չեն App Store-ում: Խնդրում ենք ստուգել կապը և փորձել կրկին:"
                    case .russian: return "Не удалось связаться с App Store. Пожалуйста, проверьте подключение и повторите попытку."
                    case .english: return "Unable to connect to the App Store. Please check your connection and try again."
                    }
                }()
                errorMessage = subscriptionManager.purchaseErrorMessage ?? fallbackError
                showErrorAlert = true
            }
        }
    }

    private func executeRestore() {
        isPurchasing = true
        Task {
            let success = await subscriptionManager.restorePurchases()
            isPurchasing = false
            Funnel.track("restore_result", ["result": success ? "success" : "none"])
            if success {
                triggerHaptic(.success)
                showSuccessAlert = true
            } else {
                triggerHaptic(.warning)
                errorMessage = (language == .armenian) ? "Գնումներ չեն գտնվել" : "Покупки не найдены"
                showErrorAlert = true
            }
        }
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        Haptics.notify(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        Haptics.impact(style)
    }

    private func triggerHaptic(_ type: SelectionHapticTag) {
        Haptics.selection()
    }

    private enum SelectionHapticTag {
        case selection
    }

    // MARK: - Локализация текстов

    private var headerTitle: String {
        switch language {
        case .armenian: return "Աստվածաշունչ Premium"
        case .russian: return "Библия Premium"
        case .english: return "Armenian Bible Premium"
        }
    }

    private var headerSubtitle: String {
        language.pick(
            hy: "Ձեռագիր և կոդեքս, Նարեկացի, սրբավայրերի քարտեզ և անսահմանափակ AI",
            ru: "Рукопись и кодекс, Нарекаци, карта святынь и безлимитный ИИ",
            en: "Manuscript & codex, Narekatsi, the map of sanctuaries and unlimited AI"
        )
    }

    private func benefitsTitle(hasFocus: Bool) -> String {
        hasFocus
            ? language.pick(hy: "Նաև Premium-ում", ru: "Также в Premium", en: "Also in Premium")
            : language.pick(hy: "Ինչ է ներառված", ru: "Что входит", en: "What's included")
    }

    private func showMoreTitle(_ count: Int) -> String {
        language.pick(hy: "Ցույց տալ ևս \(count)", ru: "Показать ещё \(count)", en: "Show \(count) more")
    }

    // MARK: - Что входит в Premium

    private struct Feature: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    /// Какая из возможностей закрыла дверь, перед которой стоит человек: её показываем в заголовке
    private var focusFeatureID: String? {
        switch source {
        case "ai", "quiz": return "ai"
        case "wallpaper", "wallpaper_auto": return "widgets"
        case "codex_pdf", "manuscript_surface", "manuscript_pen": return "manuscript"
        case "narek_audio", "consolation": return "narek"
        case "candle": return "candles"
        case "map": return "map"
        default: return nil
        }
    }

    private var focusFeature: Feature? {
        guard let id = focusFeatureID else { return nil }
        return features.first(where: { $0.id == id })
    }

    /// Список повторяет то, что на самом деле закрыто подпиской: добавляя платную функцию, добавляйте её и сюда.
    /// Порядок важен: первые три видны сразу, остальные раскрываются кнопкой
    private var features: [Feature] {
        // Про «без ключей» пишем, только когда сервер ИИ подключён (AIProxy.baseURL задан)
        let aiTail = AIProxy.isConfigured
            ? language.pick(hy: "։ Աշխատում է անմիջապես՝ առանց բանալիների", ru: ". Работает сразу, без ключей", en: ". Works right away, no keys needed")
            : ""
        return [
            Feature(
                id: "manuscript",
                icon: "scroll.fill",
                color: Paper.gold,
                title: language.pick(hy: "«Ձեռագիր» և Մատենադարան", ru: "«Рукопись» и Матенадаран", en: "Manuscript & Matenadaran"),
                subtitle: language.pick(
                    hy: "Բոլոր գրիչները և էջի հիմքերը, հատորները PDF-ով՝ տպելու կամ նվիրելու համար",
                    ru: "Все перья и основы листа, тома кодекса в PDF для печати и подарка",
                    en: "Every pen and page surface, codex volumes as PDF to print or give"
                )
            ),
            Feature(
                id: "ai",
                icon: "sparkles",
                color: Paper.plum,
                title: language.pick(hy: "Անսահմանափակ AI. օգնական և վիկտորինա", ru: "Безлимитный ИИ: наставник и викторина", en: "Unlimited AI: guide & quiz"),
                subtitle: language.pick(
                    hy: "Մեկնաբանություններ Եկեղեցու Հայրերի ավանդությամբ, վիկտորինայի նոր հարցեր առանց կրկնությունների",
                    ru: "Толкования в традиции Святых Отцов ААЦ, новые вопросы викторины без повторов",
                    en: "Explanations in the Armenian Church tradition, new quiz questions without repeats"
                ) + aiTail
            ),
            Feature(
                id: "candles",
                icon: "flame.fill",
                color: Paper.cinnabar,
                title: language.pick(hy: "Անսահմանափակ աղոթքի մոմեր", ru: "Молитвенные свечи без ограничений", en: "Unlimited Prayer Candles"),
                subtitle: language.pick(
                    hy: "Վառեք մոմեր 24 ժամով՝ նաև Dynamic Island-ում և կողպէկրանին",
                    ru: "Сколько угодно свечей на 24 часа, в том числе в Dynamic Island и на экране блокировки",
                    en: "Light as many 24-hour candles as you wish, including in the Dynamic Island and on the Lock Screen"
                )
            ),
            Feature(
                id: "narek",
                icon: "headphones",
                color: Paper.lapis,
                title: language.pick(hy: "Նարեկացի. 95 գլուխ աուդիո", ru: "Нарекаци: 95 глав аудио", en: "Narekatsi: 95 audio chapters"),
                subtitle: language.pick(
                    hy: "Սոս Սարգսյան և Օլեգ Մոլենկո, անցանց: «Նարեկը մխիթարում է»՝ առանց օրական սահմանի",
                    ru: "Сос Саргсян и о. Моленко, офлайн. «Нарек утешает» без дневного лимита",
                    en: "Sos Sargsyan & Oleg Molenko, offline. “Narek Consoles” without a daily limit"
                )
            ),
            Feature(
                id: "map",
                icon: "map.fill",
                color: Paper.moss,
                title: language.pick(hy: "Սրբավայրերի քարտեզ", ru: "Карта святынь Армении", en: "Map of Sanctuaries"),
                subtitle: language.pick(
                    hy: "Բոլոր 16 վանքերն ու եկեղեցիները՝ պատմությամբ, տեղի համարով և հեռավորությամբ",
                    ru: "Все 16 монастырей и храмов: история, стих места и расстояние до вас",
                    en: "All 16 monasteries and churches: history, the place's verse and the distance to you"
                )
            ),
            Feature(
                id: "widgets",
                icon: "paintpalette.fill",
                color: Paper.gold,
                title: language.pick(hy: "Վիջեթներ և պաստառներ PRO", ru: "Виджеты, постеры и обои PRO", en: "Widgets, posters & wallpapers PRO"),
                subtitle: language.pick(
                    hy: "«Խաչքար» և «Բեթղեհեմ» պաստառներ, համարներ կողպէկրանին, 4K պաստառներ ոսկե հարդարանքով",
                    ru: "Постеры «Хачкар» и «Вифлеем», стихи на экране блокировки, 4K-обои с золотым тиснением",
                    en: "“Khachkar” and “Bethlehem” posters, Lock Screen verses, 4K wallpapers with gold foil"
                )
            ),
            Feature(
                id: "icons",
                icon: "app.dashed",
                color: Paper.gold,
                title: language.pick(hy: "Հավելվածի բացառիկ պատկերակներ", ru: "Эксклюзивные иконки приложения", en: "Exclusive App Icons"),
                subtitle: language.pick(
                    hy: "Ոսկեգույն Փայլ, Արքայական Ինդիգո, Արքայական Նուռ, Սրբազան Զմրուխտ, Ձեռագիր և Մատյան",
                    ru: "Золотое сияние, Королевский Индиго, Королевский Гранат, Священный Изумруд, Рукопись и Кодекс",
                    en: "Golden Glow, Royal Indigo, Royal Pomegranate, Sacred Emerald, Manuscript & Codex"
                )
            ),
            Feature(
                id: "mission",
                icon: "heart.fill",
                color: Paper.plum,
                title: language.pick(hy: "Աջակցություն հավելվածին", ru: "Поддержка Христианской Миссии", en: "Support the Mission"),
                subtitle: language.pick(
                    hy: "Նպաստեք հայկական հոգևոր ժառանգության տարածմանը",
                    ru: "Вклад в развитие армянского духовного наследия",
                    en: "Help spread the Armenian Christian heritage"
                )
            )
        ]
    }

    private var restoreTitle: String {
        switch language {
        case .armenian: return "Վերականգնել գնումները"
        case .russian: return "Восстановить"
        case .english: return "Restore Purchases"
        }
    }

    private var termsTitle: String {
        switch language {
        case .armenian: return "Պայմաններ"
        case .russian: return "Условия"
        case .english: return "Terms"
        }
    }

    private var privacyTitle: String {
        switch language {
        case .armenian: return "Գաղտնիություն"
        case .russian: return "Конфиденциальность"
        case .english: return "Privacy"
        }
    }

    private var successMessage: String {
        switch language {
        case .armenian: return "Դուք հաջողությամբ ակտիվացրել եք Armenian Bible Premium-ը: Շնորհակալություն աջակցության համար!"
        case .russian: return "Вы успешно активировали Armenian Bible Premium! Благодарим за вашу поддержку!"
        case .english: return "You have successfully activated Armenian Bible Premium! Thank you for your support!"
        }
    }
}
