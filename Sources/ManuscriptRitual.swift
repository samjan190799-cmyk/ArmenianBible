import Foundation

// MARK: - «Лист дня»: серия дней и замеры «Рукописи»
// Раньше «Рукопись» открывали, любовались и уходили: за две недели в среднем по два раза на человека.
// Лист, дописанный пером, теперь считается ритуалом дня: он питает древо (задание дня), ведёт серию
// дней подряд (её видно на карточке главного экрана) и попадает в замеры, чтобы было видно, что работает.

enum ManuscriptRitual {
    static let lastDayKey = "luys_manuscript_last_day"
    static let streakKey = "luys_manuscript_streak"

    static func dayString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static var yesterdayString: String {
        dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    /// Сегодня уже дописан хотя бы один лист
    static var wroteToday: Bool {
        UserDefaults.standard.string(forKey: lastDayKey) == dayString()
    }

    /// Сколько дней подряд писали лист; серия жива, если последний лист написан сегодня или вчера
    static var streak: Int {
        let defaults = UserDefaults.standard
        guard let last = defaults.string(forKey: lastDayKey) else { return 0 }
        guard last == dayString() || last == yesterdayString else { return 0 }
        return defaults.integer(forKey: streakKey)
    }

    /// Лист дописан: засчитывается в серию, питает древо и попадает в замеры. За день серия растёт один раз.
    @MainActor
    static func recordWritten() {
        let defaults = UserDefaults.standard
        let today = dayString()
        if defaults.string(forKey: lastDayKey) != today {
            let continued = defaults.string(forKey: lastDayKey) == yesterdayString
            defaults.set(continued ? defaults.integer(forKey: streakKey) + 1 : 1, forKey: streakKey)
            defaults.set(today, forKey: lastDayKey)
        }
        PomegranateTreeManager.shared.record(.manuscript)
        ManuscriptStats.track("ms_written")
    }
}

// MARK: - Замеры внутри «Рукописи»
// Раньше считалось только «открыл» (feature_used: manuscript): не было видно, сохраняют ли листы, делятся ли,
// меняют ли перо. Имена короткие и из разрешённого набора символов (a-z, 0-9, _), как требует Worker.
enum ManuscriptStats {
    static func track(_ name: String) {
        Funnel.track("feature_used", ["feature": name])
    }
}
