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

// MARK: - Намерение конфигурации виджета (AppIntent)
@available(iOS 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description: LocalizedStringResource = "Customize your Bible widget language and content type."
    
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
        let lockPool = BibleVerse.lockScreenVerses(for: cat)
        
        let target = targetSize
        
        // 1. Для малого виджета (System Small) - строго короткие стихи активной категории
        if target == "small" || target == "all" {
            if let v = lockPool.randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentSmallVerseId")
            }
        }
        
        // 2. Для среднего виджета (System Medium) - стихи 38-95 символов
        if target == "medium" || target == "all" {
            let medPool = BibleVerse.database.filter { $0.textHy.count >= 38 && $0.textHy.count <= 95 }
            if let v = (medPool.isEmpty ? BibleVerse.database : medPool).randomElement() {
                defaults.set(v.id.uuidString, forKey: "currentMediumVerseId")
            }
        }
        
        // 3. Для большого виджета (System Large) - глубокие отрывки от 85 символов
        if target == "large" || target == "all" {
            let largePool = BibleVerse.database.filter { $0.textHy.count >= 85 }
            if let v = (largePool.isEmpty ? BibleVerse.database : largePool).randomElement() {
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
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            verse: BibleVerse.shortPearls[0],
            configuration: ConfigurationAppIntent(),
            language: .armenian
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let verse = getSharedVerse(for: configuration, family: context.family)
        return SimpleEntry(date: Date(), verse: verse, configuration: configuration, language: lang)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [BibleWidgetEntry] = []
        let currentDate = Date()
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let interval = getSharedUpdateInterval()
        let family = context.family
        
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.isEmpty ? BibleVerse.shortPearls[0] : database[0]
        
        let minutesStep = interval.minutes
        let totalEntries = max(1, min(12, 1440 / max(1, minutesStep)))
        
        var currentVerse = getSharedVerse(for: configuration, family: family)
        
        for i in 0..<totalEntries {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: i * minutesStep, to: currentDate) else { continue }
            
            let entryVerse: BibleVerse
            if i == 0 {
                entryVerse = currentVerse
            } else {
                entryVerse = database.randomElement() ?? fallback
            }
            
            let entry = BibleWidgetEntry(
                date: entryDate,
                verse: entryVerse,
                configuration: configuration,
                language: lang
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
        
        // Для виджетов экрана блокировки
        if let family = family, family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular {
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
                default:
                    return activeLockVerses
                }
            } else {
                return activeLockVerses
            }
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
            return activeLockVerses
            
        case .systemSmall:
            return activeLockVerses
            
        case .systemMedium:
            let medVerses = base.filter { $0.text(for: lang).count >= 38 && $0.text(for: lang).count <= 95 }
            return !medVerses.isEmpty ? medVerses : base
            
        case .systemLarge:
            let largeVerses = base.filter { $0.text(for: lang).count >= 85 }
            return !largeVerses.isEmpty ? largeVerses : base
            
        @unknown default:
            return base
        }
    }
    
    private func getSharedVerse(for configuration: ConfigurationAppIntent, family: WidgetFamily? = nil) -> BibleVerse {
        let lang = configuration.language.appLanguage ?? getSharedLanguage()
        let database = getFilteredDatabase(for: configuration.category.textCategory, configuration: configuration, family: family, lang: lang)
        let fallback = database.isEmpty ? BibleVerse.shortPearls[0] : database[0]
        let defaults = UserDefaults(suiteName: appGroupSuiteName)
        
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

    // Адаптивные цвета для домашнего экрана
    private var widgetBackgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "0D0E15"), Color(hex: "151720")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "F8FAFC"), Color(hex: "E2E8F0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.95) : Color(hex: "1E293B")
    }
    
    private var accentColor: Color {
        Color(hex: getSharedTheme().colorHex)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: getSharedTheme().secondaryColorHex) : accentColor
    }
    
    private var quoteIconColor: Color {
        colorScheme == .dark ? Color(hex: getSharedTheme().secondaryColorHex).opacity(0.35) : accentColor.opacity(0.18)
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
            if count <= 28 { return 13.0 }
            else if count <= 55 { return 11.5 }
            else { return 10.5 }
            
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
                // Прямоугольный виджет на экране блокировки: адаптивный читаемый текст и гарантированная ссылка со стихом
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .accessoryRectangular), weight: .semibold, design: .rounded))
                        .lineLimit(3)
                        .lineSpacing(-0.5)
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 3) {
                        Text("✝")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                            .foregroundColor(.secondary)
                    }
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
                // Маленький виджет на домашнем экране (System Small 2x2): крупный четкий шрифт для слабовидящих (только короткие цитаты до 45 символов)
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
                                .background(Color.primary.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemSmall), weight: .bold, design: .rounded))
                        .lineLimit(4)
                        .minimumScaleFactor(0.75)
                        .lineSpacing(2.0)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 2)
                    
                    HStack {
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isPrayerDone ? .green : secondaryTextColor.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 11.0, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                            .foregroundColor(secondaryTextColor)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(widgetBackgroundGradient)
                
            case .systemMedium:
                // Средний виджет на домашнем экране (System Medium 4x2): просторный крупный текст
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 13.0, weight: .bold, design: .rounded))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemMedium), weight: .bold, design: .rounded))
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
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.08))
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background((isFavorite ? Color.red : Color.primary).opacity(0.08))
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background((isPrayerDone ? Color.green : accentColor).opacity(0.14))
                            .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(13)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(widgetBackgroundGradient)
                
            case .systemLarge:
                // Большой виджет на домашнем экране (System Large 4x4): максимальный комфорт и крупный кегль для слабовидящих
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 15.5, weight: .bold, design: .rounded))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: dynamicFontSize(for: .systemLarge), weight: .bold, design: .rounded))
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
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.primary.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background((isFavorite ? Color.red : Color.primary).opacity(0.08))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background((isPrayerDone ? Color.green : accentColor).opacity(0.14))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
