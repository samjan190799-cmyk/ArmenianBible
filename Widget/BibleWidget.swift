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
    case both = "both"
    case verses = "verses"
    case prayers = "prayers"
    case favorites = "favorites"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Content"
    }
    
    static var caseDisplayRepresentations: [TextCategoryAppEnum: DisplayRepresentation] {
        [
            .both: DisplayRepresentation(title: "Verses & Prayers", subtitle: "Shows both Bible verses and prayers"),
            .verses: DisplayRepresentation(title: "Bible Verses Only", subtitle: "Shows only biblical verses"),
            .prayers: DisplayRepresentation(title: "Prayers Only", subtitle: "Shows only christian prayers"),
            .favorites: DisplayRepresentation(title: "Favorites Only", subtitle: "Shows only your saved favorite items")
        ]
    }
    
    var textCategory: TextCategory {
        switch self {
        case .both: return .both
        case .verses: return .verses
        case .prayers: return .prayers
        case .favorites: return .favorites
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
    
    @Parameter(title: "Content Type", default: .both)
    var category: TextCategoryAppEnum
}

// MARK: - Интерактивное намерение: Следующий стих (Next Verse Intent)
@available(iOS 17.0, *)
struct NextVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Verse"
    static var description: LocalizedStringResource = "Changes the widget to a new random Bible verse or prayer."
    
    func perform() async throws -> some IntentResult {
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        
        let categoryRaw = defaults.string(forKey: "selectedCategory") ?? "both"
        let category = TextCategory(rawValue: categoryRaw) ?? .both
        
        let database: [BibleVerse]
        switch category {
        case .verses:
            database = BibleVerse.database.filter { !$0.isPrayer }
        case .prayers:
            database = BibleVerse.database.filter { $0.isPrayer }
        case .favorites:
            if let savedFavoritesData = defaults.data(forKey: "favorite_verses"),
               let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData),
               !decoded.isEmpty {
                database = decoded.map { item in
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
                database = BibleVerse.database
            }
        case .both:
            database = BibleVerse.database
        }
        
        if let randomVerse = database.randomElement() {
            defaults.set(randomVerse.id.uuidString, forKey: "currentVerseId")
            defaults.set(randomVerse.textHy, forKey: "currentVerseTextHy")
            defaults.set(randomVerse.textRu, forKey: "currentVerseTextRu")
            defaults.set(randomVerse.textEn, forKey: "currentVerseTextEn")
            defaults.set(randomVerse.refHy, forKey: "currentVerseReferenceHy")
            defaults.set(randomVerse.refRu, forKey: "currentVerseReferenceRu")
            defaults.set(randomVerse.refEn, forKey: "currentVerseReferenceEn")
            
            let langRaw = defaults.string(forKey: "app_language") ?? "armenian"
            let lang = AppLanguage(rawValue: langRaw) ?? .armenian
            defaults.set(randomVerse.text(for: lang), forKey: "currentVerseText")
            defaults.set(randomVerse.reference(for: lang), forKey: "currentVerseReference")
            defaults.synchronize()
        }
        
        return .result()
    }
}

// MARK: - Интерактивное намерение: Отметить молитву прочитанной / выполненной
@available(iOS 17.0, *)
struct TogglePrayerCompletedWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Prayer as Completed"
    static var description: LocalizedStringResource = "Toggles today's prayer completion status."
    
    func perform() async throws -> some IntentResult {
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        
        if let lastDate = defaults.object(forKey: "daily_prayer_completed_date") as? Date,
           Calendar.current.isDateInToday(lastDate) {
            defaults.removeObject(forKey: "daily_prayer_completed_date")
        } else {
            defaults.set(Date(), forKey: "daily_prayer_completed_date")
        }
        defaults.synchronize()
        return .result()
    }
}

