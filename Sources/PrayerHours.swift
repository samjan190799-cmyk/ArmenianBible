import SwiftUI
import Combine
import UserNotifications

// MARK: - Молитвы по часам
// Четыре короткие паузы в течение дня: утро, день, вечер, ночь. К каждой отрывок Писания из самой Библии приложения
// и по желанию тихое напоминание. Тексты берутся из базы Библии, своих «молитв» приложение не сочиняет.
// Каждый день отрывок новый (больше ста тридцати наборов, PrayerPassages.swift), а виден он только с назначенного часа:
// до этого времени вместо молитвы закрытая карточка.

// MARK: Часы молитвы
enum PrayerHour: String, CaseIterable, Identifiable {
    case morning
    case noon
    case evening
    case night

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    /// Время напоминания по умолчанию, минут от полуночи
    var defaultMinutes: Int {
        switch self {
        case .morning: return 7 * 60 + 30
        case .noon: return 12 * 60
        case .evening: return 18 * 60 + 30
        case .night: return 21 * 60 + 30
        }
    }

    /// Какой час молитвы сейчас по местному времени
    static func current(at date: Date = Date()) -> PrayerHour {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<11: return .morning
        case 11..<16: return .noon
        case 16..<21: return .evening
        default: return .night
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .morning: return language.pick(hy: "Առավոտյան աղոթք", ru: "Утренняя молитва", en: "Morning prayer")
        case .noon: return language.pick(hy: "Կեսօրվա աղոթք", ru: "Полуденная молитва", en: "Midday prayer")
        case .evening: return language.pick(hy: "Երեկոյան աղոթք", ru: "Вечерняя молитва", en: "Evening prayer")
        case .night: return language.pick(hy: "Գիշերային աղոթք", ru: "Молитва на ночь", en: "Night prayer")
        }
    }

    func shortTitle(for language: AppLanguage) -> String {
        switch self {
        case .morning: return language.pick(hy: "Առավոտ", ru: "Утро", en: "Morning")
        case .noon: return language.pick(hy: "Կեսօր", ru: "День", en: "Midday")
        case .evening: return language.pick(hy: "Երեկո", ru: "Вечер", en: "Evening")
        case .night: return language.pick(hy: "Գիշեր", ru: "Ночь", en: "Night")
        }
    }

    func invitation(for language: AppLanguage) -> String {
        switch self {
        case .morning:
            return language.pick(
                hy: "Սկսեք օրը շնորհակալությամբ և լույսով",
                ru: "Начните день с благодарности и света",
                en: "Begin the day with thanks and light"
            )
        case .noon:
            return language.pick(
                hy: "Կանգ առեք մեկ րոպե օրվա մեջտեղում",
                ru: "Остановитесь на минуту посреди дня",
                en: "Pause for a minute in the middle of the day"
            )
        case .evening:
            return language.pick(
                hy: "Շնորհակալ եղեք անցած օրվա համար և հանձնեք ձեր հոգսերը Աստծուն",
                ru: "Поблагодарите за прожитый день и передайте Богу свои заботы",
                en: "Give thanks for the day and hand your cares to God"
            )
        case .night:
            return language.pick(
                hy: "Բաց թողեք օրը և խաղաղությամբ պառկեք քնելու",
                ru: "Отпустите день и ложитесь спать с миром",
                en: "Let the day go and lie down in peace"
            )
        }
    }

    /// Все наборы отрывков этого часа (таблица в PrayerPassages.swift). Каждый набор показывается вместе
    var passageSets: [[PrayerPassage]] {
        let table: [[[Int]]]
        switch self {
        case .morning: table = PrayerPassageTable.morning
        case .noon: table = PrayerPassageTable.noon
        case .evening: table = PrayerPassageTable.evening
        case .night: table = PrayerPassageTable.night
        }
        return table.map { group in
            group.map { PrayerPassage(bookId: $0[0], chapter: $0[1], from: $0[2], to: $0[3]) }
        }
    }

    /// Набор отрывков на заданный день: набор идёт по кругу, поэтому молитва каждый день новая.
    /// У каждого часа свой сдвиг и свой размер таблицы, так что утро, день, вечер и ночь не повторяют друг друга в одном порядке
    func passages(forDay day: Int) -> [PrayerPassage] {
        let sets = passageSets
        guard !sets.isEmpty else { return [] }
        let shift: Int
        switch self {
        case .morning: shift = 0
        case .noon: shift = 11
        case .evening: shift = 5
        case .night: shift = 17
        }
        let index = ((day + shift) % sets.count + sets.count) % sets.count
        return sets[index]
    }

    /// Отрывки на сегодня
    var passages: [PrayerPassage] {
        passages(forDay: VersePuzzleLogic.dayNumber())
    }
}

