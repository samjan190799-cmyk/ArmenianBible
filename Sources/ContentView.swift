import SwiftUI

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var selectedTab = 0
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("tab_home".localized(for: manager.appLanguage), systemImage: "house.fill")
                }
                .tag(0)
            
            AIGuideView()
                .tabItem {
                    Label("tab_ai_guide".localized(for: manager.appLanguage), systemImage: "sparkles")
                }
                .tag(1)
            
            ExplanationView()
                .tabItem {
                    Label("tab_explanation".localized(for: manager.appLanguage), systemImage: "book.fill")
                }
                .tag(2)
        }
        .tint(accentColor)
    }
}

struct HomeView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var animateVerse = false
    @State private var isShowingSettings = false
    
    // Переменные для обработки ошибок ИИ
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    // Переменные для экспорта картинок
    @State private var shareImage: UIImage? = nil
    @State private var isShowingShareSheet = false
    
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
                    VStack(spacing: 20) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 28))
                            .foregroundColor(secondaryAccentColor.opacity(0.7))
                        
                        Text(manager.currentVerse.text)
                            .font(.system(size: 21, weight: .medium, design: .serif))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateVerse ? 1 : 0)
                            .offset(y: animateVerse ? 0 : 15)
                        
                        Text(manager.currentVerse.reference)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(secondaryAccentColor)
                            .padding(.top, 4)
                            .opacity(animateVerse ? 0.8 : 0)
                            .offset(y: animateVerse ? 0 : 10)
                        
                        // Кнопки управления стихом (Избранное и Поделиться)
                        HStack(spacing: 24) {
                            // Кнопка Лайка
                            Button {
                                triggerHaptic(.light)
                                if manager.isFavorite(manager.currentVerse) {
                                    manager.removeFromFavorites(manager.currentVerse)
                                } else {
                                    manager.addToFavorites(manager.currentVerse)
                                }
                            } label: {
                                Image(systemName: manager.isFavorite(manager.currentVerse) ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(manager.isFavorite(manager.currentVerse) ? .red : primaryTextColor.opacity(0.4))
                                    .padding(10)
                                    .background(primaryTextColor.opacity(0.04))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Кнопка Поделиться открыткой
                            Button {
                                triggerHaptic(.medium)
                                shareVerseAsImage()
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
                        .padding(.top, 8)
                        .opacity(animateVerse ? 1 : 0)
                    }
                    .padding(26)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardBackgroundColor)
                            .background(.ultraThinMaterial)
                    )
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
                    
                    // MARK: - Блок кнопок генерации
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Кнопка: Случайный оффлайн-стих
                            Button {
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
                            } label: {
                                Text("button_random_verse".localized(for: manager.appLanguage))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(randomButtonTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(randomButtonBgColor)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(randomButtonBorderColor, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Кнопка: Генерация через ИИ
                            Button {
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
                                } else {
                                    triggerHaptic(.medium)
                                    runAIGeneration()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if manager.isGeneratingAI {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 15))
                                        Text("button_ai_generation".localized(for: manager.appLanguage))
                                    }
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [accentColor, secondaryAccentColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, y: 4)
                            }
                            .disabled(manager.isGeneratingAI)
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // MARK: - Блок инструкций для экрана блокировки
                    VStack(alignment: .leading, spacing: 14) {
                        Text("instruction_title".localized(for: manager.appLanguage))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .padding(.bottom, 2)
                        
                        InstructionRow(number: "1", text: "instruction_step_1".localized(for: manager.appLanguage))
                        InstructionRow(number: "2", text: "instruction_step_2".localized(for: manager.appLanguage))
                        InstructionRow(number: "3", text: "instruction_step_3".localized(for: manager.appLanguage))
                        InstructionRow(number: "4", text: "instruction_step_4".localized(for: manager.appLanguage))
                    }
                    .padding(20)
                    .background(instructionBgColor)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(instructionBorderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(isPresented: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = shareImage {
                ActivityView(activityItems: [image])
            }
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
            if url.scheme == "armenianbible" && url.host == "next-verse" {
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
        hostingController.view.backgroundColor = .clear
        
        // Принудительный layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareImage = image
        self.isShowingShareSheet = true
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
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

// MARK: - Activity View (Share Sheet) для SwiftUI
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ЭКРАН ИИ РУКОВОДСТВА (AI Guide View)
struct AIGuideView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var customPrompt = ""
    @State private var selectedMood: String? = nil
    @State private var generatedVerse: BibleVerse? = nil
    
    // Ошибки
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    // Карточка
    @State private var shareImage: UIImage? = nil
    @State private var isShowingShareSheet = false
    @State private var animateVerse = false
    
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
    
    struct MoodItem: Identifiable {
        let id = UUID()
        let key: String
        let icon: String
        let moodNameEn: String
    }
    
    private let moods = [
        MoodItem(key: "mood_comfort", icon: "heart.text.square.fill", moodNameEn: "Comfort"),
        MoodItem(key: "mood_gratitude", icon: "hands.sparkles.fill", moodNameEn: "Gratitude"),
        MoodItem(key: "mood_hope", icon: "sun.max.fill", moodNameEn: "Hope"),
        MoodItem(key: "mood_peace", icon: "wind", moodNameEn: "Peace"),
        MoodItem(key: "mood_wisdom", icon: "book.closed.fill", moodNameEn: "Wisdom"),
        MoodItem(key: "mood_strength", icon: "shield.fill", moodNameEn: "Strength")
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
                    VStack(spacing: 6) {
                        Text("ai_guide_title".localized(for: manager.appLanguage))
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        Text("ai_guide_subtitle".localized(for: manager.appLanguage))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Сетка настроений
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(moods) { mood in
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selectedMood == mood.moodNameEn ? accentColor.opacity(0.12) : cardBackgroundColor)
                                    .background(.ultraThinMaterial)
                                
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selectedMood == mood.moodNameEn ? accentColor : Color.primary.opacity(0.06), lineWidth: 1.2)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: mood.icon)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(selectedMood == mood.moodNameEn ? accentColor : secondaryAccentColor.opacity(0.8))
                                    Text(mood.key.localized(for: manager.appLanguage))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(primaryTextColor)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 10)
                            }
                            .onTapGesture {
                                triggerHaptic(.light)
                                selectedMood = mood.moodNameEn
                                customPrompt = ""
                                generatedVerse = nil
                                startAIGeneration(mood: mood.moodNameEn, custom: nil)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Поле ввода запроса
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            TextField("ai_placeholder_prompt".localized(for: manager.appLanguage), text: $customPrompt)
                                .font(.system(size: 14))
                                .padding()
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(customPrompt.isEmpty ? Color.primary.opacity(0.06) : accentColor.opacity(0.5), lineWidth: 1.2)
                                )
                                .onChange(of: customPrompt) { _ in
                                    if !customPrompt.isEmpty {
                                        selectedMood = nil
                                    }
                                }
                            
                            Button {
                                triggerHaptic(.medium)
                                selectedMood = nil
                                generatedVerse = nil
                                startAIGeneration(mood: "", custom: customPrompt)
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary.opacity(0.3) : accentColor)
                            }
                            .disabled(customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.isGeneratingAI)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Результат
                    if manager.isGeneratingAI {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(accentColor)
                            Text("explain_loading".localized(for: manager.appLanguage))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if let verse = generatedVerse {
                        VStack(spacing: 20) {
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 28))
                                .foregroundColor(secondaryAccentColor.opacity(0.7))
                            
                            Text(verse.text)
                                .font(.system(size: 19, weight: .medium, design: .serif))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .padding(.horizontal, 10)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateVerse ? 1 : 0)
                                .offset(y: animateVerse ? 0 : 15)
                            
                            Text(verse.reference)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                                .padding(.top, 4)
                                .opacity(animateVerse ? 0.8 : 0)
                                .offset(y: animateVerse ? 0 : 10)
                            
                            HStack(spacing: 24) {
                                // Лайк
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
                                
                                // Поделиться
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
                            .padding(.top, 8)
                            .opacity(animateVerse ? 1 : 0)
                        }
                        .padding(26)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(cardBackgroundColor)
                                .background(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(cardBorderColor, lineWidth: 1.2)
                        )
                        .padding(.horizontal, 20)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                animateVerse = true
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = shareImage {
                ActivityView(activityItems: [image])
            }
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
    
    private func startAIGeneration(mood: String, custom: String?) {
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
        
        animateVerse = false
        manager.generateContextVerse(mood: mood, customPrompt: custom) { result in
            switch result {
            case .success(let verse):
                DispatchQueue.main.async {
                    self.generatedVerse = verse
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.animateVerse = true
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
    
    @MainActor
    private func shareVerse(_ verse: BibleVerse) {
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        self.shareImage = image
        self.isShowingShareSheet = true
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
    
    @State private var selectedProvider: AIProvider = .gemini
    @State private var selectedLanguage: AppLanguage = .armenian
    @State private var geminiKeyInput = ""
    @State private var openaiKeyInput = ""
    @State private var anthropicKeyInput = ""
    
    @State private var selectedInterval: UpdateInterval = .everyHour
    @State private var selectedCategory: TextCategory = .both
    @State private var selectedTheme: AccentColorTheme = .indigo
    @State private var selectedWidgetLanguage: WidgetLanguage = .followApp
    
    // Переменные для уведомлений
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Выбор ИИ Провайдера
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
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                        
                        // MARK: - Выбор языка приложения (интерфейса и стихов)
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
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Выбор цветовой темы оформления
                        VStack(alignment: .leading, spacing: 10) {
                            Text("theme_section_title".localized(for: selectedLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            HStack(spacing: 16) {
                                ForEach(AccentColorTheme.allCases) { theme in
                                    // Используем ZStack с onTapGesture вместо Button для 100% стабильного срабатывания в ScrollView
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
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Поле ввода API Key в зависимости от провайдера
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
                                
                                if !manager.anthropicApiKey.isEmpty && !anthropicKeyInput.isEmpty {
                                    Text("api_key_saved".localized(for: selectedLanguage))
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Ежедневные уведомления
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
                                if newValue {
                                    manager.requestNotificationPermission { granted in
                                        if !granted {
                                            self.notificationsEnabled = false
                                        }
                                    }
                                }
                            }
                            
                            if notificationsEnabled {
                                DatePicker("notification_time_title".localized(for: selectedLanguage), selection: $notificationTime, displayedComponents: .hourAndMinute)
                                    .font(.system(size: 14))
                                    .foregroundColor(primaryTextColor)
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Частота смены стихов
                        VStack(alignment: .leading, spacing: 10) {
                            Text("update_interval_title".localized(for: selectedLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
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
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Выбор типа контента (Стихи / Молитвы / Избранное / Все)
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
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Выбор языка виджета
                        VStack(alignment: .leading, spacing: 10) {
                            Text("widget_language_title".localized(for: selectedLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            Picker("widget_language_title", selection: $selectedWidgetLanguage) {
                                ForEach(WidgetLanguage.allCases) { lang in
                                    Text(lang.localizedName(for: selectedLanguage)).tag(lang)
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
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Кнопка сохранения
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            
                            manager.setActiveProvider(selectedProvider)
                            manager.setAppLanguage(selectedLanguage)
                            manager.setAccentTheme(selectedTheme)
                            manager.setDailyNotificationsEnabled(notificationsEnabled)
                            manager.setDailyNotificationTime(notificationTime)
                            manager.setWidgetLanguage(selectedWidgetLanguage)
                            
                            // Сохраняем ключи, очищая их от лишних пробелов
                            manager.geminiApiKey = geminiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            manager.openaiApiKey = openaiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            manager.anthropicApiKey = anthropicKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            manager.setUpdateInterval(selectedInterval)
                            manager.setSelectedCategory(selectedCategory)
                            
                            // Выбираем новый оффлайн стих на выбранном языке
                            manager.selectRandomVerse()
                            
                            // Принудительно обновляем UI: BibleVerse — struct, и при смене языка
                            // stored properties не меняются, поэтому SwiftUI может "не заметить" изменение.
                            // forceRefreshUI() вызывает objectWillChange.send() для перерисовки.
                            manager.forceRefreshUI()
                            
                            // Закрываем настройки с задержкой, чтобы SwiftUI успел обработать
                            // все изменения state до начала анимации закрытия sheet
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isPresented = false
                            }
                        } label: {
                            Text("save_button".localized(for: selectedLanguage))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: selectedTheme.colorHex))
                                .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Divider()
                            .opacity(0.1)
                            .padding(.vertical, 8)
                        
                        // MARK: - О приложении
                        VStack(alignment: .leading, spacing: 12) {
                            Text("about_app_title".localized(for: selectedLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            HStack {
                                Text("about_app_version".localized(for: selectedLanguage))
                                Spacer()
                                Text("1.0.1")
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
                        }
                        .padding(18)
                        .background(aboutBlockBgColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(aboutBlockBorderColor, lineWidth: 1)
                        )
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
                selectedTheme = manager.accentTheme
                notificationsEnabled = manager.dailyNotificationsEnabled
                notificationTime = manager.dailyNotificationTime
                selectedWidgetLanguage = manager.widgetLanguage
            }
        }
        .environment(\.locale, Locale(identifier: selectedLanguage.localeCode))
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
