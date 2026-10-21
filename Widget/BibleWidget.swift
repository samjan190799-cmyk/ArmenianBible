import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Перечисления конфигурации для AppIntents
@available(iOS 17.0, *)
enum WidgetLanguageAppEnum: String, AppEnum {
    case followApp = "followApp"
    case armenian = "armenian"
    case russian = "russian"
    case english = "english"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Language"
    }
    
    static var caseDisplayRepresentations: [WidgetLanguageAppEnum: DisplayRepresentation] {
        [
            .followApp: DisplayRepresentation(title: "Same as App", subtitle: "Uses language selected in the main app settings"),
            .armenian: DisplayRepresentation(title: "Հայերեն (Armenian)", subtitle: "Forces Armenian language for the widget"),
            .russian: DisplayRepresentation(title: "Русский (Russian)", subtitle: "Forces Russian language for the widget"),
            .english: DisplayRepresentation(title: "English", subtitle: "Forces English language for the widget")
        ]
    }
    
    var appLanguage: AppLanguage? {
        switch self {
        case .followApp: return nil
        case .armenian: return .armenian
        case .russian: return .russian
        case .english: return .english
        }
    }
}

@available(iOS 17.0, *)
enum TextCategoryAppEnum: String, AppEnum {
    case pearls = "pearls"
    case narekatsi = "narekatsi"
    case psalms = "psalms"
    case wisdom = "wisdom"
    case love = "love"
    case faith = "faith"
    case both = "both"
    case verses = "verses"
    case prayers = "prayers"
    case favorites = "favorites"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Content"
    }
    
    static var caseDisplayRepresentations: [TextCategoryAppEnum: DisplayRepresentation] {
        [
            .pearls: DisplayRepresentation(title: "🕊️ Short Pearls (Free)", subtitle: "Ultra-compact inspiring verses (up to 45 chars)"),
            .narekatsi: DisplayRepresentation(title: "👑 Narekatsi Prayers (PRO)", subtitle: "Concise prayers of St. Gregory of Narek"),
            .psalms: DisplayRepresentation(title: "✝️ Psalms (PRO)", subtitle: "Short verses from Psalms"),
            .wisdom: DisplayRepresentation(title: "📖 Wisdom & Proverbs (PRO)", subtitle: "Short proverbs and wisdom"),
            .love: DisplayRepresentation(title: "❤️ Love & Peace (PRO)", subtitle: "Short verses about love and peace"),
            .faith: DisplayRepresentation(title: "⚓ Faith & Courage (PRO)", subtitle: "Short verses about faith and courage"),
            .both: DisplayRepresentation(title: "All Verses & Prayers", subtitle: "Shows both Bible verses and prayers"),
            .verses: DisplayRepresentation(title: "Bible Verses Only", subtitle: "Shows only biblical verses"),
            .prayers: DisplayRepresentation(title: "🤲 Prayers Only", subtitle: "Shows christian prayers"),
            .favorites: DisplayRepresentation(title: "Favorites Only", subtitle: "Shows only your saved favorite items")
        ]
    }
    
    var textCategory: TextCategory {
        switch self {
        case .both: return .both
        case .verses: return .verses
        case .prayers: return .prayers
        case .favorites: return .favorites
        default: return .both
        }
    }
}

// MARK: - Какие подборки соответствуют выбранному содержимому виджета
@available(iOS 17.0, *)
extension TextCategoryAppEnum {
    /// Короткая подборка для экрана блокировки и малого виджета; у остальных пунктов берётся категория из настроек приложения
    var lockCategory: LockScreenCategory? {
        switch self {
        case .pearls: return .pearls
        case .narekatsi: return .narekatsi
        case .psalms: return .psalms
        case .wisdom: return .wisdom
        case .love: return .love
        case .faith: return .faith
        default: return nil
        }
    }

    /// Подборка для среднего и большого виджета; «Жемчужины», «Любовь» и «Вера» берут категорию из настроек приложения
    var homeCategory: HomeWidgetCategory? {
        switch self {
        case .narekatsi: return .narekatsi
        case .psalms: return .psalms
        case .wisdom: return .wisdom
        case .prayers: return .prayers
        case .favorites: return .favorites
        default: return nil
        }
    }
}