struct PrayerPassage {
    let bookId: Int
    let chapter: Int
    let from: Int
    let to: Int
}

/// Отрывок, прочитанный из базы: ссылка и текст на языке интерфейса
struct PrayerPassageText: Identifiable {
    let reference: String
    let text: String
    var id: String { reference }

    /// Приводит стих из базы к читаемому виду. Убирает заголовок Псалма в квадратных скобках («[Псалом Давида.]»), букву алфавита
    /// в начале стиха («NUN. Thy word…») и примечания переводчиков в фигурных скобках с двоеточием («{lamp: or, candle}»).
    /// Слова, добавленные переводчиком («{is}»), и слова в квадратных скобках остаются, но без скобок
    static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("["), let close = text.firstIndex(of: "]") {
            text.removeSubrange(text.startIndex...close)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let dot = text.firstIndex(of: "."), text.distance(from: text.startIndex, to: dot) <= 7,
           !text[text.startIndex..<dot].isEmpty,
           text[text.startIndex..<dot].allSatisfy({ $0.isASCII && $0.isUppercase }) {
            text.removeSubrange(text.startIndex...dot)
        }
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "{", let close = text[index...].firstIndex(of: "}") {
                let inner = text[text.index(after: index)..<close]
                if !inner.contains(":") { result += String(inner) }
                index = text.index(after: close)
            } else {
                result.append(character)
                index = text.index(after: index)
            }
        }
        result = result.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        while result.contains("  ") { result = result.replacingOccurrences(of: "  ", with: " ") }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func load(_ passage: PrayerPassage, language: AppLanguage) -> PrayerPassageText? {
        var parts: [String] = []
        for verse in passage.from...passage.to {
            if let found = BibleDatabase.shared.getVerseText(bookId: passage.bookId, chapter: passage.chapter, verse: verse) {
                let text = clean(found.text(for: language))
                if !text.isEmpty { parts.append(text) }
            }
        }
        guard !parts.isEmpty else { return nil }
        var bookName = ""
        if let book = ScriptureReferenceParser.book(id: passage.bookId) {
            switch language {
            case .armenian: bookName = book.nameHy
            case .russian: bookName = book.nameRu
            case .english: bookName = book.nameEn
            }
        }
        let verses = passage.from == passage.to ? "\(passage.from)" : "\(passage.from)–\(passage.to)"
        let reference = bookName.isEmpty ? "\(passage.chapter):\(verses)" : "\(bookName) \(passage.chapter):\(verses)"
        return PrayerPassageText(reference: reference, text: parts.joined(separator: " "))
    }
}

// MARK: Хранилище: напоминания и «помолился сегодня»
final class PrayerHoursStore: ObservableObject {
    static let shared = PrayerHoursStore()

    private let defaults = UserDefaults.standard
    private let doneDayKey = "prayer_hours_done_day_v1"
    private let doneIdsKey = "prayer_hours_done_ids_v1"

    @Published private(set) var enabled: Set<PrayerHour> = []
    @Published private(set) var minutes: [PrayerHour: Int] = [:]
    @Published private(set) var doneToday: Set<PrayerHour> = []
    /// Человек отказал в уведомлениях: подсказываем, где их разрешить
    @Published var showsPermissionHint = false

