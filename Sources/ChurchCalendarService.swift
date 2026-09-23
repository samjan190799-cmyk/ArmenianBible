import Foundation
import UIKit

// MARK: - Сервис Церковного календаря и Пасхалии
final class ChurchCalendarService: @unchecked Sendable {
    static let shared = ChurchCalendarService()
    
    private init() {}
    
    // MARK: - Алгоритм вычисления даты Пасхи (Григорианская Пасхалия для ААЦ)
    func calculateEaster(for year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31 // 3 = Март, 4 = Апрель
        let day = ((h + l - 7 * m + 114) % 31) + 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Asia/Yerevan") ?? TimeZone.current
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // Вспомогательная функция сдвига даты на N дней
    func dateByAdding(days: Int, to baseDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate
    }
    
    // Воскресенье, ближайшее к указанной дате (день и месяц)
    func sundayNearest(toMonth month: Int, day: Int, inYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let calendar = Calendar.current
        guard let targetDate = calendar.date(from: components) else { return Date() }
        
        let weekday = calendar.component(.weekday, from: targetDate)
        let diff = (1 - weekday)
        let adjustedDiff = (diff > 3) ? (diff - 7) : ((diff < -3) ? (diff + 7) : diff)
        return calendar.date(byAdding: .day, value: adjustedDiff, to: targetDate) ?? targetDate
    }
    
    // Вторая суббота указанного месяца
    func secondSaturday(ofMonth month: Int, inYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 12
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: components) else { return Date() }
        
        let weekday = calendar.component(.weekday, from: firstDay)
        var daysToFirstSat = (7 - weekday) % 7
        if daysToFirstSat < 0 { daysToFirstSat += 7 }
        let firstSat = calendar.date(byAdding: .day, value: daysToFirstSat, to: firstDay) ?? firstDay
        return calendar.date(byAdding: .day, value: 7, to: firstSat) ?? firstSat
    }
    
    func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.timeZone = TimeZone(identifier: "Asia/Yerevan") ?? TimeZone.current
        return Calendar.current.date(from: components) ?? Date()
    }
    

    // MARK: - Сортировка по дате приближения праздника (Ближайшие предстоящие первыми)
    func feastsSortedByApproaching(for year: Int, from baseDate: Date = Date()) -> [ArmenianChurchFeast] {
        let all = feasts(for: year)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        
        let upcoming = all.filter { calendar.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
        
        let passed = all.filter { calendar.startOfDay(for: $0.date) < today }
            .sorted { $0.date < $1.date }
        
        return upcoming + passed
    }
    
    // MARK: - Праздник на сегодня (если есть)
    func todayFeast(from baseDate: Date = Date()) -> ArmenianChurchFeast? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: baseDate)
        let allFeasts = feasts(for: year)
        return allFeasts.first { calendar.isDate($0.date, inSameDayAs: baseDate) }
    }
    
    // MARK: - Ближайший Великий праздник (Тагавар)
    func nextDaghavarFeast(from baseDate: Date = Date()) -> (feast: ArmenianChurchFeast, daysLeft: Int)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        let year = calendar.component(.year, from: today)
        
        var candidates = feasts(for: year).filter { $0.type == .daghavar && calendar.startOfDay(for: $0.date) >= today }
        
        if candidates.isEmpty {
            candidates = feasts(for: year + 1).filter { $0.type == .daghavar }
        }
        
        guard let next = candidates.first else { return nil }
        let nextDay = calendar.startOfDay(for: next.date)
        let diff = calendar.dateComponents([.day], from: today, to: nextDay).day ?? 0
        return (next, max(0, diff))
    }
    
    // MARK: - Ближайший предстоящий любой праздник
    func nextUpcomingFeast(from baseDate: Date = Date()) -> (feast: ArmenianChurchFeast, daysLeft: Int)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        let year = calendar.component(.year, from: today)
        
        var candidates = feasts(for: year).filter { calendar.startOfDay(for: $0.date) >= today }
        
        if candidates.isEmpty {
            candidates = feasts(for: year + 1)
        }
        
        guard let next = candidates.first else { return nil }
        let nextDay = calendar.startOfDay(for: next.date)
        let diff = calendar.dateComponents([.day], from: today, to: nextDay).day ?? 0
        return (next, max(0, diff))
    }
    
    // MARK: - Генератор iCalendar (.ics) файла для Apple Calendar / Google Calendar
    func generateICSFile(for year: Int, language: AppLanguage) -> URL? {
        let allFeasts = feasts(for: year)
        var icsString = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Samvel//Armenian Bible Church Calendar//HY
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:\("church_calendar_title".localized(for: language)) \(year)
        X-WR-TIMEZONE:Asia/Yerevan
        
        """
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Yerevan")
        
        let nowFormatter = DateFormatter()
        nowFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        nowFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let nowStr = nowFormatter.string(from: Date())
        
        for feast in allFeasts {
            let dtStart = dateFormatter.string(from: feast.date)
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: feast.date) ?? feast.date
            let dtEnd = dateFormatter.string(from: nextDay)
            
            let summary = feast.title(for: language)
            var desc = feast.description(for: language)
            if !feast.meaning(for: language).isEmpty {
                desc += "\\n\\n\("feast_meaning_section_spiritual".localized(for: language)): \(feast.meaning(for: language))"
            }
            if !feast.traditions(for: language).isEmpty {
                desc += "\\n\\n\("feast_meaning_section_traditions".localized(for: language)): \(feast.traditions(for: language))"
            }
            if !feast.scriptureReading.isEmpty {
                desc += "\\n\\n\("scripture_readings_title".localized(for: language)): \(feast.scriptureReading)"
            }
            if !feast.prayer(for: language).isEmpty {
                desc += "\\n\\n\("prayer_title".localized(for: language)): \(feast.prayer(for: language))"
            }
            
            icsString += """
            BEGIN:VEVENT
            UID:\(feast.id)_\(year)@armenianbible.app
            DTSTAMP:\(nowStr)
            DTSTART;VALUE=DATE:\(dtStart)
            DTEND;VALUE=DATE:\(dtEnd)
            SUMMARY:\(summary)
            DESCRIPTION:\(desc)
            STATUS:CONFIRMED
            TRANSP:TRANSPARENT
            BEGIN:VALARM
            ACTION:DISPLAY
            DESCRIPTION:\(summary)
            TRIGGER:-P1D
            END:VALARM
            END:VEVENT
            
            """
        }
        
        icsString += "END:VCALENDAR"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ArmenianChurchCalendar_\(year).ics")
        
        do {
            try icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing .ics file: \(error)")
            return nil
        }
    }
}