// MARK: - Перечисление стиля оформления виджета и StandBy
@available(iOS 17.0, *)
enum WidgetStyleAppEnum: String, AppEnum {
    case followApp = "followApp"
    case oledStandby = "oledStandby"
    case modernMinimal = "modernMinimal"
    case sacredParchment = "sacredParchment"
    case royalMonastery = "royalMonastery"
    case monochrome = "monochrome"
    case celestialEmerald = "celestialEmerald"
    case crimsonGospel = "crimsonGospel"
    case auroraSunset = "auroraSunset"
    case monasticStone = "monasticStone"
    case posterArarat = "posterArarat"
    case posterKhachkar = "posterKhachkar"
    case posterParchment = "posterParchment"
    case posterNight = "posterNight"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget & StandBy Style"
    }
    
    static var caseDisplayRepresentations: [WidgetStyleAppEnum: DisplayRepresentation] {
        [
            .followApp: DisplayRepresentation(title: "Same as App", subtitle: "Uses visual style chosen in Settings"),
            .oledStandby: DisplayRepresentation(title: "🌟 Gold OLED (StandBy)", subtitle: "Pure pitch black and sacred gold, ideal for StandBy"),
            .modernMinimal: DisplayRepresentation(title: "💎 Glass Modern", subtitle: "Frosted glass and contemporary rounded typography"),
            .sacredParchment: DisplayRepresentation(title: "📜 Sacred Parchment", subtitle: "Ancient manuscript sepia and illuminated bronze"),
            .royalMonastery: DisplayRepresentation(title: "🌌 Royal Midnight", subtitle: "Monastic midnight sapphire and starlight azure"),
            .monochrome: DisplayRepresentation(title: "⚪ Studio Monochrome", subtitle: "High-contrast black and white minimalism"),
            .celestialEmerald: DisplayRepresentation(title: "🌿 Celestial Emerald", subtitle: "Liturgical malachite and glowing mint gold"),
            .crimsonGospel: DisplayRepresentation(title: "🍷 Sacred Pomegranate", subtitle: "Cilician royal crimson ruby and champagne gold"),
            .auroraSunset: DisplayRepresentation(title: "🌅 Ararat Sunset", subtitle: "Warm apricot amber, rose and mountain twilight"),
            .monasticStone: DisplayRepresentation(title: "⛰️ Monastic Stone", subtitle: "Khachkar volcanic basalt and chiseled silver"),
            .posterArarat: DisplayRepresentation(title: "🏔️ Poster · Ararat", subtitle: "Dawn over Ararat with a big phrase"),
            .posterKhachkar: DisplayRepresentation(title: "✝️ Poster · Khachkar (PRO)", subtitle: "A golden khachkar on dark stone"),
            .posterParchment: DisplayRepresentation(title: "📜 Poster · Parchment", subtitle: "A manuscript page with a gold frame"),
            .posterNight: DisplayRepresentation(title: "⭐ Poster · Bethlehem (PRO)", subtitle: "Night sky with a star")
        ]
    }
    
    var widgetStyle: WidgetVisualStyle? {
        switch self {
        case .followApp: return nil
        case .oledStandby: return .oledStandby
        case .modernMinimal: return .modernMinimal
        case .sacredParchment: return .sacredParchment
        case .royalMonastery: return .royalMonastery
        case .monochrome: return .monochrome
        case .celestialEmerald: return .celestialEmerald
        case .crimsonGospel: return .crimsonGospel
        case .auroraSunset: return .auroraSunset
        case .monasticStone: return .monasticStone
        case .posterArarat: return .posterArarat
        case .posterKhachkar: return .posterKhachkar
        case .posterParchment: return .posterParchment
        case .posterNight: return .posterNight
        }
    }
}

// MARK: - Намерение конфигурации виджета (AppIntent)
@available(iOS 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description: LocalizedStringResource = "Customize your Bible widget visual style, language and content type."
    
    @Parameter(title: "Visual Style", default: .followApp)
    var visualStyle: WidgetStyleAppEnum
    
    @Parameter(title: "Language", default: .followApp)
    var language: WidgetLanguageAppEnum
    
    @Parameter(title: "Content Style", default: .pearls)
    var category: TextCategoryAppEnum
}

