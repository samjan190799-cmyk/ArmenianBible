import SwiftUI
import WidgetKit
import Foundation
import UserNotifications
import LocalAuthentication

// MARK: - Менеджер стихов (Bible Manager)
class BibleManager: ObservableObject {
    static let shared = BibleManager()
    
    @Published var currentVerse: BibleVerse
    @Published var isGeneratingAI = false
    @Published var isGeneratingText: Bool = false
    @Published var updateInterval: UpdateInterval = .everyHour
    @Published var selectedCategory: TextCategory = .both
    @Published var activeProvider: AIProvider = .gemini
    @Published var appLanguage: AppLanguage = .armenian
    @Published var favoriteVerses: [FavoriteItem] = []
    @Published var appearanceMode: AppAppearanceMode = .system
    @Published var accentTheme: AccentColorTheme = .indigo
    @Published var dailyNotificationsEnabled: Bool = false
    @Published var dailyNotificationTime: Date = Date()
    
    // Духовные уведомления нового поколения
    @Published var morningNotificationsEnabled: Bool = false
    @Published var morningNotificationTime: Date = Date()
    @Published var eveningNotificationsEnabled: Bool = false
    @Published var eveningNotificationTime: Date = Date()
    @Published var churchFeastsNotificationsEnabled: Bool = false
    @Published var readingPlanNotificationsEnabled: Bool = false
    @Published var readingPlanNotificationTime: Date = Date()
    @Published var widgetLanguage: WidgetLanguage = .followApp
    @Published var widgetVisualStyle: WidgetVisualStyle = .oledStandby
    @Published var verseSourceScope: VerseSourceScope = .allBible
    
    // Системные настройки и безопасность (Пункт 6)
    @Published var isHapticsEnabled: Bool = true
    @Published var isBiometricLockEnabled: Bool = false
    @Published var isAppUnlocked: Bool = true
    @Published var cachedStorageSize: String = "0 KB"
    
    // Переменные для полной Библии и Deep Link
    @Published var bibleFontSize: Double = 18.0
    @Published var activeTabSelection: Int = 0
    @Published var selectedReaderSection: Int = 0 // 0: Библия, 1: Нарекаци
    @Published var quizBestScore: Int = 0
    @Published var highlightedVerses: [String: String] = [:]
    @Published var annotations: [String: VerseAnnotation] = [:]
    @Published var isPrayerCompletedToday: Bool = false
    @Published var armenianEdition: ArmenianBibleEdition = .ararat
    
    // Глубокие ссылки для чтения Библии
    @Published var deepLinkBookId: Int? = nil
    @Published var deepLinkChapter: Int? = nil
    @Published var deepLinkVerse: Int? = nil
    @Published var lastReadBookId: Int? = nil
    @Published var lastReadChapter: Int? = nil
    @Published var readChaptersByBook: [Int: Set<Int>] = [:]
    private let readChaptersKey = "bible_read_chapters_by_book"
    
    // MARK: - История сообщений чата Духовного Помощника
    @Published var aiChatMessages: [AIChatMessage] = []
    private let aiChatMessagesKey = "ai_spiritual_chat_messages"
    
    func addAIChatMessage(_ message: AIChatMessage) {
        aiChatMessages.append(message)
        saveAIChat()
    }
    
    func clearAIChat() {
        aiChatMessages.removeAll()
        UserDefaults.standard.removeObject(forKey: aiChatMessagesKey)
    }
    
    private func saveAIChat() {
        if let data = try? JSONEncoder().encode(aiChatMessages) {
            UserDefaults.standard.set(data, forKey: aiChatMessagesKey)
        }
    }
    
    private func loadAIChat() {
        if let data = UserDefaults.standard.data(forKey: aiChatMessagesKey),
           let messages = try? JSONDecoder().decode([AIChatMessage].self, from: data) {
            self.aiChatMessages = messages
        }
    }
    
    func openNarekatsi() {
        self.selectedReaderSection = 1
        self.activeTabSelection = 3
    }
    
    func openBibleReader() {
        self.selectedReaderSection = 0
        self.activeTabSelection = 3
    }
    
