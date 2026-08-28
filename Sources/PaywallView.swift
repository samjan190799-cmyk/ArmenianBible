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
        Color(hex: bibleManager.accentTheme.colorHex)
    }
    
    private var secondaryAccentColor: Color {
        Color(hex: bibleManager.accentTheme.secondaryColorHex)
    }
    
    init() {}
    
    var body: some View {
        ZStack {
            // MARK: - Премиальный Темный Фон с Градиентом
            Color(hex: "08090E").ignoresSafeArea()
            
            // Динамические световые пятна (Glow Orbs)
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -80, y: animateGlow ? -200 : -160)
                
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.12)) // Золотое свечение
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: 100, y: animateGlow ? -100 : -140)
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    
                    // MARK: - Кнопка закрытия
                    HStack {
                        Spacer()
                        Button {
                            triggerHaptic(.light)
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // MARK: - Заголовок и Золотой Венец
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F59E0B").opacity(0.3), accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Circle().stroke(Color(hex: "F59E0B").opacity(0.4), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B"), Color(hex: "D97706")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color(hex: "F59E0B").opacity(0.5), radius: 10, y: 3)
                        }
                        
                        Text(headerTitle)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(headerSubtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Список Преимуществ (Feature List)
                    VStack(spacing: 14) {
                        featureRow(
                            icon: "headphones",
                            iconColor: Color(hex: "38BDF8"),
                            title: featureTitle1,
                            subtitle: featureDesc1
                        )
                        featureRow(
                            icon: "sparkles",
                            iconColor: Color(hex: "A855F7"),
                            title: featureTitle2,
                            subtitle: featureDesc2
                        )
                        featureRow(
                            icon: "paintpalette.fill",
                            iconColor: Color(hex: "F59E0B"),
                            title: featureTitle3,
                            subtitle: featureDesc3
                        )
                        featureRow(
                            icon: "lock.square.fill",
                            iconColor: Color(hex: "34D399"),
                            title: featureTitle4,
                            subtitle: featureDesc4
                        )
                        featureRow(
                            icon: "heart.fill",
                            iconColor: Color(hex: "EC4899"),
                            title: featureTitle5,
                            subtitle: featureDesc5
                        )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Выбор Тарифного Плана
                    VStack(spacing: 12) {
                        ForEach(SubscriptionPlan.allCases) { plan in
                            planCard(plan: plan)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Главная Кнопка Покупки (CTA)
                    VStack(spacing: 12) {
                        Button {
                            triggerHaptic(.medium)
                            executePurchase()
                        } label: {
                            HStack(spacing: 10) {
                                if isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(ctaButtonTitle)
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), Color(hex: "D97706"), accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 12, y: 4)
                        }
                        .disabled(isPurchasing)
                        .buttonStyle(ScaleButtonStyle())
                        
                        Text(trialDisclaimer)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
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
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Link(termsTitle, destination: URL(string: "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Link(privacyTitle, destination: URL(string: "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 36)
                    .padding(.top, 6)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Սխալ"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Շնորհավորում ենք! 🕊️"),
                message: Text(successMessage),
                dismissButton: .default(Text("Ամեն"), action: {
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
            }
            
            Spacer()
        }
    }
    
    private func planCard(plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlan == plan
        
        return Button {
            triggerHaptic(.selection)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "F59E0B") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "F59E0B"))
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.localizedTitle(for: language))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let badge = plan.localizedBadge(for: language) {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "FDE68A"))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Text(displayPrice(for: plan))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? Color(hex: "FDE68A") : .white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color(hex: "F59E0B").opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color(hex: "F59E0B") : Color.white.opacity(0.08), lineWidth: isSelected ? 1.8 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            } else if let err = subscriptionManager.purchaseErrorMessage {
                triggerHaptic(.error)
                errorMessage = err
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
