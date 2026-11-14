import Foundation

// MARK: - История чатов Духовного Помощника
// Раньше был один бесконечный чат в UserDefaults. Теперь у каждой беседы свой файл в Application Support/AIChats,
// а список бесед (название, время, отрывок, текст для поиска) лежит в index.json: список открывается мгновенно
// и не читает сообщения всех чатов. Старый единый чат при первом запуске переносится в одну беседу.
//
// Всё работает на главном потоке: store вызывается из экранов и из их обработчиков ответа ИИ,
// поэтому блокировок нет. Пустой «новый чат» нигде не хранится, пока в нём нет первого вопроса.

/// Беседа в списке истории (без сообщений)
struct AIChatSummary: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var messageCount: Int
    /// Начало последнего сообщения для списка
    var preview: String
    /// Заголовок и вопросы человека в нижнем регистре: по нему работает поиск по истории
    var searchText: String
}

final class AIChatStore: ObservableObject {
    static let shared = AIChatStore()

    /// Беседы: закреплённые сверху, дальше по времени последнего сообщения
    @Published private(set) var summaries: [AIChatSummary] = []
    /// Открытая беседа; nil — новый чат, который ещё не сохранён
    @Published private(set) var currentID: UUID? = nil
    /// Сообщения открытой беседы
    @Published private(set) var messages: [AIChatMessage] = []
    /// Беседы, в которых сейчас ждут ответ ИИ (ответ придёт в свою беседу, даже если человек ушёл в другую)
    @Published private(set) var pendingIDs: Set<UUID> = []

    private let legacyKey = "ai_spiritual_chat_messages"
    private let maxChats = 200
    private let maxMessagesPerChat = 400
    private let directory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent("AIChats", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        loadIndex()
        migrateLegacyChatIfNeeded()

        // Открывается последняя беседа: как раньше открывался единственный чат
        if let latest = summaries.max(by: { $0.updatedAt < $1.updatedAt }) {
            currentID = latest.id
            messages = loadMessages(latest.id)
        }
    }

    // MARK: - Чтение

    var totalMessageCount: Int {
        summaries.reduce(0) { $0 + $1.messageCount }
    }

    func isPending(_ id: UUID?) -> Bool {
        guard let id = id else { return false }
        return pendingIDs.contains(id)
    }

    func setPending(_ pending: Bool, for id: UUID) {
        if pending {
            pendingIDs.insert(id)
        } else {
            pendingIDs.remove(id)
        }
    }

