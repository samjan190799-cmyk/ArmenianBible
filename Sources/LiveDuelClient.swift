import Foundation
import SwiftUI

// MARK: - Дуэль в реальном времени: модели и соединение
// Два телефона играют в одни вопросы одновременно. Комната живёт на Worker (Durable Object, WebSocket), вся логика
// партии там же (cloudflare/ai-proxy/src/duel-room.js): телефон лишь показывает состояние и присылает свои ответы.
// Вопросы по-прежнему берутся из кураторской базы по «семени» (QuizDuelEngine), сервер самих вопросов не знает.

struct LiveDuelConfig: Codable, Equatable {
    let c: String // категория
    let s: Int // «семя» перемешивания
    let n: Int // сколько вопросов
    let m: Int // сколько вопросов в пуле категории: так видно, что у друга другая версия базы

    init(c: String, s: Int, n: Int, m: Int) {
        self.c = c
        self.s = s
        self.n = n
        self.m = m
    }

    init(_ duel: QuizDuel) {
        self.init(c: duel.c, s: duel.s, n: duel.n, m: duel.m)
    }

    /// То же самое в виде обычной дуэли: из неё QuizDuelEngine достаёт вопросы
    var asDuel: QuizDuel {
        QuizDuel(c: c, s: s, n: n, m: m, a: nil, r: nil, b: nil, q: nil)
    }
}

struct LiveDuelPlayer: Decodable, Equatable {
    let you: Bool
    let name: String
    let connected: Bool
    let score: Int
    let answered: Bool
    let correct: Bool?
    let rematch: Bool
}

struct LiveDuelState: Decodable, Equatable {
    let code: String
    let phase: String // lobby, countdown, playing, finished
    let config: LiveDuelConfig?
    let serverNow: Double
    let startsAt: Double?
    let qStart: Double?
    let revealAt: Double?
    let questionMs: Double
    let revealMs: Double
    let q: Int
    let isHost: Bool
    let abandoned: String? // you / opponent: кто ушёл посреди партии
    let players: [LiveDuelPlayer]

    var me: LiveDuelPlayer? { players.first { $0.you } }
    var opponent: LiveDuelPlayer? { players.first { !$0.you } }
    var isRevealing: Bool { phase == "playing" && revealAt != nil }
}

/// Запуск экрана дуэли: свой код и настройки (создатель) либо чужой код (гость)
struct LiveDuelLaunch: Identifiable {
    let id = UUID()
    let code: String
    let config: LiveDuelConfig?
}

enum LiveDuelCode {
    // Без похожих знаков (0/O, 1/I): код диктуют голосом и переписывают с экрана
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func random() -> String {
        String((0..<5).map { _ in alphabet.randomElement() ?? "A" })
    }

    /// Что бы ни ввёл человек, остаются допустимые знаки в верхнем регистре, не больше пяти
    static func normalize(_ text: String) -> String {
        String(text.uppercased().filter { alphabet.contains($0) }.prefix(5))
    }

    static func isValid(_ text: String) -> Bool {
        text.count == 5 && text.allSatisfy { alphabet.contains($0) }
    }

    /// Страница-приглашение на Worker: код после «#»
    static func inviteURL(_ code: String) -> URL? {
        URL(string: "\(PairLink.webBase)/r#\(code)")
    }

    /// Код из ссылки приложения armenianbible://room?c=…
    static func code(from url: URL) -> String? {
        guard let raw = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "c" })?
            .value else { return nil }
        let code = normalize(raw)
        return isValid(code) ? code : nil
    }
}

