import WidgetKit
import SwiftUI

// MARK: - Модель записи таймлайна (Timeline Entry)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let verse: BibleVerse
}

// MARK: - Провайдер временной шкалы (Timeline Provider)
struct Provider: TimelineProvider {
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    
    // Вспомогательный метод для получения текущего стиха из App Group UserDefaults
    private func getSharedVerse() -> BibleVerse {
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedText = defaults.string(forKey: textKey),
           let savedRef = defaults.string(forKey: referenceKey) {
            return BibleVerse(text: savedText, reference: savedRef)
        }
        return BibleVerse.database[0]
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), verse: BibleVerse.database[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), verse: getSharedVerse())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // 1. Первая запись отображает стих, выбранный пользователем в приложении прямо сейчас
        let currentVerse = getSharedVerse()
        entries.append(SimpleEntry(date: currentDate, verse: currentVerse))
        
        // 2. Генерируем автоматическое обновление каждый час на 5 часов вперед, выбирая случайные стихи
        // Это обеспечивает автономную смену стихов на экране блокировки
        let calendar = Calendar.current
        var lastVerse = currentVerse
        
        for hourOffset in 1..<5 {
            if let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                // Выбираем случайный стих, отличный от предыдущего
                let availableVerses = BibleVerse.database.filter { $0.text != lastVerse.text }
                let randomVerse = availableVerses.randomElement() ?? BibleVerse.database[0]
                
                entries.append(SimpleEntry(date: entryDate, verse: randomVerse))
                lastVerse = randomVerse
            }
        }
        
        // Создаем таймлайн. В конце 5-часового цикла мы просим систему обновить таймлайн заново
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Интерфейс виджета для Lock Screen (Widget View)
struct BibleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // Специальный дизайн для прямоугольной области на экране блокировки iOS
            VStack(alignment: .leading, spacing: 3) {
                // Текст стиха на армянском языке с засечками и масштабированием под размер виджета
                Text(entry.verse.text)
                    .font(.system(size: 11.5, weight: .medium, design: .serif))
                    .minimumScaleFactor(0.78)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Ссылка на стих мелким полупрозрачным шрифтом
                Text(entry.verse.reference)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 2)
            
        default:
            // Резервный вариант для обычного виджета на домашнем экране (systemSmall)
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(entry.verse.text)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .minimumScaleFactor(0.8)
                    .lineLimit(4)
                
                Spacer()
                
                Text(entry.verse.reference)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Конфигурация виджета (Widget Settings)
@main
struct BibleWidget: Widget {
    let kind: String = "BibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BibleWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget) // Поддержка iOS 17 контейнерного фона
        }
        .configurationDisplayName("Աստվածաշունչ") // "Библия" на армянском
        .description("Աստվածաշնչի ոգեշնչող տողեր Կողպման էկրանին:") // "Вдохновляющие стихи из Библии на экране блокировки."
        .supportedFamilies([.accessoryRectangular]) // Поддерживаем только прямоугольный виджет Lock Screen
    }
}