    // Идентификатор App Group для совместного доступа к данным между приложением и виджетом
    private let appGroupSuiteName = AppGroupConstants.activeSuiteName
    
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    private let apiKeyStoreKey = "gemini_api_key_secure"
    private let openaiApiKeyStoreKey = "openai_api_key_secure"
    private let anthropicApiKeyStoreKey = "anthropic_api_key_secure"
    private let updateIntervalKey = "widgetUpdateInterval"
    private let categoryKey = "selectedCategory"
    private let activeProviderKey = "active_ai_provider"
    private let appLanguageKey = "app_language"
    private let favoritesKey = "favorite_verses"
    private let verseSourceScopeKey = "verse_source_scope"
    private let appearanceModeKey = "app_appearance_mode"
    private let accentThemeKey = "accent_theme"
    private let notificationsEnabledKey = "daily_notifications_enabled"
    private let notificationTimeKey = "daily_notification_time"
    private let morningNotificationsEnabledKey = "morning_notifications_enabled"
    private let morningNotificationTimeKey = "morning_notification_time"
    private let eveningNotificationsEnabledKey = "evening_notifications_enabled"
    private let eveningNotificationTimeKey = "evening_notification_time"
    private let churchFeastsNotificationsEnabledKey = "church_feasts_notifications_enabled"
    private let readingPlanNotificationsEnabledKey = "reading_plan_notifications_enabled"
    private let readingPlanNotificationTimeKey = "reading_plan_notification_time"
    private let hapticsEnabledKey = "haptics_enabled"
    private let biometricLockEnabledKey = "biometric_lock_enabled"
    private let aiTheologicalToneKey = "ai_theological_tone"
    private let quizDefaultQuestionCountKey = "quiz_default_question_count"
    private let quizTimerDurationKey = "quiz_timer_duration"
    private let quizSoundEffectsEnabledKey = "quiz_sound_effects_enabled"
    private let lockScreenCategoryKey = "lock_screen_category"
    private let mediumWidgetCategoryKey = "medium_widget_category"
    private let largeWidgetCategoryKey = "large_widget_category"
    private let widgetVisualStyleKey = "widget_visual_style"
    private let lockScreenFontDesignKey = "lock_screen_font_design"
    
    @Published var aiTheologicalTone: AITheologicalTone = .patristic
    @Published var quizDefaultQuestionCount: Int = 10
    @Published var quizTimerDuration: Int = 0
    @Published var quizSoundEffectsEnabled: Bool = true
    @Published var lockScreenCategory: LockScreenCategory = .pearls
    @Published var lockScreenFontDesign: LockScreenFontDesign = .serif
    @Published var mediumWidgetCategory: HomeWidgetCategory = .all
    @Published var largeWidgetCategory: HomeWidgetCategory = .all
    
    private var sharedDefaults: UserDefaults? {
        AppGroupConstants.sharedDefaults
    }
    
    // Свойство для получения и сохранения API-ключа Gemini
    var geminiApiKey: String {
        get {
            UserDefaults.standard.string(forKey: apiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyStoreKey)
            objectWillChange.send()
        }
    }
    
    // Свойство для получения и сохранения API-ключа OpenAI (ChatGPT)
    var openaiApiKey: String {
        get {
            UserDefaults.standard.string(forKey: openaiApiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: openaiApiKeyStoreKey)
            objectWillChange.send()
        }
    }
    
    // Свойство для получения и сохранения API-ключа Anthropic (Claude)
    var anthropicApiKey: String {
        get {
            UserDefaults.standard.string(forKey: anthropicApiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: anthropicApiKeyStoreKey)
            objectWillChange.send()
        }
    }
    
