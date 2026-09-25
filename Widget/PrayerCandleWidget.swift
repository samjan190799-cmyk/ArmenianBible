import WidgetKit
import SwiftUI

// MARK: - Модель записи временной шкалы виджета свечи (PrayerCandleEntry)
struct PrayerCandleEntry: TimelineEntry {
    let date: Date
    let candle: PrayerCandle?
    let language: AppLanguage
}

// MARK: - Провайдер временной шкалы (PrayerCandleProvider)
struct PrayerCandleProvider: TimelineProvider {
    typealias Entry = PrayerCandleEntry
    
    func placeholder(in context: Context) -> PrayerCandleEntry {
        let sample = PrayerCandle(
            personName: "Աննա",
            intention: .health,
            customPrayer: "Տէր, պահպանեա և օրհնեա զՔո ծառային:",
            tier: .rewarded,
            litDate: Date()
        )
        return PrayerCandleEntry(date: Date(), candle: sample, language: getSharedLanguage())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PrayerCandleEntry) -> Void) {
        let candle = loadCurrentActiveCandle() ?? placeholder(in: context).candle
        let entry = PrayerCandleEntry(date: Date(), candle: candle, language: getSharedLanguage())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerCandleEntry>) -> Void) {
        let currentCandle = loadCurrentActiveCandle()
        let language = getSharedLanguage()
        let now = Date()
        
        var entries: [PrayerCandleEntry] = []
        
        if let candle = currentCandle {
            let expirationDate = candle.litDate.addingTimeInterval(candle.duration)
            if expirationDate > now {
                // Текущая запись
                entries.append(PrayerCandleEntry(date: now, candle: candle, language: language))
                
                // Промежуточные записи каждый час для обновления визуала шкалы
                var intermediate = now.addingTimeInterval(3600)
                while intermediate < expirationDate {
                    entries.append(PrayerCandleEntry(date: intermediate, candle: candle, language: language))
                    intermediate = intermediate.addingTimeInterval(3600)
                }
                
                // Запись в момент угасания свечи
                entries.append(PrayerCandleEntry(date: expirationDate, candle: nil, language: language))
            } else {
                entries.append(PrayerCandleEntry(date: now, candle: nil, language: language))
            }
        } else {
            entries.append(PrayerCandleEntry(date: now, candle: nil, language: language))
        }
        
        let nextUpdate = currentCandle != nil
            ? min(now.addingTimeInterval(1800), currentCandle!.litDate.addingTimeInterval(currentCandle!.duration))
            : now.addingTimeInterval(1800)
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentActiveCandle() -> PrayerCandle? {
        guard let data = AppGroupConstants.sharedDefaults.data(forKey: CandleConstants.candlesStorageKey)
                ?? UserDefaults.standard.data(forKey: CandleConstants.candlesStorageKey),
              let list = try? JSONDecoder().decode([PrayerCandle].self, from: data) else {
            return nil
        }
        let now = Date()
        // Возвращаем первую горящую свечу
        return list.first { candle in
            candle.litDate.addingTimeInterval(candle.duration) > now
        }
    }
    
    private func getSharedLanguage() -> AppLanguage {
        if let langStr = AppGroupConstants.sharedString(forKey: "app_language"),
           let lang = AppLanguage(rawValue: langStr) {
            return lang
        }
        return .armenian
    }
}

// MARK: - Главное представление виджета свечи (PrayerCandleWidgetEntryView)
struct PrayerCandleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PrayerCandleEntry
    
    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                CandleAccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                CandleAccessoryRectangularView(entry: entry)
            case .accessoryInline:
                CandleAccessoryInlineView(entry: entry)
            case .systemSmall:
                CandleSystemSmallView(entry: entry)
            case .systemMedium:
                CandleSystemMediumView(entry: entry)
            default:
                CandleSystemSmallView(entry: entry)
            }
        }
        .widgetBackground(Color(hex: "090A0F"))
        .widgetURL(URL(string: "armenianbible://sanctuary"))
    }
}

// MARK: - 1. Экран блокировки: Круглый виджет (Accessory Circular)
struct CandleAccessoryCircularView: View {
    let entry: PrayerCandleEntry
    
    var body: some View {
        if let candle = entry.candle, candle.isLit {
            let total = candle.duration
            let elapsed = Date().timeIntervalSince(candle.litDate)
            let progress = max(0.0, min(1.0, 1.0 - (elapsed / total)))
            
            let remaining = candle.expirationDate.timeIntervalSince(Date())
            Gauge(value: progress, in: 0...1) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                if remaining < 3600 {
                    Text("\(max(1, Int(ceil(remaining / 60.0))))m")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                } else {
                    Text("\(candle.hoursRemaining)h")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Color(hex: "F59E0B"))
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "flame")
                        .font(.system(size: 16))
                    Text(entry.language == .armenian ? "Մոմ" : (entry.language == .russian ? "Свеча" : "Vigil"))
                        .font(.system(size: 8, weight: .bold))
                }
            }
        }
    }
}

