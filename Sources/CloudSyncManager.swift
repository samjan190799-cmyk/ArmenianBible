import Foundation
import SwiftUI
import Combine
import CryptoKit
import UIKit
import WidgetKit

// MARK: - Синхронизация через iCloud (NSUbiquitousKeyValueStore)
/// Переносит между устройствами одного Apple ID: избранное, заметки и маркеры, прогресс чтения,
/// основные настройки и рекорд викторины. Выключена по умолчанию: включается пользователем в «Настройках».
///
/// Принцип: для каждого набора данных хранится «базовый» хеш последнего согласованного состояния.
///  • изменилось только здесь   — отправляем в iCloud;
///  • изменилось только в iCloud — применяем локально;
///  • изменилось и там, и там   — объединяем (ничего не теряем) и отправляем результат.
/// Ключи API (Gemini/OpenAI/Anthropic), подписка и чат с ИИ в iCloud НЕ отправляются.
@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    enum Status: Equatable {
        case off
        case unavailable
        case syncing
        case idle(Date?)
        case tooLarge
    }

    @Published private(set) var isEnabled: Bool
    @Published private(set) var status: Status = .off

    private let store = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private let enabledKey = "icloud_sync_enabled"
    private let lastSyncKey = "icloud_sync_last_date"
    private let maxPayloadBytes = 700_000
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var isSyncing = false

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "icloud_sync_enabled")
        self.status = isEnabled ? .idle(lastSyncDate) : .off
    }

    var lastSyncDate: Date? {
        defaults.object(forKey: lastSyncKey) as? Date
    }

    /// Есть ли вход в iCloud на устройстве.
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: Запуск и включение
    func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.syncNow() }
        })
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.syncNow() }
        })
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.syncNow() }
        })
        observers.append(center.addObserver(forName: NSNotification.Name.NSUbiquityIdentityDidChange,
                                            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.syncNow() }
        })
        let timer = Timer(timeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.syncNow() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        if isEnabled {
            store.synchronize()
            syncNow()
        }
    }

    func setEnabled(_ value: Bool) {
        isEnabled = value
        defaults.set(value, forKey: enabledKey)
        if value {
            start()
            store.synchronize()
            syncNow()
        } else {
            status = .off
        }
    }

    // MARK: Синхронизация
    func syncNow() {
        guard isEnabled else { return }
        guard isICloudAvailable else {
            status = .unavailable
            return
        }
        guard !isSyncing else { return }
        isSyncing = true
        status = .syncing

        var needsReload = false
        var tooLarge = false
        for spec in Self.specs {
            let key = "sync.\(spec.name)"
            let baseKey = "icloud_sync_base_\(spec.name)"
            let local = spec.read()
            let remote = store.data(forKey: key)
            let base = defaults.string(forKey: baseKey)
            let localHash = local.map(Self.hash)
            let remoteHash = remote.map(Self.hash)

            switch (local, remote) {
            case (nil, nil):
                break
            case (let l?, nil):
                tooLarge = !push(l, key: key, baseKey: baseKey) || tooLarge
            case (nil, let r?):
                spec.write(r)
                defaults.set(Self.hash(r), forKey: baseKey)
                needsReload = true
            case (let l?, let r?):
                if localHash == remoteHash {
                    defaults.set(localHash, forKey: baseKey)
                } else if base != nil && localHash == base {
                    // изменилось только в iCloud
                    spec.write(r)
                    defaults.set(remoteHash, forKey: baseKey)
                    needsReload = true
                } else if base != nil && remoteHash == base {
                    // изменилось только здесь
                    tooLarge = !push(l, key: key, baseKey: baseKey) || tooLarge
                } else {
                    // первая синхронизация или конфликт: объединяем, ничего не теряя
                    let merged = spec.merge(l, r)
                    if Self.hash(merged) != localHash {
                        spec.write(merged)
                        needsReload = true
                    }
                    if Self.hash(merged) != remoteHash {
                        tooLarge = !push(merged, key: key, baseKey: baseKey) || tooLarge
                    } else {
                        defaults.set(Self.hash(merged), forKey: baseKey)
                    }
                }
            }
        }

        store.synchronize()
        if needsReload {
            BibleManager.shared.reloadFromCloudSync()
            WidgetCenter.shared.reloadAllTimelines()
        }
        let now = Date()
        defaults.set(now, forKey: lastSyncKey)
        status = tooLarge ? .tooLarge : .idle(now)
        isSyncing = false
    }

    /// Возвращает false, если данных слишком много для iCloud-хранилища.
    private func push(_ data: Data, key: String, baseKey: String) -> Bool {
        guard data.count <= maxPayloadBytes else { return false }
        store.set(data, forKey: key)
        defaults.set(Self.hash(data), forKey: baseKey)
        return true
    }

    private nonisolated static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Наборы данных
    private struct Spec {
        let name: String
        let read: () -> Data?
        let write: (Data) -> Void
        let merge: (Data, Data) -> Data
    }

    private static let favoritesKey = "favorite_verses"
    private static let annotationsKey = "verse_annotations_map"
    private static let highlightsKey = "highlighted_verses_map"
    private static let readChaptersKey = "bible_read_chapters_by_book"

    private static var sharedDefaults: UserDefaults { AppGroupConstants.sharedDefaults }

    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }

    private static let specs: [Spec] = [
        // Избранное
        Spec(
            name: "favorites",
            read: {
                guard let raw = sharedDefaults.data(forKey: favoritesKey),
                      let items = try? JSONDecoder().decode([FavoriteItem].self, from: raw) else { return nil }
                return try? encoder().encode(items)
            },
            write: { data in
                // Не затираем локальные данные, если формат из iCloud нам неизвестен
                guard (try? JSONDecoder().decode([FavoriteItem].self, from: data)) != nil else { return }
                AppGroupConstants.syncToAll { $0.set(data, forKey: favoritesKey) }
            },
            merge: { l, r in
                let local = (try? JSONDecoder().decode([FavoriteItem].self, from: l)) ?? []
                let remote = (try? JSONDecoder().decode([FavoriteItem].self, from: r)) ?? []
                func identity(_ item: FavoriteItem) -> String {
                    item.isDailyVerse
                        ? "d|\(item.textHy)"
                        : "b|\(item.bookId ?? -1)|\(item.chapter ?? -1)|\(item.verseNumber ?? -1)"
                }
                var seen = Set(local.map(identity))
                var result = local
                for item in remote where !seen.contains(identity(item)) {
                    seen.insert(identity(item))
                    result.append(item)
                }
                return (try? encoder().encode(result)) ?? l
            }
        ),
        // Заметки, теги и цвета маркеров
        Spec(
            name: "annotations",
            read: {
                guard let raw = sharedDefaults.data(forKey: annotationsKey),
                      let map = try? JSONDecoder().decode([String: VerseAnnotation].self, from: raw) else { return nil }
                return try? encoder().encode(map)
            },
            write: { data in
                guard (try? JSONDecoder().decode([String: VerseAnnotation].self, from: data)) != nil else { return }
                AppGroupConstants.syncToAll { $0.set(data, forKey: annotationsKey) }
            },
            merge: { l, r in
                var result = (try? JSONDecoder().decode([String: VerseAnnotation].self, from: l)) ?? [:]
                let remote = (try? JSONDecoder().decode([String: VerseAnnotation].self, from: r)) ?? [:]
                for (key, value) in remote {
                    if let existing = result[key], existing.updatedAt >= value.updatedAt { continue }
                    result[key] = value
                }
                return (try? encoder().encode(result)) ?? l
            }
        ),
        // Цветные маркеры
        Spec(
            name: "highlights",
            read: {
                guard let map = sharedDefaults.dictionary(forKey: highlightsKey) as? [String: String] else { return nil }
                return try? encoder().encode(map)
            },
            write: { data in
                guard let map = try? JSONDecoder().decode([String: String].self, from: data) else { return }
                AppGroupConstants.syncToAll { $0.set(map, forKey: highlightsKey) }
            },
            merge: { l, r in
                var result = (try? JSONDecoder().decode([String: String].self, from: r)) ?? [:]
                let local = (try? JSONDecoder().decode([String: String].self, from: l)) ?? [:]
                for (key, value) in local { result[key] = value }
                return (try? encoder().encode(result)) ?? l
            }
        ),
        // Прочитанные главы
        Spec(
            name: "readChapters",
            read: {
                guard let map = sharedDefaults.dictionary(forKey: readChaptersKey) as? [String: [Int]] else { return nil }
                let sorted = map.mapValues { Array(Set($0)).sorted() }
                return try? encoder().encode(sorted)
            },
            write: { data in
                guard let map = try? JSONDecoder().decode([String: [Int]].self, from: data) else { return }
                AppGroupConstants.syncToAll { $0.set(map, forKey: readChaptersKey) }
            },
            merge: { l, r in
                var result = (try? JSONDecoder().decode([String: [Int]].self, from: l)) ?? [:]
                let remote = (try? JSONDecoder().decode([String: [Int]].self, from: r)) ?? [:]
                for (key, chapters) in remote {
                    result[key] = Array(Set(result[key] ?? []).union(chapters)).sorted()
                }
                return (try? encoder().encode(result)) ?? l
            }
        ),
        // Основные настройки (язык, оформление, шрифт, издание)
        Spec(
            name: "settings",
            read: {
                let d = sharedDefaults
                let payload = SettingsPayload(
                    language: d.string(forKey: "app_language"),
                    appearance: d.string(forKey: "app_appearance_mode"),
                    accent: d.string(forKey: "accent_theme"),
                    fontSize: d.object(forKey: "bible_font_size") as? Double,
                    edition: d.string(forKey: "armenian_bible_edition"),
                    scope: d.string(forKey: "verse_source_scope")
                )
                return try? encoder().encode(payload)
            },
            write: { data in
                guard let p = try? JSONDecoder().decode(SettingsPayload.self, from: data) else { return }
                AppGroupConstants.syncToAll { d in
                    if let v = p.language { d.set(v, forKey: "app_language") }
                    if let v = p.appearance { d.set(v, forKey: "app_appearance_mode") }
                    if let v = p.accent { d.set(v, forKey: "accent_theme") }
                    if let v = p.fontSize { d.set(v, forKey: "bible_font_size") }
                    if let v = p.edition { d.set(v, forKey: "armenian_bible_edition") }
                    if let v = p.scope { d.set(v, forKey: "verse_source_scope") }
                }
            },
            merge: { l, r in
                guard let local = try? JSONDecoder().decode(SettingsPayload.self, from: l),
                      let remote = try? JSONDecoder().decode(SettingsPayload.self, from: r) else { return l }
                let merged = SettingsPayload(
                    language: local.language ?? remote.language,
                    appearance: local.appearance ?? remote.appearance,
                    accent: local.accent ?? remote.accent,
                    fontSize: local.fontSize ?? remote.fontSize,
                    edition: local.edition ?? remote.edition,
                    scope: local.scope ?? remote.scope
                )
                return (try? encoder().encode(merged)) ?? l
            }
        ),
        // Рекорд викторины
        Spec(
            name: "quiz",
            read: {
                let best = sharedDefaults.integer(forKey: "quiz_best_score")
                guard best > 0 else { return nil }
                return try? encoder().encode(QuizPayload(best: best))
            },
            write: { data in
                guard let p = try? JSONDecoder().decode(QuizPayload.self, from: data) else { return }
                AppGroupConstants.syncToAll { $0.set(p.best, forKey: "quiz_best_score") }
            },
            merge: { l, r in
                let local = (try? JSONDecoder().decode(QuizPayload.self, from: l))?.best ?? 0
                let remote = (try? JSONDecoder().decode(QuizPayload.self, from: r))?.best ?? 0
                return (try? encoder().encode(QuizPayload(best: max(local, remote)))) ?? l
            }
        )
    ]

    struct SettingsPayload: Codable {
        var language: String?
        var appearance: String?
        var accent: String?
        var fontSize: Double?
        var edition: String?
        var scope: String?
    }

    struct QuizPayload: Codable {
        var best: Int
    }
}