    private init() {
        // Подключаем провайдер поиска текстов стихов из базы данных SQLite
        BibleVerse.textLookupProvider = { ref in
            BibleDatabase.shared.lookupVerseTexts(referenceHy: ref)
        }
        
        // Попытка загрузить сохраненный стих из общей памяти App Group
        if let defaults = UserDefaults(suiteName: appGroupSuiteName) {
            if let savedIdString = defaults.string(forKey: "currentVerseId"),
               let savedId = UUID(uuidString: savedIdString),
               let foundVerse = BibleVerse.database.first(where: { $0.id == savedId }) {
                self.currentVerse = foundVerse
            } else if let savedText = defaults.string(forKey: textKey),
                      let savedRef = defaults.string(forKey: referenceKey) {
                if let foundVerse = BibleVerse.database.first(where: {
                    $0.textHy == savedText || $0.textRu == savedText || $0.textEn == savedText
                }) {
                    self.currentVerse = foundVerse
                } else {
                    self.currentVerse = BibleVerse(text: savedText, reference: savedRef)
                }
            } else {
                let defaultVerse = BibleVerse.database[0]
                self.currentVerse = defaultVerse
                defaults.set(defaultVerse.id.uuidString, forKey: "currentVerseId")
                defaults.set(defaultVerse.text, forKey: textKey)
                defaults.set(defaultVerse.reference, forKey: referenceKey)
            }
        } else {
            self.currentVerse = BibleVerse.database[0]
        }
        
        // Загрузка интервала обновления
        if let defaults = sharedDefaults,
           let savedIntervalRaw = defaults.string(forKey: updateIntervalKey),
           let savedInterval = UpdateInterval(rawValue: savedIntervalRaw) {
            self.updateInterval = savedInterval
        } else {
            self.updateInterval = .everyHour
        }
        
        // Загрузка категории отображаемого текста
        if let defaults = sharedDefaults,
           let savedCategoryRaw = defaults.string(forKey: categoryKey),
           let savedCategory = TextCategory(rawValue: savedCategoryRaw) {
            self.selectedCategory = savedCategory
        } else {
            self.selectedCategory = .both
        }
        
        // Загрузка активного провайдера ИИ
        if let defaults = sharedDefaults,
           let savedProviderRaw = defaults.string(forKey: activeProviderKey),
           let savedProvider = AIProvider(rawValue: savedProviderRaw) {
            self.activeProvider = savedProvider
        } else {
            self.activeProvider = .gemini
        }
        
        // Загрузка языка приложения
        if let defaults = sharedDefaults {
            if let savedLanguageRaw = defaults.string(forKey: appLanguageKey),
               let savedLanguage = AppLanguage(rawValue: savedLanguageRaw) {
                self.appLanguage = savedLanguage
            } else {
                self.appLanguage = .armenian
                AppGroupConstants.syncToAll { defs in
                    defs.set(AppLanguage.armenian.rawValue, forKey: appLanguageKey)
                }
            }
        } else {
            self.appLanguage = .armenian
        }
        
        // Загрузка Избранного
        if let defaults = sharedDefaults,
           let savedFavoritesData = defaults.data(forKey: favoritesKey) {
            if let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData) {
                self.favoriteVerses = decoded
            } else if let decodedOld = try? JSONDecoder().decode([BibleVerse].self, from: savedFavoritesData) {
                // Конвертируем старый формат в новый
                self.favoriteVerses = decodedOld.map { verse in
                    FavoriteItem(
                        id: verse.id,
                        isDailyVerse: true,
                        bookId: nil,
                        chapter: nil,
                        verseNumber: nil,
                        textHy: verse.textHy,
                        textRu: verse.textRu,
                        textEn: verse.textEn,
                        refHy: verse.refHy,
                        refRu: verse.refRu,
                        refEn: verse.refEn
                    )
                }
            }
        }
        
        // Загрузка размера шрифта Библии
        if let defaults = sharedDefaults {
            let savedFontSize = defaults.double(forKey: "bible_font_size")
            self.bibleFontSize = savedFontSize > 0 ? savedFontSize : 18.0
        } else {
            self.bibleFontSize = 18.0
        }
        
        // Загрузка рекорда викторины и цветных маркеров
        if let defaults = sharedDefaults {
            self.quizBestScore = defaults.integer(forKey: "quiz_best_score")
            if let savedHighlights = defaults.dictionary(forKey: "highlighted_verses_map") as? [String: String] {
                self.highlightedVerses = savedHighlights
            }
            if let savedAnnotationsData = defaults.data(forKey: "verse_annotations_map"),
               let decoded = try? JSONDecoder().decode([String: VerseAnnotation].self, from: savedAnnotationsData) {
                self.annotations = decoded
            }
            let savedEdRaw = defaults.string(forKey: "armenian_bible_edition") ?? UserDefaults.standard.string(forKey: "armenian_bible_edition")
            if let savedEdRaw,
               let ed = ArmenianBibleEdition(rawValue: savedEdRaw) {
                self.armenianEdition = ed
            }
            if let savedScopeRaw = defaults.string(forKey: verseSourceScopeKey),
               let savedScope = VerseSourceScope(rawValue: savedScopeRaw) {
                self.verseSourceScope = savedScope
            } else {
                self.verseSourceScope = .allBible
            }
        }
        
        // Проверка статуса молитвы дня
        checkPrayerCompletionStatus()
        
        // Загрузка темы оформления (System / Light / Dark)
        if let defaults = sharedDefaults,
           let savedModeRaw = defaults.string(forKey: appearanceModeKey),
           let savedMode = AppAppearanceMode(rawValue: savedModeRaw) {
            self.appearanceMode = savedMode
        } else {
            self.appearanceMode = .system
        }
        
        // Загрузка Цветовой темы
        if let defaults = sharedDefaults,
           let savedThemeRaw = defaults.string(forKey: accentThemeKey),
           let savedTheme = AccentColorTheme(rawValue: savedThemeRaw) {
            self.accentTheme = savedTheme
        } else {
            self.accentTheme = .indigo
        }
        