// MARK: - Интерактивное намерение: Следующий стих (Next Verse Intent)
@available(iOS 17.0, *)
struct NextVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Verse"
    static var description: LocalizedStringResource = "Changes to the next Bible verse tailored for this widget size."
    
    @Parameter(title: "Target Size")
    var targetSize: String
    
    init() {
        self.targetSize = "all"
    }
    
    init(targetSize: String) {
        self.targetSize = targetSize
    }
    
    func perform() async throws -> some IntentResult {
        let defaults = AppGroupConstants.sharedDefaults
        let isPremium = AppGroupConstants.sharedBool(forKey: "is_premium_active")
        let lang = getSharedLanguage()
        let savedLockCatRaw = defaults.string(forKey: "lock_screen_category") ?? "pearls"
        let lockCategory = LockScreenCategory(rawValue: savedLockCatRaw) ?? .pearls
        let savedMedRaw = defaults.string(forKey: "medium_widget_category") ?? "all"
        let medCategory = HomeWidgetCategory(rawValue: savedMedRaw) ?? .all
        let savedLargeRaw = defaults.string(forKey: "large_widget_category") ?? "all"
        let largeCategory = HomeWidgetCategory(rawValue: savedLargeRaw) ?? .all

        // Длина цитаты по месту показа (QuoteTier): экран блокировки и малый — короткие, средний — средние, большой — длинные
        func pick(_ tier: QuoteTier) -> BibleVerse? {
            BibleVerse.quotes(
                for: tier, lang: lang, isPremium: isPremium,
                lockCategory: lockCategory,
                homeCategory: tier == .large ? largeCategory : medCategory
            ).randomElement()
        }

        let target = targetSize
        let smallVerse = (target == "small" || target == "all") ? pick(.small) : nil
        let mediumVerse = (target == "medium" || target == "all") ? pick(.medium) : nil
        let largeVerse = (target == "large" || target == "all") ? pick(.large) : nil
        let lockVerse = (target == "lockScreen" || target == "all") ? pick(.lockScreen) : nil

        AppGroupConstants.syncToAll { defs in
            if let v = smallVerse {
                defs.set(v.id.uuidString, forKey: "currentSmallVerseId")
            }
            if let v = mediumVerse {
                defs.set(v.id.uuidString, forKey: "currentMediumVerseId")
            }
            if let v = largeVerse {
                defs.set(v.id.uuidString, forKey: "currentLargeVerseId")
            }
            if let v = lockVerse {
                defs.set(v.id.uuidString, forKey: "currentLockScreenVerseId")
                defs.set(v.textHy, forKey: "currentLockScreenTextHy")
                defs.set(v.textRu, forKey: "currentLockScreenTextRu")
                defs.set(v.textEn, forKey: "currentLockScreenTextEn")
                defs.set(v.refHy, forKey: "currentLockScreenRefHy")
                defs.set(v.refRu, forKey: "currentLockScreenRefRu")
                defs.set(v.refEn, forKey: "currentLockScreenRefEn")
            }
        }
        
        return .result()
    }
}

// MARK: - Интерактивное намерение: Отметить молитву прочитанной / выполненной
@available(iOS 17.0, *)
struct TogglePrayerCompletedWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Prayer Completed"
    static var description: LocalizedStringResource = "Marks today's prayer as completed directly from the widget."
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        let defaults = AppGroupConstants.sharedDefaults
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let currentStatus = defaults.bool(forKey: "prayer_completed_\(todayStr)")
        AppGroupConstants.syncToAll { defs in
            defs.set(!currentStatus, forKey: "prayer_completed_\(todayStr)")
        }
        
        return .result()
    }
}

// MARK: - Интерактивное намерение: Добавить / удалить из Избранного прямо из виджета
@available(iOS 17.0, *)
struct ToggleFavoriteWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    static var description: LocalizedStringResource = "Adds or removes the current widget verse from favorites."
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        let defaults = AppGroupConstants.sharedDefaults
        
        // 1. Получаем текущий ID стиха из виджета
        var currentVerseIdStr = defaults.string(forKey: "currentLockScreenVerseId")
        if currentVerseIdStr == nil {
            currentVerseIdStr = defaults.string(forKey: "currentMediumVerseId")
        }
        if currentVerseIdStr == nil {
            currentVerseIdStr = defaults.string(forKey: "currentSmallVerseId")
        }
        
        guard let idStr = currentVerseIdStr, let verseId = UUID(uuidString: idStr) else {
            return .result()
        }
        
        // 2. Находим сам стих в базе (разбито на под-выражения для компилятора Swift)
        var foundVerse: BibleVerse? = BibleVerse.database.first(where: { $0.id == verseId })
        if foundVerse == nil { foundVerse = BibleVerse.shortPearls.first(where: { $0.id == verseId }) }
        if foundVerse == nil { foundVerse = BibleVerse.shortNarekatsi.first(where: { $0.id == verseId }) }
        if foundVerse == nil { foundVerse = BibleVerse.shortPsalms.first(where: { $0.id == verseId }) }
        if foundVerse == nil { foundVerse = BibleVerse.shortWisdom.first(where: { $0.id == verseId }) }
        if foundVerse == nil { foundVerse = BibleVerse.shortLove.first(where: { $0.id == verseId }) }
        if foundVerse == nil { foundVerse = BibleVerse.shortFaith.first(where: { $0.id == verseId }) }
        guard let verse = foundVerse else {
            return .result()
        }
        
        // 3. Загружаем сохраненный список избранного
        var favorites: [FavoriteItem] = []
        if let savedData = defaults.data(forKey: "favorite_verses"),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedData) {
            favorites = decoded
        }
        
        // 4. Добавляем или удаляем
        if let index = favorites.firstIndex(where: { $0.id == verse.id }) {
            favorites.remove(at: index)
        } else {
            let newItem = FavoriteItem(
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
            favorites.insert(newItem, at: 0)
        }
        
        // 5. Сохраняем обратно во все App Group контейнеры
        if let encoded = try? JSONEncoder().encode(favorites) {
            AppGroupConstants.syncToAll { defs in
                defs.set(encoded, forKey: "favorite_verses")
            }
        }
        
        return .result()
    }
}