    private static func enabledKey(_ hour: PrayerHour) -> String { "prayer_hour_\(hour.rawValue)_on_v1" }
    private static func minutesKey(_ hour: PrayerHour) -> String { "prayer_hour_\(hour.rawValue)_minutes_v1" }

    private init() {
        for hour in PrayerHour.allCases {
            if defaults.bool(forKey: Self.enabledKey(hour)) { enabled.insert(hour) }
            minutes[hour] = defaults.object(forKey: Self.minutesKey(hour)) as? Int ?? hour.defaultMinutes
        }
        refreshDone()
    }

    /// Включено ли хотя бы одно напоминание (читает прямо из хранилища: годится для любого потока)
    static var hasEnabledReminders: Bool {
        PrayerHour.allCases.contains { UserDefaults.standard.bool(forKey: enabledKey($0)) }
    }

    /// Напоминания для планировщика. Повторяющиеся: в системе каждое занимает одну запись из 64 возможных
    static func reminderRequests(language: AppLanguage) -> [UNNotificationRequest] {
        let defaults = UserDefaults.standard
        return PrayerHour.allCases.compactMap { hour -> UNNotificationRequest? in
            guard defaults.bool(forKey: enabledKey(hour)) else { return nil }
            let total = defaults.object(forKey: minutesKey(hour)) as? Int ?? hour.defaultMinutes
            var parts = DateComponents()
            parts.hour = min(23, max(0, total / 60))
            parts.minute = min(59, max(0, total % 60))

            let content = UNMutableNotificationContent()
            content.title = hour.title(for: language)
            content.body = language.pick(
                hy: "Լռության և աղոթքի րոպե։ Բացեք Luys-ը։",
                ru: "Минута тишины и молитвы. Откройте Luys.",
                en: "A quiet minute for prayer. Open Luys."
            )
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
            return UNNotificationRequest(identifier: "prayer_hour_\(hour.rawValue)", content: content, trigger: trigger)
        }
    }

    func isEnabled(_ hour: PrayerHour) -> Bool { enabled.contains(hour) }

    func reminderMinutes(for hour: PrayerHour) -> Int { minutes[hour] ?? hour.defaultMinutes }

    // MARK: Когда молитва открывается
    /// Молитва открывается в назначенное время своего часа (время напоминания; по умолчанию 7:30, 12:00, 18:30 и 21:30)
    /// и остаётся открытой до полуночи. Ночная после полуночи остаётся открытой до утреннего времени.
    /// Напоминание включать не обязательно: время работает и без него
    func isOpen(_ hour: PrayerHour, at date: Date = Date()) -> Bool {
        let now = Self.minutesOfDay(date)
        if now >= reminderMinutes(for: hour) { return true }
        return hour == .night && now < reminderMinutes(for: .morning)
    }

    /// Через сколько минут молитва откроется; nil, если уже открыта
    func minutesUntilOpen(_ hour: PrayerHour, at date: Date = Date()) -> Int? {
        guard !isOpen(hour, at: date) else { return nil }
        return max(1, reminderMinutes(for: hour) - Self.minutesOfDay(date))
    }

    private static func minutesOfDay(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    func setEnabled(_ hour: PrayerHour, _ on: Bool) {
        if on {
            BibleManager.shared.requestNotificationPermission { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.enabled.insert(hour)
                    self.defaults.set(true, forKey: Self.enabledKey(hour))
                    self.showsPermissionHint = false
                    BibleManager.shared.scheduleAllNotifications()
                    Funnel.track("feature_used", ["feature": "prayer_reminder_on"])
                } else {
                    self.showsPermissionHint = true
                    self.objectWillChange.send()
                }
            }
        } else {
            enabled.remove(hour)
            defaults.set(false, forKey: Self.enabledKey(hour))
            BibleManager.shared.scheduleAllNotifications()
        }
    }

    func setMinutes(_ hour: PrayerHour, _ value: Int) {
        let clamped = min(24 * 60 - 1, max(0, value))
        minutes[hour] = clamped
        defaults.set(clamped, forKey: Self.minutesKey(hour))
        if enabled.contains(hour) {
            BibleManager.shared.scheduleAllNotifications()
        }
    }