        // Загрузка визуального стиля виджетов и StandBy (отказоустойчивый опрос всех хранилищ)
        self.widgetVisualStyle = AppGroupConstants.sharedVisualStyle()
        
        // Загрузка шрифта виджета Lock Screen
        self.lockScreenFontDesign = AppGroupConstants.sharedLockScreenFontDesign()
        
        // Загрузка Уведомлений
        let notifDefaults = sharedDefaults ?? UserDefaults.standard
        let hasMorningKey = notifDefaults.object(forKey: morningNotificationsEnabledKey) != nil
        if hasMorningKey {
            self.morningNotificationsEnabled = notifDefaults.bool(forKey: morningNotificationsEnabledKey)
        } else {
            self.morningNotificationsEnabled = notifDefaults.bool(forKey: notificationsEnabledKey)
        }
        
        if let savedMorning = notifDefaults.object(forKey: morningNotificationTimeKey) as? Date {
            self.morningNotificationTime = savedMorning
        } else if let savedLegacy = notifDefaults.object(forKey: notificationTimeKey) as? Date {
            self.morningNotificationTime = savedLegacy
        } else {
            var comp = DateComponents()
            comp.hour = 8
            comp.minute = 30
            self.morningNotificationTime = Calendar.current.date(from: comp) ?? Date()
        }
        
        self.dailyNotificationsEnabled = self.morningNotificationsEnabled
        self.dailyNotificationTime = self.morningNotificationTime
        
        self.eveningNotificationsEnabled = notifDefaults.bool(forKey: eveningNotificationsEnabledKey)
        if let savedEvening = notifDefaults.object(forKey: eveningNotificationTimeKey) as? Date {
            self.eveningNotificationTime = savedEvening
        } else {
            var comp = DateComponents()
            comp.hour = 21
            comp.minute = 30
            self.eveningNotificationTime = Calendar.current.date(from: comp) ?? Date()
        }
        
        self.churchFeastsNotificationsEnabled = notifDefaults.bool(forKey: churchFeastsNotificationsEnabledKey)
        
        self.readingPlanNotificationsEnabled = notifDefaults.bool(forKey: readingPlanNotificationsEnabledKey)
        if let savedPlanTime = notifDefaults.object(forKey: readingPlanNotificationTimeKey) as? Date {
            self.readingPlanNotificationTime = savedPlanTime
        } else {
            var comp = DateComponents()
            comp.hour = 20
            comp.minute = 30
            self.readingPlanNotificationTime = Calendar.current.date(from: comp) ?? Date()
        }
        
        // Загрузка тактильного отклика и биометрии
        if notifDefaults.object(forKey: hapticsEnabledKey) != nil {
            self.isHapticsEnabled = notifDefaults.bool(forKey: hapticsEnabledKey)
        } else {
            self.isHapticsEnabled = true
        }
        
        self.isBiometricLockEnabled = notifDefaults.bool(forKey: biometricLockEnabledKey)
        self.isAppUnlocked = !self.isBiometricLockEnabled
        self.cachedStorageSize = calculateCacheSize()
        
        // Загрузка тона ИИ
        if let savedToneRaw = notifDefaults.string(forKey: aiTheologicalToneKey),
           let savedTone = AITheologicalTone(rawValue: savedToneRaw) {
            self.aiTheologicalTone = savedTone
        } else {
            self.aiTheologicalTone = .patristic
        }
        
        // Загрузка настроек викторины
        let savedQuizCount = notifDefaults.integer(forKey: quizDefaultQuestionCountKey)
        self.quizDefaultQuestionCount = savedQuizCount > 0 ? savedQuizCount : 10
        self.quizTimerDuration = notifDefaults.integer(forKey: quizTimerDurationKey)
        if notifDefaults.object(forKey: quizSoundEffectsEnabledKey) != nil {
            self.quizSoundEffectsEnabled = notifDefaults.bool(forKey: quizSoundEffectsEnabledKey)
        } else {
            self.quizSoundEffectsEnabled = true
        }
        
        // Загрузка языка виджета
        if let defaults = sharedDefaults,
           let savedWidgetLangRaw = defaults.string(forKey: "widget_language"),
           let savedWidgetLang = WidgetLanguage(rawValue: savedWidgetLangRaw) {
            self.widgetLanguage = savedWidgetLang
        } else {
            self.widgetLanguage = .followApp
        }
        