// MARK: - Модель записи таймлайна (Timeline Entry)
@available(iOS 17.0, *)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let verse: BibleVerse
    let configuration: ConfigurationAppIntent
    let language: AppLanguage
    let visualStyle: WidgetVisualStyle
    var styleTimestamp: Double = 0.0
}

@available(iOS 17.0, *)
typealias BibleWidgetEntry = SimpleEntry

// MARK: - Провайдер временной шкалы виджета (Timeline Provider)
@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationAppIntent
    
    private let appGroupSuiteName = AppGroupConstants.activeSuiteName
    private let textCategoryKey = "selected_category"
    private let updateIntervalKey = "widgetUpdateInterval"
    
    private func getSharedVisualStyle() -> WidgetVisualStyle {
        AppGroupConstants.sharedVisualStyle()
    }
    
    private func getSharedStyleTimestamp() -> Double {
        for suite in AppGroupConstants.allSuites {
            if let d = UserDefaults(suiteName: suite) {
                let ts = d.double(forKey: "widget_style_timestamp")
                if ts > 0 { return ts }
            }
        }
        return UserDefaults.standard.double(forKey: "widget_style_timestamp")
    }
    
    private func resolveVisualStyle(for configuration: ConfigurationAppIntent) -> WidgetVisualStyle {
        let appStyle = getSharedVisualStyle()
        let chosen: WidgetVisualStyle
        if configuration.visualStyle == .followApp {
            chosen = appStyle
        } else if let custom = configuration.visualStyle.widgetStyle {
            chosen = custom
        } else {
            chosen = appStyle
        }
        // Постер «Хачкар»/«Вифлеем» рисуется как выбран, без пометок: короны и PRO на виджете нет
        return chosen
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        let style = getSharedVisualStyle()
        let lang = getSharedLanguage()
        let verse = getSharedVerse(for: ConfigurationAppIntent(), family: context.family)
        return SimpleEntry(
            date: Date(),
            verse: verse,
            configuration: ConfigurationAppIntent(),
            language: lang,
            visualStyle: style,
            styleTimestamp: getSharedStyleTimestamp()
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let verse = getSharedVerse(for: configuration, family: context.family)
        let style = resolveVisualStyle(for: configuration)
        return SimpleEntry(
            date: Date(),
            verse: verse,
            configuration: configuration,
            language: lang,
            visualStyle: style,
            styleTimestamp: getSharedStyleTimestamp()
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [BibleWidgetEntry] = []
        let currentDate = Date()
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let interval = getSharedUpdateInterval()
        let style = resolveVisualStyle(for: configuration)
        let family = context.family
        
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.isEmpty ? BibleVerse.shortPearls[0] : database[0]
        
        let minutesStep = interval.minutes
        let totalEntries = max(1, min(12, 1440 / max(1, minutesStep)))
        let tier = QuoteTier(family: family)

        var currentVerse = getSharedVerse(for: configuration, family: family)
        
        for i in 0..<totalEntries {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: i * minutesStep, to: currentDate) else { continue }
            
            let rawVerse: BibleVerse
            if i == 0 {
                rawVerse = currentVerse
            } else {
                rawVerse = database.randomElement() ?? fallback
            }
            
            // Страховка: цитата не должна выходить за допустимую длину для этого размера виджета
            let entryVerse: BibleVerse
            if let tier, !tier.limit.contains(rawVerse.text(for: lang).count) {
                entryVerse = database.randomElement() ?? rawVerse
            } else {
                entryVerse = rawVerse
            }
            
            let entry = BibleWidgetEntry(
                date: entryDate,
                verse: entryVerse,
                configuration: configuration,
                language: lang,
                visualStyle: style,
                styleTimestamp: getSharedStyleTimestamp()
            )
            entries.append(entry)
        }
        
        let reloadDate = Calendar.current.date(byAdding: .minute, value: minutesStep, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(reloadDate))
    }
    
    /// Подборка цитат для виджета: категория из настроек виджета, длина — по его размеру (QuoteTier)
    private func getFilteredDatabase(for category: TextCategory, configuration: ConfigurationAppIntent? = nil, family: WidgetFamily? = nil, lang: AppLanguage) -> [BibleVerse] {
        guard let family, let tier = QuoteTier(family: family) else {
            return BibleVerse.database
        }
        let defaults = AppGroupConstants.sharedDefaults
        let isPremium = AppGroupConstants.sharedBool(forKey: "is_premium_active")
        let savedLockCatRaw = defaults.string(forKey: "lock_screen_category") ?? "pearls"
        let savedMedRaw = defaults.string(forKey: "medium_widget_category") ?? "all"
        let savedLargeRaw = defaults.string(forKey: "large_widget_category") ?? "all"
        let chosen = configuration?.category

        // Своя категория виджета важнее общей из настроек приложения
        let lockCategory = chosen?.lockCategory ?? LockScreenCategory(rawValue: savedLockCatRaw) ?? .pearls
        let homeCategory = chosen?.homeCategory
            ?? HomeWidgetCategory(rawValue: tier == .large ? savedLargeRaw : savedMedRaw)
            ?? .all

        // «Молитвы» и «Избранное» в виджете были бесплатными, поэтому их Premium не ограничивает
        let isHomeTier = (tier == .medium || tier == .large)
        let unlocked = isPremium || (isHomeTier && (chosen == .prayers || chosen == .favorites))

        let pool = BibleVerse.quotes(for: tier, lang: lang, isPremium: unlocked, lockCategory: lockCategory, homeCategory: homeCategory)
        if chosen == .verses {
            let verses = pool.filter { !$0.isPrayer }
            return verses.isEmpty ? pool : verses
        }
        return pool
    }

    private func getSharedVerse(for configuration: ConfigurationAppIntent, family: WidgetFamily? = nil) -> BibleVerse {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.first ?? BibleVerse.shortPearls[0]
        let defaults = AppGroupConstants.sharedDefaults
        let tier = family.flatMap { QuoteTier(family: $0) }
        let isLockScreen = (tier == .lockScreen)

        let key: String
        switch tier {
        case .lockScreen?: key = "currentLockScreenVerseId"
        case .small?: key = "currentSmallVerseId"
        case .medium?: key = "currentMediumVerseId"
        case .large?: key = "currentLargeVerseId"
        case nil: key = "currentVerseId"
        }

        // Сохранённый стих этого размера: берём, только если он есть в подборке (а она уже отобрана по длине)
        let idStr = defaults.string(forKey: key) ?? (isLockScreen ? nil : defaults.string(forKey: "currentVerseId"))
        if let idStr, let uuid = UUID(uuidString: idStr), let found = database.first(where: { $0.id == uuid }) {
            return found
        }

        // Отдельный текст для экрана блокировки или стих приложения (в том числе от ИИ или из SQLite):
        // берём, только если он подходит по длине для этого размера. Стих из основного приложения в малый виджет не попадает.
        let prefix = isLockScreen ? "currentLockScreen" : "currentVerse"
        if let tier, let textHy = defaults.string(forKey: "\(prefix)TextHy"), !textHy.isEmpty {
            let custom = BibleVerse(
                id: idStr.flatMap { UUID(uuidString: $0) } ?? UUID(),
                textHy: defaults.string(forKey: "\(prefix)TextHyEchmiadzin") ?? textHy,
                textHyArarat: defaults.string(forKey: "\(prefix)TextHyArarat") ?? "",
                textRu: defaults.string(forKey: "\(prefix)TextRu") ?? "",
                textEn: defaults.string(forKey: "\(prefix)TextEn") ?? "",
                refHy: defaults.string(forKey: "\(prefix)RefHy") ?? "",
                refRu: defaults.string(forKey: "\(prefix)RefRu") ?? "",
                refEn: defaults.string(forKey: "\(prefix)RefEn") ?? ""
            )
            if tier.limit.contains(custom.text(for: lang).count) {
                return custom
            }
        }

        return database.randomElement() ?? fallback
    }

    private func getSharedUpdateInterval() -> UpdateInterval {
        let defaults = AppGroupConstants.sharedDefaults
        if let savedRaw = defaults.string(forKey: updateIntervalKey),
           let interval = UpdateInterval(rawValue: savedRaw) {
            return interval
        }
        return .everyHour
    }
}

