import Foundation
import SwiftUI
import Combine

// MARK: - Модель Награды / Значка
struct AchievementBadge: Identifiable, Codable, Hashable {
    let id: String
    let icon: String
    let gradientColors: [String]
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let descHy: String
    let descRu: String
    let descEn: String
    let requiredCount: Int
    
    var currentProgress: Int = 0
    var isUnlocked: Bool = false
    var unlockedDate: Date? = nil
    
    func title(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func description(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return descHy
        case .russian: return descRu
        case .english: return descEn
        }
    }
    
    var progressRatio: Double {
        guard requiredCount > 0 else { return 1.0 }
        return min(1.0, Double(currentProgress) / Double(requiredCount))
    }
}

// MARK: - Менеджер Наград и Достижений
@MainActor
final class AchievementsManager: ObservableObject {
    static let shared = AchievementsManager()
    
    private let suiteName = "group.com.samvel.ArmenianBible"
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
    
    @Published var badges: [AchievementBadge] = []
    @Published var newlyUnlockedBadges: [AchievementBadge] = []
    
    // Статистика пользователя
    @Published var totalCorrectAnswers: Int = 0
    @Published var completedRoundsCount: Int = 0
    @Published var perfectRoundsCount: Int = 0
    @Published var oldTestamentCorrect: Int = 0
    @Published var gospelsCorrect: Int = 0
    @Published var newTestamentCorrect: Int = 0
    @Published var churchHistoryCorrect: Int = 0
    @Published var versesCorrect: Int = 0
    
    private init() {
        loadStats()
        setupDefaultBadges()
        refreshBadgesState()
    }
    
    // MARK: - Определение всех наград
    private func setupDefaultBadges() {
        let initialBadges: [AchievementBadge] = [
            AchievementBadge(
                id: "first_quiz",
                icon: "flag.fill",
                gradientColors: ["#3B82F6", "#1D4ED8"],
                titleHy: "Առաջին Քայլեր",
                titleRu: "Первые шаги",
                titleEn: "First Steps",
                descHy: "Ավարտեք ձեր առաջին աստվածաշնչյան վիկտորինան:",
                descRu: "Завершите свою первую библейскую викторину.",
                descEn: "Complete your very first Bible trivia quiz.",
                requiredCount: 1
            ),
            AchievementBadge(
                id: "perfect_round",
                icon: "sparkles",
                gradientColors: ["#F59E0B", "#D97706"],
                titleHy: "Անթերի Արդյունք",
                titleRu: "Безупречный результат",
                titleEn: "Flawless Round",
                descHy: "Պատասխանեք 100% ճիշտ բոլոր հարցերին մեկ փուլում:",
                descRu: "Ответьте на 100% вопросов правильно за один раунд.",
                descEn: "Score 100% correct answers in a single round.",
                requiredCount: 1
            ),
            AchievementBadge(
                id: "old_testament_scholar",
                icon: "scroll.fill",
                gradientColors: ["#D97706", "#B45309"],
                titleHy: "Հին Կտակարանի Գիտակ",
                titleRu: "Знаток Ветхого Завета",
                titleEn: "Old Testament Scholar",
                descHy: "Տվեք 20 ճիշտ պատասխան Հին Կտակարանի հարցերին:",
                descRu: "Дайте 20 правильных ответов по Ветхому Завету.",
                descEn: "Answer 20 Old Testament questions correctly.",
                requiredCount: 20
            ),
            AchievementBadge(
                id: "gospels_scholar",
                icon: "book.closed.fill",
                gradientColors: ["#10B981", "#059669"],
                titleHy: "Ավետարանների Գիտակ",
                titleRu: "Знаток Евангелий",
                titleEn: "Gospels Scholar",
                descHy: "Տվեք 20 ճիշտ պատասխան Ավետարանների հարցերին:",
                descRu: "Дайте 20 правильных ответов по Евангелиям.",
                descEn: "Answer 20 Gospel questions correctly.",
                requiredCount: 20
            ),
            AchievementBadge(
                id: "apostolic_student",
                icon: "cross.fill",
                gradientColors: ["#8B5CF6", "#6D28D9"],
                titleHy: "Առաքելական Աշակերտ",
                titleRu: "Апостольский ученик",
                titleEn: "Apostolic Student",
                descHy: "Տվեք 20 ճիշտ պատասխան Նոր Կտակարանի հարցերին:",
                descRu: "Дайте 20 правильных ответов по Новому Завету.",
                descEn: "Answer 20 New Testament questions correctly.",
                requiredCount: 20
            ),
            AchievementBadge(
                id: "church_history_guardian",
                icon: "building.columns.fill",
                gradientColors: ["#EC4899", "#BE185D"],
                titleHy: "Հայ Եկեղեցու Պահապան",
                titleRu: "Хранитель Армянского Наследия",
                titleEn: "Armenian Heritage Guardian",
                descHy: "Տվեք 15 ճիշտ պատասխան Հայ Եկեղեցու և սրբերի պատմությունից:",
                descRu: "Дайте 15 правильных ответов по истории Армянской Церкви и святых.",
                descEn: "Answer 15 Armenian Church history and saints questions correctly.",
                requiredCount: 15
            ),
            AchievementBadge(
                id: "master_of_verses",
                icon: "quote.bubble.fill",
                gradientColors: ["#06B6D4", "#0891B2"],
                titleHy: "Ոսկե Խոսքերի Վարպետ",
                titleRu: "Мастер Библейских Цитат",
                titleEn: "Master of Scripture Quotes",
                descHy: "Ճիշտ գուշակեք 15 աստվածաշնչյան համարների ծագումը:",
                descRu: "Правильно определите 15 золотых стихов Библии.",
                descEn: "Correctly identify 15 Scripture verses and quotes.",
                requiredCount: 15
            ),
            AchievementBadge(
                id: "bible_sage_50",
                icon: "star.circle.fill",
                gradientColors: ["#F97316", "#C2410C"],
                titleHy: "Աստվածաշնչյան Իմաստուն",
                titleRu: "Библейский Мудрец",
                titleEn: "Bible Sage",
                descHy: "Հավաքեք 50 ճիշտ պատասխան ընդհանուր վիկտորինաներում:",
                descRu: "Наберите 50 правильных ответов суммарно.",
                descEn: "Score 50 correct answers in total across all quizzes.",
                requiredCount: 50
            ),
            AchievementBadge(
                id: "theologian_100",
                icon: "crown.fill",
                gradientColors: ["#EAB308", "#A16207"],
                titleHy: "Մեծ Աստվածաբան",
                titleRu: "Великий Богослов",
                titleEn: "Grand Theologian",
                descHy: "Հասեք 100 ճիշտ պատասխանի և դարձեք իսկական գիտակ:",
                descRu: "Достигните 100 правильных ответов и станьте знатоком Писания.",
                descEn: "Reach 100 correct answers to become a true scholar.",
                requiredCount: 100
            ),
            AchievementBadge(
                id: "quiz_veteran_10",
                icon: "medal.fill",
                gradientColors: ["#6366F1", "#4338CA"],
                titleHy: "Հավատարիմ Ուսումնասիրող",
                titleRu: "Преданный исследователь",
                titleEn: "Faithful Student",
                descHy: "Ավարտեք 10 վիկտորինայի փուլ:",
                descRu: "Завершите 10 раундов викторины.",
                descEn: "Complete 10 full quiz rounds.",
                requiredCount: 10
            )
        ]
        
        self.badges = initialBadges
    }
    