        // Загрузка категории для экрана блокировки
        if let defaults = sharedDefaults,
           let savedLockCatRaw = defaults.string(forKey: lockScreenCategoryKey),
           let savedLockCat = LockScreenCategory(rawValue: savedLockCatRaw) {
            self.lockScreenCategory = savedLockCat
        } else {
            self.lockScreenCategory = .pearls
        }
        
        // Загрузка категорий для среднего и большого виджетов
        if let defaults = sharedDefaults {
            if let savedMedRaw = defaults.string(forKey: mediumWidgetCategoryKey),
               let savedMed = HomeWidgetCategory(rawValue: savedMedRaw) {
                self.mediumWidgetCategory = savedMed
            } else {
                self.mediumWidgetCategory = .all
            }
            if let savedLargeRaw = defaults.string(forKey: largeWidgetCategoryKey),
               let savedLarge = HomeWidgetCategory(rawValue: savedLargeRaw) {
                self.largeWidgetCategory = savedLarge
            } else {
                self.largeWidgetCategory = .all
            }
        }
        
        // Загрузка последнего места чтения
        if let defaults = sharedDefaults {
            let savedBookId = defaults.integer(forKey: "last_read_book_id")
            let savedChapter = defaults.integer(forKey: "last_read_chapter")
            if savedBookId != 0 && savedChapter != 0 {
                self.lastReadBookId = savedBookId
                self.lastReadChapter = savedChapter
            }
            
            // Загрузка прочитанных глав Библии
            if let savedDict = defaults.dictionary(forKey: readChaptersKey) as? [String: [Int]] {
                var loaded: [Int: Set<Int>] = [:]
                for (key, values) in savedDict {
                    if let bookId = Int(key) {
                        loaded[bookId] = Set(values)
                    }
                }
                self.readChaptersByBook = loaded
            }
            
            // Гарантируем первоначальную инициализацию короткого стиха для экрана блокировки, если еще не настроен
            if defaults.string(forKey: "currentLockScreenVerseId") == nil {
                syncLockScreenWidget()
            }
        }
        
        // Загрузка сохраненной истории чата духовного помощника
        loadAIChat()
        