// MARK: - Вспомогательные функции локализации и тем оформления для виджета
func getSharedLanguage() -> AppLanguage {
    sharedWidgetLanguage()
}

private func getSharedTheme() -> AccentColorTheme {
    let defaults = AppGroupConstants.sharedDefaults
    if let savedRaw = defaults.string(forKey: "accent_theme"),
       let theme = AccentColorTheme(rawValue: savedRaw) {
        return theme
    }
    return .cinnabar
}

extension String {
    func localized(for language: AppLanguage) -> String {
        switch self {
        case "widget_next_verse_btn":
            switch language {
            case .armenian: return "Հաջորդը"
            case .russian: return "Следующий"
            case .english: return "Next"
            }
        case "widget_fav_btn":
            switch language {
            case .armenian: return "Սիրված"
            case .russian: return "Избранное"
            case .english: return "Favorite"
            }
        case "widget_pray_todo_btn":
            switch language {
            case .armenian: return "Աղոթք"
            case .russian: return "Молитва"
            case .english: return "Prayer"
            }
        case "widget_pray_done_btn":
            switch language {
            case .armenian: return "Կատարված"
            case .russian: return "Прочитано"
            case .english: return "Completed"
            }
        case "widget_circular_text":
            switch language {
            case .armenian: return "ԱՍՏ"
            case .russian: return "БИБ"
            case .english: return "BIB"
            }
        case "widget_title":
            switch language {
            case .armenian: return "Աստվածաշունչ"
            case .russian: return "Армянская Библия"
            case .english: return "Armenian Bible"
            }
        case "widget_description":
            switch language {
            case .armenian: return "Աստվածաշնչի ոգեշնչող համարներ կողպեքի և գլխավոր էկրանին:"
            case .russian: return "Вдохновляющие стихи из Библии на экране блокировки и домашнем экране."
            case .english: return "Inspiring Bible verses on Lock Screen and Home Screen."
            }
        case "widget_style_oled":
            switch language {
            case .armenian: return "Ոսկե OLED (StandBy)"
            case .russian: return "Золотой OLED (StandBy)"
            case .english: return "Gold OLED (StandBy)"
            }
        case "widget_style_oled_desc":
            switch language {
            case .armenian: return "Խորը սև OLED և ազնիվ ոսկի"
            case .russian: return "Глубокий черный OLED и благородное золото"
            case .english: return "Pure pitch black OLED and sacred gold"
            }
        case "widget_style_glass":
            switch language {
            case .armenian: return "Ապակե Մինիմալիզմ"
            case .russian: return "Стеклянный Минимализм"
            case .english: return "Glass Modern"
            }
        case "widget_style_glass_desc":
            switch language {
            case .armenian: return "Անփայլ ապակի և ժամանակակից տառատեսակ"
            case .russian: return "Матовое стекло и современный шрифт"
            case .english: return "Frosted glass and modern typography"
            }
        case "widget_style_parchment":
            switch language {
            case .armenian: return "Սուրբ Մագաղաթ"
            case .russian: return "Древний Пергамент"
            case .english: return "Sacred Parchment"
            }
        case "widget_style_parchment_desc":
            switch language {
            case .armenian: return "Հայկական հին ձեռագրերի ոճ"
            case .russian: return "Стиль армянских древних манускриптов"
            case .english: return "Ancient Armenian manuscript aesthetic"
            }
        case "widget_style_royal":
            switch language {
            case .armenian: return "Արքայական Կապույտ"
            case .russian: return "Монастырский Синий"
            case .english: return "Royal Midnight"
            }
        case "widget_style_royal_desc":
            switch language {
            case .armenian: return "Գիշերային շափյուղա և երկնային աստղեր"
            case .russian: return "Ночной сапфир и небесные звезды"
            case .english: return "Monastic midnight sapphire and starlight azure"
            }
        case "widget_style_monochrome":
            switch language {
            case .armenian: return "Մաքուր Մոնոքրոմ"
            case .russian: return "Чистый Монохром"
            case .english: return "Studio Monochrome"
            }
        case "widget_style_monochrome_desc":
            switch language {
            case .armenian: return "Բարձր կոնտրաստով սև ու սպիտակ"
            case .russian: return "Контрастная ч/б типографика"
            case .english: return "High-contrast black & white studio"
            }
        case "widget_style_section_title":
            switch language {
            case .armenian: return "Վիջեթների և StandBy ոճ"
            case .russian: return "Стиль виджетов и StandBy"
            case .english: return "Widget & StandBy Style"
            }
        case "widget_style_section_desc":
            switch language {
            case .armenian: return "Ընտրեք ձևավորումը StandBy և գլխավոր էկրանների համար."
            case .russian: return "Выберите оформление для экрана StandBy и домашнего экрана:"
            case .english: return "Select visual theme for StandBy and Home Screen widgets:"
            }
        default:
            guard let path = Bundle.main.path(forResource: language.localeCode, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                return self
            }
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
    }
}

// MARK: - Интерфейс виджета (Widget View)
@available(iOS 17.0, *)
struct BibleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    // Выбранный визуальный стиль виджета и режима StandBy
    private var activeStyle: WidgetVisualStyle {
        entry.visualStyle
    }

