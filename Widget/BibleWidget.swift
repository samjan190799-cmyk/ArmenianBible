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
    private let updateIntervalKey = "widgetUpdateInterval"
    
    // Вспомогательный метод для получения текущего стиха из App Group UserDefaults
    private func getSharedVerse() -> BibleVerse {
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedText = defaults.string(forKey: textKey),
           let savedRef = defaults.string(forKey: referenceKey) {
            return BibleVerse(text: savedText, reference: savedRef)
        }
        return BibleVerse.database[0]
    }
    
    // Вспомогательный метод для получения текущего интервала обновления
    private func getSharedUpdateInterval() -> UpdateInterval {
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedRaw = defaults.string(forKey: updateIntervalKey),
           let interval = UpdateInterval(rawValue: savedRaw) {
            return interval
        }
        return .everyHour
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
        
        let interval = getSharedUpdateInterval()
        
        // Если обновление только по тапу или при активации, не генерируем будущие автоматические обновления.
        if interval == .onTapOnly || interval == .onScreenActivation {
            let timeline = Timeline(entries: entries, policy: .never)
            completion(timeline)
            return
        }
        
        // Генерируем автоматическое обновление со смещением по времени, выбирая случайные стихи
        let calendar = Calendar.current
        var lastVerse = currentVerse
        
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
                // Выбираем случайный стих, отличный от предыдущего
                let availableVerses = BibleVerse.database.filter { $0.text != lastVerse.text }
                let randomVerse = availableVerses.randomElement() ?? BibleVerse.database[0]
                
                entries.append(SimpleEntry(date: entryDate, verse: randomVerse))
                lastVerse = randomVerse
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Интерфейс виджета для Lock Screen и Home Screen (Widget View)
struct BibleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                // Прямоугольный виджет на экране блокировки iOS (Accessory Rectangular)
                (Text(entry.verse.text)
                    .font(.system(size: 8.2, weight: .medium, design: .serif))
                + Text(" — \(entry.verse.reference)")
                    .font(.system(size: 7.2, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary))
                .lineLimit(5)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
            case .systemSmall:
                // Маленький виджет на домашнем экране (System Small)
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "A5B4FC").opacity(0.6))
                    
                    Text(entry.verse.text)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .minimumScaleFactor(0.65)
                        .lineLimit(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(entry.verse.reference)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "818CF8"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(Color(hex: "090A0F"))
                
            case .systemMedium:
                // Средний виджет на домашнем экране (System Medium)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "A5B4FC").opacity(0.6))
                        Spacer()
                    }
                    
                    Text(entry.verse.text)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .minimumScaleFactor(0.70)
                        .lineSpacing(3)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(entry.verse.reference)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "818CF8"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(Color(hex: "090A0F"))
                
            case .systemLarge:
                // Большой виджет на домашнем экране (System Large)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "A5B4FC").opacity(0.6))
                        Spacer()
                    }
                    
                    Text(entry.verse.text)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .lineSpacing(5)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(entry.verse.reference)
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "818CF8"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetBackground(Color(hex: "090A0F"))
                
            default:
                EmptyView()
            }
        }
        .widgetURL(URL(string: "armenianbible://next-verse"))
    }
}

// MARK: - Конфигурация виджета (Widget Settings)
@main
struct BibleWidget: Widget {
    let kind: String = "BibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BibleWidgetEntryView(entry: entry)
                .widgetBackground(.clear)
        }
        .configurationDisplayName("Աստվածաշունչ") // "Библия" на армянском
        .description("Աստվածաշնչի ոգեշնչող տողեր Կողպման էկրանին և Գլխավոր էկրանին:") // "Вдохновляющие стихи из Библии на экране блокировки и домашнем экране."
        .supportedFamilies([
            .accessoryRectangular,
            .systemSmall,
            .systemMedium,
            .systemLarge
        ]) // Поддерживаем Lock Screen и Home Screen виджеты
    }
}

// MARK: - Поддержка контейнерного фона для iOS 17
extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
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