// MARK: - 2. Экран блокировки: Прямоугольный виджет (Accessory Rectangular)
struct CandleAccessoryRectangularView: View {
    let entry: PrayerCandleEntry
    
    var body: some View {
        if let candle = entry.candle, candle.isLit {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                    Text(candle.personName.isEmpty ? candle.intention.title(for: entry.language) : candle.personName)
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Text(candle.intention.title(for: entry.language))
                        .font(.system(size: 10, weight: .medium))
                    Text("•")
                        .font(.system(size: 9))
                    Text(candle.expirationDate, style: .timer)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .opacity(0.85)
                
                Text(prayerSummary(for: candle, language: entry.language))
                    .font(.system(size: 9))
                    .opacity(0.65)
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 12))
                    Text(entry.language == .armenian ? "Տաճարային Մոմ" : (entry.language == .russian ? "Храмовая Свеча" : "Sanctuary Candle"))
                        .font(.system(size: 12, weight: .bold, design: .serif))
                }
                Text(entry.language == .armenian ? "Վառեք մոմ սրտի լռության մեջ" : (entry.language == .russian ? "Зажгите свечу в притворе" : "Light a candle in sanctuary"))
                    .font(.system(size: 10))
                    .opacity(0.75)
            }
        }
    }
}

// MARK: - 3. Экран блокировки: Строка над часами (Accessory Inline)
struct CandleAccessoryInlineView: View {
    let entry: PrayerCandleEntry
    
    var body: some View {
        if let candle = entry.candle, candle.isLit {
            let name = candle.personName.isEmpty ? candle.intention.title(for: entry.language) : candle.personName
            ViewThatFits {
                HStack(spacing: 3) {
                    Text("🕯️ \(name):")
                    Text(candle.expirationDate, style: .timer)
                }
                Text("🕯️ \(name)")
            }
        } else {
            Text(entry.language == .armenian ? "🕯️ Տաճարային Մոմ" : (entry.language == .russian ? "🕯️ Храмовая Свеча" : "🕯️ Sacred Vigil"))
        }
    }
}

// MARK: - 4. Главный экран: Квадратный виджет (System Small)
struct CandleSystemSmallView: View {
    let entry: PrayerCandleEntry
    
    var body: some View {
        ZStack {
            Color(hex: "090A0F")
            
            RadialGradient(
                colors: [
                    Color(hex: "F59E0B").opacity(entry.candle != nil ? 0.35 : 0.08),
                    Color(hex: "D97706").opacity(entry.candle != nil ? 0.12 : 0.03),
                    Color.clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 90
            )
            
            if let candle = entry.candle, candle.isLit {
                VStack(spacing: 5) {
                    WidgetWaxCandleView(tier: candle.tier, isLit: true)
                        .padding(.top, 4)
                    
                    Text(candle.personName.isEmpty ? candle.intention.title(for: entry.language) : candle.personName)
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                    
                    HStack(spacing: 3) {
                        Image(systemName: candle.intention.icon)
                            .font(.system(size: 8))
                        Text(candle.intention.title(for: entry.language))
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "F59E0B"))
                    .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("⏳")
                            .font(.system(size: 8))
                        Text(candle.expirationDate, style: .timer)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 4)
                }
            } else {
                VStack(spacing: 7) {
                    Image(systemName: "flame")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "F59E0B").opacity(0.55))
                    
                    Text(entry.language == .armenian ? "Տաճարային Մոմ" : (entry.language == .russian ? "Храмовая Свеча" : "Sanctuary Candle"))
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text(entry.language == .armenian ? "Վառեք մոմ սրտի լռության մեջ" : (entry.language == .russian ? "Зажгите свечу в тишине сердца" : "Light a candle in silent prayer"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    HStack(spacing: 4) {
                        Text(entry.language == .armenian ? "Վառել" : (entry.language == .russian ? "Зажечь" : "Light"))
                            .font(.system(size: 11, weight: .bold, design: .serif))
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4.5)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .padding(8)
            }
        }
    }
}

// MARK: - 5. Главный экран: Средний виджет (System Medium)
struct CandleSystemMediumView: View {
    let entry: PrayerCandleEntry
    
