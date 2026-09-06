import Foundation
import SwiftUI
import Combine

// MARK: - Менеджер Планов Чтения Библии и Трекера Стриков
@MainActor
final class ReadingPlanManager: ObservableObject {
    static let shared = ReadingPlanManager()
    
    private let suiteName = "group.com.samvel.ArmenianBible"
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
    
    private let activePlanKey = "reading_plan_active_id"
    private let completedDaysKey = "reading_plan_completed_days"
    private let currentStreakKey = "reading_plan_current_streak"
    private let bestStreakKey = "reading_plan_best_streak"
    private let lastStreakDateKey = "reading_plan_last_streak_date"
    
    @Published var activePlanId: String? = nil
    @Published var completedDays: [String: [Int]] = [:]
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var lastStreakDate: String = ""
    
    private init() {
        loadData()
        checkStreakIntegrity()
    }
    
    // MARK: - Загрузка данных
    private func loadData() {
        self.activePlanId = defaults.string(forKey: activePlanKey)
        
        if let data = defaults.data(forKey: completedDaysKey),
           let dict = try? JSONDecoder().decode([String: [Int]].self, from: data) {
            self.completedDays = dict
        } else {
            self.completedDays = [:]
        }
        
        self.currentStreak = defaults.integer(forKey: currentStreakKey)
        self.bestStreak = defaults.integer(forKey: bestStreakKey)
        self.lastStreakDate = defaults.string(forKey: lastStreakDateKey) ?? ""
    }
    
    // MARK: - Сохранение
    private func saveCompletedDays() {
        if let data = try? JSONEncoder().encode(completedDays) {
            defaults.set(data, forKey: completedDaysKey)
        }
    }
    
    private func saveStreak() {
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        defaults.set(lastStreakDate, forKey: lastStreakDateKey)
    }
    
    // MARK: - Проверка непрерывности стрика на старте
    func checkStreakIntegrity() {
        guard !lastStreakDate.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        guard let lastDate = formatter.date(from: lastStreakDate) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        
        if let diffDays = calendar.dateComponents([.day], from: lastDay, to: today).day {
            // Если последний прочитанный день был более 1 дня назад (пропустили вчера)
            if diffDays > 1 && currentStreak > 0 {
                currentStreak = 0
                saveStreak()
            }
        }
    }
    
    // MARK: - Управление планами
    var activePlan: ReadingPlan? {
        guard let id = activePlanId else { return nil }
        return ReadingPlan.getPlan(by: id)
    }
    
    func startPlan(id: String) {
        self.activePlanId = id
        defaults.set(id, forKey: activePlanKey)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func stopActivePlan() {
        self.activePlanId = nil
        defaults.removeObject(forKey: activePlanKey)
    }
    
    func isDayCompleted(planId: String, dayNumber: Int) -> Bool {
        return completedDays[planId]?.contains(dayNumber) ?? false
    }
    
    func toggleDayCompletion(planId: String, dayNumber: Int) {
        var days = completedDays[planId] ?? []
        
        if days.contains(dayNumber) {
            days.removeAll { $0 == dayNumber }
            completedDays[planId] = days
            saveCompletedDays()
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } else {
            days.append(dayNumber)
            completedDays[planId] = days
            saveCompletedDays()
            
            // Начисляем стрик за чтение
            recordStreakForToday()
            
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    func completedDaysCount(for planId: String) -> Int {
        return completedDays[planId]?.count ?? 0
    }
    
    func progress(for planId: String) -> Double {
        guard let plan = ReadingPlan.getPlan(by: planId), plan.daysCount > 0 else { return 0.0 }
        let completed = completedDaysCount(for: planId)
        return min(1.0, Double(completed) / Double(plan.daysCount))
    }
    
    func nextIncompleteDay(for planId: String) -> ReadingPlanDay? {
        guard let plan = ReadingPlan.getPlan(by: planId) else { return nil }
        let completed = Set(completedDays[planId] ?? [])
        return plan.days.first { !completed.contains($0.dayNumber) } ?? plan.days.last
    }
    
    // MARK: - Начисление ежедневного стрика 🔥
    func recordStreakForToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let todayString = formatter.string(from: Date())
        
        // Если сегодня уже засчитан стрик — не дублируем
        if lastStreakDate == todayString {
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = formatter.date(from: lastStreakDate) {
            let lastDay = calendar.startOfDay(for: lastDate)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if diff == 1 {
                // Читали вчера — серия продолжается!
                currentStreak += 1
            } else {
                // Пропустили день или больше — начинаем новую серию
                currentStreak = 1
            }
        } else {
            // Самый первый день
            currentStreak = 1
        }
        
        lastStreakDate = todayString
        
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
        
        saveStreak()
    }
    
    // MARK: - Быстрый переход к чтению в Библии
    func openReadingInBible(target: PlanReadingTarget) {
        let manager = BibleManager.shared
        manager.deepLinkBookId = target.bookId
        manager.deepLinkChapter = target.chapter
        manager.openBibleReader()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
