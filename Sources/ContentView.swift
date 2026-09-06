import SwiftUI

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        TabView(selection: $manager.activeTabSelection) {
            HomeView()
                .tabItem {
                    Label("tab_home".localized(for: manager.appLanguage), systemImage: "house.fill")
                }
                .tag(0)
            
            FavoritesView()
                .tabItem {
                    Label("tab_favorites".localized(for: manager.appLanguage), systemImage: "heart.fill")
                }
                .tag(1)
            
            AIGuideView()
                .tabItem {
                    Label("tab_ai_guide".localized(for: manager.appLanguage), systemImage: "sparkles")
                }
                .tag(2)
            
            BibleReaderView()
                .tabItem {
                    Label("tab_bible".localized(for: manager.appLanguage), systemImage: "book.pages.fill")
                }
                .tag(3)
        }
        .tint(accentColor)
        .preferredColorScheme(manager.appearanceMode.colorScheme)
    }
}

struct HomeView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var animateVerse = false
    @State private var isShowingSettings = false
    @State private var isShowingReadingPlans = false
    @State private var isShowingQuiz = false
    @State private var isShowingCalendar = false
    @State private var isShowingPaywall = false
    
    // Переменные для обработки ошибок ИИ
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    // Переменные для экспорта картинок
    @State private var shareItem: ShareItem? = nil
    @State private var isShowingWallpaperMaker = false
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Адаптивная цветовая палитра на основе AccentColorTheme
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var dotGridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.025) : Color.black.opacity(0.03)
    }
    
    private var glowColor: Color {
        accentColor.opacity(colorScheme == .dark ? 0.08 : 0.05)
    }
    
    private var settingsButtonBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }
    
    private var settingsButtonBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }
    
    private var settingsButtonIconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
    }
    
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var randomButtonBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }
    
    private var randomButtonBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    private var randomButtonTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var instructionBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.015)
    }
    
    private var instructionBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)
    }
    
    var body: some View {
        ZStack {
            // MARK: - Фон
            backgroundColor
                .ignoresSafeArea()
            
            // Тонкая сетка для техно-индустриального стиля
            StaticDotGridView(dotColor: dotGridColor)
                .ignoresSafeArea()
            
            // Фоновое неоновое свечение позади текста
            Circle()
                .fill(glowColor)
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(y: -70)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Кнопка настроек
                    HStack {
                        Spacer()
                        
                        Button {
                            triggerHaptic(.light)
                            isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(settingsButtonIconColor)
                                .padding(12)
                                .background(settingsButtonBgColor)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(settingsButtonBorderColor, lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // MARK: - Контейнер со стихом
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 24))
                                .foregroundColor(secondaryAccentColor.opacity(0.7))
                            
                            Spacer()
                            
                            Image(systemName: "laurel.trailing")
                                .font(.system(size: 24))
                                .foregroundColor(secondaryAccentColor.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        
                        Text(manager.currentVerse.text)
                            .font(.system(size: 21, weight: .medium, design: manager.widgetVisualStyle.fontDesign))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateVerse ? 1 : 0)
                            .offset(y: animateVerse ? 0 : 15)
                        
                        Text(manager.currentVerse.reference)
                            .font(.system(size: 13, weight: .bold, design: manager.widgetVisualStyle.fontDesign))
                            .foregroundColor(secondaryAccentColor)
                            .padding(.top, 2)
                            .opacity(animateVerse ? 0.8 : 0)
                            .offset(y: animateVerse ? 0 : 10)
                        
                        // Кнопки управления стихом: Избранное, Обои, Аудио-озвучка, Поделиться
                        HStack(spacing: 24) {
                            // 1. Кнопка Лайка (Избранное)
                            Button {
                                triggerHaptic(.light)
                                if manager.isFavorite(manager.currentVerse) {
                                    manager.removeFromFavorites(manager.currentVerse)
                                } else {
                                    manager.addToFavorites(manager.currentVerse)
                                }
                            } label: {
                                Image(systemName: manager.isFavorite(manager.currentVerse) ? "heart.fill" : "heart")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(manager.isFavorite(manager.currentVerse) ? .red : primaryTextColor.opacity(0.6))
                                    .padding(11)
                                    .background(primaryTextColor.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // 2. Кнопка Генератора Обоев для LockScreen
                            Button {
                                triggerHaptic(.medium)
                                isShowingWallpaperMaker = true
                            } label: {
                                Image(systemName: "photo.artframe")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(primaryTextColor.opacity(0.6))
                                    .padding(11)
                                    .background(primaryTextColor.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // 3. Кнопка Поделиться открыткой
                            Button {
                                triggerHaptic(.medium)
                                shareVerseAsImage()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(primaryTextColor.opacity(0.6))
                                    .padding(11)
                                    .background(primaryTextColor.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.top, 8)
                        .opacity(animateVerse ? 1 : 0)
                    }
                    .padding(26)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(cardBackgroundColor)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardBorderColor, lineWidth: 1.2)
                    )
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        triggerHaptic(.medium)
                        
                        withAnimation(.easeOut(duration: 0.18)) {
                            animateVerse = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            manager.selectRandomVerse()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                animateVerse = true
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 6)
                    
                    // MARK: - Баннерная Реклама Meta (на самом видном месте сразу под стихом дня)
                    BannerAdView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    
                    // MARK: - Карточка Григора Нарекаци (Գրիգոր Նարեկացի)

                    NarekatsiBannerCardView(
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenNarek: {
                            triggerHaptic(.medium)
                            manager.openNarekatsi()
                        }
                    )
                    
                    // MARK: - Карточка Плана Чтения Библии и Стрика (Reading Plans & Daily Streak)
                    ReadingPlanBannerCardView(
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenPlans: {
                            triggerHaptic(.medium)
                            isShowingReadingPlans = true
                        }
                    )
                    
                    // MARK: - Карточка Библейской Викторины
                    BibleQuizCardView(
                        bestScore: manager.quizBestScore,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onStartQuiz: {
                            triggerHaptic(.medium)
                            isShowingQuiz = true
                        }
                    )
                    
                    // MARK: - Карточка Церковных праздников и Календаря
                    ChurchFeastsBannerCardView(
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenCalendar: {
                            triggerHaptic(.medium)
                            isShowingCalendar = true
                        }
                    )
                    
                    // MARK: - Карточка Armenian Bible Premium
                    PremiumPromoBannerCardView(
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        isPremium: subscriptionManager.isPremium,
                        onOpenPaywall: {
                            triggerHaptic(.medium)
                            isShowingPaywall = true
                        }
                    )
                }
                .padding(.bottom, 30)
            }
        }
        .environment(\.locale, Locale(identifier: manager.appLanguage.localeCode))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateVerse = true
            }
            // Перепланируем уведомления на неделю вперед при открытии
            manager.scheduleDailyNotifications()
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(isPresented: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingReadingPlans) {
            ReadingPlansCatalogView()
                .preferredColorScheme(manager.appearanceMode.colorScheme)
        }
        .sheet(isPresented: $isShowingQuiz) {
            BibleQuizView()
        }
        .sheet(isPresented: $isShowingCalendar) {
            ChurchCalendarView()
        }
        .sheet(isPresented: $isShowingWallpaperMaker) {
            BibleWallpaperMakerView(verse: manager.currentVerse)
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .alert("alert_empty_key_title".localized(for: manager.appLanguage), isPresented: $showingNoKeyAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {
                isShowingSettings = true
            }
        } message: {
            Text(String(format: "alert_empty_key_message".localized(for: manager.appLanguage), manager.activeProvider.displayName))
        }
        .alert("alert_error_title".localized(for: manager.appLanguage), isPresented: $showingErrorAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onOpenURL { url in
            if url.scheme == "armenianbible" {
                if url.host == "next-verse" {
                    triggerHaptic(.medium)
                    manager.activeTabSelection = 0
                    withAnimation(.easeOut(duration: 0.18)) {
                        animateVerse = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        manager.selectRandomVerse()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            animateVerse = true
                        }
                    }
                } else if url.host == "read" {
                    // Парсим параметры: armenianbible://read?bookId=43&chapter=3&verse=16
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                          let queryItems = components.queryItems else { return }
                    
                    let bookIdStr = queryItems.first(where: { $0.name == "bookId" })?.value
                    let chapterStr = queryItems.first(where: { $0.name == "chapter" })?.value
                    let verseStr = queryItems.first(where: { $0.name == "verse" })?.value
                    
                    if let bIdStr = bookIdStr, let bId = Int(bIdStr),
                       let cStr = chapterStr, let chapter = Int(cStr) {
                        triggerHaptic(.medium)
                        
                        manager.deepLinkBookId = bId
                        manager.deepLinkChapter = chapter
                        if let vStr = verseStr, let verse = Int(vStr) {
                            manager.deepLinkVerse = verse
                        }
                        
                        manager.openBibleReader()
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && manager.updateInterval == .onScreenActivation {
                triggerHaptic(.light)
                withAnimation(.easeOut(duration: 0.18)) {
                    animateVerse = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    manager.selectRandomVerse()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateVerse = true
                    }
                }
            }
        }
    }
    
    // MARK: - Логика отправки запроса к ИИ
    private func runAIGeneration() {
        withAnimation(.easeOut(duration: 0.18)) {
            animateVerse = false
        }
        
        manager.generateVerseWithAI { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateVerse = true
                    }
                case .failure(let error):
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    errorMessage = "\(prefix)\(error.localizedDescription)"
                    showingErrorAlert = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateVerse = true
                    }
                }
            }
        }
    }
    
    @MainActor
    private func shareVerseAsImage() {
        let exportView = VerseCardExportView(
            verse: manager.currentVerse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        
        // Используем UIHostingController для стабильного рендеринга на всех iOS 16+
        // ImageRenderer(content:).uiImage часто возвращает nil при наличии blur/gradient
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        
        // Принудительный layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareItem = ShareItem(image: image)
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Баннерная Карточка Григора Нарекаци (Գրիգոր Նարեկացի)
struct NarekatsiBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenNarek: () -> Void
    
    var body: some View {
        Button {
            onOpenNarek()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("narekatsi_title".localized(for: language))
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("narekatsi_subtitle".localized(for: language))
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(secondaryAccentColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor.opacity(0.3))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Карточка Церковного календаря и праздников на Главном экране
struct ChurchFeastsBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenCalendar: () -> Void
    
    private var todayFeast: ArmenianChurchFeast? {
        ChurchCalendarService.shared.todayFeast()
    }
    
    private var nextDaghavar: (feast: ArmenianChurchFeast, daysLeft: Int)? {
        ChurchCalendarService.shared.nextDaghavarFeast()
    }
    
    var body: some View {
        Button {
            onOpenCalendar()
        } label: {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.25), Color(hex: "D97706").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: todayFeast != nil ? todayFeast!.type.icon : "calendar")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let today = todayFeast {
                        HStack(spacing: 6) {
                            Text("today_badge".localized(for: language))
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(5)
                            
                            Text(today.title(for: language))
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundColor(primaryTextColor)
                                .lineLimit(1)
                        }
                        
                        Text(today.formattedDate(for: language) + (today.isFasting ? " • " + "fasting_day_badge".localized(for: language) : ""))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "F59E0B"))
                            .lineLimit(1)
                    } else if let next = nextDaghavar {
                        Text("church_calendar_title".localized(for: language))
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        
                        Text("\(next.feast.title(for: language)) • \(next.daysLeft) " + "days_left_format".localized(for: language))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "F59E0B"))
                            .lineLimit(1)
                    } else {
                        Text("church_calendar_title".localized(for: language))
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        
                        Text("church_calendar_subtitle".localized(for: language))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryAccentColor)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor.opacity(0.3))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Карточка Подписки Armenian Bible Premium на Главном экране