    // MARK: Помолился сегодня
    private func refreshDone() {
        let today = VersePuzzleLogic.dayNumber()
        if defaults.integer(forKey: doneDayKey) == today {
            let ids = defaults.array(forKey: doneIdsKey) as? [String] ?? []
            doneToday = Set(ids.compactMap { PrayerHour(rawValue: $0) })
        } else {
            doneToday = []
        }
    }

    /// Отметка «Аминь». Возвращает true, если час отмечен впервые за сегодня
    @discardableResult
    func markDone(_ hour: PrayerHour) -> Bool {
        refreshDone()
        guard !doneToday.contains(hour) else { return false }
        doneToday.insert(hour)
        defaults.set(VersePuzzleLogic.dayNumber(), forKey: doneDayKey)
        defaults.set(doneToday.map { $0.rawValue }, forKey: doneIdsKey)
        return true
    }

    /// Новый день: вчерашние отметки больше не показываются
    func refresh() {
        refreshDone()
    }
}

// MARK: Карточка на главном экране
struct PrayerHoursBannerCardView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    let onOpen: () -> Void

    @ObservedObject private var store = PrayerHoursStore.shared

    private var subtitle: String {
        let done = store.doneToday.count
        if done > 0 {
            return language.pick(
                hy: "Այսօր աղոթել եք՝ \(done) / 4",
                ru: "Сегодня помолились: \(done) из 4",
                en: "Prayed today: \(done) of 4"
            )
        }
        let now = PrayerHour.current()
        return language.pick(
            hy: "Հիմա՝ \(now.title(for: .armenian).lowercased())",
            ru: "Сейчас: \(now.title(for: .russian).lowercased())",
            en: "Now: \(now.title(for: .english).lowercased())"
        )
    }

    var body: some View {
        HomeFeatureCard(
            symbol: "sunrise.fill",
            label: language.pick(hy: "ԱՂՈԹՔ ԺԱՄԵՐՈՎ", ru: "МОЛИТВЫ ПО ЧАСАМ", en: "PRAYERS BY THE HOUR"),
            labelColor: Paper.cinnabar,
            title: language.pick(hy: "Աղոթքի րոպե օրվա ընթացքում", ru: "Минута молитвы в течение дня", en: "A minute of prayer through the day"),
            subtitle: subtitle,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryAccentColor,
            onOpen: onOpen
        )
        .onAppear { store.refresh() }
    }
}

