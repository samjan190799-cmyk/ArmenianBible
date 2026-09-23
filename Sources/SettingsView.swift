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
    
    // MARK: - Единая секция «Искусственный Интеллект»
    @ViewBuilder
    private var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            aiHeaderView
            aiProviderPillSelector
            aiCarouselView
            aiPageIndicatorDots
            aiTheologicalToneSection
            aiClearChatSection
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
    
    @ViewBuilder
    private var aiHeaderView: some View {
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
    }
    
    @ViewBuilder
    private func aiPillBackground(for provider: AIProvider, isSelected: Bool) -> some View {
        let pColor = providerAccentColor(for: provider)
        let sColor = providerSecondaryColor(for: provider)
        let unselectedFill = colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
        
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [pColor, sColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: pColor.opacity(0.35), radius: 6, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(unselectedFill)
        }
    }
    
    @ViewBuilder
    private var aiProviderPillSelector: some View {
        HStack(spacing: 6) {
            ForEach(AIProvider.allCases) { provider in
                let isSelected = selectedProvider == provider
                
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
                    .background(aiPillBackground(for: provider, isSelected: isSelected))
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
    }
    
    @ViewBuilder
    private var aiCarouselView: some View {
        TabView(selection: $selectedProvider) {
            ForEach(AIProvider.allCases) { provider in
                aiProviderCard(for: provider)
                    .tag(provider)
                    .padding(.horizontal, 4)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 255)
        .onChange(of: selectedProvider) { newProvider in
            manager.setActiveProvider(newProvider)
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    @ViewBuilder
    private var aiPageIndicatorDots: some View {
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
    
    @ViewBuilder
    private var aiTheologicalToneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cross.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                Text("ai_theological_tone_title".localized(for: selectedLanguage))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor)
            }
            
            Text("ai_theological_tone_desc".localized(for: selectedLanguage))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(AITheologicalTone.allCases) { tone in
                    aiTheologicalToneCard(for: tone)
                }
            }
        }
        .padding(.top, 6)
    }
    
    @ViewBuilder
    private func aiTheologicalToneCard(for tone: AITheologicalTone) -> some View {
        let isSelected = selectedTheologicalTone == tone
        let tColor = Color(hex: tone.colorHex)
        let strokeColor = isSelected ? tColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
        
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTheologicalTone = tone
                manager.setAITheologicalTone(tone)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? tColor : tColor.opacity(0.12))
                            .frame(width: 26, height: 26)
                        Image(systemName: tone.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isSelected ? .white : tColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tColor)
                    }
                }
                
                Text(tone.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                Text(tone.localizedDesc(for: selectedLanguage))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var aiClearChatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ai_clear_chat_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("\(manager.aiChatMessages.count) " + "ai_chat_messages_count".localized(for: selectedLanguage))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .cornerRadius(6)
                    }
                    
                    Text("ai_clear_chat_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingClearAIChatAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text("ai_clear_chat_btn".localized(for: selectedLanguage))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "EF4444").opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(manager.aiChatMessages.isEmpty)
                .opacity(manager.aiChatMessages.isEmpty ? 0.5 : 1.0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
            )
            
            if showAIChatClearedToast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "10B981"))
                        .font(.system(size: 12))
                    Text("ai_clear_chat_cleared_toast".localized(for: selectedLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 4)
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
            
            // Статус сохранения ключа и кнопка автопроверки моделей
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
                
                // Кнопка автообновления моделей (доступна для всех: Gemini, ChatGPT, Claude)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if !isKeySaved(for: provider) {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            activeKeyCheckToast = "enter_api_key_to_check".localized(for: selectedLanguage)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { activeKeyCheckToast = nil }
                        }
                        return
                    }
                    
                    isCheckingModels = true
                    Task {
                        let res = await AIModelRegistry.shared.updateModels(for: provider)
                        await MainActor.run {
                            isCheckingModels = false
                            if res.success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeKeyCheckToast = res.message.localized(for: selectedLanguage)
                                }
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeKeyCheckToast = res.message.localized(for: selectedLanguage)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation { activeKeyCheckToast = nil }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isCheckingModels {
                            ProgressView()
                                .scaleEffect(0.65)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(isCheckingModels ? "checking_models".localized(for: selectedLanguage) : "check_models".localized(for: selectedLanguage))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(pColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(pColor.opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isCheckingModels)
            }
            .padding(.top, 2)
            
            if let toast = activeKeyCheckToast {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(pColor)
                .transition(.opacity.combined(with: .scale))
            }
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
        let activeName = AIModelRegistry.shared.displayName(for: provider)
        return "⚡ \(activeName) • " + "auto_upgrade_active".localized(for: selectedLanguage)
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
    
    // MARK: - Единая секция Духовных Напоминаний
    @ViewBuilder
    private var spiritualNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("notification_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            
            Text("notification_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            VStack(spacing: 12) {
                // 1. Утренний стих дня
                notificationItemRow(
                    icon: "sun.max.fill",
                    iconColor: Color(hex: "F59E0B"),
                    title: "notification_morning_title".localized(for: selectedLanguage),
                    subtitle: "notification_morning_desc".localized(for: selectedLanguage),
                    isOn: $morningNotificationsEnabled,
                    onToggle: { newVal in
                        handleMorningToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $morningNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: morningNotificationTime) { newTime in
                        manager.setMorningNotificationTime(newTime)
                    }
                }
                
                Divider().opacity(0.3)
                
                // 2. Вечерняя молитва и покой
                notificationItemRow(
                    icon: "moon.stars.fill",
                    iconColor: Color(hex: "818CF8"),
                    title: "notification_evening_title".localized(for: selectedLanguage),
                    subtitle: "notification_evening_desc".localized(for: selectedLanguage),
                    isOn: $eveningNotificationsEnabled,
                    onToggle: { newVal in
                        handleEveningToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $eveningNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: eveningNotificationTime) { newTime in
                        manager.setEveningNotificationTime(newTime)
                    }
                }
                
                Divider().opacity(0.3)
                
                // 3. Церковные праздники и посты ААЦ
                notificationItemRow(
                    icon: "cross.fill",
                    iconColor: Color(hex: "10B981"),
                    title: "notification_church_calendar_title".localized(for: selectedLanguage),
                    subtitle: "notification_church_calendar_desc".localized(for: selectedLanguage),
                    isOn: $churchFeastsNotificationsEnabled,
                    onToggle: { newVal in
                        handleChurchFeastsToggle(newVal)
                    }
                )
                
                Divider().opacity(0.3)
                
                // 4. План чтения и стрик
                notificationItemRow(
                    icon: "flame.fill",
                    iconColor: Color(hex: "EC4899"),
                    title: "notification_reading_plan_title".localized(for: selectedLanguage),
                    subtitle: "notification_reading_plan_desc".localized(for: selectedLanguage),
                    isOn: $readingPlanNotificationsEnabled,
                    onToggle: { newVal in
                        handleReadingPlanToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $readingPlanNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: readingPlanNotificationTime) { newTime in
                        manager.setReadingPlanNotificationTime(newTime)
                    }
                }
            }
            .padding(14)
            .background(inputFieldBgColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
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
    private func notificationItemRow<PickerContent: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onToggle: @escaping (Bool) -> Void,
        @ViewBuilder picker: () -> PickerContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(hex: selectedTheme.colorHex))
                    .onChange(of: isOn.wrappedValue) { val in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        onToggle(val)
                    }
            }
            
            if isOn.wrappedValue {
                HStack {
                    Spacer()
                    picker()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn.wrappedValue)
    }
    
    @ViewBuilder
    private func notificationItemRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onToggle: @escaping (Bool) -> Void
    ) -> some View {
        notificationItemRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            isOn: isOn,
            onToggle: onToggle,
            picker: { EmptyView() }
        )
    }
    
    private func handleMorningToggle(_ newVal: Bool) {
        manager.setMorningNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.morningNotificationsEnabled = false
                    manager.setMorningNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleEveningToggle(_ newVal: Bool) {
        manager.setEveningNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.eveningNotificationsEnabled = false
                    manager.setEveningNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleChurchFeastsToggle(_ newVal: Bool) {
        manager.setChurchFeastsNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.churchFeastsNotificationsEnabled = false
                    manager.setChurchFeastsNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleReadingPlanToggle(_ newVal: Bool) {
        manager.setReadingPlanNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.readingPlanNotificationsEnabled = false
                    manager.setReadingPlanNotificationsEnabled(false)
                }
            }
        }
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
            
            // 3. Стиль оформления StandBy / Home виджетов (9 вариантов)
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
                            WidgetStyleCardButton(
                                style: style,
                                isSelected: selectedWidgetStyle == style,
                                isLocked: false,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                colorScheme: colorScheme
                            ) {
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
            
            // 4. Интерактивный Live Preview с удобным перелистыванием размеров (в стиле блоков ИИ)
            VStack(alignment: .leading, spacing: 14) {
                // Заголовок секции предпросмотра
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("standby_preview_title".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                }
                
                // Горизонтальные табы выбора размера виджета (как в блоках ИИ - можно листать)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PreviewWidgetSize.allCases) { size in
                            let isSelected = previewWidgetSize == size
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    previewWidgetSize = size
                                }
                                pickVerseForCurrentSize(size)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: size.iconName)
                                        .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    Text(size.localizedTitle(for: selectedLanguage))
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8.5)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: selectedTheme.colorHex), Color(hex: selectedTheme.secondaryColorHex)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: Color(hex: selectedTheme.colorHex).opacity(0.35), radius: 6, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(inputFieldBgColor)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(inputFieldBorderColor, lineWidth: 1)
                                                )
                                        }
                                    }
                                )
                                .foregroundColor(isSelected ? .white : primaryTextColor)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                
                // Подсказка о выбранном типе виджета + кнопка случайного стиха
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: selectedTheme.colorHex))
                            .frame(width: 6, height: 6)
                        Text(previewWidgetSize == .small ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Փոքր 2×2)" : selectedLanguage == .russian ? "Рабочий стол (Малый 2×2)" : "Home Screen (Small 2×2)") :
                             previewWidgetSize == .medium ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Միջին 4×2)" : selectedLanguage == .russian ? "Рабочий стол (Средний 4×2)" : "Home Screen (Medium 4×2)") :
                             previewWidgetSize == .large ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Մեծ 4×4)" : selectedLanguage == .russian ? "Рабочий стол (Большой 4×4)" : "Home Screen (Large 4×4)") :
                             (selectedLanguage == .armenian ? "Կողպեքի էկրան (Մոնոխրոմ)" : selectedLanguage == .russian ? "Экран блокировки (Монохром)" : "Lock Screen (Monochrome)"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        pickVerseForCurrentSize(previewWidgetSize)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 11, weight: .bold))
                            Text("button_random_verse".localized(for: selectedLanguage))
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Живое интерактивное превью в выбранном стиле оформления
                Group {
                    switch previewWidgetSize {
                    case .lockScreen:
                        LockScreenPreviewCardView(
                            verse: previewVerse,
                            language: selectedWidgetLanguage.appLanguage ?? selectedLanguage,
                            style: selectedWidgetStyle,
                            colorScheme: colorScheme,
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
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: previewWidgetSize)
                
                // Выбор категории цитат под выбранный размер виджета
                VStack(alignment: .leading, spacing: 6) {
                    switch previewWidgetSize {
                    case .small:
                        Text(selectedLanguage == .armenian ? "Գլխավոր էկրանի համարների ոճը" : selectedLanguage == .russian ? "Стиль стихов для Рабочего стола" : "Home Screen Verse Category")
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
                        
                    case .lockScreen:
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
                        
                        // Выбор шрифта для виджета Lock Screen
                        Text(selectedLanguage == .armenian ? "Ֆոնտ" : selectedLanguage == .russian ? "Шрифт виджета" : "Widget Font")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LockScreenFontDesign.allCases) { design in
                                    let isSelected = selectedLockFontDesign == design
                                    Button {
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.prepare()
                                        gen.impactOccurred()
                                        selectedLockFontDesign = design
                                        manager.setLockScreenFontDesign(design)
                                    } label: {
                                        VStack(spacing: 3) {
                                            Text(design.previewText)
                                                .font(.system(size: 13, weight: .semibold, design: design.fontDesign))
                                                .foregroundColor(isSelected ? Color(hex: selectedTheme.colorHex) : primaryTextColor)
                                            Text(design.title(for: selectedLanguage))
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(isSelected ? Color(hex: selectedTheme.colorHex) : .secondary)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isSelected
                                                    ? Color(hex: selectedTheme.colorHex).opacity(0.15)
                                                    : inputFieldBgColor)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(isSelected ? Color(hex: selectedTheme.colorHex) : inputFieldBorderColor, lineWidth: isSelected ? 1.5 : 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
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
                
                // Кнопка «Применить и обновить все виджеты» с обратной связью
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                    
                    manager.setWidgetVisualStyle(selectedWidgetStyle)
                    manager.syncLockScreenWidget()
                    WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
                    WidgetCenter.shared.reloadAllTimelines()
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isWidgetsUpdatedSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isWidgetsUpdatedSuccess = false
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isWidgetsUpdatedSuccess ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 14.5, weight: .bold))
                        Text(isWidgetsUpdatedSuccess ?
                             (selectedLanguage == .armenian ? "✓ Բոլոր վիջեթները թարմացված են" :
                              selectedLanguage == .russian ? "✓ Все виджеты успешно обновлены" :
                              "✓ All Widgets Updated Successfully") :
                             "update_widgets_now_button".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        isWidgetsUpdatedSuccess ?
                            LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "059669")], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color(hex: selectedTheme.colorHex), Color(hex: selectedTheme.secondaryColorHex)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(13)
                    .shadow(color: (isWidgetsUpdatedSuccess ? Color(hex: "10B981") : Color(hex: selectedTheme.colorHex)).opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
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
    
    // MARK: - Секция «Викторина и Обучение»
    @ViewBuilder
    private var quizSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("quiz_settings_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Text("quiz_settings_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. Количество вопросов по умолчанию
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .font(.system(size: 14))
                        Text("quiz_default_count_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach([5, 10, 15, 20], id: \.self) { count in
                            let isSelected = quizDefaultCount == count
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    quizDefaultCount = count
                                    manager.setQuizDefaultQuestionCount(count)
                                }
                            } label: {
                                Text("\(count)")
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? Color(hex: selectedTheme.colorHex) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 2. Таймер на ответ
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.system(size: 14))
                        Text("quiz_timer_setting_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        let timerOptions: [(Int, String)] = [
                            (0, "quiz_timer_none".localized(for: selectedLanguage)),
                            (15, "quiz_timer_15s".localized(for: selectedLanguage)),
                            (30, "quiz_timer_30s".localized(for: selectedLanguage))
                        ]
                        
                        ForEach(timerOptions, id: \.0) { option in
                            let isSelected = quizTimerDuration == option.0
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    quizTimerDuration = option.0
                                    manager.setQuizTimerDuration(option.0)
                                }
                            } label: {
                                Text(option.1)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? Color(hex: "F59E0B") : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 3. Звуковые эффекты
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "10B981").opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("quiz_sound_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text("quiz_sound_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $quizSoundEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: quizSoundEnabled) { newVal in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            manager.setQuizSoundEffectsEnabled(newVal)
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 4. Сброс статистики викторины
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "EF4444").opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("quiz_reset_stats_title".localized(for: selectedLanguage))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                            Text("quiz_reset_stats_desc".localized(for: selectedLanguage))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            isShowingResetQuizAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("quiz_reset_stats_btn".localized(for: selectedLanguage))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    if showQuizResetToast {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "10B981"))
                                .font(.system(size: 12))
                            Text("quiz_stats_reset_toast".localized(for: selectedLanguage))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "10B981"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Секция «Аудиоплеер Нарекаци»
    @ViewBuilder
    private var narekAudioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("narek_audio_settings_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                if narekPlayer.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "10B981"))
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "10B981").opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            Text("narek_audio_settings_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. Скорость воспроизведения
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .font(.system(size: 14))
                        Text("narek_playback_rate_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    Text("narek_playback_rate_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        let rateOptions: [(Double, String)] = [
                            (0.8, "narek_playback_rate_08".localized(for: selectedLanguage)),
                            (1.0, "narek_playback_rate_10".localized(for: selectedLanguage)),
                            (1.25, "narek_playback_rate_125".localized(for: selectedLanguage))
                        ]
                        
                        ForEach(rateOptions, id: \.0) { option in
                            let isSelected = narekPlayer.playbackRate == option.0
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    narekPlayer.setPlaybackRate(option.0)
                                }
                            } label: {
                                Text(option.1)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? Color(hex: selectedTheme.colorHex) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 2. Таймер сна
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.system(size: 14))
                        Text("narek_sleep_timer_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                        
                        if narekPlayer.sleepTimerRemainingSeconds > 0 {
                            let mins = narekPlayer.sleepTimerRemainingSeconds / 60
                            let secs = narekPlayer.sleepTimerRemainingSeconds % 60
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "F59E0B"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "F59E0B").opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("narek_sleep_timer_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(NarekSleepTimerOption.allCases) { option in
                                let isSelected = narekPlayer.sleepTimerOption == option
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        narekPlayer.setSleepTimer(option)
                                    }
                                } label: {
                                    Text(option.title(for: selectedLanguage))
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : primaryTextColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isSelected ? Color(hex: "F59E0B") : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 3. Автопереход к следующей главе
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "repeat")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("narek_autoplay_next_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text("narek_autoplay_next_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { narekPlayer.autoPlayNextChapter },
                        set: { newVal in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            narekPlayer.setAutoPlayNextChapter(newVal)
                        }
                    ))
                    .labelsHidden()
                    .tint(Color(hex: selectedTheme.colorHex))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Секция: Система и данные (Haptics, Face ID, Cache, Backup)
    @ViewBuilder
    private var systemAndDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Шапка секции
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("system_storage_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
            }
            
            Text("system_storage_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            VStack(spacing: 12) {
                // 1. Тактильный отклик (Haptic Feedback)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "3B82F6").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("haptics_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("haptics_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isHapticsEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: isHapticsEnabled) { newVal in
                            manager.setHapticsEnabled(newVal)
                            if newVal {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                            }
                        }
                }
                
                Divider().opacity(0.3)
                
                // 2. Блокировка Face ID / Touch ID
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "10B981").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("biometric_lock_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("biometric_lock_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isBiometricLockEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: isBiometricLockEnabled) { newVal in
                            manager.setBiometricLockEnabled(newVal) { success in
                                if !success {
                                    self.isBiometricLockEnabled = manager.isBiometricLockEnabled
                                }
                            }
                        }
                }
                
                Divider().opacity(0.3)
                
                // 3. Очистка кэша
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "EF4444").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("cache_clear_title".localized(for: selectedLanguage))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                            
                            // Бейдж размера кэша
                            Text(cacheSizeDisplay)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(inputFieldBgColor)
                                .cornerRadius(6)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("cache_clear_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        isClearingCache = true
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        
                        _ = manager.clearAppCache()
                        cacheSizeDisplay = manager.calculateCacheSize()
                        isClearingCache = false
                        withAnimation {
                            showCacheClearedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showCacheClearedToast = false
                            }
                        }
                    } label: {
                        Text("cache_clear_btn".localized(for: selectedLanguage))
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                if showCacheClearedToast {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                            .font(.system(size: 12))
                        Text("cache_cleared_toast".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Divider().opacity(0.3)
                
                // 4. Резервное копирование и экспорт
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("export_backup_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("export_backup_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        
                        if let url = manager.generateBackupArchive() {
                            self.backupShareUrl = url
                            self.isShowingShareSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .padding(8)
                            .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(14)
            .background(inputFieldBgColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
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
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.4")
                    .foregroundColor(.secondary)
                
                Button {
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.prepare(); g.impactOccurred()
                    AppUpdateManager.shared.checkForUpdates(language: selectedLanguage)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                        .padding(4)
                }
                .buttonStyle(ScaleButtonStyle())
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
            
            // ─── Кнопка "Оценить Luys в App Store" ───────────────────────
            Button {
                let g = UINotificationFeedbackGenerator()
                g.prepare(); g.notificationOccurred(.success)
                ReviewManager.shared.openAppStoreReviewDirectly()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text({
                        switch selectedLanguage {
                        case .armenian: return "Գնահատել Luys-ը App Store-ում ⭐⭐⭐⭐⭐"
                        case .russian:  return "Оценить Luys в App Store ⭐⭐⭐⭐⭐"
                        case .english:  return "Rate Luys on App Store ⭐⭐⭐⭐⭐"
                        }
                    }())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color(hex: "F59E0B").opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "F59E0B").opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
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