    private var widgetBackgroundGradient: LinearGradient {
        activeStyle.backgroundGradient(for: colorScheme)
    }
    
    private var primaryTextColor: Color {
        activeStyle.primaryTextColor(for: colorScheme)
    }
    
    private var accentColor: Color {
        Color(hex: getSharedTheme().colorHex)
    }
    
    private var secondaryTextColor: Color {
        activeStyle.secondaryTextColor(for: colorScheme, accentHex: getSharedTheme().colorHex)
    }
    
    private var quoteIconColor: Color {
        activeStyle.quoteIconColor(for: colorScheme, accentHex: getSharedTheme().colorHex)
    }
    
    private var buttonBackgroundColor: Color {
        activeStyle.buttonBackground(for: colorScheme)
    }
    
    private var borderStrokeGradient: LinearGradient {
        activeStyle.borderStroke(for: colorScheme)
    }
    
    private var fontDesign: Font.Design {
        activeStyle.fontDesign
    }
    
    /// Шрифт специально для виджета Lock Screen — настраивается пользователем отдельно
    private var lockScreenFontDesign: Font.Design {
        AppGroupConstants.sharedLockScreenFontDesign().fontDesign
    }
    
    private func getLanguage() -> AppLanguage {
        if let forced = entry.configuration.language.appLanguage {
            return forced
        }
        return getSharedLanguage()
    }

