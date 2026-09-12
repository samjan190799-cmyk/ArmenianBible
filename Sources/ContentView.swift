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
    @State private var isHeartBouncing = false
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
                            // 1. Кнопка Лайка (Избранное) с упругой пружинной анимацией
                            Button {
                                triggerHaptic(.medium)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                    if manager.isFavorite(manager.currentVerse) {
                                        manager.removeFromFavorites(manager.currentVerse)
                                    } else {
                                        manager.addToFavorites(manager.currentVerse)
                                        isHeartBouncing = true
                                    }
                                }
                                if isHeartBouncing {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            isHeartBouncing = false
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: manager.isFavorite(manager.currentVerse) ? "heart.fill" : "heart")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(manager.isFavorite(manager.currentVerse) ? .red : primaryTextColor.opacity(0.6))
                                    .scaleEffect(isHeartBouncing ? 1.32 : 1.0)
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
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
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
                } else if url.host == "tab" {
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let tabStr = components.queryItems?.first(where: { $0.name == "id" })?.value,
                       let tabInt = Int(tabStr) {
                        manager.activeTabSelection = tabInt
                    }
                } else if url.host == "calendar" {
                    isShowingCalendar = true
                } else if url.host == "quiz" {
                    isShowingQuiz = true
                } else if url.host == "settings" {
                    isShowingSettings = true
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
    @State private var isAskingAI = false
    @State private var isShowingPaywall = false
    @State private var isShowingRewardedOffer = false
    
    // Ошибки и подтверждения
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    @State private var showingClearChatConfirmation = false
    
    // Экспорт и Toast
    @State private var shareItem: ShareItem? = nil
    @State private var showCopiedToast = false
    @State private var toastMessage = ""
    
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
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85)
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
            
            // Фоновое мягкое свечение
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.07 : 0.04), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Верхняя панель чата (Header)
                chatHeaderView
                
                Divider()
                    .opacity(0.2)
                
                // 2. Область сообщений со скроллом к низу
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if manager.aiChatMessages.isEmpty {
                                chatWelcomeView
                            } else {
                                ForEach(manager.aiChatMessages) { msg in
                                    AIChatBubbleRow(
                                        message: msg,
                                        manager: manager,
                                        accentColor: accentColor,
                                        secondaryAccentColor: secondaryAccentColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        cardBorderColor: cardBorderColor,
                                        primaryTextColor: primaryTextColor,
                                        onShareVerse: { verse in
                                            shareVerse(verse)
                                        },
                                        onCopy: { text in
                                            copyText(text)
                                        }
                                    )
                                    .id(msg.id)
                                }
                                
                                if isAskingAI {
                                    AIChatThinkingRow(
                                        language: manager.appLanguage,
                                        accentColor: accentColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        cardBorderColor: cardBorderColor,
                                        primaryTextColor: primaryTextColor
                                    )
                                    .id("thinkingAnchor")
                                }
                            }
                            
                            // Якорь прокрутки
                            Color.clear
                                .frame(height: 1)
                                .id("bottomChatAnchor")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: manager.aiChatMessages.count) { _ in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            proxy.scrollTo("bottomChatAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: isAskingAI) { asking in
                        if asking {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                proxy.scrollTo("bottomChatAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 3. Нижняя панель ввода (Bottom Input Bar)
                chatBottomInputBar
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            
            // Всплывающий Toast о копировании
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
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
        .confirmationDialog(
            manager.appLanguage == .armenian ? "Ջնջե՞լ զրույցի պատմությունը" : (manager.appLanguage == .russian ? "Очистить историю чата?" : "Clear chat history?"),
            isPresented: $showingClearChatConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                manager.appLanguage == .armenian ? "Մաքրել զրույցը" : (manager.appLanguage == .russian ? "Очистить чат" : "Clear Chat"),
                role: .destructive
            ) {
                triggerHaptic(.medium)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    manager.clearAIChat()
                }
            }
            Button("alert_cancel_button".localized(for: manager.appLanguage), role: .cancel) {}
        }
    }
    
    // MARK: - Верхняя панель (Header)
    private var chatHeaderView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("ai_guide_title".localized(for: manager.appLanguage))
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    // Меню переключения активной модели ИИ
                    Menu {
                        ForEach(AIProvider.allCases) { provider in
                            Button {
                                triggerHaptic(.medium)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    manager.activeProvider = provider
                                }
                            } label: {
                                HStack {
                                    Text(provider.displayName)
                                    if manager.activeProvider == provider {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: manager.activeProvider.accentColorHex))
                                .frame(width: 6, height: 6)
                            Text(manager.activeProvider.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: manager.activeProvider.accentColorHex).opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                
                // Статус подписки
                HStack(spacing: 5) {
                    Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Text(subscriptionManager.isPremium ?
                         (manager.appLanguage == .armenian ? "PRO • Անսահմանափակ" : (manager.appLanguage == .russian ? "PRO • Безлимитно" : "PRO • Unlimited")) :
                         (manager.appLanguage == .armenian ? "Մնացել է \(subscriptionManager.remainingFreeAiQuestions) հարց" : (manager.appLanguage == .russian ? "Осталось \(subscriptionManager.remainingFreeAiQuestions) вопр." : "\(subscriptionManager.remainingFreeAiQuestions) questions left")))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(subscriptionManager.isPremium ? Color(hex: "F59E0B") : .secondary)
                    
                    if !subscriptionManager.isPremium {
                        Button {
                            triggerHaptic(.light)
                            isShowingPaywall = true
                        } label: {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(accentColor.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Кнопка очистки истории диалога
            if !manager.aiChatMessages.isEmpty {
                Button {
                    triggerHaptic(.light)
                    showingClearChatConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(9)
                        .background(cardBackgroundColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    // MARK: - Приветственный экран, если чат еще пуст
    private var chatWelcomeView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)
            
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 68, height: 68)
                Image(systemName: "sparkles")
                    .font(.system(size: 30))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 6) {
                Text("ai_guide_title".localized(for: manager.appLanguage))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                
                Text("ai_guide_subtitle".localized(for: manager.appLanguage))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
            
            // MARK: - Переключатель моделей ИИ
            HStack(spacing: 8) {
                ForEach(AIProvider.allCases) { provider in
                    Button {
                        triggerHaptic(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            manager.activeProvider = provider
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: provider.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(provider.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(manager.activeProvider == provider ? .white : primaryTextColor.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            manager.activeProvider == provider ?
                            Color(hex: provider.accentColorHex) :
                            cardBackgroundColor
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(manager.activeProvider == provider ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 2)
            
            // MARK: - Баннерная Реклама Meta
            BannerAdView()
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            
            // Подсказки быстрых вопросов
            VStack(alignment: .leading, spacing: 10) {
                Text("suggested_questions_title".localized(for: manager.appLanguage))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                ForEach(suggestedQuestions) { sq in
                    Button {
                        triggerHaptic(.medium)
                        let q = sq.key.localized(for: manager.appLanguage)
                        submitQuestion(q)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sq.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryAccentColor)
                                .frame(width: 22)
                            
                            Text(sq.key.localized(for: manager.appLanguage))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(cardBackgroundColor)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Нижняя панель ввода (Bottom Input Bar)
    private var chatBottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)
            
            HStack(alignment: .bottom, spacing: 10) {
                TextField("ai_placeholder_prompt".localized(for: manager.appLanguage), text: $questionText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(cardBackgroundColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(questionText.isEmpty ? Color.primary.opacity(0.08) : accentColor.opacity(0.5), lineWidth: 1.2)
                    )
                
                Button {
                    triggerHaptic(.medium)
                    let textToSend = questionText
                    questionText = ""
                    submitQuestion(textToSend)
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSubmit ? accentColor : Color.gray.opacity(0.3))
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: -1, y: 1)
                    }
                }
                .disabled(!canSubmit)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
    
    private var canSubmit: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isAskingAI
    }
    
    // MARK: - Логика отправки вопроса
    private func submitQuestion(_ rawQuestion: String) {
        let trimmed = rawQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !subscriptionManager.canAskAI() {
            triggerHaptic(.heavy)
            isShowingRewardedOffer = true
            return
        }
        
        let key: String
        switch manager.activeProvider {
        case .gemini: key = manager.geminiApiKey
        case .chatgpt: key = manager.openaiApiKey
        case .claude: key = manager.anthropicApiKey
        }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerHaptic(.heavy)
            showingNoKeyAlert = true
            return
        }
        
        // Добавляем вопрос пользователя в историю чата
        let userMessage = AIChatMessage(isUser: true, text: trimmed)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            manager.addAIChatMessage(userMessage)
            isAskingAI = true
        }
        
        manager.askBibleAI(question: trimmed) { result in
            DispatchQueue.main.async {
                self.isAskingAI = false
                switch result {
                case .success(let answer):
                    self.subscriptionManager.recordAiQuestionUsed()
                    let aiMessage = AIChatMessage(
                        isUser: false,
                        text: answer.answerText,
                        verse: answer.verse
                    )
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        self.manager.addAIChatMessage(aiMessage)
                    }
                case .failure(let error):
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func copyText(_ text: String) {
        triggerHaptic(.light)
        UIPasteboard.general.string = text
        toastMessage = "copied_to_clipboard".localized(for: manager.appLanguage)
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
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
}

// MARK: - Строка сообщения чата (Bubble Row)

struct AIChatBubbleRow: View {
    let message: AIChatMessage
    @ObservedObject var manager: BibleManager
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onShareVerse: (BibleVerse) -> Void
    let onCopy: (String) -> Void
    
    @State private var isHeartBouncing = false
    
    var body: some View {
        if message.isUser {
            // Сообщение пользователя (справа)
            HStack {
                Spacer(minLength: 44)
                
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: accentColor.opacity(0.25), radius: 6, y: 3)
            }
        } else {
            // Ответ Духовного Помощника (слева)
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Заголовок карточки ответа
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        Text("ai_guide_title".localized(for: manager.appLanguage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                        
                        // Кнопка копирования ответа
                        Button {
                            onCopy(message.text)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Text(message.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Если есть цитируемый стих
                    if let verse = message.verse {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "laurel.leading")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                                Spacer()
                                Image(systemName: "laurel.trailing")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                            }
                            
                            Text(verse.text)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                            
                            Text(verse.reference)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                            
                            // Кнопки управления стихом
                            HStack(spacing: 18) {
                                // Добавить в Избранное
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                        if manager.isFavorite(verse) {
                                            manager.removeFromFavorites(verse)
                                        } else {
                                            manager.addToFavorites(verse)
                                            isHeartBouncing = true
                                        }
                                    }
                                    if isHeartBouncing {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                            withAnimation(.easeOut(duration: 0.15)) {
                                                isHeartBouncing = false
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: manager.isFavorite(verse) ? "heart.fill" : "heart")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(manager.isFavorite(verse) ? .red : primaryTextColor.opacity(0.5))
                                        .scaleEffect(isHeartBouncing ? 1.3 : 1.0)
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Поделиться открыткой
                                Button {
                                    onShareVerse(verse)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Скопировать стих
                                Button {
                                    onCopy("\(verse.text)\n— \(verse.reference)")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(cardBackgroundColor.opacity(0.6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
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
                
                Spacer(minLength: 32)
            }
        }
    }
}

// MARK: - Индикатор размышления ИИ (Thinking Bubble)

struct AIChatThinkingRow: View {
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(accentColor)
                    .scaleEffect(0.9)
                
                Text("ai_searching_answer".localized(for: language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            
            Spacer(minLength: 40)
        }
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
            prompt = "Ты эксперт по Библии и богословию. Объясни и истолкуй следующий библейский стих: «\(manager.currentVerse.text)» (\(manager.currentVerse.reference)). Дай глубокое, богословское, но понятное толкование на русском языке. \(depthPrompt) Пиши структурировано, разделяя текст на логические абзацы."
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
    @State private var previewWidgetSize: PreviewWidgetSize = .lockScreen
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
                        appLanguageSection
                        appearanceModeSection
                        colorThemeSection
                        appIconSection
                        apiKeysSection
                        dailyNotificationsSection
                        updateIntervalSection
                        verseSourceScopeSection
                        contentTypeSection
                        widgetsUnifiedSection
                        autoWallpaperSection
                        aboutSection
                    }
                    .padding(20)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
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
                if !subscriptionManager.isPremium && manager.widgetVisualStyle != .oledStandby {
                    manager.setWidgetVisualStyle(.oledStandby)
                    selectedWidgetStyle = .oledStandby
                } else {
                    selectedWidgetStyle = manager.widgetVisualStyle
                }
                selectedLockCategory = manager.lockScreenCategory
                selectedMediumCategory = manager.mediumWidgetCategory
                selectedLargeCategory = manager.largeWidgetCategory
                selectedArmenianEdition = manager.armenianEdition
                pickVerseForCurrentSize(previewWidgetSize)
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    manager.setAppLanguage(newLang)
                    manager.forceRefreshUI()
                }
            }
            
            if selectedLanguage == .armenian {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                        Text("cards_translation_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.top, 2)
                    
                    Text("cards_translation_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                    
                    Picker("cards_translation_title", selection: $selectedArmenianEdition) {
                        Text("edition_ararat_badge".localized(for: selectedLanguage))
                            .tag(ArmenianBibleEdition.ararat)
                        Text("edition_echmiadzin_badge".localized(for: selectedLanguage))
                            .tag(ArmenianBibleEdition.echmiadzin)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color(hex: selectedTheme.colorHex))
                    .onChange(of: selectedArmenianEdition) { newEd in
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        manager.setArmenianEdition(newEd)
                        manager.forceRefreshUI()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                    let isSelected = selectedTheme == theme
                    ZStack {
                        Circle()
                            .fill(Color(hex: theme.colorHex))
                            .frame(width: 40, height: 40)
                            .scaleEffect(isSelected ? 1.08 : 1.0)
                            .shadow(color: Color(hex: theme.colorHex).opacity(isSelected ? 0.45 : 0.2), radius: isSelected ? 6 : 4, y: 2)
                        
                        if isSelected {
                            Circle()
                                .stroke(primaryTextColor, lineWidth: 2)
                                .frame(width: 50, height: 50)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTheme = theme
                            manager.setAccentTheme(theme)
                        }
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTheme)
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
                            
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                                appIconManager.selectIcon(option) {
                                    isShowingPaywall = true
                                }
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(option.assetPreviewName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 68, height: 68)
                                        .scaleEffect(isSelected ? 1.04 : 1.0)
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
                                        .transition(.scale.combined(with: .opacity))
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
    
    // MARK: - Свайп-карусель ИИ-провайдеров
    @ViewBuilder
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Верхняя плашка заголовка секции
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(providerAccentColor(for: selectedProvider))
                
                Text("ai_provider".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                // Бейдж текущей выбранной модели
                HStack(spacing: 4) {
                    Circle()
                        .fill(providerAccentColor(for: selectedProvider))
                        .frame(width: 6, height: 6)
                    Text(selectedProvider.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(providerAccentColor(for: selectedProvider).opacity(0.12))
                .cornerRadius(10)
            }
            .padding(.horizontal, 4)
            
            // Верхние переключатели-пилюли с плавной анимацией
            HStack(spacing: 6) {
                ForEach(AIProvider.allCases) { provider in
                    let isSelected = selectedProvider == provider
                    let pColor = providerAccentColor(for: provider)
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            selectedProvider = provider
                            manager.setActiveProvider(provider)
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: providerIconName(for: provider))
                                .font(.system(size: 11, weight: .bold))
                            Text(provider.displayName)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? .white : primaryTextColor.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [pColor, providerSecondaryColor(for: provider)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: pColor.opacity(0.35), radius: 6, y: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                                }
                            }
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
            )
            .padding(.horizontal, 4)
            
            // Интерактивная свайп-карусель карточек с нативной пружинной физикой
            TabView(selection: $selectedProvider) {
                ForEach(AIProvider.allCases) { provider in
                    aiProviderCard(for: provider)
                        .tag(provider)
                        .padding(.horizontal, 4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 245)
            .onChange(of: selectedProvider) { newProvider in
                manager.setActiveProvider(newProvider)
                UISelectionFeedbackGenerator().selectionChanged()
            }
            
            // Нижние анимированные индикаторы страниц (dots) и подсказка свайпа
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(AIProvider.allCases) { provider in
                        let isSelected = selectedProvider == provider
                        let pColor = providerAccentColor(for: provider)
                        
                        Capsule()
                            .fill(isSelected ? pColor : Color.secondary.opacity(0.3))
                            .frame(width: isSelected ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedProvider)
                    }
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .onChange(of: geminiKeyInput) { val in
            manager.geminiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: openaiKeyInput) { val in
            manager.openaiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: anthropicKeyInput) { val in
            manager.anthropicApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // MARK: - Карточка отдельного ИИ-провайдера
    @ViewBuilder
    private func aiProviderCard(for provider: AIProvider) -> some View {
        let pColor = providerAccentColor(for: provider)
        let isCurrentActive = manager.activeProvider == provider
        
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя плашка с иконкой, заголовком и статусом
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [pColor.opacity(0.25), providerSecondaryColor(for: provider).opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: providerIconName(for: provider))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(pColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(providerTitle(for: provider))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Text(providerModelSubtitle(for: provider))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(pColor.opacity(0.95))
                }
                
                Spacer()
                
                if isCurrentActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text(activeBadgeText)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [pColor, providerSecondaryColor(for: provider)], startPoint: .leading, endPoint: .trailing))
                    )
                }
            }
            
            // Описание назначения модели
            Text(providerDescription(for: provider))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .lineSpacing(2)
            
            // Поле ввода API ключа
            VisibleApiKeyField(
                placeholder: providerPlaceholder(for: provider),
                text: providerKeyBinding(for: provider),
                accentColor: pColor
            )
            
            // Статус сохранения ключа
            HStack(spacing: 6) {
                if isKeySaved(for: provider) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(apiKeyRequiredText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [pColor.opacity(0.6), pColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: pColor.opacity(0.08), radius: 10, y: 4)
    }
    
    // MARK: - Вспомогательные методы для ИИ-карусели
    private func providerAccentColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Color(hex: "4E80EE")
        case .chatgpt: return Color(hex: "10A37F")
        case .claude: return Color(hex: "E07A5F")
        }
    }
    
    private func providerSecondaryColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Color(hex: "8E55EA")
        case .chatgpt: return Color(hex: "059669")
        case .claude: return Color(hex: "D97706")
        }
    }
    
    private func providerIconName(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "sparkles"
        case .chatgpt: return "bubble.left.and.text.bubble.right.fill"
        case .claude: return "cpu.fill"
        }
    }
    
    private func providerModelSubtitle(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "Google Gemini 2.5 / 3.5 Flash"
        case .chatgpt: return "OpenAI GPT-4o / GPT-4o-mini"
        case .claude: return "Anthropic Claude 3.5 Sonnet"
        }
    }
    
    private func providerTitle(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_title".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_title".localized(for: selectedLanguage)
        case .claude: return "claude_settings_title".localized(for: selectedLanguage)
        }
    }
    
    private func providerDescription(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_description".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_description".localized(for: selectedLanguage)
        case .claude: return "claude_settings_description".localized(for: selectedLanguage)
        }
    }
    
    private func providerPlaceholder(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "placeholder_gemini_key".localized(for: selectedLanguage)
        case .chatgpt: return "placeholder_openai_key".localized(for: selectedLanguage)
        case .claude: return "placeholder_anthropic_key".localized(for: selectedLanguage)
        }
    }
    
    private func providerKeyBinding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .gemini: return $geminiKeyInput
        case .chatgpt: return $openaiKeyInput
        case .claude: return $anthropicKeyInput
        }
    }
    
    private func isKeySaved(for provider: AIProvider) -> Bool {
        switch provider {
        case .gemini: return !manager.geminiApiKey.isEmpty && !geminiKeyInput.isEmpty
        case .chatgpt: return !manager.openaiApiKey.isEmpty && !openaiKeyInput.isEmpty
        case .claude: return !manager.anthropicApiKey.isEmpty && !anthropicKeyInput.isEmpty
        }
    }
    
    private var activeBadgeText: String {
        switch selectedLanguage {
        case .armenian: return "Ակտիվ"
        case .russian: return "Активная"
        case .english: return "Active"
        }
    }
    
    private var apiKeyRequiredText: String {
        switch selectedLanguage {
        case .armenian: return "Մուտքագրեք անձնական API բանալին"
        case .russian: return "Введите персональный API-ключ"
        case .english: return "Enter personal API key"
        }
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
    
    // MARK: - Объединенная секция: Виджеты, Экран блокировки и StandBy
    @ViewBuilder
    private var widgetsUnifiedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Шапка карточки: Заголовок + Бейдж + Кнопка справки
            HStack(spacing: 8) {
                Label {
                    Text("lockscreen_widget_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                } icon: {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                
                // Бейдж STANDBY
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("STANDBY")
                        .font(.system(size: 9, weight: .black))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color(hex: "F59E0B").opacity(0.18))
                .foregroundColor(Color(hex: "F59E0B"))
                .cornerRadius(6)
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingWidgetInstruction = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                        Text("widget_instruction_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("widget_style_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            // 2. Язык виджетов
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_language_title".localized(for: selectedLanguage))
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                Picker("widget_language_title", selection: $selectedWidgetLanguage) {
                    ForEach(WidgetLanguage.allCases) { lang in
                        Text(lang.localizedName(for: selectedLanguage)).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .tint(colorScheme == .dark ? .white : .primary)
                .onChange(of: selectedWidgetLanguage) { newLang in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    manager.setWidgetLanguage(newLang)
                }
            }
            
            // 3. Стиль оформления StandBy / Home виджетов (5 вариантов)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_style_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WidgetVisualStyle.allCases) { style in
                            let isLocked = (style != .oledStandby) && !subscriptionManager.isPremium
                            WidgetStyleCardButton(
                                style: style,
                                isSelected: selectedWidgetStyle == style,
                                isLocked: isLocked,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                colorScheme: colorScheme
                            ) {
                                if isLocked {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.warning)
                                    isShowingPaywall = true
                                    return
                                }
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedWidgetStyle = style
                                }
                                manager.setWidgetVisualStyle(style)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Divider().opacity(0.3)
            
            // 4. Интерактивный Live Preview с переключателем 4-х размеров
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("standby_preview_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(primaryTextColor)
                    
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
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Переключатель размера (Lock Screen, 2x2, 4x2, 4x4)
                Picker("preview_widget_size", selection: $previewWidgetSize) {
                    ForEach(PreviewWidgetSize.allCases) { size in
                        HStack(spacing: 4) {
                            Image(systemName: size.iconName)
                            Text(size.localizedTitle(for: selectedLanguage))
                        }
                        .tag(size)
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
                
                // 5. Контекстный выбор категории цитат (именно под выбранный размер!)
                VStack(alignment: .leading, spacing: 6) {
                    switch previewWidgetSize {
                    case .lockScreen, .small:
                        Text("lockscreen_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
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
                                            pickVerseForCurrentSize(previewWidgetSize)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                    case .medium:
                        Text("widget_medium_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
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
                                            pickVerseForCurrentSize(.medium)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                    case .large:
                        Text("widget_large_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
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
                                            pickVerseForCurrentSize(.large)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // 6. Карточка превью выбранного размера
                Group {
                    switch previewWidgetSize {
                    case .lockScreen:
                        LockScreenPreviewCardView(
                            verse: previewVerse,
                            language: selectedWidgetLanguage.appLanguage ?? selectedLanguage,
                            primaryTextColor: primaryTextColor,
                            isDarkMode: colorScheme == .dark,
                            fontDesign: selectedWidgetStyle.fontDesign,
                            accentHex: selectedWidgetStyle == .oledStandby ? "F59E0B" : selectedTheme.colorHex
                        )
                        
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
                
                // 7. Кнопка «Применить и обновить виджеты»
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
                .padding(.top, 2)
            }
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
            case .lockScreen:
                let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
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

// MARK: - Вспомогательное представление: Карточка выбора стиля виджетов
struct WidgetStyleCardButton: View {
    let style: WidgetVisualStyle
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    private var accentColor: Color {
        style == .oledStandby ? Color(hex: "F59E0B") : Color(hex: themeColorHex)
    }
    
    private var shadowColor: Color {
        if isSelected {
            return accentColor.opacity(0.28)
        }
        return Color.black.opacity(0.12)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: style.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: themeColorHex))
                    
                    Spacer()
                    
                    if isLocked {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: "F59E0B").opacity(0.22))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .cornerRadius(5)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(accentColor)
                    }
                }
                
                Spacer(minLength: 2)
                
                Text(style.localizedName(for: selectedLanguage))
                    .font(.system(size: 12.5, weight: .bold, design: style.fontDesign))
                    .foregroundColor(style.primaryTextColor(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(style.localizedSubtitle(for: selectedLanguage))
                    .font(.system(size: 9.5))
                    .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: themeColorHex).opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(11)
            .frame(width: 130, height: 120)
            .background(style.backgroundGradient(for: colorScheme))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ?
                            LinearGradient(
                                colors: [accentColor, Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : style.borderStroke(for: colorScheme),
                        lineWidth: isSelected ? 2.2 : 1.0
                    )
            )
            .shadow(color: shadowColor, radius: isSelected ? 6 : 3, y: 2)
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
    var fontDesign: Font.Design = .serif
    var accentHex: String = "6366F1"
    
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
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: accentHex).opacity(0.35), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(verse.text(for: language))
                    .font(.system(size: fontSize, weight: .bold, design: fontDesign))
                    .lineLimit(3)
                    .lineSpacing(-0.5)
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Text("✝️")
                        .font(.system(size: 9.5))
                    Text(verse.reference(for: language))
                        .font(.system(size: 11.5, weight: .bold, design: fontDesign))
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


// MARK: - Visible API Key Field (high contrast, show/hide button)
struct VisibleApiKeyField: View {
    let placeholder: String
    @Binding var text: String
    let accentColor: Color

    @State private var isRevealed: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var fieldBackground: Color {
        colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.96)
    }

    private var fieldBorderColor: Color {
        text.isEmpty
            ? (colorScheme == .dark ? Color(white: 0.32) : Color(white: 0.7))
            : accentColor.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 0) {
            if isRevealed {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
            }

            Button {
                isRevealed.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(accentColor.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
        .background(fieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(fieldBorderColor, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
    }
}
