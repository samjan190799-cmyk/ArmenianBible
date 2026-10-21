import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Постеры как отдельные виджеты в галерее
// Раньше постеры были только стилями общего виджета «Библия» и в галерее не показывались.
// Теперь у каждого свой виджет (малый, средний, большой); отрисовку берут из BibleWidgetEntryView.

@available(iOS 17.0, *)
struct PosterConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Poster Widget"
    static var description: LocalizedStringResource = "Choose the language and the kind of verses for this poster widget."

    @Parameter(title: "Language", default: .followApp)
    var language: WidgetLanguageAppEnum

    @Parameter(title: "Content Style", default: .pearls)
    var category: TextCategoryAppEnum
}

/// Берёт стих и расписание у общего провайдера и подставляет фиксированный фон-постер
@available(iOS 17.0, *)
struct PosterProvider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = PosterConfigurationAppIntent

    let style: WidgetVisualStyle
    private let base = Provider()

    private func baseConfiguration(_ configuration: PosterConfigurationAppIntent) -> ConfigurationAppIntent {
        var converted = ConfigurationAppIntent()
        converted.visualStyle = .followApp
        converted.language = configuration.language
        converted.category = configuration.category
        return converted
    }

    /// Фон у виджета всегда свой; пометку PRO без Premium рисует сам виджет
    private func restyled(_ entry: SimpleEntry) -> SimpleEntry {
        SimpleEntry(
            date: entry.date,
            verse: entry.verse,
            configuration: entry.configuration,
            language: entry.language,
            visualStyle: style,
            styleTimestamp: entry.styleTimestamp
        )
    }

    func placeholder(in context: Context) -> SimpleEntry {
        restyled(base.placeholder(in: context))
    }

    func snapshot(for configuration: PosterConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let entry = await base.snapshot(for: baseConfiguration(configuration), in: context)
        return restyled(entry)
    }

    func timeline(for configuration: PosterConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let timeline = await base.timeline(for: baseConfiguration(configuration), in: context)
        return Timeline(entries: timeline.entries.map { restyled($0) }, policy: timeline.policy)
    }
}

@available(iOS 17.0, *)
private func posterConfiguration(kind: String, style: WidgetVisualStyle) -> some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: PosterConfigurationAppIntent.self, provider: PosterProvider(style: style)) { entry in
        BibleWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(style.localizedName(for: getSharedLanguage()))
    .description(style.localizedSubtitle(for: getSharedLanguage()))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .disableContentMarginsIfNeeded()
}

@available(iOS 17.0, *)
struct PosterAraratWidget: Widget {
    var body: some WidgetConfiguration { posterConfiguration(kind: "PosterAraratWidget", style: .posterArarat) }
}

@available(iOS 17.0, *)
struct PosterKhachkarWidget: Widget {
    var body: some WidgetConfiguration { posterConfiguration(kind: "PosterKhachkarWidget", style: .posterKhachkar) }
}

@available(iOS 17.0, *)
struct PosterParchmentWidget: Widget {
    var body: some WidgetConfiguration { posterConfiguration(kind: "PosterParchmentWidget", style: .posterParchment) }
}

@available(iOS 17.0, *)
struct PosterNightWidget: Widget {
    var body: some WidgetConfiguration { posterConfiguration(kind: "PosterNightWidget", style: .posterNight) }
}