    // MARK: - Загрузка сохраненной статистики
    private func loadStats() {
        totalCorrectAnswers = defaults.integer(forKey: "ach_total_correct")
        completedRoundsCount = defaults.integer(forKey: "ach_completed_rounds")
        perfectRoundsCount = defaults.integer(forKey: "ach_perfect_rounds")
        oldTestamentCorrect = defaults.integer(forKey: "ach_ot_correct")
        gospelsCorrect = defaults.integer(forKey: "ach_gospels_correct")
        newTestamentCorrect = defaults.integer(forKey: "ach_nt_correct")
        churchHistoryCorrect = defaults.integer(forKey: "ach_church_correct")
        versesCorrect = defaults.integer(forKey: "ach_verses_correct")
    }
    
    // MARK: - Сохранение статистики
    private func saveStats() {
        defaults.set(totalCorrectAnswers, forKey: "ach_total_correct")
        defaults.set(completedRoundsCount, forKey: "ach_completed_rounds")
        defaults.set(perfectRoundsCount, forKey: "ach_perfect_rounds")
        defaults.set(oldTestamentCorrect, forKey: "ach_ot_correct")
        defaults.set(gospelsCorrect, forKey: "ach_gospels_correct")
        defaults.set(newTestamentCorrect, forKey: "ach_nt_correct")
        defaults.set(churchHistoryCorrect, forKey: "ach_church_correct")
        defaults.set(versesCorrect, forKey: "ach_verses_correct")
    }
    
    // MARK: - Обновление состояния значков
    func refreshBadgesState() {
        var updated: [AchievementBadge] = []
        
        for var badge in badges {
            let progress: Int
            switch badge.id {
            case "first_quiz":
                progress = completedRoundsCount
            case "perfect_round":
                progress = perfectRoundsCount
            case "old_testament_scholar":
                progress = oldTestamentCorrect
            case "gospels_scholar":
                progress = gospelsCorrect
            case "apostolic_student":
                progress = newTestamentCorrect
            case "church_history_guardian":
                progress = churchHistoryCorrect
            case "master_of_verses":
                progress = versesCorrect
            case "bible_sage_50", "theologian_100":
                progress = totalCorrectAnswers
            case "quiz_veteran_10":
                progress = completedRoundsCount
            default:
                progress = 0
            }
            
            badge.currentProgress = progress
            let wasUnlocked = defaults.bool(forKey: "badge_unlocked_\(badge.id)")
            if wasUnlocked || progress >= badge.requiredCount {
                badge.isUnlocked = true
                if !wasUnlocked {
                    defaults.set(true, forKey: "badge_unlocked_\(badge.id)")
                    defaults.set(Date().timeIntervalSince1970, forKey: "badge_date_\(badge.id)")
                }
                let savedDate = defaults.double(forKey: "badge_date_\(badge.id)")
                badge.unlockedDate = savedDate > 0 ? Date(timeIntervalSince1970: savedDate) : Date()
            }
            updated.append(badge)
        }
        
        self.badges = updated
    }
    