// MARK: - Интерактивное намерение: Добавить/Удалить из Избранного
@available(iOS 17.0, *)
struct ToggleFavoriteWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    static var description: LocalizedStringResource = "Adds or removes the current verse from favorites."
    
    func perform() async throws -> some IntentResult {
        let appGroupSuiteName = "group.com.samvel.ArmenianBible"
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return .result()
        }
        
        var favorites: [FavoriteItem] = []
        if let data = defaults.data(forKey: "favorite_verses"),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            favorites = decoded
        }
        
        let textHy = defaults.string(forKey: "currentVerseTextHy") ?? defaults.string(forKey: "currentVerseText") ?? ""
        let textRu = defaults.string(forKey: "currentVerseTextRu") ?? defaults.string(forKey: "currentVerseText") ?? ""
        let textEn = defaults.string(forKey: "currentVerseTextEn") ?? defaults.string(forKey: "currentVerseText") ?? ""
        let refHy = defaults.string(forKey: "currentVerseReferenceHy") ?? defaults.string(forKey: "currentVerseReference") ?? ""
        let refRu = defaults.string(forKey: "currentVerseReferenceRu") ?? defaults.string(forKey: "currentVerseReference") ?? ""
        let refEn = defaults.string(forKey: "currentVerseReferenceEn") ?? defaults.string(forKey: "currentVerseReference") ?? ""
        
        if let existingIdx = favorites.firstIndex(where: { $0.refHy == refHy || ($0.textHy == textHy && !textHy.isEmpty) }) {
            favorites.remove(at: existingIdx)
        } else {
            let newItem = FavoriteItem(
                id: UUID(),
                isDailyVerse: true,
                bookId: nil,
                chapter: nil,
                verseNumber: nil,
                textHy: textHy,
                textRu: textRu,
                textEn: textEn,
                refHy: refHy,
                refRu: refRu,
                refEn: refEn
            )
            favorites.insert(newItem, at: 0)
        }
        
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
}