    private var isPrayerDone: Bool {
        guard let lastDate = AppGroupConstants.sharedDefaults.object(forKey: "daily_prayer_completed_date") as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    private var isFavorite: Bool {
        guard let data = AppGroupConstants.sharedDefaults.data(forKey: "favorite_verses"),
              let list = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            return false
        }
        return list.contains { $0.refHy == entry.verse.refHy || $0.textHy == entry.verse.textHy }
    }


    /// Постер рисуется только в системных размерах; экран блокировки остаётся как был
    private var posterArt: PosterArt? {
        guard family == .systemSmall || family == .systemMedium || family == .systemLarge else { return nil }
        return activeStyle.posterArt
    }

    @ViewBuilder
    private func posterContent(_ art: PosterArt) -> some View {
        let size: PosterSize = family == .systemSmall ? .small : (family == .systemMedium ? .medium : .large)
        let target = family == .systemSmall ? "small" : (family == .systemMedium ? "medium" : "large")
        let tint = art.mainColor
        PosterWidgetLayout(
            art: art,
            size: size,
            text: entry.verse.text(for: getLanguage()),
            reference: entry.verse.reference(for: getLanguage())
        ) {
            HStack(spacing: 8) {
                if size == .large {
                    Button(intent: TogglePrayerCompletedWidgetIntent()) {
                        PosterGlassIcon(symbol: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill", tint: isPrayerDone ? .green : tint, size: 34)
                    }
                    .buttonStyle(.plain)
                    Button(intent: ToggleFavoriteWidgetIntent()) {
                        PosterGlassIcon(symbol: isFavorite ? "heart.fill" : "heart", tint: isFavorite ? .red : tint, size: 34)
                    }
                    .buttonStyle(.plain)
                }
                Button(intent: NextVerseIntent(targetSize: target)) {
                    PosterGlassIcon(symbol: "arrow.clockwise", tint: tint, size: size == .large ? 34 : 30)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var body: some View {
        Group {
            if let art = posterArt {
                posterContent(art)
            } else {
            switch family {
            case .accessoryRectangular:
                // Прямоугольный виджет на экране блокировки: вертикальная черта и подпись с линейкой (LockScreenQuoteViews.swift);
                // цитата — самая крупная, при которой помещается
                LockQuoteCard(
                    text: entry.verse.text(for: getLanguage()),
                    reference: entry.verse.reference(for: getLanguage()),
                    design: lockScreenFontDesign
                )

            case .accessoryInline:
                // Строчный виджет на экране блокировки над часами
                Text("\(isPrayerDone ? "✓ " : "✠ ")\(entry.verse.reference(for: getLanguage()))")

            case .accessoryCircular:
                // Круглый виджет на экране блокировки: хачкар в кольце, при прочитанной молитве — галочка
                LockQuoteCircle(prayerDone: isPrayerDone)

            case .systemSmall:
                // Маленький виджет на домашнем экране (System Small 2x2) / Режим StandBy
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        Spacer()
                        
                        // Интерактивная кнопка следующего стиха
                        Button(intent: NextVerseIntent(targetSize: "small")) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(secondaryTextColor)
                                .padding(5)
                                .background(buttonBackgroundColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    FittedQuoteText(
                        text: entry.verse.text(for: getLanguage()),
                        maxSize: 30,
                        minScale: 0.55,
                        weight: .bold,
                        design: fontDesign,
                        lineSpacing: 2.0
                    )
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    HStack {
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isPrayerDone ? .green : secondaryTextColor.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 11.0, weight: .bold, design: fontDesign))
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                            .foregroundColor(secondaryTextColor)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(widgetBackgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                
            case .systemMedium:
                // Средний виджет на домашнем экране (System Medium 4x2) / Режим StandBy
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 13.0, weight: .bold, design: fontDesign))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    FittedQuoteText(
                        text: entry.verse.text(for: getLanguage()),
                        maxSize: 28,
                        minScale: 0.55,
                        weight: .bold,
                        design: fontDesign,
                        lineSpacing: 3.5
                    )
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    // Интерактивная панель действий с 3 крупными кнопками
                    HStack(spacing: 6) {
                        Button(intent: NextVerseIntent(targetSize: "medium")) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(secondaryTextColor)
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: fontDesign))
                                    .foregroundColor(secondaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(buttonBackgroundColor)
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: fontDesign))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isFavorite ? Color.red.opacity(0.12) : buttonBackgroundColor)
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: fontDesign))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isPrayerDone ? Color.green.opacity(0.16) : buttonBackgroundColor)
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(13)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(widgetBackgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                
            case .systemLarge:
                // Большой виджет на домашнем экране (System Large 4x4)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 15.5, weight: .bold, design: fontDesign))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    FittedQuoteText(
                        text: entry.verse.text(for: getLanguage()),
                        maxSize: 34,
                        minScale: 0.42,
                        weight: .bold,
                        design: fontDesign,
                        lineSpacing: 5.5
                    )
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    // Интерактивная панель действий с 3 крупными кнопками
                    HStack(spacing: 8) {
                        Button(intent: NextVerseIntent(targetSize: "large")) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(secondaryTextColor)
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: fontDesign))
                                    .foregroundColor(secondaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(buttonBackgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: fontDesign))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(isFavorite ? Color.red.opacity(0.12) : buttonBackgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: fontDesign))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(isPrayerDone ? Color.green.opacity(0.16) : buttonBackgroundColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(widgetBackgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                
            default:
                EmptyView()
            }
            }
        }
        .widgetURL(URL(string: "armenianbible://next-verse"))
        .widgetBackground(
            (family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular)
                ? AnyShapeStyle(Color.clear)
                : AnyShapeStyle(widgetBackgroundGradient)
        )
        .id("bible_widget_\(entry.visualStyle.rawValue)_\(entry.styleTimestamp)")
    }
}