    // MARK: - Запись результатов раунда с точным распределением по категориям
    func recordQuizResult(score: Int, total: Int, categoryBreakdown: [QuizCategory: Int]) -> [AchievementBadge] {
        completedRoundsCount += 1
        totalCorrectAnswers += score
        
        if score == total && total >= 5 {
            perfectRoundsCount += 1
        }
        
        oldTestamentCorrect += categoryBreakdown[.oldTestament] ?? 0
        gospelsCorrect += categoryBreakdown[.gospels] ?? 0
        newTestamentCorrect += categoryBreakdown[.newTestament] ?? 0
        churchHistoryCorrect += categoryBreakdown[.churchHistory] ?? 0
        versesCorrect += categoryBreakdown[.verses] ?? 0
        
        saveStats()
        return evaluateBadges()
    }
    
    // MARK: - Упрощенная запись с равномерным распределением (обратная совместимость)
    @discardableResult
    func recordQuizResult(score: Int, total: Int, category: QuizCategory) -> [AchievementBadge] {
        completedRoundsCount += 1
        totalCorrectAnswers += score
        
        if score == total && total >= 5 {
            perfectRoundsCount += 1
        }
        
        switch category {
        case .all:
            // Распределяем честно без раздувания: сумма частей строго равна score
            let base = score / 4
            var remainder = score % 4
            
            oldTestamentCorrect += base + (remainder > 0 ? 1 : 0); if remainder > 0 { remainder -= 1 }
            gospelsCorrect += base + (remainder > 0 ? 1 : 0); if remainder > 0 { remainder -= 1 }
            newTestamentCorrect += base + (remainder > 0 ? 1 : 0); if remainder > 0 { remainder -= 1 }
            churchHistoryCorrect += base + (remainder > 0 ? 1 : 0)
        case .oldTestament:
            oldTestamentCorrect += score
        case .gospels:
            gospelsCorrect += score
        case .newTestament:
            newTestamentCorrect += score
        case .churchHistory:
            churchHistoryCorrect += score
        case .verses:
            versesCorrect += score
        }
        
        saveStats()
        return evaluateBadges()
    }
    
    private func evaluateBadges() -> [AchievementBadge] {
        
        // Проверяем, какие награды открылись только что
        var newUnlocks: [AchievementBadge] = []
        
        for i in 0..<badges.count {
            let badge = badges[i]
            let wasUnlocked = defaults.bool(forKey: "badge_unlocked_\(badge.id)")
            
            let progress: Int
            switch badge.id {
            case "first_quiz": progress = completedRoundsCount
            case "perfect_round": progress = perfectRoundsCount
            case "old_testament_scholar": progress = oldTestamentCorrect
            case "gospels_scholar": progress = gospelsCorrect
            case "apostolic_student": progress = newTestamentCorrect
            case "church_history_guardian": progress = churchHistoryCorrect
            case "master_of_verses": progress = versesCorrect
            case "bible_sage_50", "theologian_100": progress = totalCorrectAnswers
            case "quiz_veteran_10": progress = completedRoundsCount
            default: progress = 0
            }
            
            badges[i].currentProgress = progress
            
            if !wasUnlocked && progress >= badge.requiredCount {
                badges[i].isUnlocked = true
                badges[i].unlockedDate = Date()
                defaults.set(true, forKey: "badge_unlocked_\(badge.id)")
                defaults.set(Date().timeIntervalSince1970, forKey: "badge_date_\(badge.id)")
                newUnlocks.append(badges[i])
            }
        }
        
        self.newlyUnlockedBadges = newUnlocks
        return newUnlocks
    }
    
    // Количество разблокированных наград
    var unlockedCount: Int {
        badges.filter { $0.isUnlocked }.count
    }
    
    // Духовный ранг игрока
    func userRankTitle(for lang: AppLanguage) -> String {
        let count = unlockedCount
        if count >= 9 {
            return "rank_grand_theologian".localized(for: lang)
        } else if count >= 6 {
            return "rank_bible_sage".localized(for: lang)
        } else if count >= 3 {
            return "rank_scholar".localized(for: lang)
        } else if count >= 1 {
            return "rank_student".localized(for: lang)
        } else {
            return "rank_beginner".localized(for: lang)
        }
    }
}
