import SwiftUI
import WidgetKit

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var reviewManager = ReviewManager.shared
    @ObservedObject private var updateManager = AppUpdateManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        ZStack {
            if UserDefaults.standard.string(forKey: "openTab") == "lockscreen" {
                iPadLockScreenShowcaseView()
            } else {
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
                .onAppear {
                    if let tabArg = UserDefaults.standard.string(forKey: "openTab") {
                        if tabArg == "favorites" { manager.activeTabSelection = 1 }
                        else if tabArg == "ai" { manager.activeTabSelection = 2 }
                        else if tabArg == "bible" { manager.activeTabSelection = 3 }
                    }
                }
            }
            
            if manager.isBiometricLockEnabled && !manager.isAppUnlocked {
                BiometricLockOverlayView(manager: manager)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(999)
            }
            
            // 🚨 Окно обязательного принудительного обновления приложения
            if updateManager.isForceUpdateRequired {
                ForceUpdateOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: manager.isAppUnlocked)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: updateManager.isForceUpdateRequired)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                manager.lockApp()
            } else if newPhase == .active {
                if manager.isBiometricLockEnabled && !manager.isAppUnlocked {
                    manager.authenticateWithBiometrics()
                }
                updateManager.checkForUpdates(language: manager.appLanguage)
            }
        }
        .onAppear {
            if manager.isBiometricLockEnabled && !manager.isAppUnlocked {
                manager.authenticateWithBiometrics()
            }
            updateManager.checkForUpdates(language: manager.appLanguage)
        }
    }
}

