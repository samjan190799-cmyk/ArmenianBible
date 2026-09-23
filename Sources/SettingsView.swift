import SwiftUI
import WidgetKit
import LocalAuthentication

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
    @State private var isCheckingModels = false
    @State private var activeKeyCheckToast: String? = nil
    
    @State private var selectedInterval: UpdateInterval = .everyHour
    @State private var selectedCategory: TextCategory = .both
    @State private var selectedScope: VerseSourceScope = .allBible
    @State private var selectedTheme: AccentColorTheme = .indigo
    @State private var selectedAppearanceMode: AppAppearanceMode = .system
    @State private var selectedWidgetLanguage: WidgetLanguage = .followApp
    @State private var selectedWidgetStyle: WidgetVisualStyle = .oledStandby
    @State private var selectedLockCategory: LockScreenCategory = .pearls
    @State private var selectedLockFontDesign: LockScreenFontDesign = .serif
    @State private var selectedMediumCategory: HomeWidgetCategory = .all
    @State private var selectedLargeCategory: HomeWidgetCategory = .all
    @State private var selectedArmenianEdition: ArmenianBibleEdition = .ararat
    @State private var previewWidgetSize: PreviewWidgetSize = .small
    @State private var previewVerse: BibleVerse = BibleVerse.lockScreenPearls[0]
    
    // Переменные для духовных уведомлений
    @State private var morningNotificationsEnabled = false
    @State private var morningNotificationTime = Date()
    @State private var eveningNotificationsEnabled = false
    @State private var eveningNotificationTime = Date()
    @State private var churchFeastsNotificationsEnabled = false
    @State private var readingPlanNotificationsEnabled = false
    @State private var readingPlanNotificationTime = Date()
    
    // Системные настройки и данные (Haptics, Face ID, Cache, Backup)
    @State private var isHapticsEnabled = true
    @State private var isBiometricLockEnabled = false
    @State private var cacheSizeDisplay = "0 KB"
    @State private var isClearingCache = false
    @State private var showCacheClearedToast = false
    @State private var backupShareUrl: URL? = nil
    @State private var isShowingShareSheet = false
    
    // Настройки ИИ (Тон толкования и очистка истории)
    @State private var selectedTheologicalTone: AITheologicalTone = .patristic
    @State private var isShowingClearAIChatAlert = false
    @State private var showAIChatClearedToast = false
    
    // Настройки Викторины (Количество, Таймер, Звук, Сброс)
    @State private var quizDefaultCount: Int = 10
    @State private var quizTimerDuration: Int = 0
    @State private var quizSoundEnabled: Bool = true
    @State private var isShowingResetQuizAlert = false
    @State private var showQuizResetToast = false
    
    // Настройки Аудиоплеера Нарекаци (Пункт 2)
    @ObservedObject private var narekPlayer = NarekAudioPlayer.shared
    
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
    @State private var isWidgetsUpdatedSuccess = false

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
                        spiritualNotificationsSection
                        widgetsUnifiedSection
                        updateIntervalSection
                        verseSourceScopeSection
                        contentTypeSection
                        autoWallpaperSection
                        aiAssistantSection
                        quizSettingsSection
                        narekAudioSection
                        systemAndDataSection
                        aboutSection
                        
                        // MARK: - Баннерная Реклама в Настройках
                        LuysHybridBannerView(placement: .settings)
                            .padding(.top, 4)
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
                morningNotificationsEnabled = manager.morningNotificationsEnabled
                morningNotificationTime = manager.morningNotificationTime
                eveningNotificationsEnabled = manager.eveningNotificationsEnabled
                eveningNotificationTime = manager.eveningNotificationTime
                churchFeastsNotificationsEnabled = manager.churchFeastsNotificationsEnabled
                readingPlanNotificationsEnabled = manager.readingPlanNotificationsEnabled
                readingPlanNotificationTime = manager.readingPlanNotificationTime
                selectedWidgetLanguage = manager.widgetLanguage
                selectedWidgetStyle = manager.widgetVisualStyle
                selectedLockCategory = manager.lockScreenCategory
                selectedLockFontDesign = manager.lockScreenFontDesign
                selectedMediumCategory = manager.mediumWidgetCategory
                selectedLargeCategory = manager.largeWidgetCategory
                selectedArmenianEdition = manager.armenianEdition
                isHapticsEnabled = manager.isHapticsEnabled
                isBiometricLockEnabled = manager.isBiometricLockEnabled
                cacheSizeDisplay = manager.calculateCacheSize()
                selectedTheologicalTone = manager.aiTheologicalTone
                quizDefaultCount = manager.quizDefaultQuestionCount
                quizTimerDuration = manager.quizTimerDuration
                quizSoundEnabled = manager.quizSoundEffectsEnabled
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
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = backupShareUrl {
                    ActivityView(activityItems: [url])
                }
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
            .alert("ai_clear_chat_confirm_title".localized(for: selectedLanguage), isPresented: $isShowingClearAIChatAlert) {
                Button("ai_clear_chat_btn".localized(for: selectedLanguage), role: .destructive) {
                    manager.clearAIChat()
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                    withAnimation {
                        showAIChatClearedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showAIChatClearedToast = false
                        }
                    }
                }
                Button("cancel_button".localized(for: selectedLanguage), role: .cancel) {}
            } message: {
                Text("ai_clear_chat_confirm_msg".localized(for: selectedLanguage))
            }
            .alert("quiz_reset_confirm_title".localized(for: selectedLanguage), isPresented: $isShowingResetQuizAlert) {
                Button("quiz_reset_stats_btn".localized(for: selectedLanguage), role: .destructive) {
                    manager.resetQuizFullStats()
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                    withAnimation {
                        showQuizResetToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showQuizResetToast = false
                        }
                    }
                }
                Button("cancel_button".localized(for: selectedLanguage), role: .cancel) {}
            } message: {
                Text("quiz_reset_confirm_msg".localized(for: selectedLanguage))
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
                            
                            _ = withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
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
    
}
