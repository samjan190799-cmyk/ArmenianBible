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

// MARK: - Перечисление стиля оформления виджета и StandBy
@available(iOS 17.0, *)
enum WidgetStyleAppEnum: String, AppEnum {
    case followApp = "followApp"
    case oledStandby = "oledStandby"
    case modernMinimal = "modernMinimal"
    case sacredParchment = "sacredParchment"
    case royalMonastery = "royalMonastery"
    case monochrome = "monochrome"
    
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
            .monochrome: DisplayRepresentation(title: "⚪ Studio Monochrome", subtitle: "High-contrast black and white minimalism")
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
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        let isPremium = defaults.bool(forKey: "is_premium_active")
        let savedLockCatRaw = defaults.string(forKey: "lock_screen_category") ?? "pearls"
        let activeLockCategory = LockScreenCategory(rawValue: savedLockCatRaw) ?? .pearls
        let cat = (isPremium || !activeLockCategory.isPremiumRequired) ? activeLockCategory : .pearls
        let rawLockPool = BibleVerse.lockScreenVerses(for: cat).filter { $0.textHy.count <= 46 }
        let lockPool = !rawLockPool.isEmpty ? rawLockPool : BibleVerse.shortPearls
        
        let target = targetSize
        
        // 1. Для малого виджета (System Small) - строго короткие стихи активной категории
        if target == "small" || target == "all" {
            if let v = lockPool.randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentSmallVerseId")
            }
        }
        
        // 2. Для среднего виджета (System Medium) - стихи 35-100 символов с учетом medium_widget_category
        if target == "medium" || target == "all" {
            let savedMedRaw = defaults.string(forKey: "medium_widget_category") ?? "all"
            let medCat = HomeWidgetCategory(rawValue: savedMedRaw) ?? .all
            let activeMedCat = (isPremium || !medCat.isPremiumRequired) ? medCat : .all
            let medVerses = BibleVerse.verses(for: activeMedCat, isPremium: isPremium)
            let medFiltered = medVerses.filter { $0.textHy.count >= 35 && $0.textHy.count <= 100 }
            let medPool = !medFiltered.isEmpty ? medFiltered : (!medVerses.isEmpty ? medVerses : BibleVerse.database)
            if let v = medPool.randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentMediumVerseId")
            }
        }
        
        // 3. Для большого виджета (System Large) - глубокие отрывки от 75 символов с учетом large_widget_category
        if target == "large" || target == "all" {
            let savedLargeRaw = defaults.string(forKey: "large_widget_category") ?? "all"
            let largeCat = HomeWidgetCategory(rawValue: savedLargeRaw) ?? .all
            let activeLargeCat = (isPremium || !largeCat.isPremiumRequired) ? largeCat : .all
            let largeVerses = BibleVerse.verses(for: activeLargeCat, isPremium: isPremium)
            let largeFiltered = largeVerses.filter { $0.textHy.count >= 75 }
            let largePool = !largeFiltered.isEmpty ? largeFiltered : (!largeVerses.isEmpty ? largeVerses : BibleVerse.database)
            if let v = largePool.randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentLargeVerseId")
            }
        }
        
        // 4. Для экрана блокировки (Lock Screen)
        if target == "lockScreen" || target == "all" {
            if let v = lockPool.randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentLockScreenVerseId")
                defaults.set(v.textHy, forKey: "currentLockScreenTextHy")
                defaults.set(v.textRu, forKey: "currentLockScreenTextRu")
                defaults.set(v.textEn, forKey: "currentLockScreenTextEn")
                defaults.set(v.refHy, forKey: "currentLockScreenRefHy")
                defaults.set(v.refRu, forKey: "currentLockScreenRefRu")
                defaults.set(v.refEn, forKey: "currentLockScreenRefEn")
            }
        }
        
        defaults.synchronize()
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
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let currentStatus = defaults.bool(forKey: "prayer_completed_\(todayStr)")
        defaults.set(!currentStatus, forKey: "prayer_completed_\(todayStr)")
        defaults.synchronize()
        
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
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        
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
        
        // 5. Сохраняем обратно в App Group
        if let encoded = try? JSONEncoder().encode(favorites) {
            defaults.set(encoded, forKey: "favorite_verses")
            defaults.synchronize()
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
}