// MARK: - Провайдер временной шкалы (Timeline Provider)
@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationAppIntent
    
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    private let updateIntervalKey = "widgetUpdateInterval"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), verse: BibleVerse.database[0], configuration: ConfigurationAppIntent())
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let verse = getSharedVerse(for: configuration)
        return SimpleEntry(date: Date(), verse: verse, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        let currentVerse = getSharedVerse(for: configuration)
        entries.append(SimpleEntry(date: currentDate, verse: currentVerse, configuration: configuration))
        
        let interval = getSharedUpdateInterval()
        
        if interval == .onTapOnly || interval == .onScreenActivation {
            let timeline = Timeline(entries: entries, policy: .never)
            return timeline
        }
        
        let calendar = Calendar.current
        var lastVerse = currentVerse
        
        let database = getFilteredDatabase(for: configuration.category.textCategory)
        let fallback = database.isEmpty ? BibleVerse.database[0] : database[0]
        
        let intervalHours: Int
        switch interval {
        case .everyHour:
            intervalHours = 1
        case .every6Hours:
            intervalHours = 6
        case .every12Hours:
            intervalHours = 12
        case .every24Hours:
            intervalHours = 24
        default:
            intervalHours = 1
        }
        
        for offset in 1..<5 {
            if let entryDate = calendar.date(byAdding: .hour, value: offset * intervalHours, to: currentDate) {
                let availableVerses = database.filter { $0.id != lastVerse.id }
                let randomVerse = availableVerses.randomElement() ?? fallback
                
                entries.append(SimpleEntry(date: entryDate, verse: randomVerse, configuration: configuration))
                lastVerse = randomVerse
            }
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    private func getFilteredDatabase(for category: TextCategory) -> [BibleVerse] {
        switch category {
        case .verses:
            return BibleVerse.database.filter { !$0.isPrayer }
        case .prayers:
            return BibleVerse.database.filter { $0.isPrayer }
        case .favorites:
            if let defaults = UserDefaults(suiteName: appGroupSuiteName),
               let savedFavoritesData = defaults.data(forKey: "favorite_verses") {
                if let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData),
                   !decoded.isEmpty {
                    // Конвертируем FavoriteItem (только те, которые применимы к виджетам) в BibleVerse
                    let dailyFavorites = decoded.filter { $0.isDailyVerse }
                    if !dailyFavorites.isEmpty {
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
                    }
                } else if let decodedOld = try? JSONDecoder().decode([BibleVerse].self, from: savedFavoritesData),
                          !decodedOld.isEmpty {
                    return decodedOld
                }
            }
            return BibleVerse.database
        case .both:
            return BibleVerse.database
        }
    }
    
    private func getSharedVerse(for configuration: ConfigurationAppIntent) -> BibleVerse {
        let category = configuration.category.textCategory
        let database = getFilteredDatabase(for: category)
        let fallback = database.isEmpty ? BibleVerse.database[0] : database[0]
        
        if let defaults = UserDefaults(suiteName: appGroupSuiteName) {
            if let savedIdString = defaults.string(forKey: "currentVerseId"),
               let savedId = UUID(uuidString: savedIdString),
               let foundVerse = BibleVerse.database.first(where: { $0.id == savedId }) {
                return foundVerse
            }
            
            if let savedText = defaults.string(forKey: textKey) {
                let normalizedSaved = savedText.normalizedForComparison
                if !normalizedSaved.isEmpty {
                    if let foundVerse = BibleVerse.database.first(where: {
                        $0.textHy.normalizedForComparison == normalizedSaved ||
                        $0.textRu.normalizedForComparison == normalizedSaved ||
                        $0.textEn.normalizedForComparison == normalizedSaved
                    }) {
                        return foundVerse
                    }
                }
                
                let savedRef = defaults.string(forKey: referenceKey) ?? ""
                return BibleVerse(text: savedText, reference: savedRef)
            }
        }
        return fallback
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
        guard let path = Bundle.main.path(forResource: language.localeCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
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

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                // Прямоугольный виджет на экране блокировки
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        if isPrayerDone {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 9))
                        }
                    }
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .lineLimit(4)
                        .minimumScaleFactor(0.35)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
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
                // Маленький виджет на домашнем экране (System Small)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        Spacer()
                        
                        // Интерактивная кнопка следующего стиха
                        Button(intent: NextVerseIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(secondaryTextColor)
                                .padding(4)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: 12.5, weight: .medium, design: .serif))
                        .lineLimit(6)
                        .minimumScaleFactor(0.42)
                        .lineSpacing(2)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 2)
                    
                    HStack {
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isPrayerDone ? .green : secondaryTextColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 9.0, weight: .bold, design: .monospaced))
                            .foregroundColor(secondaryTextColor)
                    }
                }
                .padding(11)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(widgetBackgroundGradient)
                
            case .systemMedium:
                // Средний виджет на домашнем экране (System Medium)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: 13.5, weight: .medium, design: .serif))
                        .lineLimit(5)
                        .minimumScaleFactor(0.45)
                        .lineSpacing(2.5)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 2)
                    
                    // Интерактивная панель действий
                    HStack(spacing: 8) {
                        Button(intent: NextVerseIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .bold))
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 4) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((isPrayerDone ? Color.green : accentColor).opacity(0.12))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(widgetBackgroundGradient)
                
            case .systemLarge:
                // Большой виджет на домашнем экране (System Large)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(quoteIconColor)
                        Spacer()
                        
                        Text(entry.verse.reference(for: getLanguage()))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Text(entry.verse.text(for: getLanguage()))
                        .font(.system(size: 16.5, weight: .medium, design: .serif))
                        .lineLimit(12)
                        .minimumScaleFactor(0.50)
                        .lineSpacing(4)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer(minLength: 4)
                    
                    // Интерактивная панель действий
                    HStack(spacing: 10) {
                        Button(intent: NextVerseIntent()) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .bold))
                                Text("widget_next_verse_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ToggleFavoriteWidgetIntent()) {
                            HStack(spacing: 5) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : primaryTextColor)
                                Text("widget_fav_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(intent: TogglePrayerCompletedWidgetIntent()) {
                            HStack(spacing: 5) {
                                Image(systemName: isPrayerDone ? "checkmark.circle.fill" : "hands.sparkles.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                                Text(isPrayerDone ? "widget_pray_done_btn".localized(for: getLanguage()) : "widget_pray_todo_btn".localized(for: getLanguage()))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isPrayerDone ? .green : accentColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((isPrayerDone ? Color.green : accentColor).opacity(0.12))
                            .cornerRadius(10)
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