struct PremiumPromoBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let isPremium: Bool
    let onOpenPaywall: () -> Void
    
    var body: some View {
        Button {
            onOpenPaywall()
        } label: {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.3), Color(hex: "D97706").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: isPremium ? "crown.fill" : "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isPremium ? "PREMIUM ԱԿՏԻՎ Է" : "ARMENIAN BIBLE PREMIUM")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(hex: "F59E0B"))
                        
                        if !isPremium {
                            Text("PRO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "FDE68A"))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(isPremium ? (language == .armenian ? "Բոլոր 95 աուդիո գլուխները և AI-ն ապաբլոկավորված են" : "Все 95 аудио глав и ИИ разблокированы") : (language == .armenian ? "Բացեք Նարեկացու 95 աուդիո գլուխները և AI-ն" : "95 аудио глав Нарекаци и безлимитный ИИ"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryTextColor.opacity(0.85))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isPremium ? "checkmark.seal.fill" : "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPremium ? Color(hex: "F59E0B") : .secondary)
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "F59E0B").opacity(0.04))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B").opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Представление открытки для экспорта (без Canvas/StaticDotGridView для 100% стабильного рендеринга на iOS 16+)
struct VerseCardExportView: View {
    let verse: BibleVerse
    let theme: AccentColorTheme
    let colorScheme: ColorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var accentColor: Color {
        Color(hex: theme.colorHex)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: theme.secondaryColorHex) : accentColor
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            
            // Мягкое фоновое свечение (без blur — совместимость с UIHostingController рендерингом)
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            
            VStack(spacing: 40) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 64))
                    .foregroundColor(secondaryTextColor.opacity(0.7))
                
                Text(verse.text)
                    .font(.system(size: 42, weight: .medium, design: .serif))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .padding(.horizontal, 80)
                
                Text(verse.reference)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
                    .padding(.top, 10)
                
                Image(systemName: "laurel.trailing")
                    .font(.system(size: 32))
                    .foregroundColor(secondaryTextColor.opacity(0.3))
                    .padding(.top, 20)
                
                Spacer()
                    .frame(height: 20)
                
                // Подпись приложения
                VStack(spacing: 6) {
                    Text("widget_title".localized(for: BibleManager.shared.appLanguage))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor.opacity(0.6))
                    Text("LockScreen Widget App")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(secondaryTextColor.opacity(0.5))
                }
            }
            .padding(60)
            .frame(width: 960, height: 960)
            .background(
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.06), radius: 30, x: 0, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(colorScheme == .dark ? 0.12 : 0.4), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .frame(width: 1080, height: 1080)
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Activity View (Share Sheet) для SwiftUI
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ЭКРАН ИИ РУКОВОДСТВА (AI Guide View - Библейский Ответчик)
struct AIGuideView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var questionText = ""
    @State private var currentAnswer: BibleAnswer? = nil
    @State private var isAskingAI = false
    @State private var isShowingPaywall = false
    @State private var isShowingRewardedOffer = false
    
    // Ошибки
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    // Карточка экспорта
    @State private var shareItem: ShareItem? = nil
    @State private var animateAnswer = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
    }
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    struct SuggestedQuestion: Identifiable {
        let id = UUID()
        let key: String
        let icon: String
    }
    
    private let suggestedQuestions = [
        SuggestedQuestion(key: "q_fear", icon: "shield.fill"),
        SuggestedQuestion(key: "q_forgive", icon: "heart.fill"),
        SuggestedQuestion(key: "q_peace", icon: "wind"),
        SuggestedQuestion(key: "q_hope", icon: "sun.max.fill"),
        SuggestedQuestion(key: "q_trials", icon: "hands.sparkles.fill")
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Фоновое свечение
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.06 : 0.04), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("ai_guide_title".localized(for: manager.appLanguage))
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        Text("ai_guide_subtitle".localized(for: manager.appLanguage))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Индикатор подписки / остатка бесплатных вопросов
                        HStack(spacing: 6) {
                            Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "sparkles")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            
                            Text(subscriptionManager.isPremium ?
                                 (manager.appLanguage == .armenian ? "PRO • Անսահմանափակ" : "PRO • Безлимитно") :
                                 (manager.appLanguage == .armenian ? "Օրական մնացել է \(subscriptionManager.remainingFreeAiQuestions) անվճար հարց" : "Осталось \(subscriptionManager.remainingFreeAiQuestions) бесплатных вопроса на сегодня"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(subscriptionManager.isPremium ? Color(hex: "F59E0B") : .secondary)
                            
                            if !subscriptionManager.isPremium {
                                Button {
                                    triggerHaptic(.light)
                                    isShowingPaywall = true
                                } label: {
                                    Text("PRO")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(accentColor.opacity(0.12))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.top, 16)
                    
                    // Поле ввода вопроса
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 10) {
                            TextField("ai_placeholder_prompt".localized(for: manager.appLanguage), text: $questionText, axis: .vertical)
                                .lineLimit(1...4)
                                .font(.system(size: 15))
                                .foregroundColor(primaryTextColor)
                                .padding(14)
                                .background(cardBackgroundColor)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(questionText.isEmpty ? Color.primary.opacity(0.06) : accentColor.opacity(0.5), lineWidth: 1.2)
                                )
                            
                            Button {
                                triggerHaptic(.medium)
                                submitQuestion(questionText)
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(
                                        questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAskingAI
                                        ? Color.gray.opacity(0.3)
                                        : accentColor
                                    )
                                    .clipShape(Circle())
                            }
                            .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAskingAI)
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Быстрые частые вопросы
                        VStack(alignment: .leading, spacing: 10) {
                            Text("suggested_questions_title".localized(for: manager.appLanguage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestedQuestions) { sq in
                                        Button {
                                            triggerHaptic(.light)
                                            let q = sq.key.localized(for: manager.appLanguage)
                                            questionText = q
                                            submitQuestion(q)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: sq.icon)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(secondaryAccentColor)
                                                Text(sq.key.localized(for: manager.appLanguage))
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(primaryTextColor)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(cardBackgroundColor)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Баннерная Реклама Meta (на видном месте под блоком ввода)
                    BannerAdView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    
                    // Блок вывода результата
                    if isAskingAI {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(accentColor)
                            Text("ai_searching_answer".localized(for: manager.appLanguage))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if let answer = currentAnswer {
                        VStack(spacing: 20) {
                            // 1. Духовный ответ ИИ
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(accentColor)
                                    Text("ai_guide_title".localized(for: manager.appLanguage))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(accentColor)
                                }
                                
                                Text(answer.answerText)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(primaryTextColor)
                                    .lineSpacing(7)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(22)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(cardBackgroundColor)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(cardBorderColor, lineWidth: 1.2)
                            )
                            
                            // 2. Ключевой Библейский стих (если есть)
                            if let verse = answer.verse {
                                VStack(spacing: 16) {
                                    Image(systemName: "laurel.leading")
                                        .font(.system(size: 24))
                                        .foregroundColor(secondaryAccentColor.opacity(0.7))
                                    
                                    Text(verse.text)
                                        .font(.system(size: 17, weight: .medium, design: .serif))
                                        .foregroundColor(primaryTextColor)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(6)
                                    
                                    Text(verse.reference)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(secondaryAccentColor)
                                    
                                    HStack(spacing: 20) {
                                        // Лайк (Избранное)
                                        Button {
                                            triggerHaptic(.light)
                                            if manager.isFavorite(verse) {
                                                manager.removeFromFavorites(verse)
                                            } else {
                                                manager.addToFavorites(verse)
                                            }
                                        } label: {
                                            Image(systemName: manager.isFavorite(verse) ? "heart.fill" : "heart")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(manager.isFavorite(verse) ? .red : primaryTextColor.opacity(0.4))
                                                .padding(10)
                                                .background(primaryTextColor.opacity(0.04))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                        
                                        // Поделиться открыткой
                                        Button {
                                            triggerHaptic(.medium)
                                            shareVerse(verse)
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(primaryTextColor.opacity(0.4))
                                                .padding(10)
                                                .background(primaryTextColor.opacity(0.04))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(22)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(cardBackgroundColor)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(cardBorderColor, lineWidth: 1.2)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(animateAnswer ? 1 : 0)
                        .offset(y: animateAnswer ? 0 : 15)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                animateAnswer = true
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .confirmationDialog(
            limitDialogTitle,
            isPresented: $isShowingRewardedOffer,
            titleVisibility: .visible
        ) {
            Button(limitDialogWatchAdTitle) {
                triggerHaptic(.medium)
                AdManager.shared.showRewardedAd {
                    subscriptionManager.grantBonusAiQuestionFromAd()
                    submitQuestion(questionText)
                }
            }
            Button(limitDialogPaywallTitle) {
                triggerHaptic(.light)
                isShowingPaywall = true
            }
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(limitDialogMessage)
        }
        .alert("alert_empty_key_title".localized(for: manager.appLanguage), isPresented: $showingNoKeyAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(String(format: "alert_empty_key_message".localized(for: manager.appLanguage), manager.activeProvider.displayName))
        }
        .alert("alert_error_title".localized(for: manager.appLanguage), isPresented: $showingErrorAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Локализация предложений Rewarded рекламы
    private var limitDialogTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Հարցերի սահմանաչափը սպառվել է"
        case .russian: return "Лимит вопросов исчерпан"
        case .english: return "Daily Question Limit Reached"
        }
    }
    
    private var limitDialogMessage: String {
        switch manager.appLanguage {
        case .armenian: return "Դիտեք կարճ գովազդ՝ ևս 1 անվճար հարց ստանալու համար, կամ ակտիվացրեք Premium-ը:"
        case .russian: return "Посмотрите короткий ролик Meta, чтобы получить +1 вопрос бесплатно, или оформите Premium для безлимита:"
        case .english: return "Watch a short Meta video ad to get +1 question for free, or upgrade to Premium for unlimited access:"
        }
    }
    
    private var limitDialogWatchAdTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Դիտել գովազդ (+1 հարց)"
        case .russian: return "Смотреть рекламу (+1 вопрос)"
        case .english: return "Watch Ad (+1 Question)"
        }
    }
    
    private var limitDialogPaywallTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Ակտիվացնել Premium"
        case .russian: return "Оформить Premium"
        case .english: return "Upgrade to Premium"
        }
    }
    
    private func submitQuestion(_ question: String) {
        if !subscriptionManager.canAskAI() {
            triggerHaptic(.heavy)
            isShowingRewardedOffer = true
            return
        }
        
        let key: String
        switch manager.activeProvider {
        case .gemini:
            key = manager.geminiApiKey
        case .chatgpt:
            key = manager.openaiApiKey
        case .claude:
            key = manager.anthropicApiKey
        }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerHaptic(.heavy)
            showingNoKeyAlert = true
            return
        }
        
        isAskingAI = true
        animateAnswer = false
        
        manager.askBibleAI(question: question) { result in
            DispatchQueue.main.async {
                self.isAskingAI = false
                switch result {
                case .success(let answer):
                    self.subscriptionManager.recordAiQuestionUsed()
                    self.currentAnswer = answer
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.animateAnswer = true
                    }
                case .failure(let error):
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    @MainActor
    private func shareVerse(_ verse: BibleVerse) {
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        self.shareItem = ShareItem(image: image)
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - ЭКРАН ТОЛКОВАНИЯ (Explanation View)
struct ExplanationView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var explanationText = ""
    @State private var selectedDepth = 0 // 0 = суть, 1 = контекст, 2 = жизнь
    
    // Ошибки
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
    }
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.05 : 0.03), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 6) {
                        Text("explain_title".localized(for: manager.appLanguage))
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        Text("explain_subtitle".localized(for: manager.appLanguage))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Блок текущего стиха
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 14))
                                .foregroundColor(secondaryAccentColor)
                            Text(manager.currentVerse.reference)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                        }
                        
                        Text(manager.currentVerse.text)
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundColor(primaryTextColor.opacity(0.85))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .background(cardBackgroundColor)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(cardBorderColor, lineWidth: 1.2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Выбор глубины погружения
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Depth", selection: $selectedDepth) {
                            Text("explain_depth_short".localized(for: manager.appLanguage)).tag(0)
                            Text("explain_depth_history".localized(for: manager.appLanguage)).tag(1)
                            Text("explain_depth_life".localized(for: manager.appLanguage)).tag(2)
                        }
                        .pickerStyle(.segmented)
                        .tint(accentColor)
                    }
                    .padding(.horizontal, 20)
                    
                    // Кнопка запуска
                    Button {
                        triggerHaptic(.medium)
                        runTheologicalExplanation()
                    } label: {
                        HStack(spacing: 10) {
                            if manager.isGeneratingText {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 15))
                                Text("button_generate_explanation".localized(for: manager.appLanguage))
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(14)
                        .shadow(color: accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, y: 4)
                    }
                    .disabled(manager.isGeneratingText)
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // Результат
                    if manager.isGeneratingText {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(accentColor)
                            Text("explain_loading".localized(for: manager.appLanguage))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 60)
                    } else if !explanationText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "cross.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(secondaryAccentColor)
                                Text("explain_title".localized(for: manager.appLanguage))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(secondaryAccentColor)
                            }
                            .padding(.bottom, 4)
                            
                            Text(explanationText)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(7)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackgroundColor)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(cardBorderColor, lineWidth: 1.2)
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        // Приветственное состояние
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(secondaryAccentColor.opacity(0.4))
                            Text("explain_welcome".localized(for: manager.appLanguage))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: manager.currentVerse) { _ in
            // Сбрасываем текст при смене текущего стиха
            explanationText = ""
        }
        .alert("alert_empty_key_title".localized(for: manager.appLanguage), isPresented: $showingNoKeyAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(String(format: "explain_no_key".localized(for: manager.appLanguage)))
        }
        .alert("alert_error_title".localized(for: manager.appLanguage), isPresented: $showingErrorAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func runTheologicalExplanation() {
        let key: String
        switch manager.activeProvider {
        case .gemini:
            key = manager.geminiApiKey
        case .chatgpt:
            key = manager.openaiApiKey
        case .claude:
            key = manager.anthropicApiKey
        }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerHaptic(.heavy)
            showingNoKeyAlert = true
            return
        }
        
        let depthPrompt: String
        switch selectedDepth {
        case 0:
            depthPrompt = "Focus on the brief spiritual summary and key theological message."
        case 1:
            depthPrompt = "Focus deeply on the historical context, the original Greek/Hebrew translation nuances, and background of the writing."
        default:
            depthPrompt = "Focus on how this verse applies directly to contemporary daily life, and how to practice its message."
        }
        
        let prompt: String
        switch manager.appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ և աստվածաբան ես: Բացատրիր և մեկնաբանիր հետևյալ աստվածաշնչյան մեջբերումը՝ «\(manager.currentVerse.text)» (\(manager.currentVerse.reference)): Տուր խորը, բայց հասկանալի բացատրություն հայերեն լեզվով: \(depthPrompt) Գրիր գեղեցիկ, կառուցվածքային, բաժանված պարագրաֆների:"
        case .russian:
            prompt = "Ты эксперт по Библии и богословию. Объясни и истолкуй следующий библейский стих: «\(manager.currentVerse.text)» (\(manager.currentVerse.reference)). Дай глубокое, богословское, но понятное толкование на русском языке. \(depthPrompt) Пиши структурированно, разделяя текст на логические абзацы."
        case .english:
            prompt = "You are a Bible expert and theologian. Explain and interpret the following Bible verse: \"\(manager.currentVerse.text)\" (\(manager.currentVerse.reference)). Provide a deep theological but easy-to-understand explanation in English. \(depthPrompt) Write in clean, structured paragraphs."
        }
        
        manager.generateTextFromAI(prompt: prompt) { result in
            switch result {
            case .success(let text):
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.explanationText = text
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Экран Настроек (Settings View)
struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var appIconManager = AppIconManager.shared
    
    @State private var isShowingPaywall = false
    @State private var selectedProvider: AIProvider = .gemini
    @State private var selectedLanguage: AppLanguage = .armenian
    @State private var geminiKeyInput = ""
    @State private var openaiKeyInput = ""
    @State private var anthropicKeyInput = ""
    
    @State private var selectedInterval: UpdateInterval = .everyHour
    @State private var selectedCategory: TextCategory = .both
    @State private var selectedScope: VerseSourceScope = .allBible
    @State private var selectedTheme: AccentColorTheme = .indigo
    @State private var selectedAppearanceMode: AppAppearanceMode = .system
    @State private var selectedWidgetLanguage: WidgetLanguage = .followApp
    @State private var selectedWidgetStyle: WidgetVisualStyle = .oledStandby
    @State private var selectedLockCategory: LockScreenCategory = .pearls
    @State private var selectedMediumCategory: HomeWidgetCategory = .all
    @State private var selectedLargeCategory: HomeWidgetCategory = .all
    @State private var selectedArmenianEdition: ArmenianBibleEdition = .ararat
    @State private var previewWidgetSize: PreviewWidgetSize = .small
    @State private var previewVerse: BibleVerse = BibleVerse.lockScreenPearls[0]
    
    // Переменные для уведомлений
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    
    // Всплывающая инструкция по виджетам
    @State private var isShowingWidgetInstruction = false
    @State private var isShowingWallpaperAutomation = false
    
    // 🔐 Панель разработчика (переключение Premium/Free по PIN-коду)
    @State private var secretTapCount = 0
    @State private var secretLastTap = Date.distantPast
    @State private var isShowingDevPasscodeAlert = false
    @State private var devPasscodeInput = ""
    @State private var devToastMessage = ""
    @State private var devToastSubtitle = ""
    @State private var devToastIcon = "crown.fill"
    @State private var devToastColor: [Color] = [Color(hex: "F59E0B"), Color(hex: "D97706")]
    @State private var showDevToast = false

    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var inputFieldBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }
    
    private var inputFieldBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
    
    private var aboutBlockBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.015)
    }
    
    private var aboutBlockBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
    }
    
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        premiumMembershipSection
                        aiProviderSection
                        appLanguageSection
                        appearanceModeSection
                        colorThemeSection
                        appIconSection
                        apiKeysSection
                        dailyNotificationsSection
                        updateIntervalSection
                        verseSourceScopeSection
                        contentTypeSection
                        widgetStyleSection
                        autoWallpaperSection
                        lockScreenWidgetSection
                        aboutSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("settings_title".localized(for: selectedLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close_button".localized(for: selectedLanguage)) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        isPresented = false
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
            .onAppear {
                selectedProvider = manager.activeProvider
                selectedLanguage = manager.appLanguage
                geminiKeyInput = manager.geminiApiKey
                openaiKeyInput = manager.openaiApiKey
                anthropicKeyInput = manager.anthropicApiKey
                selectedInterval = manager.updateInterval
                selectedCategory = manager.selectedCategory
                selectedScope = manager.verseSourceScope
                selectedTheme = manager.accentTheme
                selectedAppearanceMode = manager.appearanceMode
                notificationsEnabled = manager.dailyNotificationsEnabled
                notificationTime = manager.dailyNotificationTime
                selectedWidgetLanguage = manager.widgetLanguage
                selectedWidgetStyle = manager.widgetVisualStyle
                selectedLockCategory = manager.lockScreenCategory
                selectedMediumCategory = manager.mediumWidgetCategory
                selectedLargeCategory = manager.largeWidgetCategory
                selectedArmenianEdition = manager.armenianEdition
                let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
                appIconManager.syncWithSystem()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $isShowingWidgetInstruction) {
                WidgetInstructionSheetView(
                    language: selectedLanguage,
                    accentColor: Color(hex: selectedTheme.colorHex),
                    cardBackgroundColor: cardBackgroundColor,
                    cardBorderColor: cardBorderColor,
                    primaryTextColor: primaryTextColor
                )
            }
            .sheet(isPresented: $isShowingWallpaperAutomation) {
                WallpaperAutomationSheetView()
            }
            .alert("Панель разработчика", isPresented: $isShowingDevPasscodeAlert) {
                SecureField("Секретный PIN-код", text: $devPasscodeInput)
                
                Button("Включить Free (для теста рекламы)") {
                    handleDevToggle(enablePremium: false)
                }
                
                Button("Включить Premium") {
                    handleDevToggle(enablePremium: true)
                }
                
                Button("Отмена", role: .cancel) {
                    devPasscodeInput = ""
                }
            } message: {
                Text("Текущий статус: \(subscriptionManager.isPremium ? "👑 Premium активен" : "🆓 Free режим")\n\nВведите PIN для переключения режима.")
            }
        }
        .preferredColorScheme(manager.appearanceMode.colorScheme)
        .environment(\.locale, Locale(identifier: selectedLanguage.localeCode))
    }
    
    // MARK: - Подсекции настроек
    @ViewBuilder
    private var premiumMembershipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.3), Color(hex: "D97706").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Armenian Bible Premium")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        if subscriptionManager.isPremium {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "FDE68A"))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(subscriptionManager.isPremium ?
                         (selectedLanguage == .armenian ? "Կարգավիճակ՝ Ակտիվ (Բոլոր ֆունկցիաները բացված են)" : "Статус: Активен (Все функции открыты)") :
                         (selectedLanguage == .armenian ? "Բացեք Նարեկացու 95 աուդիոները, անսահմանափակ AI-ն և PRO պաստառները" : "95 аудио Нарекаци, безлимитный ИИ и PRO обои"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            HStack(spacing: 10) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isShowingPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "sparkles")
                            .font(.system(size: 13, weight: .bold))
                        Text(subscriptionManager.isPremium ?
                             (selectedLanguage == .armenian ? "Կառավարել" : "Управление") :
                             (selectedLanguage == .armenian ? "Ստանալ Premium" : "Оформить Premium"))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    Task {
                        _ = await subscriptionManager.restorePurchases()
                    }
                } label: {
                    Text(selectedLanguage == .armenian ? "Վերականգնել" : "Восстановить")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(cardBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "F59E0B").opacity(0.04))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "F59E0B").opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
    }
    
    // MARK: - Подсекции настроек
    @ViewBuilder
    private var aiProviderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ai_provider".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("ai_provider_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("ai_provider", selection: $selectedProvider) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 4)
            .onChange(of: selectedProvider) { newProvider in
                manager.setActiveProvider(newProvider)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var appLanguageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ai_language".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("ai_language_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("ai_language", selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 4)
            .onChange(of: selectedLanguage) { newLang in
                manager.setAppLanguage(newLang)
                manager.forceRefreshUI()
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("appearance_section_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Picker("appearance_section_title", selection: $selectedAppearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.localizedName(for: selectedLanguage))
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 4)
            .onChange(of: selectedAppearanceMode) { newMode in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                manager.setAppearanceMode(newMode)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var colorThemeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("theme_section_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            HStack(spacing: 16) {
                ForEach(AccentColorTheme.allCases) { theme in
                    ZStack {
                        Circle()
                            .fill(Color(hex: theme.colorHex))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color(hex: theme.colorHex).opacity(0.3), radius: 4, y: 2)
                        
                        if selectedTheme == theme {
                            Circle()
                                .stroke(primaryTextColor, lineWidth: 2)
                                .frame(width: 48, height: 48)
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        selectedTheme = theme
                        manager.setAccentTheme(theme)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings_app_icon_title".localized(for: selectedLanguage))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Text("settings_app_icon_subtitle".localized(for: selectedLanguage))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let errorMsg = appIconManager.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 13))
                    Text(errorMsg)
                        .font(.system(size: 12))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                    Spacer()
                    Button("OK") {
                        appIconManager.clearError()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(AppIconOption.allCases) { option in
                        let isSelected = appIconManager.currentOption == option
                        let isLocked = option.isPremium && !subscriptionManager.isPremium
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            appIconManager.selectIcon(option) {
                                isShowingPaywall = true
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(option.assetPreviewName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 68, height: 68)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(isSelected ? Color(hex: selectedTheme.colorHex) : Color.white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                                        )
                                        .shadow(color: isSelected ? Color(hex: selectedTheme.colorHex).opacity(0.4) : Color.black.opacity(0.15), radius: isSelected ? 8 : 4, y: 3)
                                    
                                    if isSelected {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: selectedTheme.colorHex))
                                                .frame(width: 22, height: 22)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                        .offset(x: 6, y: -6)
                                    } else if isLocked {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 22, height: 22)
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                                
                                VStack(spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(option.title(for: selectedLanguage))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(primaryTextColor)
                                            .lineLimit(1)
                                        
                                        if option.isPremium {
                                            Text("PRO")
                                                .font(.system(size: 8, weight: .heavy))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color(hex: "FDE68A"))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .frame(width: 80)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isSelected ? Color(hex: selectedTheme.colorHex).opacity(0.08) : Color.clear)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch selectedProvider {
            case .gemini:
                Text("gemini_settings_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text("gemini_settings_description".localized(for: selectedLanguage))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.bottom, 6)
                
                SecureField("placeholder_gemini_key".localized(for: selectedLanguage), text: $geminiKeyInput)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(primaryTextColor)
                    .padding()
                    .background(inputFieldBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputFieldBorderColor, lineWidth: 1)
                    )
                    .onChange(of: geminiKeyInput) { val in
                        manager.geminiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                if !manager.geminiApiKey.isEmpty && !geminiKeyInput.isEmpty {
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                }
                
            case .chatgpt:
                Text("chatgpt_settings_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text("chatgpt_settings_description".localized(for: selectedLanguage))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.bottom, 6)
                
                SecureField("placeholder_openai_key".localized(for: selectedLanguage), text: $openaiKeyInput)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(primaryTextColor)
                    .padding()
                    .background(inputFieldBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputFieldBorderColor, lineWidth: 1)
                    )
                    .onChange(of: openaiKeyInput) { val in
                        manager.openaiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                if !manager.openaiApiKey.isEmpty && !openaiKeyInput.isEmpty {
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                }
                
            case .claude:
                Text("claude_settings_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text("claude_settings_description".localized(for: selectedLanguage))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.bottom, 6)
                
                SecureField("placeholder_anthropic_key".localized(for: selectedLanguage), text: $anthropicKeyInput)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(primaryTextColor)
                    .padding()
                    .background(inputFieldBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputFieldBorderColor, lineWidth: 1)
                    )
                    .onChange(of: anthropicKeyInput) { val in
                        manager.anthropicApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                if !manager.anthropicApiKey.isEmpty && !anthropicKeyInput.isEmpty {
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var dailyNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("notification_section_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Toggle(isOn: $notificationsEnabled) {
                Text("notification_enable_title".localized(for: selectedLanguage))
                    .font(.system(size: 14))
                    .foregroundColor(primaryTextColor)
            }
            .tint(Color(hex: selectedTheme.colorHex))
            .onChange(of: notificationsEnabled) { newValue in
                manager.setDailyNotificationsEnabled(newValue)
                if newValue {
                    manager.requestNotificationPermission { granted in
                        if !granted {
                            self.notificationsEnabled = false
                            manager.setDailyNotificationsEnabled(false)
                        }
                    }
                }
            }
            
            if notificationsEnabled {
                DatePicker("notification_time_title".localized(for: selectedLanguage), selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .font(.system(size: 14))
                    .foregroundColor(primaryTextColor)
                    .padding(.vertical, 4)
                    .onChange(of: notificationTime) { newTime in
                        manager.setDailyNotificationTime(newTime)
                    }
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var updateIntervalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("update_interval_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingWidgetInstruction = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                        Text("widget_instruction_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("update_interval_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("update_interval_title", selection: $selectedInterval) {
                ForEach(UpdateInterval.allCases) { interval in
                    Text(interval.localizedTitle(for: selectedLanguage)).tag(interval)
                }
            }
            .pickerStyle(.menu)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inputFieldBgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
            .onChange(of: selectedInterval) { newInt in
                manager.setUpdateInterval(newInt)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var verseSourceScopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("verse_source_scope_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("verse_source_scope_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            VStack(spacing: 8) {
                ForEach(VerseSourceScope.allCases) { scope in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        selectedScope = scope
                        manager.updateVerseSourceScope(scope)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(selectedScope == scope ? Color(hex: selectedTheme.colorHex) : .secondary)
                                .frame(width: 24)
                            
                            Text(scope.title(for: selectedLanguage))
                                .font(.system(size: 14, weight: selectedScope == scope ? .bold : .medium))
                                .foregroundColor(primaryTextColor)
                            
                            Spacer()
                            
                            if selectedScope == scope {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedScope == scope ? Color(hex: selectedTheme.colorHex).opacity(0.12) : inputFieldBgColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedScope == scope ? Color(hex: selectedTheme.colorHex) : inputFieldBorderColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var contentTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("content_type_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("content_type_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("content_type_title", selection: $selectedCategory) {
                ForEach(TextCategory.allCases) { category in
                    Text(category.localizedTitle(for: selectedLanguage)).tag(category)
                }
            }
            .pickerStyle(.menu)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inputFieldBgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
            .onChange(of: selectedCategory) { newCat in
                manager.setSelectedCategory(newCat)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var widgetStyleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("widget_style_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                } icon: {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                
                Spacer()
                
                // StandBy бейдж
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("STANDBY")
                        .font(.system(size: 10, weight: .black))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(hex: "F59E0B").opacity(0.18))
                .foregroundColor(Color(hex: "F59E0B"))
                .cornerRadius(6)
            }
            
            Text("widget_style_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            // Горизонтальный список 5 вариантов оформления
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WidgetVisualStyle.allCases) { style in
                        let isSelected = selectedWidgetStyle == style
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedWidgetStyle = style
                            }
                            manager.setWidgetVisualStyle(style)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: style.iconName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(style == .oledStandby ? Color(hex: "F59E0B") : Color(hex: selectedTheme.colorHex))
                                    }
                                }
                                
                                Spacer(minLength: 4)
                                
                                Text(style.localizedName(for: selectedLanguage))
                                    .font(.system(size: 13, weight: .bold, design: style.fontDesign))
                                    .foregroundColor(style.primaryTextColor(for: colorScheme))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text(style.localizedSubtitle(for: selectedLanguage))
                                    .font(.system(size: 10))
                                    .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex).opacity(0.85))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .frame(width: 135, height: 130)
                            .background(style.backgroundGradient(for: colorScheme))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isSelected ?
                                            LinearGradient(
                                                colors: [style == .oledStandby ? Color(hex: "F59E0B") : Color(hex: selectedTheme.colorHex), Color.white.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : style.borderStroke(for: colorScheme),
                                        lineWidth: isSelected ? 2.2 : 1.0
                                    )
                            )
                            .shadow(color: isSelected ? (style == .oledStandby ? Color(hex: "F59E0B").opacity(0.3) : Color(hex: selectedTheme.colorHex).opacity(0.25)) : Color.black.opacity(0.15), radius: isSelected ? 8 : 4, y: 3)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
            
            // Live Preview карточка виджета / StandBy
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11))
                        Text("standby_preview_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        pickVerseForCurrentSize(previewWidgetSize)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 11))
                            Text("button_random_verse".localized(for: selectedLanguage))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                }
                
                // Переключатель размера превью (Малый 2x2, Средний 4x2, Большой 4x4)
                Picker("preview_widget_size", selection: $previewWidgetSize) {
                    ForEach(PreviewWidgetSize.allCases) { size in
                        Text(size.localizedTitle(for: selectedLanguage)).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .tint(colorScheme == .dark ? .white : .primary)
                .onChange(of: previewWidgetSize) { newSize in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    pickVerseForCurrentSize(newSize)
                }
                .padding(.bottom, 2)
                
                // Карточка в натуральную величину выбранного размера
                Group {
                    switch previewWidgetSize {
                    case .small:
                        // Малый 2x2 (StandBy / Small Widget)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 16, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                                .lineSpacing(3)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 2)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("widget_pray_done_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .semibold, design: selectedWidgetStyle.fontDesign))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(8)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(6)
                                    .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(14)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                        
                    case .medium:
                        // Средний 4x2 (Medium Widget)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 12.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 16.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(4)
                                .minimumScaleFactor(0.78)
                                .lineSpacing(3.5)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 1)
                            
                            Spacer(minLength: 4)
                            
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_next_verse_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(9)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_fav_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .cornerRadius(9)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "hands.sparkles.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_pray_todo_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(Color(hex: selectedTheme.colorHex))
                                .cornerRadius(9)
                            }
                        }
                        .padding(14)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                        
                    case .large:
                        // Большой 4x4 (Large Widget)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 14, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 17.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(7)
                                .minimumScaleFactor(0.75)
                                .lineSpacing(4.5)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 2)
                            
                            Spacer(minLength: 6)
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_next_verse_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(10)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_fav_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .cornerRadius(10)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "hands.sparkles.fill")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_pray_todo_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(Color(hex: selectedTheme.colorHex))
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: previewWidgetSize)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var autoWallpaperSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8").opacity(0.3), Color(hex: "0284C7").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("settings_auto_wallpaper_title".localized(for: selectedLanguage))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "0284C7"))
                            .cornerRadius(5)
                    }
                    
                    Text("settings_auto_wallpaper_subtitle".localized(for: selectedLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                isShowingWallpaperAutomation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .bold))
                    Text("auto_wallpaper_nav_button".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var lockScreenWidgetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("lockscreen_widget_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                } icon: {
                    Image(systemName: "lock.iphone")
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingWidgetInstruction = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 15))
                        Text("widget_instruction_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("lockscreen_widget_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            // 1. Язык виджетов
            VStack(alignment: .leading, spacing: 6) {
                Text("widget_language_title".localized(for: selectedLanguage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Picker("widget_language_title", selection: $selectedWidgetLanguage) {
                    ForEach(WidgetLanguage.allCases) { lang in
                        Text(lang.localizedName(for: selectedLanguage)).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .tint(colorScheme == .dark ? .white : .primary)
                .onChange(of: selectedWidgetLanguage) { newLang in
                    manager.setWidgetLanguage(newLang)
                }
            }
            .padding(.vertical, 4)
            
            // 2. Армянский перевод Библии
            VStack(alignment: .leading, spacing: 6) {
                Text("armenian_translation_title".localized(for: selectedLanguage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Picker("armenian_translation_title", selection: $selectedArmenianEdition) {
                    ForEach(ArmenianBibleEdition.allCases) { edition in
                        Text(edition.localizedTitle(for: selectedLanguage)).tag(edition)
                    }
                }
                .pickerStyle(.segmented)
                .tint(colorScheme == .dark ? .white : .primary)
                .onChange(of: selectedArmenianEdition) { newEd in
                    manager.setArmenianEdition(newEd)
                }
            }
            .padding(.vertical, 4)
            
            // 3. Категория цитат для Экрана Блокировки
            VStack(alignment: .leading, spacing: 8) {
                Text("lockscreen_category_title".localized(for: selectedLanguage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LockScreenCategory.allCases) { cat in
                            let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                            LockCategoryChipView(
                                cat: cat,
                                isSelected: selectedLockCategory == cat,
                                isLocked: isLocked,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                inputFieldBgColor: inputFieldBgColor,
                                inputFieldBorderColor: inputFieldBorderColor,
                                primaryTextColor: primaryTextColor
                            ) {
                                if isLocked {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    isShowingPaywall = true
                                } else {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    selectedLockCategory = cat
                                    manager.setLockScreenCategory(cat)
                                    
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        let pool = BibleVerse.lockScreenVerses(for: cat)
                                        previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
            
            // 4. Категория цитат для Среднего виджета (4x2)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_medium_category_title".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HomeWidgetCategory.allCases) { cat in
                            let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                            HomeCategoryChipView(
                                cat: cat,
                                isSelected: selectedMediumCategory == cat,
                                isLocked: isLocked,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                inputFieldBgColor: inputFieldBgColor,
                                inputFieldBorderColor: inputFieldBorderColor,
                                primaryTextColor: primaryTextColor
                            ) {
                                if isLocked {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    isShowingPaywall = true
                                } else {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    selectedMediumCategory = cat
                                    manager.setMediumWidgetCategory(cat)
                                    if previewWidgetSize == .medium {
                                        pickVerseForCurrentSize(.medium)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
            
            // 5. Категория цитат для Большого виджета (4x4)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "square.split.2x2")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_large_category_title".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HomeWidgetCategory.allCases) { cat in
                            let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                            HomeCategoryChipView(
                                cat: cat,
                                isSelected: selectedLargeCategory == cat,
                                isLocked: isLocked,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                inputFieldBgColor: inputFieldBgColor,
                                inputFieldBorderColor: inputFieldBorderColor,
                                primaryTextColor: primaryTextColor
                            ) {
                                if isLocked {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    isShowingPaywall = true
                                } else {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    selectedLargeCategory = cat
                                    manager.setLargeWidgetCategory(cat)
                                    if previewWidgetSize == .large {
                                        pickVerseForCurrentSize(.large)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
            
            // 6. Интерактивный Live-превью экрана блокировки
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("lockscreen_preview_title".localized(for: selectedLanguage))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                            previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 12))
                            Text("button_random_verse".localized(for: selectedLanguage))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                }
                
                LockScreenPreviewCardView(
                    verse: previewVerse,
                    language: selectedWidgetLanguage.appLanguage ?? selectedLanguage,
                    primaryTextColor: primaryTextColor,
                    isDarkMode: colorScheme == .dark
                )
                .padding(.top, 2)
            }
            
            // 5. Кнопка «Применить и обновить виджеты»
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
                manager.syncLockScreenWidget()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("update_widgets_now_button".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: selectedTheme.colorHex))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var aboutSection: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // 🔐 Секретная зона разработчика: 5 быстрых тапов → диалог PIN-кода
                HStack(spacing: 6) {
                    Text("about_app_title".localized(for: selectedLanguage))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let now = Date()
                    // Сброс счётчика если пауза между тапами > 2.5 секунд
                    if now.timeIntervalSince(secretLastTap) > 2.5 {
                        secretTapCount = 0
                    }
                    secretLastTap = now
                    secretTapCount += 1
                    
                    let g = UIImpactFeedbackGenerator(style: secretTapCount >= 5 ? .heavy : .light)
                    g.prepare()
                    g.impactOccurred()
                    
                    if secretTapCount >= 5 {
                        secretTapCount = 0
                        devPasscodeInput = ""
                        isShowingDevPasscodeAlert = true
                    }
                }
            
            HStack {
                Text("about_app_version".localized(for: selectedLanguage))
                Spacer()
                Text("2.2")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 14))
            
            HStack {
                Text("about_app_developer".localized(for: selectedLanguage))
                Spacer()
                Text("Samvel")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 14))
            
            Divider().opacity(0.4)
            
            // ─── Кнопка "Armenian Bible Premium" ────────────────────────
            if subscriptionManager.isPremium {
                // Уже Premium — показываем статус
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ARMENIAN BIBLE PREMIUM")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text({
                            switch selectedLanguage {
                            case .armenian: return "Ձեր բաժանորդագրությունն ակտիվ է ✓"
                            case .russian:  return "Ваша подписка активна ✓"
                            case .english:  return "Your subscription is active ✓"
                            }
                        }())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color(hex: "F59E0B").opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1))
            } else {
                // Не Premium — кнопка открытия Paywall
                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.prepare(); g.impactOccurred()
                    isShowingPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ARMENIAN BIBLE PREMIUM")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text({
                                switch selectedLanguage {
                                case .armenian: return "Բացեք բոլոր հնարավորությունները →"
                                case .russian:  return "Открыть все возможности →"
                                case .english:  return "Unlock all features →"
                                }
                            }())
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B").opacity(0.7))
                    }
                    .padding(12)
                    .background(Color(hex: "F59E0B").opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // ─── Кнопка "Восстановить покупки" ──────────────────────────
            Button {
                let g = UINotificationFeedbackGenerator()
                g.prepare(); g.notificationOccurred(.success)
                Task {
                    let restored = await subscriptionManager.restorePurchases()
                    if restored {
                        let s = UINotificationFeedbackGenerator()
                        s.notificationOccurred(.success)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text({
                        switch selectedLanguage {
                        case .armenian: return "Վերականգնել գնումները"
                        case .russian:  return "Восстановить покупки"
                        case .english:  return "Restore Purchases"
                        }
                    }())
                    .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: selectedTheme.colorHex))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: selectedTheme.colorHex).opacity(0.07))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: selectedTheme.colorHex).opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(subscriptionManager.isPurchasing)
        }
        .padding(18)
        .background(aboutBlockBgColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(aboutBlockBorderColor, lineWidth: 1)
        )
        
        // ─── Всплывающее уведомление режима разработчика ────────────────────
        if showDevToast {
            HStack(spacing: 12) {
                Image(systemName: devToastIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(devToastMessage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(devToastSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: devToastColor,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: (devToastColor.first ?? .clear).opacity(0.45), radius: 12, x: 0, y: 4)
            )
            .padding(.top, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        } // конец ZStack
    }
    
    // MARK: - Обработка переключения режима разработчика
    private func handleDevToggle(enablePremium: Bool) {
        let code = devPasscodeInput.trimmingCharacters(in: .whitespaces)
        if code == "1907" || code == "7777" || code == "2026" {
            subscriptionManager.toggleDeveloperPremium(to: enablePremium)
            let n = UINotificationFeedbackGenerator()
            n.notificationOccurred(.success)
            
            if enablePremium {
                devToastIcon = "crown.fill"
                devToastMessage = "👑 Premium активирован!"
                devToastSubtitle = "Все возможности открыты, реклама полностью отключена."
                devToastColor = [Color(hex: "F59E0B"), Color(hex: "D97706")]
            } else {
                devToastIcon = "hammer.fill"
                devToastMessage = "🧪 Free-режим включен!"
                devToastSubtitle = "Реклама Meta включена, лимиты активны для теста."
                devToastColor = [Color(hex: "3B82F6"), Color(hex: "1D4ED8")]
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showDevToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { showDevToast = false }
            }
        } else {
            let n = UINotificationFeedbackGenerator()
            n.notificationOccurred(.error)
        }
        devPasscodeInput = ""
    }
    
    // MARK: - Выбор стиха для текущего размера виджета в предпросмотре
    private func pickVerseForCurrentSize(_ size: PreviewWidgetSize) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            switch size {
            case .small:
                let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
            case .medium:
                let pool = BibleVerse.verses(for: selectedMediumCategory, isPremium: subscriptionManager.isPremium)
                let filtered = pool.filter { $0.textHy.count >= 35 && $0.textHy.count <= 100 }
                previewVerse = (!filtered.isEmpty ? filtered : pool).randomElement() ?? BibleVerse.database[1]
            case .large:
                let pool = BibleVerse.verses(for: selectedLargeCategory, isPremium: subscriptionManager.isPremium)
                let filtered = pool.filter { $0.textHy.count >= 75 }
                previewVerse = (!filtered.isEmpty ? filtered : pool).randomElement() ?? BibleVerse.database[0]
            }
        }
    }
}


// MARK: - Вспомогательное представление: Строка инструкции
struct InstructionRow: View {
    let number: String
    let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var numberBgColor: Color {
        let accentColor = Color(hex: BibleManager.shared.accentTheme.colorHex)
        return colorScheme == .dark ? accentColor.opacity(0.1) : accentColor.opacity(0.08)
    }
    
    private var numberTextColor: Color {
        let accentColor = Color(hex: BibleManager.shared.accentTheme.colorHex)
        let secondaryAccentColor = Color(hex: BibleManager.shared.accentTheme.secondaryColorHex)
        return colorScheme == .dark ? secondaryAccentColor : accentColor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(numberTextColor)
                .frame(width: 20, height: 20)
                .background(numberBgColor)
                .clipShape(Circle())
                .padding(.top, 1)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Вспомогательное представление: Сетка точек (Dot Grid)
struct StaticDotGridView: View {
    let dotColor: Color
    
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let dotSize: CGFloat = 1.0
            let spacing: CGFloat = 22.0
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    path.addRect(CGRect(x: x, y: y, width: dotSize, height: dotSize))
                }
            }
            context.fill(path, with: .color(dotColor))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Эластичный стиль кнопки
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Инициализация цвета по Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Расширение локализации String
extension String {
    func localized(for language: AppLanguage) -> String {
        guard let path = Bundle.main.path(forResource: language.localeCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

// MARK: - Карточка Викторины для Главного Экрана
struct BibleQuizCardView: View {
    let bestScore: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onStartQuiz: () -> Void
    
    var body: some View {
        Button {
            onStartQuiz()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("quiz_title".localized(for: language))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        if bestScore > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("\(bestScore)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(primaryTextColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }
                    
                    Text("quiz_card_subtitle".localized(for: language))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(secondaryAccentColor.opacity(0.6))
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }
}

// MARK: - Всплывающий Экран Инструкции Виджета
struct WidgetInstructionSheetView: View {
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            cardBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(primaryTextColor.opacity(0.4))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 28))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("widget_instruction_title".localized(for: language))
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("widget_instruction_subtitle".localized(for: language))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(number: "1", text: "widget_step_1".localized(for: language))
                    InstructionRow(number: "2", text: "widget_step_2".localized(for: language))
                    InstructionRow(number: "3", text: "widget_step_3".localized(for: language))
                    InstructionRow(number: "4", text: "widget_step_4".localized(for: language))
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("alert_ok_button".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}



// MARK: - Вспомогательное представление: Чип категории экрана блокировки
struct LockCategoryChipView: View {
    let cat: LockScreenCategory
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let inputFieldBgColor: Color
    let inputFieldBorderColor: Color
    let primaryTextColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Text(cat.icon)
                Text(cat.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: themeColorHex).opacity(0.18) : inputFieldBgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: themeColorHex) : inputFieldBorderColor, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color(hex: themeColorHex) : primaryTextColor)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Вспомогательное представление: Чип категории домашнего виджета (Medium 4x2 & Large 4x4)
struct HomeCategoryChipView: View {
    let cat: HomeWidgetCategory
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let inputFieldBgColor: Color
    let inputFieldBorderColor: Color
    let primaryTextColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(cat.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: themeColorHex).opacity(0.18) : inputFieldBgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: themeColorHex) : inputFieldBorderColor, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color(hex: themeColorHex) : primaryTextColor)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Вспомогательное представление: Карточка предпросмотра экрана блокировки
struct LockScreenPreviewCardView: View {
    let verse: BibleVerse
    let language: AppLanguage
    let primaryTextColor: Color
    let isDarkMode: Bool
    
    private var fontSize: CGFloat {
        let count = verse.text(for: language).count
        if count <= 25 {
            return 17.0
        } else if count <= 42 {
            return 15.5
        } else {
            return 14.0
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(verse.text(for: language))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .lineLimit(3)
                    .lineSpacing(-0.5)
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Text("✝️")
                        .font(.system(size: 9.5))
                    Text(verse.reference(for: language))
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

// MARK: - Карточка Плана Чтения и Стрика для Главного Экрана
struct ReadingPlanBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenPlans: () -> Void
    
    @ObservedObject private var planManager = ReadingPlanManager.shared
    
    var body: some View {
        Button {
            onOpenPlans()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "EF4444"), Color(hex: "F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(hex: "EF4444").opacity(0.35), radius: 6, y: 2)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("\(planManager.currentStreak) \("streak_days_suffix".localized(for: language))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(primaryTextColor)
                            
                            if planManager.currentStreak > 0 {
                                Text("🔥")
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if let plan = planManager.activePlan,
                           let day = planManager.nextIncompleteDay(for: plan.id) {
                            Text("\("day_label".localized(for: language)) \(day.dayNumber): \(day.title(for: language))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("reading_plan_card_hint".localized(for: language))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                // Если есть активный план — показываем прогресс-бар
                if let plan = planManager.activePlan {
                    let progress = planManager.progress(for: plan.id)
                    let completed = planManager.completedDaysCount(for: plan.id)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(plan.title(for: language))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(completed)/\(plan.daysCount)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 5)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(5, geo.size.width * CGFloat(progress)), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.2)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