    /// Беседы, подходящие под запрос (по названию и вопросам); без запроса все
    func filtered(by query: String) -> [AIChatSummary] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return summaries }
        return summaries.filter { $0.searchText.contains(needle) }
    }

    // MARK: - Переключение между беседами

    func startNewChat() {
        currentID = nil
        messages = []
    }

    func select(_ id: UUID) {
        guard summaries.contains(where: { $0.id == id }) else { return }
        currentID = id
        messages = loadMessages(id)
    }

    // MARK: - Запись сообщений

    /// Добавляет сообщение в беседу `chatID` (по умолчанию в открытую). Если открыт новый чат, он создаётся
    /// с названием по первому вопросу. Возвращает номер беседы, чтобы ответ ИИ вернулся именно в неё.
    /// Если беседу тем временем удалили, сообщение отбрасывается.
    @discardableResult
    func addMessage(_ message: AIChatMessage, to chatID: UUID? = nil) -> UUID {
        let targetID: UUID
        if let known = chatID ?? currentID {
            guard summaries.contains(where: { $0.id == known }) else { return known }
            targetID = known
        } else {
            targetID = UUID()
            let now = Date()
            summaries.append(AIChatSummary(
                id: targetID,
                title: Self.makeTitle(from: message.text),
                createdAt: now,
                updatedAt: now,
                isPinned: false,
                messageCount: 0,
                preview: "",
                searchText: ""
            ))
            currentID = targetID
            messages = []
        }

        var list = (targetID == currentID) ? messages : loadMessages(targetID)
        list.append(message)
        if list.count > maxMessagesPerChat {
            list.removeFirst(list.count - maxMessagesPerChat)
        }
        _ = saveMessages(list, for: targetID)
        if targetID == currentID {
            messages = list
        }
        refreshSummary(targetID, messages: list)
        pruneIfNeeded()
        persistIndex()
        return targetID
    }

    // MARK: - Управление беседами

    func rename(_ id: UUID, to newTitle: String) {
        let title = String(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !title.isEmpty, let index = summaries.firstIndex(where: { $0.id == id }) else { return }
        summaries[index].title = title
        let list = (id == currentID) ? messages : loadMessages(id)
        summaries[index].searchText = Self.makeSearchText(title: title, messages: list)
        persistIndex()
    }

    func togglePin(_ id: UUID) {
        guard let index = summaries.firstIndex(where: { $0.id == id }) else { return }
        summaries[index].isPinned.toggle()
        sortSummaries()
        persistIndex()
    }

    func delete(_ id: UUID) {
        summaries.removeAll { $0.id == id }
        pendingIDs.remove(id)
        removeFiles(for: id)
        if currentID == id {
            currentID = nil
            messages = []
        }
        persistIndex()
    }

    /// Удаляет всю историю (кнопка в «Настройках»)
    func deleteAll() {
        for summary in summaries {
            removeFiles(for: summary.id)
        }
        summaries = []
        pendingIDs = []
        currentID = nil
        messages = []
        try? FileManager.default.removeItem(at: indexURL)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    // MARK: - Файлы

    private var indexURL: URL {
        directory.appendingPathComponent("index.json")
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    private func write(_ data: Data, to url: URL) -> Bool {
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            return false
        }
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let list = try? JSONDecoder().decode([AIChatSummary].self, from: data) else { return }
        summaries = list
        sortSummaries()
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder().encode(summaries) else { return }
        _ = write(data, to: indexURL)
    }

    private func loadMessages(_ id: UUID) -> [AIChatMessage] {
        guard let data = try? Data(contentsOf: fileURL(for: id)),
              let list = try? JSONDecoder().decode([AIChatMessage].self, from: data) else { return [] }
        return list
    }

    private func saveMessages(_ list: [AIChatMessage], for id: UUID) -> Bool {
        guard let data = try? JSONEncoder().encode(list) else { return false }
        return write(data, to: fileURL(for: id))
    }

    private func removeFiles(for id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    // MARK: - Служебное

    private func sortSummaries() {
        summaries.sort { first, second in
            if first.isPinned != second.isPinned { return first.isPinned }
            return first.updatedAt > second.updatedAt
        }
    }

    private func refreshSummary(_ id: UUID, messages list: [AIChatMessage]) {
        guard let index = summaries.firstIndex(where: { $0.id == id }) else { return }
        summaries[index].messageCount = list.count
        summaries[index].updatedAt = Date()
        summaries[index].preview = Self.makeSnippet(from: list.last?.text ?? "")
        summaries[index].searchText = Self.makeSearchText(title: summaries[index].title, messages: list)
        sortSummaries()
    }

    /// Держит число бесед в пределах: сначала уходят самые старые незакреплённые
    private func pruneIfNeeded() {
        while summaries.count > maxChats {
            guard let victim = summaries.last(where: { !$0.isPinned && $0.id != currentID }) else { break }
            removeFiles(for: victim.id)
            summaries.removeAll { $0.id == victim.id }
        }
    }

    /// Старый единый чат из UserDefaults становится одной беседой. Ключ стирается, только если запись удалась.
    private func migrateLegacyChatIfNeeded() {
        guard summaries.isEmpty,
              let data = UserDefaults.standard.data(forKey: legacyKey),
              let old = try? JSONDecoder().decode([AIChatMessage].self, from: data),
              let first = old.first,
              let last = old.last else { return }

        let id = UUID()
        let firstQuestion = old.first(where: { $0.isUser })?.text ?? first.text
        guard saveMessages(old, for: id) else { return }

        let title = Self.makeTitle(from: firstQuestion)
        summaries = [AIChatSummary(
            id: id,
            title: title,
            createdAt: first.timestamp,
            updatedAt: last.timestamp,
            isPinned: false,
            messageCount: old.count,
            preview: Self.makeSnippet(from: last.text),
            searchText: Self.makeSearchText(title: title, messages: old)
        )]
        persistIndex()
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    static func makeTitle(from text: String) -> String {
        let flat = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if flat.count <= 48 { return flat }
        return String(flat.prefix(48)).trimmingCharacters(in: .whitespaces) + "…"
    }

    private static func makeSnippet(from text: String) -> String {
        let flat = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if flat.count <= 90 { return flat }
        return String(flat.prefix(90)).trimmingCharacters(in: .whitespaces) + "…"
    }

    private static func makeSearchText(title: String, messages list: [AIChatMessage]) -> String {
        var parts: [String] = [title]
        for message in list where message.isUser {
            parts.append(message.text)
        }
        return String(parts.joined(separator: " ").lowercased().prefix(1500))
    }
}