    var body: some View {
        ZStack {
            Color(hex: "090A0F")
            
            HStack(spacing: 14) {
                // Левая колонка со свечой
                ZStack {
                    RadialGradient(
                        colors: [
                            Color(hex: "F59E0B").opacity(entry.candle != nil ? 0.38 : 0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 8,
                        endRadius: 75
                    )
                    
                    VStack(spacing: 5) {
                        if let candle = entry.candle, candle.isLit {
                            WidgetWaxCandleView(tier: candle.tier, isLit: true)
                                .padding(.top, 2)
                            
                            HStack(spacing: 3) {
                                Text("⏳")
                                    .font(.system(size: 7))
                                Text(candle.expirationDate, style: .timer)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        } else {
                            Image(systemName: "flame")
                                .font(.system(size: 34))
                                .foregroundColor(Color(hex: "F59E0B").opacity(0.45))
                                .padding(.top, 10)
                            
                            Text(entry.language == .armenian ? "Մոմավառություն" : (entry.language == .russian ? "Притвор" : "Sanctuary"))
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(width: 82)
                
                // Вертикальный разделитель
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 14)
                
                // Правая колонка с молитвой и именем
                VStack(alignment: .leading, spacing: 6) {
                    if let candle = entry.candle, candle.isLit {
                        HStack {
                            Text(candle.personName.isEmpty ? candle.intention.title(for: entry.language) : candle.personName)
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            HStack(spacing: 3) {
                                Image(systemName: candle.intention.icon)
                                    .font(.system(size: 8))
                                Text(candle.intention.title(for: entry.language))
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "F59E0B"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color(hex: "F59E0B").opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        Text(prayerSummary(for: candle, language: entry.language))
                            .font(.system(size: 11.5, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(3)
                            .lineLimit(3)
                        
                        Spacer(minLength: 0)
                        
                        HStack {
                            Text(entry.language == .armenian ? "Տաճարային Աղոթք" : (entry.language == .russian ? "Храмовая Молитва" : "Sanctuary Vigil"))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Spacer()
                            
                            HStack(spacing: 3) {
                                Text(entry.language == .armenian ? "Բացել" : (entry.language == .russian ? "Открыть" : "Open"))
                                    .font(.system(size: 10, weight: .bold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(Color(hex: "F59E0B"))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.language == .armenian ? "Տաճարային Մոմավառություն" : (entry.language == .russian ? "Храмовая Молитва и Свечи" : "Sacred Sanctuary & Vigil"))
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            Text(entry.language == .armenian ? "Վառեք մոմ սրտի լռության մեջ՝ աղոթելով հարազատների առողջության, խաղաղության համար:" : (entry.language == .russian ? "Зажгите свечу в благоговейной тишине сердца о здравии и мире близких." : "Light a vigil candle in quiet prayer for loved ones and peace."))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(2)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11))
                                Text(entry.language == .armenian ? "Վառել Մոմ" : (entry.language == .russian ? "Зажечь свечу" : "Light Candle"))
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.trailing, 14)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Детализированная восковая свеча для снимка виджета (WidgetWaxCandleView)
struct WidgetWaxCandleView: View {
    let tier: CandleTier
    let isLit: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isLit {
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 1,
                                endRadius: 14
                            )
                        )
                        .frame(width: 26, height: 26)
                        .offset(y: -4)
                    
                    Capsule()
                        .fill(Color(hex: "1F2937"))
                        .frame(width: 1.5, height: 5)
                        .offset(y: 2)
                    
                    Capsule()
                        .fill(Color(hex: "60A5FA").opacity(0.85))
                        .frame(width: 4, height: 4)
                        .offset(y: -1)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFFBEB"), Color(hex: "FEF08A"), Color(hex: "F59E0B"), Color(hex: "EA580C")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "F59E0B").opacity(0.6), radius: 4)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white)
                        .offset(y: -1)
                }
                .frame(height: 20)
                .offset(y: 4)
                .zIndex(2)
            } else {
                Capsule()
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 1.5, height: 6)
                    .offset(y: 3)
            }
            
            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color(hex: "FEF9C3"))
                    .frame(width: 14, height: 3)
                    .zIndex(1)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FEF08A"),
                                Color(hex: "FDE047"),
                                Color(hex: "F59E0B"),
                                Color(hex: "D97706"),
                                Color(hex: "92400E")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 34)
                    .overlay(
                        HStack {
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.35), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 4)
                            .offset(x: 2)
                            Spacer()
                        }
                    )
            }
            .zIndex(1)
            
            VStack(spacing: 0) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FDE68A"), Color(hex: "D97706"), Color(hex: "78350F")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 22, height: 2.5)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "D97706"), Color(hex: "92400E"), Color(hex: "451A03")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 3.5)
            }
        }
    }
}

// MARK: - Вспомогательные функции
private func prayerSummary(for candle: PrayerCandle, language: AppLanguage) -> String {
    if let custom = candle.customPrayer, !custom.isEmpty {
        return custom
    }
    return candle.intention.defaultPrayer(for: language)
}

// MARK: - Конфигурация виджета (Widget Definition)
@available(iOS 17.0, *)
struct PrayerCandleWidget: Widget {
    let kind: String = "PrayerCandleWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerCandleProvider()) { entry in
            PrayerCandleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Տաճարային Մոմ • Храмовая Свеча")
        .description("Վառվող մոմի և աղոթքի վիջեթ • Виджет горящей свечи и молитвы")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .disableContentMarginsIfNeeded()
    }
}