// MARK: Экран молитв по часам
struct PrayerHoursView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var store = PrayerHoursStore.shared

    @State private var selected: PrayerHour = PrayerHour.current()
    @State private var passages: [PrayerPassageText] = []
    /// Текущее время: обновляется раз в несколько секунд, чтобы закрытая молитва раскрылась сама, когда придёт её час
    @State private var now = Date()
    private let clock = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var language: AppLanguage { manager.appLanguage }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        hourSelector
                        prayerCard
                        remindersCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            now = Date()
            store.refresh()
            loadPassages()
            Funnel.track("feature_used", ["feature": "prayer_hours_opened"])
        }
        .onReceive(clock) { value in
            withAnimation(.easeInOut(duration: 0.5)) { now = value }
        }
        .onChange(of: selected) { _ in loadPassages() }
        .onChange(of: manager.appLanguage) { _ in loadPassages() }
    }

    // MARK: Верх экрана
    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Paper.ink.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Text(language.pick(hy: "Աղոթք ժամերով", ru: "Молитвы по часам", en: "Prayers by the hour"))
                .font(PaperFont.font(size: 18, weight: .semibold))
                .foregroundColor(Paper.ink)

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Выбор часа
    private var hourSelector: some View {
        HStack(spacing: 8) {
            ForEach(PrayerHour.allCases) { hour in
                let isSelected = hour == selected
                let isDone = store.doneToday.contains(hour)
                let isLocked = !store.isOpen(hour, at: now)
                Button {
                    Haptics.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selected = hour
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: hour.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isSelected ? Paper.onAccent : Paper.gold)
                            if isDone {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Paper.moss)
                                    .background(Circle().fill(Paper.page))
                                    .offset(x: 9, y: -6)
                            } else if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(isSelected ? Paper.onAccent : Paper.inkSecondary)
                                    .offset(x: 9, y: -5)
                            }
                        }
                        Text(hour.shortTitle(for: language))
                            .font(PaperFont.font(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? Paper.onAccent : Paper.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? Paper.accentFill : Paper.gold.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.clear : Paper.gold.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: Молитва выбранного часа: до назначенного времени закрыта
    @ViewBuilder
    private var prayerCard: some View {
        if store.isOpen(selected, at: now) {
            openCard.transition(.opacity)
        } else {
            lockedCard.transition(.opacity)
        }
    }

    /// Закрытая карточка: ни отрывка, ни ссылки, ни приглашения, ни кнопки «Аминь», только час и сколько осталось
    private var lockedCard: some View {
        let opensAt = store.reminderMinutes(for: selected)
        let wait = store.minutesUntilOpen(selected, at: now) ?? 1
        return VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: selected.symbol)
                    .font(.system(size: 34))
                    .foregroundColor(Paper.gold.opacity(0.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Paper.gold)
                    .offset(x: 12, y: 6)
            }

            VStack(spacing: 6) {
                Text(selected.title(for: language))
                    .font(PaperFont.font(size: 20, weight: .semibold))
                    .foregroundColor(Paper.ink)
                Text(language.pick(
                    hy: "Աղոթքը կբացվի ժամը \(timeText(opensAt))-ին",
                    ru: "Откроется в \(timeText(opensAt))",
                    en: "Opens at \(timeText(opensAt))"
                ))
                .font(PaperFont.font(size: 15, weight: .semibold))
                .foregroundColor(Paper.gold)
                Text(waitText(wait))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(Paper.inkSecondary)
            }

            Text(language.pick(
                hy: "Աղոթքի տեքստը երևում է միայն իր ժամին։ Վերադարձեք, երբ ժամանակը գա։",
                ru: "Текст молитвы виден только в свой час. Возвращайтесь, когда придёт время.",
                en: "The prayer is revealed only at its hour. Come back when the time comes."
            ))
            .font(PaperFont.font(size: 13))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
    }

    /// Время для надписи, в формате языка приложения («18:30» или «6:30 PM»)
    private func timeText(_ minutes: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeCode)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Сколько осталось, по-человечески: «2 ч 35 мин», «12 мин»
    private func waitText(_ minutes: Int) -> String {
        let total = max(1, minutes)
        let hours = total / 60
        let mins = total % 60
        if hours > 0 {
            return language.pick(hy: "Մնաց՝ \(hours) ժ \(mins) ր", ru: "Осталось \(hours) ч \(mins) мин", en: "In \(hours) h \(mins) min")
        }
        return language.pick(hy: "Մնաց՝ \(mins) ր", ru: "Осталось \(mins) мин", en: "In \(mins) min")
    }

    /// Открытая молитва: отрывок на сегодня и кнопка «Аминь»
    private var openCard: some View {
        let done = store.doneToday.contains(selected)
        return VStack(spacing: 16) {
            Image(systemName: selected.symbol)
                .font(.system(size: 34))
                .foregroundColor(Paper.gold)

            VStack(spacing: 6) {
                Text(selected.title(for: language))
                    .font(PaperFont.font(size: 20, weight: .semibold))
                    .foregroundColor(Paper.ink)
                Text(selected.invitation(for: language))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            if passages.isEmpty {
                Text(language.pick(
                    hy: "Տեքստը հասանելի չէ",
                    ru: "Текст сейчас недоступен",
                    en: "The text is not available right now"
                ))
                .font(PaperFont.font(size: 13))
                .foregroundColor(Paper.inkSecondary)
            } else {
                VStack(spacing: 16) {
                    ForEach(passages) { passage in
                        VStack(spacing: 6) {
                            Text(passage.text)
                                .font(PaperFont.font(size: 17))
                                .foregroundColor(Paper.ink)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                            Text(passage.reference)
                                .font(PaperFont.font(size: 13, weight: .semibold))
                                .foregroundColor(Paper.gold)
                        }
                    }
                }
            }

            Button {
                amen()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: done ? "checkmark.circle.fill" : "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(done
                         ? language.pick(hy: "Այսօր աղոթել եք", ru: "Сегодня помолились", en: "Prayed today")
                         : language.pick(hy: "Ամեն", ru: "Аминь", en: "Amen"))
                        .font(PaperFont.font(size: 16, weight: .semibold))
                }
                .foregroundColor(done ? Paper.moss : Paper.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(done ? Paper.moss.opacity(0.15) : Paper.gold)
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(done)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .paperSheet(cornerRadius: 22)
    }

    // MARK: Напоминания
    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.pick(hy: "ԱՂՈԹՔԻ ԺԱՄԵՐ", ru: "ВРЕМЯ МОЛИТВ", en: "PRAYER TIMES"))
                .font(PaperFont.font(size: 11, weight: .semibold))
                .foregroundColor(Paper.inkSecondary)
                .tracking(1.0)

            Text(language.pick(
                hy: "Այս ժամին աղոթքը բացվում է։ Հիշեցումը՝ ըստ ցանկության։",
                ru: "В это время молитва открывается. Напоминание по желанию.",
                en: "The prayer opens at this time. The reminder is optional."
            ))
            .font(PaperFont.font(size: 12))
            .foregroundColor(Paper.inkSecondary)

            ForEach(PrayerHour.allCases) { hour in
                HStack(spacing: 10) {
                    Image(systemName: hour.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Paper.gold)
                        .frame(width: 24)

                    Text(hour.shortTitle(for: language))
                        .font(PaperFont.font(size: 15, weight: .medium))
                        .foregroundColor(Paper.ink)

                    Spacer()

                    DatePicker("", selection: timeBinding(for: hour), displayedComponents: .hourAndMinute)
                        .labelsHidden()

                    Image(systemName: store.isEnabled(hour) ? "bell.fill" : "bell.slash")
                        .font(.system(size: 13))
                        .foregroundColor(store.isEnabled(hour) ? Paper.gold : Paper.inkSecondary.opacity(0.6))

                    Toggle("", isOn: toggleBinding(for: hour))
                        .labelsHidden()
                        .tint(Paper.gold)
                }
            }

            if store.showsPermissionHint {
                Text(language.pick(
                    hy: "Թույլատրեք ծանուցումները Luys-ի համար iPhone-ի կարգավորումներում",
                    ru: "Разрешите уведомления для Luys в настройках iPhone",
                    en: "Allow notifications for Luys in the iPhone Settings"
                ))
                .font(PaperFont.font(size: 12, weight: .medium))
                .foregroundColor(Paper.cinnabar)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSheet(cornerRadius: 22)
    }

    // MARK: Привязки и действия
    private func toggleBinding(for hour: PrayerHour) -> Binding<Bool> {
        Binding(
            get: { store.isEnabled(hour) },
            set: { store.setEnabled(hour, $0) }
        )
    }

    private func timeBinding(for hour: PrayerHour) -> Binding<Date> {
        Binding(
            get: {
                let total = store.reminderMinutes(for: hour)
                return Calendar.current.date(bySettingHour: total / 60, minute: total % 60, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                store.setMinutes(hour, (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
            }
        )
    }

    private func loadPassages() {
        passages = selected.passages.compactMap { PrayerPassageText.load($0, language: language) }
    }

    private func amen() {
        guard store.isOpen(selected), store.markDone(selected) else { return }
        Haptics.notify(.success)
        // Молитва питает Гранатовое древо так же, как шаг плана чтения: задание дня не засчитывается, но древо поливается
        PomegranateTreeManager.shared.record(.plan)
        Funnel.track("feature_used", ["feature": "prayer_hour_done"])
    }
}
