import Foundation
import SwiftUI
import WidgetKit
import UserNotifications

extension BibleManager {
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
    
}