// MARK: - Экран блокировки Face ID / Touch ID (Biometric Lock Overlay)
struct BiometricLockOverlayView: View {
    @ObservedObject var manager: BibleManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        ZStack {
            // Размытый полноэкранный ультратонкий фон
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Полупрозрачный градиентный фон в тон темы
            LinearGradient(
                colors: [
                    (colorScheme == .dark ? Color.black.opacity(0.85) : Color.white.opacity(0.92)),
                    (colorScheme == .dark ? Color(hex: "090A0F").opacity(0.95) : Color(hex: "F8FAFC").opacity(0.95))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Иконка Face ID с пульсирующим свечением
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isPulsing ? 0.22 : 0.10))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isPulsing ? 1.08 : 0.95)
                    
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "faceid")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                
                VStack(spacing: 10) {
                    Text("app_locked_title".localized(for: manager.appLanguage))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                        .multilineTextAlignment(.center)
                    
                    Text("app_locked_subtitle".localized(for: manager.appLanguage))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Кнопка разблокировки
                Button {
                    manager.triggerHapticImpact(.medium)
                    manager.authenticateWithBiometrics()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("unlock_app_btn".localized(for: manager.appLanguage))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [accentColor, Color(hex: manager.accentTheme.secondaryColorHex)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.35), radius: 10, y: 4)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 40)
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var reviewManager = ReviewManager.shared
    @State private var animateVerse = false
    @State private var isHeartBouncing = false
    @State private var isSparkBurstActive = false
    @State private var cardFlipAngle: Double = 0.0
    @State private var isShowingSettings = false
    @State private var isShowingReadingPlans = false
    @State private var isShowingQuiz = false
    @State private var isShowingCalendar = false
    @State private var isShowingSanctuary = false
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
            
            // Фоновое живое «дышащее» свечение позади текста (Divine Breathing Glow)
            DivineBreathingGlow(color: glowColor)
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
                            // 1. Кнопка Лайка (Избранное) с упругой пружинной анимацией и золотым салютом
                            Button {
                                triggerHaptic(.medium)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                    if manager.isFavorite(manager.currentVerse) {
                                        manager.removeFromFavorites(manager.currentVerse)
                                    } else {
                                        manager.addToFavorites(manager.currentVerse)
                                        isHeartBouncing = true
                                        isSparkBurstActive = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                                            isSparkBurstActive = false
                                        }
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
                                ZStack {
                                    Image(systemName: manager.isFavorite(manager.currentVerse) ? "heart.fill" : "heart")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(manager.isFavorite(manager.currentVerse) ? .red : primaryTextColor.opacity(0.6))
                                        .scaleEffect(isHeartBouncing ? 1.35 : 1.0)
                                    
                                    GoldenSparkBurstView(isTriggered: isSparkBurstActive)
                                }
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
                    .rotation3DEffect(
                        .degrees(cardFlipAngle),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        perspective: 0.35
                    )
                    .onTapGesture {
                        triggerHaptic(.medium)
                        
                        withAnimation(.easeIn(duration: 0.15)) {
                            cardFlipAngle = 90.0
                            animateVerse = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            manager.selectRandomVerse()
                            cardFlipAngle = -90.0
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                                cardFlipAngle = 0.0
                                animateVerse = true
                            }
                        }
                    }
                    .staggeredEntrance(index: 0)
                    
                    Spacer()
                        .frame(height: 6)
                    
                    // MARK: - Баннерная Реклама VK (LuysHybridBannerView)
                    LuysHybridBannerView(placement: .home)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                        .staggeredEntrance(index: 1)
                    
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
                    .staggeredEntrance(index: 2)
                    
                    // MARK: - Карточка Храмовой Молитвы и Свечей (Մոմավառություն)
                    PrayerSanctuaryBannerCardView(
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenSanctuary: {
                            triggerHaptic(.medium)
                            isShowingSanctuary = true
                        }
                    )
                    .staggeredEntrance(index: 3)
                    
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
                    .staggeredEntrance(index: 4)
                    
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
                    .staggeredEntrance(index: 5)
                    
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
                    .staggeredEntrance(index: 6)
                    
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
                    .staggeredEntrance(index: 7)
                }
                .padding(.bottom, 30)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
        .environment(\.locale, Locale(identifier: manager.appLanguage.localeCode))
        .onAppear {
            if let tabArg = UserDefaults.standard.string(forKey: "openTab") {
                if tabArg == "calendar" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingCalendar = true
                    }
                } else if tabArg == "quiz" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingQuiz = true
                    }
                } else if tabArg == "settings" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingSettings = true
                    }
                } else if tabArg == "wallpaper" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingWallpaperMaker = true
                    }
                }
            }
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
        .sheet(isPresented: $isShowingSanctuary) {
            PrayerSanctuaryView()
        }
        .sheet(isPresented: $isShowingWallpaperMaker) {
            BibleWallpaperMakerView(verse: manager.currentVerse)
        }
        .sheet(isPresented: $reviewManager.isShowingReviewSheet) {
            ReviewPromptSheetView()
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
        manager.triggerHapticImpact(style)
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
    
    @ObservedObject private var narekAudio = NarekAudioPlayer.shared
    
    var body: some View {
        Button {
            onOpenNarek()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    FlickeringCandleFlame(baseColor: accentColor, iconSize: 22)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("narekatsi_title".localized(for: language))
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        
                        if narekAudio.isPlaying {
                            AudioWaveformIndicator(isPlaying: true, color: accentColor)
                        }
                    }
                    
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

// MARK: - Баннерная Карточка Молитвенного Притвора и Свечей (Մոմավառություն)
struct PrayerSanctuaryBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenSanctuary: () -> Void
    
    @ObservedObject private var candleManager = CandleManager.shared
    
    var body: some View {
        Button {
            onOpenSanctuary()
        } label: {
            HStack(spacing: 16) {
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
                    
                    FlickeringCandleFlame(baseColor: Color(hex: "F59E0B"), iconSize: 22)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(language == .armenian ? "ՏԱՃԱՐԱՅԻՆ ՄՈՄԱՎԱՌՈՒԹՅՈՒՆ" : (language == .russian ? "ХРАМОВАЯ СВЕЧА И МОЛИТВА" : "SANCTUARY PRAYER CANDLE"))
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color(hex: "F59E0B"))
                        
                        if !candleManager.hasUsedDailyFreeCandle {
                            Text(language == .armenian ? "ԱՆՎՃԱՐ" : (language == .russian ? "ДАР" : "FREE"))
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "10B981"))
                                .cornerRadius(4)
                                .luysShimmer(duration: 2.2)
                        }
                    }
                    
                    Text(language == .armenian ? "Վառեք մոմ հարազատների առողջության կամ հոգու համար" : (language == .russian ? "Зажгите свечу о здравии или упокоении близких" : "Light a candle for health, peace, or memory"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryTextColor.opacity(0.85))
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
                    
                    if todayFeast != nil {
                        FlickeringCandleFlame(baseColor: Color(hex: "F59E0B"), iconSize: 22)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
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
                                .luysShimmer(duration: 2.2)
                            
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
                                .luysShimmer(duration: 2.5)
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