enum LiveDuelIdentity {
    /// Случайный номер игрока, живёт на этом телефоне: по нему комната узнаёт вернувшегося игрока
    static var playerID: String {
        let key = "luys_live_duel_pid"
        if let id = UserDefaults.standard.string(forKey: key), id.count >= 8 { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}

// MARK: - Клиент комнаты
@MainActor
final class LiveDuelClient: ObservableObject {
    enum Link: Equatable {
        case connecting
        case online
        case reconnecting
    }

    @Published private(set) var state: LiveDuelState?
    @Published private(set) var link: Link = .connecting
    /// Окончательная ошибка: not_found, full, exists, bad_request, network. После неё переподключений нет
    @Published private(set) var failure: String?

    let code: String
    private let pid: String
    private let name: String
    private let config: LiveDuelConfig?

    private let session = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private var generation = 0
    private var attempts = 0
    private var closed = false
    private var clockOffset: Double = 0

    private struct Envelope: Decodable {
        let type: String
        let state: LiveDuelState?
        let code: String?
    }

    init(code: String, name: String, config: LiveDuelConfig?) {
        self.code = code
        self.pid = LiveDuelIdentity.playerID
        self.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        self.config = config
    }

    /// Время сервера в миллисекундах: таймеры обоих телефонов идут от одних часов
    func serverNow() -> Double {
        Date().timeIntervalSince1970 * 1000 + clockOffset
    }

    // MARK: Соединение
    func connect() {
        guard !closed, failure == nil else { return }
        generation += 1
        let mine = generation
        task?.cancel(with: .goingAway, reason: nil)

        let base = PairLink.webBase.replacingOccurrences(of: "https://", with: "wss://")
        guard let url = URL(string: "\(base)/v1/duel/\(code)") else {
            failure = "bad_request"
            return
        }
        let socket = session.webSocketTask(with: url)
        task = socket
        socket.resume()
        sendJoin()
        receive(socket, generation: mine)
        startPing(generation: mine)
    }

    /// Приложение вернулось на экран: старое соединение могло тихо умереть, поэтому открываем новое
    func reconnectNow() {
        guard !closed, failure == nil else { return }
        attempts = 0
        connect()
    }

    func close() {
        closed = true
        generation += 1
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    private func sendJoin() {
        var join: [String: Any] = ["type": "join", "pid": pid, "name": name]
        if let config {
            join["config"] = ["c": config.c, "s": config.s, "n": config.n, "m": config.m] as [String: Any]
        }
        send(join)
    }

    private func receive(_ socket: URLSessionWebSocketTask, generation mine: Int) {
        socket.receive { [weak self] result in
            Task { @MainActor in
                guard let self, self.generation == mine else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    self.receive(socket, generation: mine)
                case .failure:
                    self.connectionLost(generation: mine)
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let text: String
        switch message {
        case .string(let value): text = value
        case .data(let data): text = String(data: data, encoding: .utf8) ?? ""
        @unknown default: return
        }
        guard text != "pong",
              let data = text.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
        switch envelope.type {
        case "state":
            guard let incoming = envelope.state else { return }
            clockOffset = incoming.serverNow - Date().timeIntervalSince1970 * 1000
            attempts = 0
            link = .online
            state = incoming
        case "error":
            failure = envelope.code ?? "unknown"
            task?.cancel(with: .normalClosure, reason: nil)
        default:
            break
        }
    }

    private func connectionLost(generation mine: Int) {
        guard !closed, failure == nil, generation == mine else { return }
        link = state == nil ? .connecting : .reconnecting
        attempts += 1
        if state == nil && attempts > 6 {
            failure = "network"
            return
        }
        let delay = min(5.0, 0.8 * Double(attempts))
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, self.generation == mine else { return }
            self.connect()
        }
    }

    /// Раз в несколько секунд «ping»: сервер отвечает «pong», не просыпаясь, а соединение не считается мёртвым
    private func startPing(generation mine: Int) {
        Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                guard let self, self.generation == mine, !self.closed else { return }
                self.task?.send(.string("ping")) { _ in }
            }
        }
    }

    // MARK: Что игрок делает
    func startGame() {
        send(["type": "start"])
    }

    func answer(q: Int, correct: Bool, ms: Int) {
        send(["type": "answer", "q": q, "correct": correct, "ms": ms])
    }

    func rematch() {
        send(["type": "rematch"])
    }

    /// Игрок выходит из комнаты; соединение закрывается чуть позже, чтобы «leave» успел уйти
    func leave() {
        send(["type": "leave"])
        closed = true
        generation += 1
        let socket = task
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            socket?.cancel(with: .normalClosure, reason: nil)
        }
        task = nil
    }

    private func send(_ object: [String: Any]) {
        guard let task,
              let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return }
        task.send(.string(text)) { _ in }
    }
}
