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
    
    @Published var aiTheologicalTone: AITheologicalTone = .patristic
    @Published var quizDefaultQuestionCount: Int = 10
    @Published var quizTimerDuration: Int = 0
    @Published var quizSoundEffectsEnabled: Bool = true
    @Published var lockScreenCategory: LockScreenCategory = .pearls
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
    
    // MARK: - Сохранение и планирование духовных уведомлений
    func setMorningNotificationsEnabled(_ enabled: Bool) {
        self.morningNotificationsEnabled = enabled
        self.dailyNotificationsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: morningNotificationsEnabledKey)
        defaults.set(enabled, forKey: notificationsEnabledKey)
        handleNotificationToggleChange(enabled: enabled)
    }
    
    func setMorningNotificationTime(_ time: Date) {
        self.morningNotificationTime = time
        self.dailyNotificationTime = time
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(time, forKey: morningNotificationTimeKey)
        defaults.set(time, forKey: notificationTimeKey)
        if morningNotificationsEnabled {
            scheduleAllNotifications()
        }
    }
    
    func setEveningNotificationsEnabled(_ enabled: Bool) {
        self.eveningNotificationsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: eveningNotificationsEnabledKey)
        handleNotificationToggleChange(enabled: enabled)
    }
    
    func setEveningNotificationTime(_ time: Date) {
        self.eveningNotificationTime = time
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(time, forKey: eveningNotificationTimeKey)
        if eveningNotificationsEnabled {
            scheduleAllNotifications()
        }
    }
    
    func setChurchFeastsNotificationsEnabled(_ enabled: Bool) {
        self.churchFeastsNotificationsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: churchFeastsNotificationsEnabledKey)
        handleNotificationToggleChange(enabled: enabled)
    }
    
    func setReadingPlanNotificationsEnabled(_ enabled: Bool) {
        self.readingPlanNotificationsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: readingPlanNotificationsEnabledKey)
        handleNotificationToggleChange(enabled: enabled)
    }
    
    func setReadingPlanNotificationTime(_ time: Date) {
        self.readingPlanNotificationTime = time
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(time, forKey: readingPlanNotificationTimeKey)
        if readingPlanNotificationsEnabled {
            scheduleAllNotifications()
        }
    }
    
    private func handleNotificationToggleChange(enabled: Bool) {
        if enabled {
            requestNotificationPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.scheduleAllNotifications()
                } else {
                    self.morningNotificationsEnabled = false
                    self.eveningNotificationsEnabled = false
                    self.churchFeastsNotificationsEnabled = false
                    self.readingPlanNotificationsEnabled = false
                    self.dailyNotificationsEnabled = false
                    self.scheduleAllNotifications()
                }
            }
        } else {
            self.scheduleAllNotifications()
        }
    }
    
    func setDailyNotificationsEnabled(_ enabled: Bool) {
        setMorningNotificationsEnabled(enabled)
    }
    
    func setDailyNotificationTime(_ time: Date) {
        setMorningNotificationTime(time)
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleDailyNotifications() {
        scheduleAllNotifications()
    }
    
    func scheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let anyEnabled = morningNotificationsEnabled || eveningNotificationsEnabled || churchFeastsNotificationsEnabled || readingPlanNotificationsEnabled
        guard anyEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Утренний стих дня (7 дней вперед)
        if morningNotificationsEnabled {
            let database = getFilteredDatabase(for: selectedCategory)
            if !database.isEmpty {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: morningNotificationTime)
                for dayOffset in 0..<7 {
                    let verse = database.randomElement() ?? database[0]
                    let content = UNMutableNotificationContent()
                    content.title = appLanguage == .armenian ? "Առավոտյան օրվա համար" : (appLanguage == .russian ? "Утренний стих дня" : "Morning Verse of the Day")
                    content.body = "\(verse.text(for: appLanguage)) (\(verse.reference(for: appLanguage)))"
                    content.sound = .default
                    
                    guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                    var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    
                    if let scheduledDate = calendar.date(from: components), scheduledDate <= now {
                        continue
                    }
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "morning_verse_\(dayOffset)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        }
        
        // 2. Вечерняя молитва и покой (7 дней вперед)
        if eveningNotificationsEnabled {
            let eveningPool: [BibleVerse] = !BibleVerse.shortPsalms.isEmpty ? BibleVerse.shortPsalms : (!BibleVerse.shortPearls.isEmpty ? BibleVerse.shortPearls : BibleVerse.database)
            if !eveningPool.isEmpty {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: eveningNotificationTime)
                for dayOffset in 0..<7 {
                    let verse = eveningPool.randomElement() ?? eveningPool[0]
                    let content = UNMutableNotificationContent()
                    content.title = appLanguage == .armenian ? "Երեկոյան աղոթք և խաղաղություն" : (appLanguage == .russian ? "Вечерняя молитва и покой" : "Evening Peace & Prayer")
                    content.body = "\(verse.text(for: appLanguage)) (\(verse.reference(for: appLanguage)))"
                    content.sound = .default
                    
                    guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                    var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    
                    if let scheduledDate = calendar.date(from: components), scheduledDate <= now {
                        continue
                    }
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "evening_verse_\(dayOffset)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        }
        
        // 3. Праздники и посты Церкви (ААЦ) на 14 дней вперед (накануне в 19:30)
        if churchFeastsNotificationsEnabled {
            let currentYear = calendar.component(.year, from: now)
            var upcomingFeasts = ChurchCalendarService.shared.feasts(for: currentYear)
            if calendar.component(.month, from: now) == 12 {
                upcomingFeasts.append(contentsOf: ChurchCalendarService.shared.feasts(for: currentYear + 1))
            }
            
            let todayStart = calendar.startOfDay(for: now)
            if let maxDate = calendar.date(byAdding: .day, value: 14, to: todayStart) {
                let relevantFeasts = upcomingFeasts.filter {
                    let feastDay = calendar.startOfDay(for: $0.date)
                    return feastDay >= todayStart && feastDay <= maxDate
                }
                
                for (idx, feast) in relevantFeasts.prefix(12).enumerated() {
                    guard let eveDate = calendar.date(byAdding: .day, value: -1, to: feast.date) else { continue }
                    var components = calendar.dateComponents([.year, .month, .day], from: eveDate)
                    components.hour = 19
                    components.minute = 30
                    
                    if let scheduledDate = calendar.date(from: components), scheduledDate <= now {
                        continue
                    }
                    
                    let content = UNMutableNotificationContent()
                    content.title = appLanguage == .armenian ? "ՀԱԵ Տոնացույց" : (appLanguage == .russian ? "Церковный календарь ААЦ" : "Armenian Church Calendar")
                    
                    let feastTitle = feast.title(for: appLanguage)
                    let feastTypeStr = feast.type.localizedTitle(for: appLanguage)
                    content.body = appLanguage == .armenian ? "Վաղը՝ \(feastTitle) (\(feastTypeStr))" : (appLanguage == .russian ? "Завтра: \(feastTitle) (\(feastTypeStr))" : "Tomorrow: \(feastTitle) (\(feastTypeStr))")
                    content.sound = .default
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "feast_\(idx)_\(feast.id)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        }
        
        // 4. План чтения Библии и сохранение стрика (7 дней вперед)
        if readingPlanNotificationsEnabled {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: readingPlanNotificationTime)
            for dayOffset in 0..<7 {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                
                if let scheduledDate = calendar.date(from: components), scheduledDate <= now {
                    continue
                }
                
                let content = UNMutableNotificationContent()
                content.title = appLanguage == .armenian ? "Աստվածաշնչի ընթերցում" : (appLanguage == .russian ? "Чтение Библии" : "Daily Bible Reading")
                content.body = appLanguage == .armenian ? "Մի մոռացեք այսօրվա ընթերցանությունը՝ ձեր սթրիքը պահպանելու համար:" : (appLanguage == .russian ? "Уделите время чтению Писания сегодня, чтобы не прервать стрик!" : "Don't forget today's Bible reading to keep your reading streak alive!")
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "reading_plan_\(dayOffset)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        }
    }
    
    // MARK: - Тактильный отклик (Haptic Feedback)
    func setHapticsEnabled(_ enabled: Bool) {
        self.isHapticsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: hapticsEnabledKey)
        if enabled {
            triggerHapticImpact(.medium)
        }
    }
    
    func triggerHapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func triggerHapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Биометрическая безопасность (Face ID / Touch ID)
    func setBiometricLockEnabled(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?
        
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ?
            .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
            
        guard context.canEvaluatePolicy(policy, error: &error) else {
            completion(false)
            return
        }
        
        let reason = "biometric_auth_reason".localized(for: appLanguage)
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.isBiometricLockEnabled = enabled
                    let defaults = self.sharedDefaults ?? UserDefaults.standard
                    defaults.set(enabled, forKey: self.biometricLockEnabledKey)
                    self.isAppUnlocked = true
                    self.triggerHapticNotification(.success)
                    completion(true)
                } else {
                    self.triggerHapticNotification(.error)
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithBiometrics(completion: ((Bool) -> Void)? = nil) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?
        
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ?
            .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
            
        guard context.canEvaluatePolicy(policy, error: &error) else {
            DispatchQueue.main.async {
                self.isAppUnlocked = true
                completion?(true)
            }
            return
        }
        
        let reason = "biometric_auth_reason".localized(for: appLanguage)
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.isAppUnlocked = true
                    self.triggerHapticNotification(.success)
                    completion?(true)
                } else {
                    self.isAppUnlocked = false
                    self.triggerHapticNotification(.warning)
                    completion?(false)
                }
            }
        }
    }
    
    func lockApp() {
        if isBiometricLockEnabled {
            isAppUnlocked = false
        }
    }
    
    // MARK: - Управление памятью и кэшем (Cache Management)
    func calculateCacheSize() -> String {
        var totalBytes: Int64 = 0
        let fileManager = FileManager.default
        
        if let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            totalBytes += directorySize(url: cachesUrl)
        }
        
        let tempUrl = fileManager.temporaryDirectory
        totalBytes += directorySize(url: tempUrl)
        
        if let groupUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.activeSuiteName) {
            let groupCaches = groupUrl.appendingPathComponent("Library/Caches", isDirectory: true)
            totalBytes += directorySize(url: groupCaches)
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    private func directorySize(url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        
        var total: Int64 = 0
        for case let fileUrl as URL in enumerator {
            if fileUrl.lastPathComponent == "bible.db" { continue }
            if let values = try? fileUrl.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               values.isDirectory == false,
               let size = values.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    @discardableResult
    func clearAppCache() -> Bool {
        let fileManager = FileManager.default
        var hasClearedAny = false
        
        if let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let items = try? fileManager.contentsOfDirectory(at: cachesUrl, includingPropertiesForKeys: nil) {
            for item in items {
                if item.lastPathComponent == "bible.db" { continue }
                try? fileManager.removeItem(at: item)
                hasClearedAny = true
            }
        }
        
        let tempUrl = fileManager.temporaryDirectory
        if let tempItems = try? fileManager.contentsOfDirectory(at: tempUrl, includingPropertiesForKeys: nil) {
            for item in tempItems {
                if item.lastPathComponent == "bible.db" { continue }
                try? fileManager.removeItem(at: item)
                hasClearedAny = true
            }
        }
        
        self.cachedStorageSize = calculateCacheSize()
        triggerHapticNotification(.success)
        return hasClearedAny
    }
    
    // MARK: - Резервное копирование и экспорт (Backup & Export)
    struct AppBackupData: Codable {
        let appVersion: String
        let exportDate: String
        let appLanguage: String
        let favoritesCount: Int
        let favorites: [FavoriteItem]
        let annotations: [String: VerseAnnotation]
        let highlightedVerses: [String: String]
        let readingStreak: Int
        let bestStreak: Int
        let completedReadingDays: [String: [Int]]
    }
    
    func generateBackupArchive() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileDateString = fileDateFormatter.string(from: Date())
        
        let planManager = ReadingPlanManager.shared
        
        let backup = AppBackupData(
            appVersion: "2.3",
            exportDate: dateString,
            appLanguage: appLanguage.displayName,
            favoritesCount: favoriteVerses.count,
            favorites: favoriteVerses,
            annotations: annotations,
            highlightedVerses: highlightedVerses,
            readingStreak: planManager.currentStreak,
            bestStreak: planManager.bestStreak,
            completedReadingDays: planManager.completedDays
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(backup) else { return nil }
        
        let fileName = "ArmenianBible_Backup_\(fileDateString).json"
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempUrl, options: .atomic)
            triggerHapticNotification(.success)
            return tempUrl
        } catch {
            print("Failed to save backup file: \(error)")
            return nil
        }
    }
    
    // MARK: - Сохранение стиха в AppGroup и обновление виджета
    func updateCurrentVerse(_ verse: BibleVerse) {
        let enriched = BibleDatabase.shared.enrichVerse(verse)
        self.currentVerse = enriched
        // Принудительно уведомляем SwiftUI, т.к. BibleVerse struct с computed свойствами
        // может не считаться "изменённым" при смене языка (stored properties те же)
        objectWillChange.send()
        AppGroupConstants.syncToAll { defaults in
            defaults.set(enriched.id.uuidString, forKey: "currentVerseId")
            // Экран блокировки (Lock Screen) строго изолирован: питается ТОЛЬКО короткими стихами из syncLockScreenWidget()
            // Ни в коем случае не перезаписываем currentLockScreenVerseId стихами общего чтения из приложения!
            defaults.set(enriched.id.uuidString, forKey: "currentSmallVerseId")
            defaults.set(enriched.id.uuidString, forKey: "currentMediumVerseId")
            defaults.set(enriched.id.uuidString, forKey: "currentLargeVerseId")
            
            // Сохраняем мультиязычные тексты стиха для виджета домашнего экрана
            defaults.set(enriched.text(for: .armenian), forKey: "currentVerseTextHy")
            defaults.set(enriched.textHy, forKey: "currentVerseTextHyEchmiadzin")
            defaults.set(enriched.textHyArarat, forKey: "currentVerseTextHyArarat")
            defaults.set(enriched.textRu, forKey: "currentVerseTextRu")
            defaults.set(enriched.textEn, forKey: "currentVerseTextEn")
            defaults.set(enriched.refHy, forKey: "currentVerseRefHy")
            defaults.set(enriched.refRu, forKey: "currentVerseRefRu")
            defaults.set(enriched.refEn, forKey: "currentVerseRefEn")
            
            defaults.set(enriched.text, forKey: textKey)
            defaults.set(enriched.reference, forKey: referenceKey)
        }
        
        // Заставляем виджеты домашнего экрана немедленно обновиться
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Выбор случайного стиха из оффлайн-базы данных
    func selectRandomVerse() {
        if let randomVerse = BibleDatabase.shared.getRandomVerse(scope: verseSourceScope) {
            updateCurrentVerse(randomVerse)
        } else {
            let database = getFilteredDatabase(for: selectedCategory)
            guard !database.isEmpty else { return }
            
            let availableVerses = database.filter { $0.text != currentVerse.text }
            let newVerse: BibleVerse
            
            if !availableVerses.isEmpty {
                newVerse = availableVerses.randomElement() ?? database[0]
            } else {
                newVerse = database[0]
            }
            
            updateCurrentVerse(newVerse)
        }
    }
    
    // MARK: - Обновление источника выборки стихов
    func updateVerseSourceScope(_ scope: VerseSourceScope) {
        self.verseSourceScope = scope
        if let defaults = sharedDefaults {
            defaults.set(scope.rawValue, forKey: verseSourceScopeKey)
            defaults.synchronize()
        }
        selectRandomVerse()
    }
    
    // MARK: - Генерация цитаты через Gemini API / ChatGPT / Claude
    func generateVerseWithAI(completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .chatgpt:
            apiKey = openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude:
            apiKey = anthropicApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is empty"])))
            return
        }
        
        let prompt: String
        switch appLanguage {
        case .armenian:
            let editionNote = armenianEdition == .echmiadzin ? "Էջմիածնի դասական թարգմանությունից" : "Արարատ ժամանակակից թարգմանությունից"
            prompt = "Դու Աստվածաշնչի փորձագետ ես: Գեներացրու մեկ պատահական, ոգեշնչող, իմաստալից և գեղեցիկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (\(editionNote)): Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների կամ բազմակետերի (...): Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        case .russian:
            prompt = "Ты эксперт по Библии. Сгенерируй одну случайную, вдохновляющую, глубокую и красивую библейскую цитату на русском языке (из Синодального перевода). Пиши ПОЛНЫЙ текст цитаты без сокращений и многоточий (...). Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
        case .english:
            prompt = "You are a Bible expert. Generate one random, inspiring, meaningful, and beautiful Bible quote in English (from KJV or ESV translation). Write the COMPLETE text of the quote without abbreviations or ellipses (...). Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }
        
        isGeneratingAI = true
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (textResult, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 1024
                )
                await MainActor.run {
                    self.isGeneratingAI = false
                    let cleanResult = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
                    let components = cleanResult.components(separatedBy: "|")
                    
                    if components.count >= 2 {
                        let text = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        let reference = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"”'«»"))
                        
                        let newVerse = BibleVerse(text: text, reference: reference)
                        self.updateCurrentVerse(newVerse)
                        completion(.success(newVerse))
                    } else {
                        let cleanText = cleanResult.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        if !cleanText.isEmpty {
                            let newVerse = BibleVerse(text: cleanText, reference: NSLocalizedString("widget_title", comment: ""))
                            self.updateCurrentVerse(newVerse)
                            completion(.success(newVerse))
                        } else {
                            completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingAI = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Состояние генерации текста толкования
    @Published var isGeneratingText: Bool = false
    
    // MARK: - Общая генерация текста через ИИ (для толкований и свободных молитв)
    func generateTextFromAI(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey
        case .chatgpt:
            apiKey = openaiApiKey
        case .claude:
            apiKey = anthropicApiKey
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])))
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isGeneratingText = true
        }
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (resultText, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 2048
                )
                await MainActor.run {
                    self.isGeneratingText = false
                    completion(.success(resultText.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingText = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Подбор библейского стиха под тему / настроение пользователя
    func generateContextVerse(mood: String, customPrompt: String?, completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let targetTopic = customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (customPrompt ?? "") : mood
        
        let prompt: String
        switch appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ ես: Գտիր կամ գեներացրու մեկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (Արարատ թարգմանությունից), որը լավագույնս համապատասխանում է հետևյալ թեմային կամ տրամադրությանը՝ «\(targetTopic)»։ Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների: Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        case .russian:
            prompt = "Ты эксперт по Библии. Найди или сгенерируй одну библейскую цитату на русском языке (из Синодального перевода), которая идеально подходит под следующую тему или настроение: «\(targetTopic)». Пиши ПОЛНЫЙ текст цитаты без сокращений. Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
        case .english:
            prompt = "You are a Bible expert. Find or generate a Bible quote in English (KJV or ESV translation) that perfectly fits the following theme or mood: \"\(targetTopic)\". Write the COMPLETE text of the quote without abbreviations. Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }
        
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey
        case .chatgpt:
            apiKey = openaiApiKey
        case .claude:
            apiKey = anthropicApiKey
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])))
            }
            return
        }
        
        isGeneratingAI = true
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (textResult, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 1024
                )
                await MainActor.run {
                    self.isGeneratingAI = false
                    let cleanResult = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
                    let components = cleanResult.components(separatedBy: "|")
                    
                    if components.count >= 2 {
                        let text = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        let reference = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"”'«»"))
                        
                        let newVerse = BibleVerse(text: text, reference: reference)
                        self.updateCurrentVerse(newVerse)
                        completion(.success(newVerse))
                    } else {
                        let cleanText = cleanResult.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        if !cleanText.isEmpty {
                            let newVerse = BibleVerse(text: cleanText, reference: "Armenian Bible")
                            self.updateCurrentVerse(newVerse)
                            completion(.success(newVerse))
                        } else {
                            completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingAI = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Парсинг и локализация ошибок ИИ
    func getFriendlyErrorMessage(for provider: AIProvider, statusCode: Int, rawMessage: String) -> String {
        let msg = rawMessage.lowercased()
        
        // 1. Проверяем нехватку баланса (Out of Credits)
        if msg.contains("credit balance is too low") || msg.contains("insufficient_quota") || msg.contains("billing") || msg.contains("credits") {
            switch appLanguage {
            case .armenian:
                return "Ձեր \(provider.displayName) API հաշվեկշռին բավարար միջոցներ չկան: Այս սահմանաչափը ինքնաբերաբար չի վերականգնվում, անհրաժեշտ է լիցքավորել հաշիվը \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google")) կայքում:"
            case .russian:
                return "Недостаточно средств на балансе вашего аккаунта \(provider.displayName) API. Этот лимит не восстанавливается автоматически, вам нужно пополнить баланс в личном кабинете \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google"))."
            case .english:
                return "Your \(provider.displayName) API credit balance is too low. This limit does not restore automatically; you need to top up your balance in your \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google")) developer dashboard."
            }
        }
        
        // 2. Проверяем лимит частоты запросов (Rate Limit)
        if msg.contains("rate limit") || msg.contains("too many requests") || msg.contains("rate_limit_exceeded") || statusCode == 429 {
            switch appLanguage {
            case .armenian:
                return "Հարցումների սահմանաչափը գերազանցվել է: Այս սահմանաչափը վերականգնվում է ինքնաբերաբար: Խնդրում ենք սպասել 1-ից 5 րոպե նորից փորձելուց առաջ:"
            case .russian:
                return "Превышен лимит запросов. Этот лимит восстанавливается автоматически. Пожалуйста, подождите от 1 до 5 минут перед повторной попыткой."
            case .english:
                return "Rate limit exceeded. This limit restores automatically. Please wait 1 to 5 minutes before trying again."
            }
        }
        
        // 3. Проверяем неверный ключ (Invalid API Key)
        if msg.contains("invalid api key") || msg.contains("invalid_api_key") || msg.contains("key is invalid") || msg.contains("authentication") || msg.contains("unauthorized") || statusCode == 401 {
            switch appLanguage {
            case .armenian:
                return "Անվավեր API բանալի: Խնդրում ենք ստուգել բանալու ճշտությունը հավելվածի Կարգավորումներում:"
            case .russian:
                return "Неверный API-ключ. Проверьте правильность ввода ключа в Настройках приложения."
            case .english:
                return "Invalid API Key. Please check the correctness of the key in the app Settings."
            }
        }
        
        // По умолчанию возвращаем исходное сообщение от провайдера
        return "\(provider.displayName) API: \(rawMessage)"
    }
    
    // MARK: - Духовный ответчик ИИ по Библии
    func askBibleAI(question: String, completion: @escaping (Result<BibleAnswer, Error>) -> Void) {
        let toneGuidance = aiTheologicalTone.promptGuidance(for: appLanguage)
        let prompt: String
        switch appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ և հոգևոր առաջնորդ ես: Օգտատերը հարցնում է. «\(question)»: \(toneGuidance) Տուր մանրամասն, իմաստուն և մխիթարական պատասխան հայերեն լեզվով՝ հիմնված Սուրբ Գրքի վրա: Պատասխանի վերջում անպայման բեր մեկ հիմնական աստվածաշնչյան տող հետևյալ ճշգրիտ ֆորմատով՝\nVERSE_START\n[Տեքստ] | [Հղում]\nVERSE_END"
        case .russian:
            prompt = "Ты эксперт по Библии и духовный наставник. Пользователь спрашивает: «\(question)». \(toneGuidance) Дай подробный, мудрый и поддерживающий ответ на русском языке, основанный на Священном Писании. В самом конце ответа обязательно приведи один ключевой библейский стих в следующем точном формате:\nVERSE_START\n[Текст стиха] | [Ссылка на стих]\nVERSE_END"
        case .english:
            prompt = "You are a Bible expert and spiritual guide. The user asks: \"\(question)\". \(toneGuidance) Provide a detailed, wise, and comforting answer in English based on the Holy Scriptures. At the very end of your response, include one key Bible verse in the following exact format:\nVERSE_START\n[Verse Text] | [Reference]\nVERSE_END"
        }
        
        generateTextFromAI(prompt: prompt) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fullText):
                var answerText = fullText
                var verse: BibleVerse? = nil
                
                if let startRange = fullText.range(of: "VERSE_START"),
                   let endRange = fullText.range(of: "VERSE_END") {
                    
                    answerText = String(fullText[..<startRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let verseContent = String(fullText[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let components = verseContent.components(separatedBy: "|")
                    if components.count >= 2 {
                        let vText = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let vRef = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        verse = BibleVerse(
                            textHy: self.appLanguage == .armenian ? vText : "",
                            textRu: self.appLanguage == .russian ? vText : "",
                            textEn: self.appLanguage == .english ? vText : "",
                            refHy: self.appLanguage == .armenian ? vRef : "",
                            refRu: self.appLanguage == .russian ? vRef : "",
                            refEn: self.appLanguage == .english ? vRef : ""
                        )
                    }
                }
                DispatchQueue.main.async {
                    completion(.success(BibleAnswer(answerText: answerText, verse: verse)))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Управление богословским тоном ИИ
    func setAITheologicalTone(_ tone: AITheologicalTone) {
        self.aiTheologicalTone = tone
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(tone.rawValue, forKey: aiTheologicalToneKey)
        triggerHapticNotification(.success)
        objectWillChange.send()
    }
    
    // MARK: - Управление настройками викторины
    func setQuizDefaultQuestionCount(_ count: Int) {
        self.quizDefaultQuestionCount = count
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(count, forKey: quizDefaultQuestionCountKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    func setQuizTimerDuration(_ duration: Int) {
        self.quizTimerDuration = duration
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(duration, forKey: quizTimerDurationKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    func setQuizSoundEffectsEnabled(_ enabled: Bool) {
        self.quizSoundEffectsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: quizSoundEffectsEnabledKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    func resetQuizFullStats() {
        self.quizBestScore = 0
        if let defaults = sharedDefaults {
            defaults.set(0, forKey: "quiz_best_score")
        }
        QuizAdaptiveDiary.shared.resetDiary()
        AchievementsManager.shared.resetQuizStatistics()
        triggerHapticNotification(.success)
        objectWillChange.send()
    }
    
    // MARK: - Управление рекордами Викторины
    func updateQuizBestScore(_ score: Int) {
        if score > quizBestScore {
            quizBestScore = score
            if let defaults = sharedDefaults {
                defaults.set(score, forKey: "quiz_best_score")
            }
        }
    }
    
    // MARK: - Управление Заметками, Тегами и Маркерами (Annotations, Notes, Tags & Highlighters)
    func annotation(bookId: Int, chapter: Int, verseNumber: Int) -> VerseAnnotation? {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        return annotations[key]
    }
    
    func saveAnnotation(_ item: VerseAnnotation) {
        let key = item.key
        if item.hasContent {
            annotations[key] = item
            if let color = item.colorHex {
                highlightedVerses[key] = color
            } else {
                highlightedVerses.removeValue(forKey: key)
            }
        } else {
            annotations.removeValue(forKey: key)
            highlightedVerses.removeValue(forKey: key)
        }
        
        persistAnnotations()
        objectWillChange.send()
    }
    
    func deleteAnnotation(bookId: Int, chapter: Int, verseNumber: Int) {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        annotations.removeValue(forKey: key)
        highlightedVerses.removeValue(forKey: key)
        persistAnnotations()
        objectWillChange.send()
    }
    
    private func persistAnnotations() {
        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(annotations) {
            defaults.set(encoded, forKey: "verse_annotations_map")
        }
        defaults.set(highlightedVerses, forKey: "highlighted_verses_map")
        defaults.synchronize()
    }
    
    var allAnnotations: [VerseAnnotation] {
        annotations.values.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func setHighlight(
        bookId: Int,
        chapter: Int,
        verseNumber: Int,
        colorHex: String?,
        bookNameHy: String = "",
        bookNameRu: String = "",
        bookNameEn: String = "",
        textHy: String = "",
        textHyArarat: String = "",
        textRu: String = "",
        textEn: String = ""
    ) {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        var item = annotations[key] ?? VerseAnnotation(
            bookId: bookId,
            chapter: chapter,
            verseNumber: verseNumber,
            bookNameHy: bookNameHy,
            bookNameRu: bookNameRu,
            bookNameEn: bookNameEn,
            textHy: textHy,
            textHyArarat: textHyArarat,
            textRu: textRu,
            textEn: textEn
        )
        item.colorHex = colorHex
        if !bookNameHy.isEmpty {
            item = VerseAnnotation(
                id: item.id,
                bookId: bookId,
                chapter: chapter,
                verseNumber: verseNumber,
                bookNameHy: bookNameHy,
                bookNameRu: bookNameRu,
                bookNameEn: bookNameEn,
                textHy: textHy,
                textHyArarat: textHyArarat.isEmpty ? item.textHyArarat : textHyArarat,
                textRu: textRu,
                textEn: textEn,
                colorHex: colorHex,
                note: item.note,
                tags: item.tags,
                updatedAt: Date()
            )
        }
        saveAnnotation(item)
    }
    
    func highlightColor(bookId: Int, chapter: Int, verseNumber: Int) -> String? {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        if let annColor = annotations[key]?.colorHex, !annColor.isEmpty {
            return annColor
        }
        return highlightedVerses[key]
    }
    
    // MARK: - Молитва дня и статус выполнения (Widget & Lockscreen)
    func checkPrayerCompletionStatus() {
        let defaults = AppGroupConstants.sharedDefaults
        if let lastDate = defaults.object(forKey: "daily_prayer_completed_date") as? Date {
            let isToday = Calendar.current.isDateInToday(lastDate)
            self.isPrayerCompletedToday = isToday
        } else {
            self.isPrayerCompletedToday = false
        }
    }
    
    func togglePrayerCompletedToday() {
        let newValue = !isPrayerCompletedToday
        isPrayerCompletedToday = newValue
        AppGroupConstants.syncToAll { defaults in
            if newValue {
                defaults.set(Date(), forKey: "daily_prayer_completed_date")
            } else {
                defaults.removeObject(forKey: "daily_prayer_completed_date")
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        objectWillChange.send()
    }
    
    // MARK: - Закрепление стиха на Виджете
    func pinVerseToWidget(textHy: String, textRu: String, textEn: String, refHy: String, refRu: String, refEn: String) {
        let baseVerse = BibleVerse(textHy: textHy, textRu: textRu, textEn: textEn, refHy: refHy, refRu: refRu, refEn: refEn)
        let enriched = BibleDatabase.shared.enrichVerse(baseVerse)
        
        AppGroupConstants.syncToAll { defaults in
            defaults.set(enriched.text(for: .armenian), forKey: "currentVerseTextHy")
            defaults.set(enriched.textHy, forKey: "currentVerseTextHyEchmiadzin")
            defaults.set(enriched.textHyArarat, forKey: "currentVerseTextHyArarat")
            defaults.set(enriched.textRu, forKey: "currentVerseTextRu")
            defaults.set(enriched.textEn, forKey: "currentVerseTextEn")
            
            defaults.set(enriched.refHy, forKey: "currentVerseReferenceHy")
            defaults.set(enriched.refRu, forKey: "currentVerseReferenceRu")
            defaults.set(enriched.refEn, forKey: "currentVerseReferenceEn")
            
            // Устанавливаем текущий текст в зависимости от языка приложения
            switch appLanguage {
            case .armenian:
                defaults.set(enriched.text(for: .armenian), forKey: textKey)
                defaults.set(enriched.refHy, forKey: referenceKey)
            case .russian:
                defaults.set(enriched.textRu, forKey: textKey)
                defaults.set(enriched.refRu, forKey: referenceKey)
            case .english:
                defaults.set(enriched.textEn, forKey: textKey)
                defaults.set(enriched.refEn, forKey: referenceKey)
            }
        }
        self.currentVerse = enriched
        
        WidgetCenter.shared.reloadAllTimelines()
        objectWillChange.send()
    }
}

// MARK: - Армянский редактор текста Библии
enum ArmenianBibleEdition: String, CaseIterable, Identifiable, Codable {
    case ararat = "ararat"
    case echmiadzin = "echmiadzin"
    case grabar = "grabar"
    
    var id: String { rawValue }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .ararat:
            return "edition_ararat_title".localized(for: language)
        case .echmiadzin:
            return "edition_echmiadzin_title".localized(for: language)
        case .grabar:
            return "edition_grabar_title".localized(for: language)
        }
    }
}

// MARK: - Ответ Библейского ИИ
struct BibleAnswer {
    let answerText: String
    let verse: BibleVerse?
}

// MARK: - Сообщение в чате Духовного Помощника
struct AIChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let isUser: Bool
    let text: String
    let verse: BibleVerse?
    let timestamp: Date
    
    init(id: UUID = UUID(), isUser: Bool, text: String, verse: BibleVerse? = nil, timestamp: Date = Date()) {
        self.id = id
        self.isUser = isUser
        self.text = text
        self.verse = verse
        self.timestamp = timestamp
    }
}

// MARK: - Богословский тон ответов ИИ
enum AITheologicalTone: String, CaseIterable, Identifiable, Codable {
    case patristic = "patristic"
    case pastoral = "pastoral"
    case historical = "historical"
    case simple = "simple"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .patristic: return "cross.fill"
        case .pastoral: return "heart.fill"
        case .historical: return "book.fill"
        case .simple: return "sun.max.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .patristic: return "D97706"
        case .pastoral: return "EC4899"
        case .historical: return "3B82F6"
        case .simple: return "10B981"
        }
    }
    
    func localizedTitle(for lang: AppLanguage) -> String {
        switch self {
        case .patristic: return "ai_tone_patristic".localized(for: lang)
        case .pastoral: return "ai_tone_pastoral".localized(for: lang)
        case .historical: return "ai_tone_historical".localized(for: lang)
        case .simple: return "ai_tone_simple".localized(for: lang)
        }
    }
    
    func localizedDesc(for lang: AppLanguage) -> String {
        switch self {
        case .patristic: return "ai_tone_patristic_desc".localized(for: lang)
        case .pastoral: return "ai_tone_pastoral_desc".localized(for: lang)
        case .historical: return "ai_tone_historical_desc".localized(for: lang)
        case .simple: return "ai_tone_simple_desc".localized(for: lang)
        }
    }
    
    func promptGuidance(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.patristic, .armenian):
            return "Հատուկ ուշադրություն դարձրու Հայ Առաքելական Սուրբ Եկեղեցու հայրերի և վարդապետների (Գրիգոր Լուսավորիչ, Գրիգոր Նարեկացի, Ներսես Շնորհալի) ավանդությանը:"
        case (.patristic, .russian):
            return "Придерживайся святоотеческого толкования и древней традиции Армянской Апостольской Церкви и святых вардапетов (св. Григор Просветитель, св. Григор Нарекаци, св. Нерсес Шнорали)."
        case (.patristic, .english):
            return "Adhere to the patristic interpretations and the ancient sacred tradition of the Armenian Apostolic Church and holy vardapets (St. Gregory the Illuminator, St. Gregory of Narek, St. Nerses the Gracious)."
            
        case (.pastoral, .armenian):
            return "Պատասխանիր հոգևոր հոգատարությամբ, ջերմությամբ և քաջալերանքով՝ շեշտելով հոգևոր մխիթարությունն ու գործնական կիրառումը քրիստոնեական կյանքում:"
        case (.pastoral, .russian):
            return "Отвечай пастырски, тепло и ободряюще, делая главный акцент на духовном утешении, укреплении веры и практическом применении в христианской жизни."
        case (.pastoral, .english):
            return "Provide a pastoral, warm, and uplifting response emphasizing personal spiritual life, faith strengthening, and comforting guidance."
            
        case (.historical, .armenian):
            return "Մանրամասն ներկայացրու գրքի պատմական, աստվածաբանական և մշակութային համատեքստը՝ անդրադառնալով բնագրի լեզվին և իմաստային շերտերին:"
        case (.historical, .russian):
            return "Раскрой исторический, богословский и культурный контекст книги и стихов, уделяя особое внимание языку оригинала, эпохе и экзегетическому смыслу Писания."
        case (.historical, .english):
            return "Explore the historical, theological, and cultural context, noting original language nuances, historical era, and biblical exegesis."
            
        case (.simple, .armenian):
            return "Բացատրիր հնարավորինս պարզ, մատչելի և հասկանալի լեզվով՝ առանց բարդ տերմինների, նրանց համար, ովքեր նոր են սկսում ծանոթանալ Սուրբ Գրքին:"
        case (.simple, .russian):
            return "Объясняй максимально просто, тепло и доступно, избегая перегруженных терминов, специально для тех, кто только начинает читать и постигать Священное Писание."
        case (.simple, .english):
            return "Explain simply, clearly, and accessibly without complex theological jargon, specifically tailored for beginners exploring Holy Scripture."
        }
    }
}
