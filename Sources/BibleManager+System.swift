import Foundation
import SwiftUI
import WidgetKit
import UserNotifications
import LocalAuthentication

extension BibleManager {
    // MARK: - Тактильный отклик (Haptic Feedback)
    func setHapticsEnabled(_ enabled: Bool) {
        self.isHapticsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: hapticsEnabledKey)
        if enabled {
            triggerHapticImpact(.medium)
        }
    }
    
    func triggerHapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func triggerHapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Биометрическая безопасность (Face ID / Touch ID)
    func setBiometricLockEnabled(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?
        
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ?
            .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
            
        guard context.canEvaluatePolicy(policy, error: &error) else {
            completion(false)
            return
        }
        
        let reason = "biometric_auth_reason".localized(for: appLanguage)
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] (success: Bool, _: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.isBiometricLockEnabled = enabled
                    let defaults = self.sharedDefaults ?? UserDefaults.standard
                    defaults.set(enabled, forKey: self.biometricLockEnabledKey)
                    self.isAppUnlocked = true
                    self.triggerHapticNotification(.success)
                    completion(true)
                } else {
                    self.triggerHapticNotification(.error)
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithBiometrics(completion: ((Bool) -> Void)? = nil) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?
        
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ?
            .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
            
        guard context.canEvaluatePolicy(policy, error: &error) else {
            DispatchQueue.main.async {
                self.isAppUnlocked = true
                completion?(true)
            }
            return
        }
        
        let reason = "biometric_auth_reason".localized(for: appLanguage)
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] (success: Bool, _: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.isAppUnlocked = true
                    self.triggerHapticNotification(.success)
                    completion?(true)
                } else {
                    self.isAppUnlocked = false
                    self.triggerHapticNotification(.warning)
                    completion?(false)
                }
            }
        }
    }
    
    func lockApp() {
        if isBiometricLockEnabled {
            isAppUnlocked = false
        }
    }
    
    // MARK: - Управление памятью и кэшем (Cache Management)
    func calculateCacheSize() -> String {
        var totalBytes: Int64 = 0
        let fileManager = FileManager.default
        
        if let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            totalBytes += directorySize(url: cachesUrl)
        }
        
        let tempUrl = fileManager.temporaryDirectory
        totalBytes += directorySize(url: tempUrl)
        
        if let groupUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.activeSuiteName) {
            let groupCaches = groupUrl.appendingPathComponent("Library/Caches", isDirectory: true)
            totalBytes += directorySize(url: groupCaches)
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    private func directorySize(url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        
        var total: Int64 = 0
        for case let fileUrl as URL in enumerator {
            if fileUrl.lastPathComponent == "bible.db" { continue }
            if let values = try? fileUrl.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               values.isDirectory == false,
               let size = values.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    @discardableResult
    func clearAppCache() -> Bool {
        let fileManager = FileManager.default
        var hasClearedAny = false
        
        if let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let items = try? fileManager.contentsOfDirectory(at: cachesUrl, includingPropertiesForKeys: nil) {
            for item in items {
                if item.lastPathComponent == "bible.db" { continue }
                try? fileManager.removeItem(at: item)
                hasClearedAny = true
            }
        }
        
        let tempUrl = fileManager.temporaryDirectory
        if let tempItems = try? fileManager.contentsOfDirectory(at: tempUrl, includingPropertiesForKeys: nil) {
            for item in tempItems {
                if item.lastPathComponent == "bible.db" { continue }
                try? fileManager.removeItem(at: item)
                hasClearedAny = true
            }
        }
        
        self.cachedStorageSize = calculateCacheSize()
        triggerHapticNotification(.success)
        return hasClearedAny
    }
    
    // MARK: - Резервное копирование и экспорт (Backup & Export)
    struct AppBackupData: Codable {
        let appVersion: String
        let exportDate: String
        let appLanguage: String
        let favoritesCount: Int
        let favorites: [FavoriteItem]
        let annotations: [String: VerseAnnotation]
        let highlightedVerses: [String: String]
        let readingStreak: Int
        let bestStreak: Int
        let completedReadingDays: [String: [Int]]
    }
    
    @MainActor
    func generateBackupArchive() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileDateString = fileDateFormatter.string(from: Date())
        
        let planManager = ReadingPlanManager.shared
        
        let backup = AppBackupData(
            appVersion: "2.3",
            exportDate: dateString,
            appLanguage: appLanguage.displayName,
            favoritesCount: favoriteVerses.count,
            favorites: favoriteVerses,
            annotations: annotations,
            highlightedVerses: highlightedVerses,
            readingStreak: planManager.currentStreak,
            bestStreak: planManager.bestStreak,
            completedReadingDays: planManager.completedDays
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(backup) else { return nil }
        
        let fileName = "ArmenianBible_Backup_\(fileDateString).json"
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempUrl, options: .atomic)
            triggerHapticNotification(.success)
            return tempUrl
        } catch {
            print("Failed to save backup file: \(error)")
            return nil
        }
    }
    
    // MARK: - Сохранение стиха в AppGroup и обновление виджета
    func updateCurrentVerse(_ verse: BibleVerse) {
        let enriched = BibleDatabase.shared.enrichVerse(verse)
        self.currentVerse = enriched
        // Принудительно уведомляем SwiftUI, т.к. BibleVerse struct с computed свойствами
        // может не считаться "изменённым" при смене языка (stored properties те же)
        objectWillChange.send()
        AppGroupConstants.syncToAll { defaults in
            defaults.set(enriched.id.uuidString, forKey: "currentVerseId")
            // Экран блокировки (Lock Screen) строго изолирован: питается ТОЛЬКО короткими стихами из syncLockScreenWidget()
            // Ни в коем случае не перезаписываем currentLockScreenVerseId стихами общего чтения из приложения!
            defaults.set(enriched.id.uuidString, forKey: "currentSmallVerseId")
            defaults.set(enriched.id.uuidString, forKey: "currentMediumVerseId")
            defaults.set(enriched.id.uuidString, forKey: "currentLargeVerseId")
            
            // Сохраняем мультиязычные тексты стиха для виджета домашнего экрана
            defaults.set(enriched.text(for: .armenian), forKey: "currentVerseTextHy")
            defaults.set(enriched.textHy, forKey: "currentVerseTextHyEchmiadzin")
            defaults.set(enriched.textHyArarat, forKey: "currentVerseTextHyArarat")
            defaults.set(enriched.textRu, forKey: "currentVerseTextRu")
            defaults.set(enriched.textEn, forKey: "currentVerseTextEn")
            defaults.set(enriched.refHy, forKey: "currentVerseRefHy")
            defaults.set(enriched.refRu, forKey: "currentVerseRefRu")
            defaults.set(enriched.refEn, forKey: "currentVerseRefEn")
            
            defaults.set(enriched.text, forKey: textKey)
            defaults.set(enriched.reference, forKey: referenceKey)
        }
        
        // Заставляем виджеты домашнего экрана немедленно обновиться
        WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Выбор случайного стиха из оффлайн-базы данных
    func selectRandomVerse() {
        if let randomVerse = BibleDatabase.shared.getRandomVerse(scope: verseSourceScope) {
            updateCurrentVerse(randomVerse)
        } else {
            let database = getFilteredDatabase(for: selectedCategory)
            guard !database.isEmpty else { return }
            
            let availableVerses = database.filter { $0.text != currentVerse.text }
            let newVerse: BibleVerse
            
            if !availableVerses.isEmpty {
                newVerse = availableVerses.randomElement() ?? database[0]
            } else {
                newVerse = database[0]
            }
            
            updateCurrentVerse(newVerse)
        }
    }
    
    // MARK: - Обновление источника выборки стихов
    func updateVerseSourceScope(_ scope: VerseSourceScope) {
        self.verseSourceScope = scope
        if let defaults = sharedDefaults {
            defaults.set(scope.rawValue, forKey: verseSourceScopeKey)
            defaults.synchronize()
        }
        selectRandomVerse()
    }
}
