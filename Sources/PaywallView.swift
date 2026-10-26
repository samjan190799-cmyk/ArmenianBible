import SwiftUI
import StoreKit

// MARK: - Премиальный Экран Подписки (Paywall View)
// Разработан по стандартам Apple HIG 2026 с Glassmorphism, Haptics и анимациями
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared
    
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccessAlert: Bool = false
    @State private var animateGlow: Bool = false
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var accentColor: Color {
        bibleManager.accentTheme.color
    }
    
    private var secondaryAccentColor: Color {
        Paper.inkSecondary
    }
    
    /// Откуда открыт экран: попадает в воронку, чтобы видеть, какие замки приводят к подписке
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
        guard let yearly = subscriptionManager.products.first(where: { $0.id == SubscriptionPlan.yearly.rawValue }) else { return "unknown" }
        return yearly.subscription?.introductoryOffer?.paymentMode == .freeTrial ? "yes" : "no"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MARK: - Фон: тёплая бумага
            PaperBackground()
            
            ScrollView(showsIndicators: true) {
                VStack(spacing: 22) {
                    // MARK: - Заголовок и Золотой Венец
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Paper.gold.opacity(0.10))
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Circle().stroke(Paper.gold.opacity(0.4), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Paper.gold)
                        }
                        
                        Text(headerTitle)
                            .font(PaperFont.font(size: 28, weight: .semibold))
                            .foregroundColor(Paper.ink)
                            .multilineTextAlignment(.center)
                        
                        Text(headerSubtitle)
                            .font(PaperFont.font(size: 14))
                            .foregroundColor(Paper.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Список Преимуществ (Feature List)
                    VStack(spacing: 14) {
                        ForEach(features) { feature in
                            featureRow(icon: feature.icon, iconColor: feature.color, title: feature.title, subtitle: feature.subtitle)
                        }
                    }
                    .padding(18)
                    .paperSheet(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // MARK: - Выбор Тарифного Плана
                    VStack(spacing: 12) {
                        ForEach(SubscriptionPlan.allCases) { plan in
                            planCard(plan: plan)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: selectedPlan)
                    .padding(.horizontal, 20)
                    
                    // MARK: - Главная Кнопка Покупки (CTA)
                    VStack(spacing: 12) {
                        Button {
                            triggerHaptic(.medium)
                            executePurchase()
                        } label: {
                            HStack(spacing: 10) {
                                if isPurchasing {
                                    ProgressView().tint(Paper.onAccent)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(ctaButtonTitle)
                                        .font(PaperFont.font(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(Paper.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .cornerRadius(18)
                            .shadow(color: Paper.shadow, radius: 12, y: 4)
                        }
                        .disabled(isPurchasing)
                        .buttonStyle(ScaleButtonStyle())
                        
                        Text(trialDisclaimer)
                            .font(PaperFont.font(size: 11))
                            .foregroundColor(Paper.inkTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    // MARK: - Восстановление и Ссылки (Apple Guidelines)
                    HStack(spacing: 16) {
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
                    .padding(.bottom, 36)
                    .padding(.top, 6)
                }
                .padding(.top, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            
            // MARK: - Всегда фиксированная кнопка закрытия (Apple HIG / 2.1.0 App Completeness)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 3).loops(autoreverses: true)) {
                animateGlow = true
            }
            appearedAt = Date()
            Funnel.track("paywall_shown", ["source": source, "trial": trialStatus])
            Task {
                await subscriptionManager.requestProducts()
                Funnel.track("products_loaded", ["result": subscriptionManager.products.isEmpty ? "none" : "ok"])
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
    
    // MARK: - Компоненты интерфейса
    
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
            
            Spacer()
        }
    }
    
    private func planCard(plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlan == plan
        
        return Button {
            triggerHaptic(.selection)
            Funnel.track("paywall_plan", ["plan": planCode(plan)])
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Paper.gold : Paper.inkTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Paper.gold)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.localizedTitle(for: language))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(Paper.ink)
                        
                        let product = subscriptionManager.products.first(where: { $0.id == plan.rawValue })
                        if let badge = plan.localizedBadge(for: language, product: product) {
                            Text(badge)
                                .font(PaperFont.font(size: 10, weight: .semibold))
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Paper.gold.opacity(0.18))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Text(displayPrice(for: plan))
                    .font(PaperFont.font(size: 15, weight: .semibold).monospacedDigit())
                    .foregroundColor(isSelected ? Paper.gold : Paper.ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Paper.gold.opacity(0.10) : Paper.sheet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Paper.gold : Paper.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func displayPrice(for plan: SubscriptionPlan) -> String {
        if let p = subscriptionManager.products.first(where: { $0.id == plan.rawValue }) {
            return p.displayPrice
        }
        return plan.fallbackPrice(for: language)
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

    // MARK: - Что входит в Premium
    private struct Feature: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    /// Список повторяет то, что на самом деле закрыто подпиской: добавляя платную функцию, добавляйте её и сюда
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

    private var ctaButtonTitle: String {
        switch language {
        case .armenian: return "Շարունակել"
        case .russian: return "Продолжить"
        case .english: return "Continue"
        }
    }
    
    private var trialDisclaimer: String {
        switch language {
        case .armenian: return "Կարող եք չեղարկել ցանկացած պահի App Store-ի կարգավորումներում:"
        case .russian: return "Отмена в любой момент в настройках учетной записи Apple ID."
        case .english: return "Cancel anytime in your Apple ID Subscription Settings."
        }
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