@available(iOS 17.0, *)
typealias BibleWidgetEntry = SimpleEntry

// MARK: - Провайдер временной шкалы виджета (Timeline Provider)
@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationAppIntent
    
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    private let textCategoryKey = "selected_category"
    private let updateIntervalKey = "widgetUpdateInterval"
    
    private func getSharedVisualStyle() -> WidgetVisualStyle {
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedRaw = defaults.string(forKey: "widget_visual_style"),
           let style = WidgetVisualStyle(rawValue: savedRaw) {
            return style
        }
        return .oledStandby
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            verse: BibleVerse.shortPearls[0],
            configuration: ConfigurationAppIntent(),
            language: .armenian,
            visualStyle: .oledStandby
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let verse = getSharedVerse(for: configuration, family: context.family)
        let style = configuration.visualStyle.widgetStyle ?? getSharedVisualStyle()
        return SimpleEntry(date: Date(), verse: verse, configuration: configuration, language: lang, visualStyle: style)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [BibleWidgetEntry] = []
        let currentDate = Date()
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let interval = getSharedUpdateInterval()
        let style = configuration.visualStyle.widgetStyle ?? getSharedVisualStyle()
        let family = context.family
        
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.isEmpty ? BibleVerse.shortPearls[0] : database[0]
        
        let minutesStep = interval.minutes
        let totalEntries = max(1, min(12, 1440 / max(1, minutesStep)))
        let isLockScreen = (family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular)
        
        var currentVerse = getSharedVerse(for: configuration, family: family)
        
        for i in 0..<totalEntries {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: i * minutesStep, to: currentDate) else { continue }
            
            let rawVerse: BibleVerse
            if i == 0 {
                rawVerse = currentVerse
            } else {
                rawVerse = database.randomElement() ?? fallback
            }
            
            // Гарантия: на экране блокировки стих ВСЕГДА строго <= 46 символов
            let entryVerse: BibleVerse
            if isLockScreen && rawVerse.text(for: lang).count > 46 {
                let safeList = database.filter { $0.text(for: lang).count <= 46 }
                entryVerse = safeList.randomElement() ?? BibleVerse.shortPearls.randomElement() ?? BibleVerse.shortPearls[0]
            } else {
                entryVerse = rawVerse
            }
            
            let entry = BibleWidgetEntry(
                date: entryDate,
                verse: entryVerse,
                configuration: configuration,
                language: lang,
                visualStyle: style
            )
            entries.append(entry)
        }
        
        let reloadDate = Calendar.current.date(byAdding: .minute, value: minutesStep, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(reloadDate))
    }
    
    private func getFilteredDatabase(for category: TextCategory, configuration: ConfigurationAppIntent? = nil, family: WidgetFamily? = nil, lang: AppLanguage) -> [BibleVerse] {
        let defaults = UserDefaults(suiteName: appGroupSuiteName)
        let isPremium = defaults?.bool(forKey: "is_premium_active") ?? false
        let savedLockCatRaw = defaults?.string(forKey: "lock_screen_category") ?? "pearls"
        let activeLockCategory = LockScreenCategory(rawValue: savedLockCatRaw) ?? .pearls
        let activeLockVerses = BibleVerse.lockScreenVerses(for: (isPremium || !activeLockCategory.isPremiumRequired) ? activeLockCategory : .pearls)
        
        // Для виджетов экрана блокировки - строго короткие стихи <= 46 символов
        if let family = family, family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular {
            let pool: [BibleVerse]
            if let config = configuration {
                switch config.category {
                case .pearls:
                    pool = BibleVerse.shortPearls
                case .narekatsi:
                    pool = isPremium ? BibleVerse.shortNarekatsi : BibleVerse.shortPearls
                case .psalms:
                    pool = isPremium ? BibleVerse.shortPsalms : BibleVerse.shortPearls
                case .wisdom:
                    pool = isPremium ? BibleVerse.shortWisdom : BibleVerse.shortPearls
                case .love:
                    pool = isPremium ? BibleVerse.shortLove : BibleVerse.shortPearls
                case .faith:
                    pool = isPremium ? BibleVerse.shortFaith : BibleVerse.shortPearls
                default:
                    pool = activeLockVerses
                }
            } else {
                pool = activeLockVerses
            }
            let validPool = pool.filter { $0.text(for: lang).count <= 46 }
            return !validPool.isEmpty ? validPool : BibleVerse.shortPearls
        }
        
        var base: [BibleVerse] = BibleVerse.database
        
        if let config = configuration {
            switch config.category {
            case .pearls:
                return BibleVerse.shortPearls
            case .narekatsi:
                return isPremium ? BibleVerse.shortNarekatsi : BibleVerse.shortPearls
            case .psalms:
                return isPremium ? BibleVerse.shortPsalms : BibleVerse.shortPearls
            case .wisdom:
                return isPremium ? BibleVerse.shortWisdom : BibleVerse.shortPearls
            case .love:
                return isPremium ? BibleVerse.shortLove : BibleVerse.shortPearls
            case .faith:
                return isPremium ? BibleVerse.shortFaith : BibleVerse.shortPearls
            case .verses:
                base = BibleVerse.database.filter { !$0.isPrayer }
            case .prayers:
                base = BibleVerse.database.filter { $0.isPrayer }
            case .favorites:
                if let defaults = UserDefaults(suiteName: appGroupSuiteName),
                   let savedFavoritesData = defaults.data(forKey: "favorite_verses"),
                   let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData),
                   !decoded.isEmpty {
                    base = decoded.map { item in
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
                } else {
                    base = activeLockVerses
                }
            case .both:
                base = BibleVerse.database
            }
        }
        
        guard let family = family else {
            return base
        }
        
        switch family {
        case .accessoryRectangular, .accessoryInline, .accessoryCircular:
            let validPool = activeLockVerses.filter { $0.text(for: lang).count <= 46 }
            return !validPool.isEmpty ? validPool : BibleVerse.shortPearls
            
        case .systemSmall:
            return activeLockVerses
            
        case .systemMedium:
            let pool: [BibleVerse]
            if let config = configuration, config.category != .both && config.category != .pearls {
                pool = base
            } else {
                let savedCatRaw = defaults?.string(forKey: "medium_widget_category") ?? "all"
                let cat = HomeWidgetCategory(rawValue: savedCatRaw) ?? .all
                pool = BibleVerse.verses(for: cat, isPremium: isPremium)
            }
            let medVerses = pool.filter { $0.text(for: lang).count >= 35 && $0.text(for: lang).count <= 100 }
            return !medVerses.isEmpty ? medVerses : (!pool.isEmpty ? pool : base)
            
        case .systemLarge:
            let pool: [BibleVerse]
            if let config = configuration, config.category != .both && config.category != .pearls {
                pool = base
            } else {
                let savedCatRaw = defaults?.string(forKey: "large_widget_category") ?? "all"
                let cat = HomeWidgetCategory(rawValue: savedCatRaw) ?? .all
                pool = BibleVerse.verses(for: cat, isPremium: isPremium)
            }
            let largeVerses = pool.filter { $0.text(for: lang).count >= 75 }
            return !largeVerses.isEmpty ? largeVerses : (!pool.isEmpty ? pool : base)
            
        @unknown default:
            return base
        }
    }
    
    private func getSharedVerse(for configuration: ConfigurationAppIntent, family: WidgetFamily? = nil) -> BibleVerse {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.isEmpty ? BibleVerse.shortPearls[0] : database[0]
        let defaults = UserDefaults(suiteName: appGroupSuiteName)
        let isLockScreen: Bool = {
            guard let family = family else { return false }
            return family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular
        }()
        
        let key: String
        if let family {
            switch family {
            case .accessoryRectangular, .accessoryInline, .accessoryCircular:
                key = "currentLockScreenVerseId"
            case .systemSmall:
                key = "currentSmallVerseId"
            case .systemMedium:
                key = "currentMediumVerseId"
            case .systemLarge:
                key = "currentLargeVerseId"
            default:
                key = "currentVerseId"
            }
        } else {
            key = "currentVerseId"
        }
        
        if let def = defaults {
            if isLockScreen {
                // Строгая изоляция экрана блокировки: используем только проверенные короткие стихи (<= 46 символов)
                let idStr = def.string(forKey: "currentLockScreenVerseId")
                if let idStr, let uuid = UUID(uuidString: idStr),
                   let found = database.first(where: { $0.id == uuid }),
                   found.text(for: lang).count <= 46 {
                    return found
                }
                
                // Если сохранен отдельный короткий текст для экрана блокировки
                if let lockTextHy = def.string(forKey: "currentLockScreenTextHy"),
                   !lockTextHy.isEmpty,
                   lockTextHy.count <= 46 {
                    let textRu = def.string(forKey: "currentLockScreenTextRu") ?? ""
                    let textEn = def.string(forKey: "currentLockScreenTextEn") ?? ""
                    let refHy = def.string(forKey: "currentLockScreenRefHy") ?? ""
                    let refRu = def.string(forKey: "currentLockScreenRefRu") ?? ""
                    let refEn = def.string(forKey: "currentLockScreenRefEn") ?? ""
                    let id = idStr.flatMap { UUID(uuidString: $0) } ?? UUID()
                    let customVerse = BibleVerse(
                        id: id,
                        textHy: lockTextHy,
                        textRu: textRu,
                        textEn: textEn,
                        refHy: refHy,
                        refRu: refRu,
                        refEn: refEn
                    )
                    if customVerse.text(for: lang).count <= 46 {
                        return customVerse
                    }
                }
                
                // Категорически запрещено брать currentVerseTextHy из основного приложения для экрана блокировки!
                let safeLockList = database.filter { $0.text(for: lang).count <= 46 }
                return safeLockList.randomElement() ?? BibleVerse.shortPearls.randomElement() ?? BibleVerse.shortPearls[0]
            }
            
            // Логика для виджетов домашнего экрана (Small / Medium / Large)
            let idStr = def.string(forKey: key) ?? def.string(forKey: "currentVerseId")
            if let idStr, let uuid = UUID(uuidString: idStr), let found = database.first(where: { $0.id == uuid }) {
                return found
            }
            
            // Если стих был сгенерирован ИИ или выбран из базы SQLite
            if let textHy = def.string(forKey: "currentVerseTextHy"), !textHy.isEmpty {
                let textRu = def.string(forKey: "currentVerseTextRu") ?? ""
                let textEn = def.string(forKey: "currentVerseTextEn") ?? ""
                let refHy = def.string(forKey: "currentVerseRefHy") ?? ""
                let refRu = def.string(forKey: "currentVerseRefRu") ?? ""
                let refEn = def.string(forKey: "currentVerseRefEn") ?? ""
                let id = idStr.flatMap { UUID(uuidString: $0) } ?? UUID()
                return BibleVerse(
                    id: id,
                    textHy: textHy,
                    textRu: textRu,
                    textEn: textEn,
                    refHy: refHy,
                    refRu: refRu,
                    refEn: refEn
                )
            }
        }
        
        if isLockScreen {
            let safeLockList = database.filter { $0.text(for: lang).count <= 46 }
            return safeLockList.randomElement() ?? BibleVerse.shortPearls.randomElement() ?? BibleVerse.shortPearls[0]
        }
        
        return database.randomElement() ?? fallback
    }
    
    private func getSharedUpdateInterval() -> UpdateInterval {
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedRaw = defaults.string(forKey: updateIntervalKey),
           let interval = UpdateInterval(rawValue: savedRaw) {
            return interval
        }
        return .everyHour
    }
}