// MARK: - Конфигурация виджета стихов Библии (BibleWidget)
@available(iOS 17.0, *)
struct BibleWidget: Widget {
    let kind: String = "BibleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BibleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget_title".localized(for: getSharedLanguage()))
        .description("widget_description".localized(for: getSharedLanguage()))
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
        .disableContentMarginsIfNeeded()
    }
}

// MARK: - Бандл виджетов приложения (WidgetBundle)
@available(iOS 17.0, *)
@main
struct ArmenianBibleWidgetBundle: WidgetBundle {
    var body: some Widget {
        BibleWidget()
        PosterAraratWidget()
        PosterKhachkarWidget()
        PosterParchmentWidget()
        PosterNightWidget()
        PrayerCandleWidget()
        CandleLiveActivity()
    }
}

// MARK: - Расширение WidgetConfiguration для поддержки iOS 17
extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        #if compiler(>=5.9)
        if #available(iOS 17.0, *) {
            return self.contentMarginsDisabled()
        }
        #endif
        return self
    }
}

// MARK: - Поддержка контейнерного фона для iOS 17
extension View {
    @ViewBuilder
    func widgetBackground<S: ShapeStyle>(_ style: S) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(style, for: .widget)
        } else {
            self.background(style)
        }
    }
}

// MARK: - Расширение Color для работы с Hex в виджете
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
