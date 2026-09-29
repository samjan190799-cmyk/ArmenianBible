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
    
    init() {}
    
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
                        featureRow(
                            icon: "slash.circle.fill",
                            iconColor: Paper.moss,
                            title: featureTitleAds,
                            subtitle: featureDescAds
                        )
                        featureRow(
                            icon: "app.dashed",
                            iconColor: Paper.gold,
                            title: featureTitleIcons,
                            subtitle: featureDescIcons
                        )
                        featureRow(
                            icon: "brain.head.profile",
                            iconColor: Paper.plum,
                            title: featureTitleQuiz,
                            subtitle: featureDescQuiz
                        )
                        featureRow(
                            icon: "headphones",
                            iconColor: Paper.lapis,
                            title: featureTitle1,
                            subtitle: featureDesc1
                        )
                        featureRow(
                            icon: "sparkles",
                            iconColor: Paper.plum,
                            title: featureTitle2,
                            subtitle: featureDesc2
                        )
                        featureRow(
                            icon: "paintpalette.fill",
                            iconColor: Paper.gold,
                            title: featureTitle3,
                            subtitle: featureDesc3
                        )
                        featureRow(
                            icon: "lock.square.fill",
                            iconColor: Paper.moss,
                            title: featureTitle4,
                            subtitle: featureDesc4
                        )
                        featureRow(
                            icon: "heart.fill",
                            iconColor: Paper.plum,
                            title: featureTitle5,
                            subtitle: featureDesc5
                        )
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
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            Task {
                await subscriptionManager.requestProducts()
            }
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
        Task {
            let success = await subscriptionManager.purchase(plan: selectedPlan)
            isPurchasing = false
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
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    private func triggerHaptic(_ type: SelectionHapticTag) {
        UISelectionFeedbackGenerator().selectionChanged()
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
        switch language {
        case .armenian: return "Բացեք Նարեկացու բոլոր 95 աղոթքների ձայնագրությունները և անսահմանափակ AI-ն"
        case .russian: return "Откройте все 95 аудио-глав Нарекаци, безлимитный ИИ и эксклюзивные шрифты"
        case .english: return "Unlock all 95 Narekatsi audio chapters, unlimited AI & exclusive wallpapers"
        }
    }
    
    private var featureTitleAds: String {
        switch language {
        case .armenian: return "100% Առանց Գովազդի"
        case .russian: return "Полное Отключение Рекламы"
        case .english: return "100% Ad-Free Experience"
        }
    }
    
    private var featureDescAds: String {
        switch language {
        case .armenian: return "Վայելեք Սուրբ Գիրքը առանց ընդհատումների և շեղումների"
        case .russian: return "Погружайтесь в чтение Писания без баннеров и отвлечений"
        case .english: return "Immerse in Scripture with zero ads or interruptions"
        }
    }
    
    private var featureTitleIcons: String {
        switch language {
        case .armenian: return "Հավելվածի Բացառիկ Պատկերակներ"
        case .russian: return "Эксклюзивные Иконки Приложения"
        case .english: return "Exclusive App Icons"
        }
    }
    
    private var featureDescIcons: String {
        switch language {
        case .armenian: return "OLED Pitch Black, Ոսկեգույն փայլ և Արքայական ինդիգո"
        case .russian: return "OLED Pitch Black, Золотое сияние и Королевский индиго"
        case .english: return "OLED Pitch Black, Golden Glow & Royal Indigo"
        }
    }
    
    private var featureTitleQuiz: String {
        switch language {
        case .armenian: return "Անսահմանափակ AI Վիկտորինա"
        case .russian: return "Безлимитная ИИ-Викторина"
        case .english: return "Unlimited AI Bible Quiz"
        }
    }
    
    private var featureDescQuiz: String {
        switch language {
        case .armenian: return "Անհատական նոր հարցերի գեներացիա առանց կրկնությունների"
        case .russian: return "Генерация новых вопросов без повторов с адаптацией"
        case .english: return "Dynamic question generation with zero repetition"
        }
    }
    
    private var featureTitle1: String {
        switch language {
        case .armenian: return "Նարեկացու 95 Գլուխ Աուդիո"
        case .russian: return "95 Глав Аудио Нарекаци"
        case .english: return "95 Audio Chapters of Narekatsi"
        }
    }
    
    private var featureDesc1: String {
        switch language {
        case .armenian: return "Սոս Սարգսյան և Օլեգ Մոլենկո • Անցանց ռեժիմ"
        case .russian: return "Сос Саргсян и о. Моленко • Офлайн доступ"
        case .english: return "Sos Sargsyan & Oleg Molenko • Offline playback"
        }
    }
    
    private var featureTitle2: String {
        switch language {
        case .armenian: return "Անսահմանափակ Հոգևոր Օգնական (AI)"
        case .russian: return "Безлимитный Духовный Наставник (ИИ)"
        case .english: return "Unlimited Spiritual AI Guide"
        }
    }
    
    private var featureDesc2: String {
        switch language {
        case .armenian: return "Մեկնաբանություններ Եկեղեցու Հայրերի ավանդությամբ"
        case .russian: return "Толкования в традиции Святых Отцов ААЦ"
        case .english: return "Explanations in the Armenian Church tradition"
        }
    }
    
    private var featureTitle3: String {
        switch language {
        case .armenian: return "Պաստառներ PRO & Երկաթագիր"
        case .russian: return "Wallpaper Studio PRO & Еркатагир"
        case .english: return "Wallpaper Studio PRO & Calligraphy"
        }
    }
    
    private var featureDesc3: String {
        switch language {
        case .armenian: return "4K որակ, հնագույն տառատեսակներ և ոսկյա ոճեր"
        case .russian: return "4K качество, древние шрифты и золотое тиснение"
        case .english: return "4K quality, ancient fonts and golden themes"
        }
    }
    
    private var featureTitle4: String {
        switch language {
        case .armenian: return "Պրեմիում Վիջեթներ Lock Screen"
        case .russian: return "Премиум Виджеты на Экран Блокировки"
        case .english: return "Premium Lock Screen Widgets"
        }
    }
    
    private var featureDesc4: String {
        switch language {
        case .armenian: return "Ավտոմատ թարմացվող սուրբ գրային համարներ"
        case .russian: return "Авто-обновление стихов и церковных постов"
        case .english: return "Auto-updating verses and church feasts"
        }
    }
    
    private var featureTitle5: String {
        switch language {
        case .armenian: return "Աջակցություն Հավելվածին"
        case .russian: return "Поддержка Христианской Миссии"
        case .english: return "Support the Mission"
        }
    }
    
    private var featureDesc5: String {
        switch language {
        case .armenian: return "Նպաստեք հայկական հոգևոր ժառանգության տարածմանը"
        case .russian: return "Вклад в развитие армянского духовного наследия"
        case .english: return "Help spread the Armenian Christian heritage"
        }
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