// MARK: - Вспомогательные функции локализации и тем оформления для виджета
private func getSharedLanguage() -> AppLanguage {
    let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
        return .armenian
    }
    
    if let widgetLangRaw = defaults.string(forKey: "widget_language"),
       let widgetLang = WidgetLanguage(rawValue: widgetLangRaw) {
        switch widgetLang {
        case .followApp:
            break
        case .armenian:
            return .armenian
        case .russian:
            return .russian
        case .english:
            return .english
        }
    }
    
    if let savedRaw = defaults.string(forKey: "app_language"),
       let lang = AppLanguage(rawValue: savedRaw) {
        return lang
    }
    
    // Если настройки не найдены (или нет доступа к App Group), по умолчанию для ArmenianBible используем армянский язык
    return .armenian
}

private func getSharedTheme() -> AccentColorTheme {
    let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    if let defaults = UserDefaults(suiteName: appGroupSuiteName),
       let savedRaw = defaults.string(forKey: "accent_theme"),
       let theme = AccentColorTheme(rawValue: savedRaw) {
        return theme
    }
    return .indigo
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
    
    private func getLanguage() -> AppLanguage {
        if let forced = entry.configuration.language.appLanguage {
            return forced
        }
        return getSharedLanguage()
    }

    private var isPrayerDone: Bool {
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName),
              let lastDate = defaults.object(forKey: "daily_prayer_completed_date") as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    private var isFavorite: Bool {
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName),
              let data = defaults.data(forKey: "favorite_verses"),
              let list = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            return false
        }
        return list.contains { $0.refHy == entry.verse.refHy || $0.textHy == entry.verse.textHy }
    }

    private func dynamicFontSize(for family: WidgetFamily) -> CGFloat {
        let text = entry.verse.text(for: getLanguage())
        let count = text.count
        
        switch family {
        case .accessoryRectangular:
            // Строго короткие фразы (до 46 символов): красивый, четкий и читаемый размер
            if count <= 25 { return 13.5 }
            else if count <= 36 { return 12.5 }
            else { return 11.5 }
            
        case .systemSmall:
            // Малый виджет: строго короткие стихи до 45 символов -> Крупный яркий шрифт
            if count <= 25 { return 20.5 }
            else if count <= 35 { return 19.0 }
            else { return 17.5 }
            
        case .systemMedium:
            // Средний виджет: 38-95 символов
            if count <= 55 { return 22.5 }
            else if count <= 75 { return 20.0 }
            else { return 18.0 }
            
        case .systemLarge:
            // Большой виджет: 85+ символов
            if count <= 100 { return 25.0 }
            else if count <= 150 { return 22.5 }
            else if count <= 200 { return 20.5 }
            else { return 18.5 }
            
        default:
            return 16.0
        }
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                // Прямоугольный виджет на экране блокировки: строгие 2 строки для текста стиха + гарантированно видимая ссылка внизу
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .accessoryRectangular), weight: .semibold, design: .rounded))
                        .lineLimit(2)
                        .lineSpacing(-0.5)
                        .minimumScaleFactor(0.80)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 3) {
                        Text("✝")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundColor(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
            case .accessoryInline:
                // Строчный виджет на экране блокировки над часами
                Text("\(isPrayerDone ? "✓ " : "✝️ ")\(entry.verse.reference(for: getLanguage()))")
                
            case .accessoryCircular:
                // Круглый виджет на экране блокировки
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "book.closed.fill")
                            .font(.system(size: 16))
                        Text(isPrayerDone ? "OK" : "widget_circular_text".localized(for: getLanguage()))
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                
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
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemSmall), weight: .bold, design: fontDesign))
                        .lineLimit(4)
                        .minimumScaleFactor(0.75)
                        .lineSpacing(2.0)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 2)
                    
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
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                .widgetBackground(widgetBackgroundGradient)
                
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
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemMedium), weight: .bold, design: fontDesign))
                        .lineLimit(4)
                        .minimumScaleFactor(0.78)
                        .lineSpacing(3.5)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 2)
                    
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
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                .widgetBackground(widgetBackgroundGradient)
                
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
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemLarge), weight: .bold, design: fontDesign))
                        .lineLimit(8)
                        .minimumScaleFactor(0.75)
                        .lineSpacing(5.5)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 4)
                    
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
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(borderStrokeGradient, lineWidth: 1.2)
                )
                .widgetBackground(widgetBackgroundGradient)
                
            default:
                EmptyView()
            }
        }
        .widgetURL(URL(string: "armenianbible://next-verse"))
    }
}

// MARK: - Конфигурация виджета (Widget Settings)
@available(iOS 17.0, *)
@main
struct BibleWidget: Widget {
    let kind: String = "BibleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BibleWidgetEntryView(entry: entry)
                .widgetBackground(.clear)
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