        // Гарантируем, что текущий стих дня полностью обогащен обоими армянскими переводами из базы SQLite
        self.currentVerse = BibleDatabase.shared.enrichVerse(self.currentVerse)
    }
    
    // MARK: - Сохранение последней позиции чтения и отметка главы как прочитанной
    func saveLastReadLocation(bookId: Int, chapter: Int) {
        if lastReadBookId != bookId || lastReadChapter != chapter {
            lastReadBookId = bookId
            lastReadChapter = chapter
            
            if let defaults = sharedDefaults {
                defaults.set(bookId, forKey: "last_read_book_id")
                defaults.set(chapter, forKey: "last_read_chapter")
                defaults.set(chapter, forKey: "last_read_chapter_for_book_\(bookId)")
                defaults.synchronize()
            }
        }
        markChapterAsRead(bookId: bookId, chapter: chapter)
    }
    
    // MARK: - Учет прогресса чтения Библии
    func markChapterAsRead(bookId: Int, chapter: Int) {
        var currentSet = readChaptersByBook[bookId] ?? []
        if !currentSet.contains(chapter) {
            currentSet.insert(chapter)
            readChaptersByBook[bookId] = currentSet
            persistReadChapters()
        }
    }
    
    func isChapterRead(bookId: Int, chapter: Int) -> Bool {
        return readChaptersByBook[bookId]?.contains(chapter) ?? false
    }
    
    func toggleChapterRead(bookId: Int, chapter: Int) {
        var currentSet = readChaptersByBook[bookId] ?? []
        if currentSet.contains(chapter) {
            currentSet.remove(chapter)
        } else {
            currentSet.insert(chapter)
        }
        readChaptersByBook[bookId] = currentSet
        persistReadChapters()
    }
    
    func getBookProgress(bookId: Int, totalChapters: Int) -> (readCount: Int, percent: Double) {
        let count = readChaptersByBook[bookId]?.count ?? 0
        let percent = totalChapters > 0 ? min(1.0, Double(count) / Double(totalChapters)) : 0.0
        return (count, percent)
    }
    
    private func persistReadChapters() {
        var saveDict: [String: [Int]] = [:]
        for (bookId, set) in readChaptersByBook {
            saveDict[String(bookId)] = Array(set).sorted()
        }
        AppGroupConstants.syncToAll { defaults in
            defaults.set(saveDict, forKey: readChaptersKey)
        }
    }
    
    // MARK: - Сохранение и получение позиции чтения для конкретной книги
    func saveBookLastReadChapter(bookId: Int, chapter: Int) {
        AppGroupConstants.syncToAll { defaults in
            defaults.set(chapter, forKey: "last_read_chapter_for_book_\(bookId)")
        }
    }
    
    func getBookLastReadChapter(bookId: Int) -> Int {
        let chapter = AppGroupConstants.sharedDefaults.integer(forKey: "last_read_chapter_for_book_\(bookId)")
        return chapter > 0 ? chapter : 1
    }
    
    // MARK: - Сохранение активного провайдера ИИ
    func setActiveProvider(_ provider: AIProvider) {
        self.activeProvider = provider
        AppGroupConstants.syncToAll { defaults in
            defaults.set(provider.rawValue, forKey: activeProviderKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение языка приложения
    func setAppLanguage(_ language: AppLanguage) {
        self.appLanguage = language
        AppGroupConstants.syncToAll { defaults in
            defaults.set(language.rawValue, forKey: appLanguageKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение языка виджета
    func setWidgetLanguage(_ language: WidgetLanguage) {
        self.widgetLanguage = language
        AppGroupConstants.syncToAll { defaults in
            defaults.set(language.rawValue, forKey: "widget_language")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение категории для экрана блокировки
    func setLockScreenCategory(_ category: LockScreenCategory) {
        self.lockScreenCategory = category
        AppGroupConstants.syncToAll { defaults in
            defaults.set(category.rawValue, forKey: lockScreenCategoryKey)
        }
        syncLockScreenWidget()
    }
    
    // MARK: - Сохранение шрифта виджета экрана блокировки
    func setLockScreenFontDesign(_ design: LockScreenFontDesign) {
        self.lockScreenFontDesign = design
        AppGroupConstants.syncToAll { defaults in
            defaults.set(design.rawValue, forKey: lockScreenFontDesignKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение категории для среднего виджета (4x2)
    func setMediumWidgetCategory(_ category: HomeWidgetCategory) {
        self.mediumWidgetCategory = category
        AppGroupConstants.syncToAll { defaults in
            defaults.set(category.rawValue, forKey: mediumWidgetCategoryKey)
        }
        syncLockScreenWidget()
    }
    
    // MARK: - Сохранение категории для большого виджета (4x4)
    func setLargeWidgetCategory(_ category: HomeWidgetCategory) {
        self.largeWidgetCategory = category
        AppGroupConstants.syncToAll { defaults in
            defaults.set(category.rawValue, forKey: largeWidgetCategoryKey)
        }
        syncLockScreenWidget()
    }
    
    // MARK: - Сохранение армянского перевода Библии
    func setArmenianEdition(_ edition: ArmenianBibleEdition) {
        self.armenianEdition = edition
        
        // Синхронизируем ключ во всех хранилищах
        AppGroupConstants.syncToAll { defaults in
            defaults.set(edition.rawValue, forKey: "armenian_bible_edition")
        }
        
        // Обогащаем текущий стих актуальными текстами из базы данных SQLite
        self.currentVerse = BibleDatabase.shared.enrichVerse(self.currentVerse)
        
        AppGroupConstants.syncToAll { defaults in
            // Обновляем текст текущего стиха для виджетов под выбранный перевод
            defaults.set(currentVerse.text(for: .armenian), forKey: "currentVerseTextHy")
            defaults.set(currentVerse.textHy, forKey: "currentVerseTextHyEchmiadzin")
            defaults.set(currentVerse.textHyArarat, forKey: "currentVerseTextHyArarat")
            defaults.set(currentVerse.text, forKey: textKey)
        }
        
        syncLockScreenWidget()
        WidgetCenter.shared.reloadAllTimelines()
        objectWillChange.send()
    }
    
    // MARK: - Мгновенная синхронизация и случайные стихи для всех размеров виджетов
    func syncLockScreenWidget() {
        let isPremium = AppGroupConstants.sharedBool(forKey: "is_premium_active")
        let activeCategory = (isPremium || !lockScreenCategory.isPremiumRequired) ? lockScreenCategory : .pearls
        let rawList = BibleVerse.lockScreenVerses(for: activeCategory).filter { $0.textHy.count <= 46 }
        let list = !rawList.isEmpty ? rawList : BibleVerse.shortPearls
        
        let randomPearl = list.randomElement() ?? BibleVerse.shortPearls.first
        let enrichedPearl = randomPearl.map { BibleDatabase.shared.enrichVerse($0) }
        
        let smallPool = list
        let randomSmall = smallPool.randomElement() ?? BibleVerse.shortPearls.first
        
        let activeMedCat = (isPremium || !mediumWidgetCategory.isPremiumRequired) ? mediumWidgetCategory : .all
        let medVerses = BibleVerse.verses(for: activeMedCat, isPremium: isPremium)
        let medFiltered = medVerses.filter { $0.textHy.count >= 35 && $0.textHy.count <= 100 }
        let medPool = !medFiltered.isEmpty ? medFiltered : (!medVerses.isEmpty ? medVerses : BibleVerse.database)
        let randomMed = medPool.randomElement()
        
        let activeLargeCat = (isPremium || !largeWidgetCategory.isPremiumRequired) ? largeWidgetCategory : .all
        let largeVerses = BibleVerse.verses(for: activeLargeCat, isPremium: isPremium)
        let largeFiltered = largeVerses.filter { $0.textHy.count >= 75 }
        let largePool = !largeFiltered.isEmpty ? largeFiltered : (!largeVerses.isEmpty ? largeVerses : BibleVerse.database)
        let randomLarge = largePool.randomElement()
        
        AppGroupConstants.syncToAll { defaults in
            // 1. Экран блокировки (Lock Screen) - строго короткие фразы <= 46 символов
            if let enrichedPearl {
                defaults.set(enrichedPearl.id.uuidString, forKey: "currentLockScreenVerseId")
                defaults.set(enrichedPearl.textHy, forKey: "currentLockScreenTextHy")
                defaults.set(enrichedPearl.textHy, forKey: "currentLockScreenTextHyEchmiadzin")
                defaults.set(enrichedPearl.textHyArarat, forKey: "currentLockScreenTextHyArarat")
                defaults.set(enrichedPearl.textRu, forKey: "currentLockScreenTextRu")
                defaults.set(enrichedPearl.textEn, forKey: "currentLockScreenTextEn")
                defaults.set(enrichedPearl.refHy, forKey: "currentLockScreenRefHy")
                defaults.set(enrichedPearl.refRu, forKey: "currentLockScreenRefRu")
                defaults.set(enrichedPearl.refEn, forKey: "currentLockScreenRefEn")
            }
            
            // 2. Малый виджет (System Small 2x2) - строго короткие стихи активной категории
            if let randomSmall {
                defaults.set(randomSmall.id.uuidString, forKey: "currentSmallVerseId")
            }
            
            // 3. Средний виджет (System Medium 4x2) - стихи 35-100 символов с учетом mediumWidgetCategory
            if let randomMed {
                defaults.set(randomMed.id.uuidString, forKey: "currentMediumVerseId")
            }
            
            // 4. Большой виджет (System Large 4x4) - стихи от 75 символов с учетом largeWidgetCategory
            if let randomLarge {
                defaults.set(randomLarge.id.uuidString, forKey: "currentLargeVerseId")
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Принудительное обновление UI после смены языка/темы
    func forceRefreshUI() {
        objectWillChange.send()
    }
    
    // MARK: - Сохранение интервала обновления и перезапуск виджета
    func setUpdateInterval(_ interval: UpdateInterval) {
        self.updateInterval = interval
        AppGroupConstants.syncToAll { defaults in
            defaults.set(interval.rawValue, forKey: updateIntervalKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение категории контента и перезапуск виджета
    func setSelectedCategory(_ category: TextCategory) {
        self.selectedCategory = category
        AppGroupConstants.syncToAll { defaults in
            defaults.set(category.rawValue, forKey: categoryKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Получение отфильтрованной базы данных стихов/молитв (для виджета и PUSH)
    func getFilteredDatabase(for category: TextCategory) -> [BibleVerse] {
        switch category {
        case .verses:
            return BibleVerse.database.filter { !$0.isPrayer }
        case .prayers:
            return BibleVerse.database.filter { $0.isPrayer }
        case .favorites:
            // Фильтруем элементы избранного, которые применимы к виджетам (isDailyVerse = true)
            let dailyFavorites = favoriteVerses.filter { $0.isDailyVerse }
            if dailyFavorites.isEmpty {
                return BibleVerse.database
            }
            return dailyFavorites.map { item in
                BibleVerse(
                    id: item.id,
                    textHy: item.textHy,
                    textRu: item.textRu,
                    textEn: item.textEn,
                    refHy: item.refHy,
                    refRu: item.refRu,
                    refEn: item.refEn,
                    isPrayer: false
                )
            }
        case .both:
            return BibleVerse.database
        }
    }
    
    // MARK: - Управление Избранным
    func addToFavorites(_ verse: BibleVerse) {
        if !favoriteVerses.contains(where: { $0.textHy == verse.textHy || $0.textRu == verse.textRu }) {
            let favorite = FavoriteItem(
                id: verse.id,
                isDailyVerse: true,
                bookId: nil,
                chapter: nil,
                verseNumber: nil,
                textHy: verse.textHy,
                textRu: verse.textRu,
                textEn: verse.textEn,
                refHy: verse.refHy,
                refRu: verse.refRu,
                refEn: verse.refEn
            )
            favoriteVerses.append(favorite)
            saveFavorites()
        }
    }
    
    func addToFavorites(verseText: BibleVerseText, bookName: String) {
        if !favoriteVerses.contains(where: { $0.bookId == verseText.bookId && $0.chapter == verseText.chapter && $0.verseNumber == verseText.verseNumber }) {
            let refHy = "\(bookName) \(verseText.chapter):\(verseText.verseNumber)"
            let refRu = "\(bookName) \(verseText.chapter):\(verseText.verseNumber)"
            let refEn = "\(bookName) \(verseText.chapter):\(verseText.verseNumber)"
            
            let favorite = FavoriteItem(
                id: UUID(),
                isDailyVerse: false,
                bookId: verseText.bookId,
                chapter: verseText.chapter,
                verseNumber: verseText.verseNumber,
                textHy: verseText.textHy,
                textHyArarat: verseText.textHyArarat,
                textRu: verseText.textRu,
                textEn: verseText.textEn,
                refHy: refHy,
                refRu: refRu,
                refEn: refEn
            )
            favoriteVerses.append(favorite)
            saveFavorites()
        }
    }
    
    func removeFromFavorites(_ verse: BibleVerse) {
        favoriteVerses.removeAll(where: { $0.textHy == verse.textHy || $0.textRu == verse.textRu })
        saveFavorites()
    }
    
    func removeFromFavorites(verseText: BibleVerseText) {
        favoriteVerses.removeAll(where: { $0.bookId == verseText.bookId && $0.chapter == verseText.chapter && $0.verseNumber == verseText.verseNumber })
        saveFavorites()
    }
    
    func removeFromFavorites(id: UUID) {
        favoriteVerses.removeAll(where: { $0.id == id })
        saveFavorites()
    }
    
    func isFavorite(_ verse: BibleVerse) -> Bool {
        favoriteVerses.contains(where: { $0.textHy == verse.textHy || $0.textRu == verse.textRu })
    }
    
    func isFavorite(verseText: BibleVerseText) -> Bool {
        favoriteVerses.contains(where: { $0.bookId == verseText.bookId && $0.chapter == verseText.chapter && $0.verseNumber == verseText.verseNumber })
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteVerses) {
            AppGroupConstants.syncToAll { defaults in
                defaults.set(encoded, forKey: favoritesKey)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Управление шрифтом Библии
    func setBibleFontSize(_ size: Double) {
        self.bibleFontSize = size
        AppGroupConstants.syncToAll { defaults in
            defaults.set(size, forKey: "bible_font_size")
        }
    }
    
    // MARK: - Сохранение темы оформления (Системная / Светлая / Темная)
    func setAppearanceMode(_ mode: AppAppearanceMode) {
        self.appearanceMode = mode
        AppGroupConstants.syncToAll { defaults in
            defaults.set(mode.rawValue, forKey: appearanceModeKey)
        }
    }
    
    // MARK: - Сохранение цветовой темы
    func setAccentTheme(_ theme: AccentColorTheme) {
        self.accentTheme = theme
        objectWillChange.send()
        AppGroupConstants.syncToAll { defaults in
            defaults.set(theme.rawValue, forKey: accentThemeKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Сохранение стиля виджетов и режима StandBy
    func setWidgetVisualStyle(_ style: WidgetVisualStyle) {
        self.widgetVisualStyle = style
        objectWillChange.send()
        let now = Date().timeIntervalSince1970
        AppGroupConstants.syncToAll { defaults in
            defaults.set(style.rawValue, forKey: widgetVisualStyleKey)
            defaults.set(style.rawValue, forKey: "widgetVisualStyle")
            defaults.set(style.rawValue, forKey: "widget_visual_style")
            defaults.set(now, forKey: "widget_style_timestamp")
        }
        UserDefaults.standard.set(style.rawValue, forKey: "widget_visual_style")
        UserDefaults.standard.set(style.rawValue, forKey: "widgetVisualStyle")
        UserDefaults.standard.set(now, forKey: "widget_style_timestamp")
        UserDefaults.standard.synchronize()
        
        syncLockScreenWidget()
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
}
