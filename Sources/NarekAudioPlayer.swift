import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - Проверка среды выполнения (TestFlight vs App Store)
extension Bundle {
    /// Флаг определения среды: true для TestFlight (sandboxReceipt), DEBUG или симулятора.
    /// В боевом App Store возвращает false.
    static var isTestFlightOrDebug: Bool {
        #if DEBUG || targetEnvironment(simulator)
        return true
        #else
        if let receiptURL = Bundle.main.appStoreReceiptURL, receiptURL.lastPathComponent == "sandboxReceipt" {
            return true
        }
        return false
        #endif
    }
}

// MARK: - Опции таймера сна аудиоплеера
enum NarekSleepTimerOption: Int, CaseIterable, Identifiable {
    case off = 0
    case min15 = 15
    case min30 = 30
    case min45 = 45
    case min60 = 60
    case endOfChapter = -1

    var id: Int { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .off: return "narek_sleep_timer_off".localized(for: language)
        case .min15: return "narek_sleep_timer_15m".localized(for: language)
        case .min30: return "narek_sleep_timer_30m".localized(for: language)
        case .min45: return "narek_sleep_timer_45m".localized(for: language)
        case .min60: return "narek_sleep_timer_60m".localized(for: language)
        case .endOfChapter: return "narek_sleep_timer_end_of_chapter".localized(for: language)
        }
    }
}

// MARK: - Полнофункциональный Аудиоплеер Нарекаци (Запоминание позиции, перемотка, плейлист)
class NarekAudioPlayer: NSObject, ObservableObject {
    static let shared = NarekAudioPlayer()

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var timeObserverToken: Any?

    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingId: Int? = nil
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var isStreaming: Bool = false
    @Published var voiceLanguage: AppLanguage = .armenian

    // Настройки воспроизведения (Пункт 2)
    @Published var playbackRate: Double = 1.0
    @Published var autoPlayNextChapter: Bool = true
    @Published var sleepTimerOption: NarekSleepTimerOption = .off
    @Published var sleepTimerRemainingSeconds: Int = 0
    private var sleepCountdownTimer: Timer? = nil

    // Запоминание последнего прослушанного состояния
    @Published var savedPrayerId: Int = 1
    @Published var savedTimeSeconds: Double = 0.0

    /// Пользователь упёрся в бесплатный лимит — экран Нарека показывает оплату
    @Published var paywallRequested: Bool = false

    private let kSavedPrayerId = "narek_last_prayer_id"
    private let kSavedTimeSeconds = "narek_last_time_seconds"
    private let kSavedVoiceLang = "narek_voice_language"
    private let kSavedPlaybackRate = "narek_playback_rate"
    private let kSavedAutoPlayNext = "narek_autoplay_next_chapter"

    /// Голос сохранённой позиции: время в файле имеет смысл только для того же голоса
    private var savedVoiceLanguage: AppLanguage = .armenian
    /// Голос, для которого сейчас загружен AVPlayer (у каждого голоса свой файл)
    private var loadedVoiceIsArmenian: Bool? = nil
    /// Пока плеер переходит к стартовой позиции, его время (0:00) нельзя считать настоящим
    private var isSeekPending = false
    private var lastPersistDate = Date.distantPast
    /// Приложение на переднем плане (обновляется уведомлениями жизненного цикла)
    private var isAppInForeground = true

    /// Длительности файлов озвучки (сек). Нужны, чтобы бегунок сразу показывал
    /// сохранённую позицию, ещё до загрузки плеера.
    private let armenianTotalSeconds = 3169.0
    private let russianTotalSeconds = 3710.0

    override private init() {
        super.init()
        restorePlaybackState()
        setupRemoteCommandCenter()
        setupAudioSessionNotifications()
        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }

    // MARK: - Правила фонового воспроизведения

    /// Фон и экран блокировки доступны ТОЛЬКО в TestFlight (и Debug).
    /// В App Store звук работает лишь пока приложение открыто.
    private var backgroundPlaybackAllowed: Bool {
        Bundle.isTestFlightOrDebug || isAppInForeground
    }

    // MARK: - Бесплатный лимит (защита внутри плеера, а не только на кнопках)

    /// Без Premium доступна только глава 1: до начала главы 2 в файле озвучки.
    /// Ограничение по времени файла, а не по номеру главы: файл идёт подряд и сам «перетекал» бы дальше.
    private var isPremiumUser: Bool {
        SubscriptionManager.premiumSnapshot
    }

    private func freeLimitSeconds(for language: AppLanguage) -> Double {
        NarekatsiDatabase.shared.prayers.first(where: { $0.id == 2 })?.audioTimestampSeconds(for: language) ?? 258.0
    }

    private func isPositionAllowed(_ seconds: Double, language: AppLanguage) -> Bool {
        isPremiumUser || seconds < freeLimitSeconds(for: language) - 0.5
    }

    /// Дошли до конца бесплатной главы (или попытались выйти за неё): стоп, возврат к началу главы 1 и предложение оплаты.
    private func stopAtFreeLimit() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentlyPlayingId = 1
        currentTime = 0
        savePlaybackState(refreshFromPlayer: false)
        updateNowPlayingInfo()
        paywallRequested = true
    }

    private func knownDuration(for language: AppLanguage) -> Double {
        language == .armenian ? armenianTotalSeconds : russianTotalSeconds
    }

    private func isSameVoice(_ a: AppLanguage, _ b: AppLanguage) -> Bool {
        (a == .armenian) == (b == .armenian)
    }

    private func isLoadedVoice(_ language: AppLanguage) -> Bool {
        guard let loaded = loadedVoiceIsArmenian else { return false }
        return loaded == (language == .armenian)
    }

    // MARK: - Сохранение и Восстановление состояния

    func restorePlaybackState() {
        let prayerId = UserDefaults.standard.integer(forKey: kSavedPrayerId)
        savedPrayerId = prayerId > 0 ? prayerId : 1
        savedTimeSeconds = max(0, UserDefaults.standard.double(forKey: kSavedTimeSeconds))

        if let rawLang = UserDefaults.standard.string(forKey: kSavedVoiceLang),
           let lang = AppLanguage(rawValue: rawLang) {
            voiceLanguage = lang
        }
        savedVoiceLanguage = voiceLanguage

        let savedRate = UserDefaults.standard.double(forKey: kSavedPlaybackRate)
        playbackRate = savedRate > 0 ? savedRate : 1.0

        if UserDefaults.standard.object(forKey: kSavedAutoPlayNext) != nil {
            autoPlayNextChapter = UserDefaults.standard.bool(forKey: kSavedAutoPlayNext)
        } else {
            autoPlayNextChapter = true
        }

        currentTime = savedTimeSeconds
        currentlyPlayingId = savedPrayerId
        duration = knownDuration(for: voiceLanguage)
    }

    /// Записывает текущую главу и точное время на диск.
    /// - Parameter refreshFromPlayer: взять время прямо у плеера (а не из последнего тика бегунка).
    func savePlaybackState(refreshFromPlayer: Bool = true) {
        guard let currentId = currentlyPlayingId else { return }

        if refreshFromPlayer, !isSeekPending, let p = player {
            let t = p.currentTime().seconds
            if t.isFinite && t >= 0 {
                currentTime = t
            }
        }

        savedPrayerId = currentId
        savedTimeSeconds = currentTime
        savedVoiceLanguage = voiceLanguage
        UserDefaults.standard.set(savedPrayerId, forKey: kSavedPrayerId)
        UserDefaults.standard.set(savedTimeSeconds, forKey: kSavedTimeSeconds)
        UserDefaults.standard.set(voiceLanguage.rawValue, forKey: kSavedVoiceLang)
        UserDefaults.standard.set(playbackRate, forKey: kSavedPlaybackRate)
        UserDefaults.standard.set(autoPlayNextChapter, forKey: kSavedAutoPlayNext)
        lastPersistDate = Date()
    }

    /// Место, с которого нужно продолжить главу: сохранённая позиция (тот же голос и глава),
    /// иначе nil — тогда воспроизведение начнётся с начала главы.
    private func resumePosition(for prayer: NarekPrayer, language: AppLanguage) -> Double? {
        guard prayer.id == savedPrayerId,
              isSameVoice(language, savedVoiceLanguage),
              savedTimeSeconds > 1 else { return nil }
        // Дослушали файл до конца — начинаем главу заново
        guard savedTimeSeconds < knownDuration(for: language) - 3 else { return nil }
        guard isPositionAllowed(savedTimeSeconds, language: language) else { return nil }
        return savedTimeSeconds
    }

    // MARK: - Воспроизведение

    func togglePlay(prayer: NarekPrayer, language: AppLanguage? = nil) {
        let lang = language ?? voiceLanguage

        if isPlaying && currentlyPlayingId == prayer.id {
            pause()
            return
        }

        if !isPlaying && currentlyPlayingId == prayer.id && player != nil && isLoadedVoice(lang) {
            resume()
            return
        }

        playPrayer(prayer, language: lang)
    }

    func playPrayer(_ prayer: NarekPrayer, language: AppLanguage? = nil) {
        guard backgroundPlaybackAllowed else { return }

        let lang = language ?? voiceLanguage
        // Позицию продолжения определяем до смены состояния
        let startTime = resumePosition(for: prayer, language: lang) ?? prayer.audioTimestampSeconds(for: lang)
        guard isPositionAllowed(startTime, language: lang) else {
            paywallRequested = true
            return
        }

        if let p = player, isLoadedVoice(lang) {
            voiceLanguage = lang
            currentlyPlayingId = prayer.id
            savedPrayerId = prayer.id
            seek(to: startTime)
            if !isPlaying {
                p.play()
                p.rate = Float(playbackRate)
                isPlaying = true
            }
            updateNowPlayingInfo(prayer: prayer)
        } else {
            play(prayer: prayer, language: lang, startAtSeconds: startTime)
        }
    }

    func play(prayer: NarekPrayer, language: AppLanguage, startAtSeconds: Double? = nil) {
        guard backgroundPlaybackAllowed else { return }

        let startAt = startAtSeconds ?? prayer.audioTimestampSeconds(for: language)
        guard isPositionAllowed(startAt, language: language) else {
            paywallRequested = true
            return
        }

        // Останавливаем прежний плеер, не затирая сохранённую позицию промежуточным состоянием
        setSleepTimer(.off)
        cleanupPlayer()
        isStreaming = false

        currentlyPlayingId = prayer.id
        savedPrayerId = prayer.id
        voiceLanguage = language
        loadedVoiceIsArmenian = (language == .armenian)
        isPlaying = true
        currentTime = startAt
        duration = knownDuration(for: language)
        savePlaybackState(refreshFromPlayer: false)

        // Настройка AVAudioSession: категория .playback с default режимом и опциями маршрутизации
        // гарантирует непрерывное воспроизведение при блокировке экрана и сворачивании
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            DispatchQueue.main.async {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
            #if DEBUG
            print("🎧 [NarekPlayer] AVAudioSession активирован (.playback, .default) — TestFlight: \(Bundle.isTestFlightOrDebug)")
            #endif
        } catch {
            print("⚠️ [NarekPlayer] Ошибка настройки AVAudioSession: \(error)")
        }

        // Немедленно регистрируем информацию о треке в Центре управления и на Экране блокировки
        updateNowPlayingInfo(prayer: prayer)

        // Проверяем наличие встроенного файла в бандле приложения
        let resourceName = (language == .armenian) ? "narek_sos_sargsyan" : "narek_oleg_molenko"
        var targetUrl = Bundle.main.url(forResource: resourceName, withExtension: "mp3")
        if targetUrl == nil {
            targetUrl = Bundle.main.url(forResource: resourceName, withExtension: "mp3", subdirectory: "Audio")
        }
        if targetUrl == nil {
            let urlString: String? = (language == .armenian) ? prayer.audioUrlHy : (prayer.audioUrlRu ?? prayer.audioUrlHy)
            if let validUrlString = urlString {
                targetUrl = URL(string: validUrlString)
            }
        }

        guard let url = targetUrl else {
            print("⚠️ Аудиофайл для главы Нарекаци не найден")
            isPlaying = false
            return
        }

        isStreaming = url.scheme == "http" || url.scheme == "https"
        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem.preferredForwardBufferDuration = 30.0

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        newPlayer.preventsDisplaySleepDuringVideoPlayback = false
        self.player = newPlayer

        // Наблюдение за статусом
        statusObservation = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self, self.player === newPlayer else { return }
                if item.status == .readyToPlay {
                    let dur = item.duration.seconds
                    if !dur.isNaN && dur > 0 {
                        self.duration = dur
                    }
                    self.isStreaming = false
                    self.updateNowPlayingInfo(prayer: prayer)
                } else if item.status == .failed {
                    print("⚠️ Ошибка потока Нарекаци: \(item.error?.localizedDescription ?? "unknown error")")
                    self.isPlaying = false
                }
            }
        }

        // Периодический таймер времени для бегунка
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, self.isPlaying, !self.isSeekPending else { return }
            let currentSec = time.seconds
            guard !currentSec.isNaN else { return }

            // Бесплатный лимит (или Premium закончился прямо во время прослушивания)
            if !self.isPositionAllowed(currentSec, language: self.voiceLanguage) {
                self.stopAtFreeLimit()
                return
            }
            self.currentTime = currentSec

            // Сохраняем позицию на диск не чаще раза в 3 секунды: и память не потеряется,
            // и системный watchdog в фоне не сработает от лишнего I/O
            if Date().timeIntervalSince(self.lastPersistDate) >= 3 {
                self.savePlaybackState(refreshFromPlayer: false)
            }

            // Автоматически синхронизируем активную главу с текущим таймкодом
            if abs(currentSec - startAt) > 1.0,
               let active = NarekatsiDatabase.shared.prayers.last(where: { $0.audioTimestampSeconds(for: self.voiceLanguage) <= currentSec }) {
                if self.currentlyPlayingId != active.id {
                    if self.sleepTimerOption == .endOfChapter {
                        self.setSleepTimer(.off)
                        self.pause()
                        return
                    }
                    if !self.autoPlayNextChapter && self.currentlyPlayingId != nil {
                        self.pause()
                        return
                    }
                    self.currentlyPlayingId = active.id
                    self.savedPrayerId = active.id
                    self.savePlaybackState(refreshFromPlayer: false)
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Сначала переходим к нужной позиции и только потом включаем звук:
        // без «проблеска» с 00:00 и без обратного скачка после загрузки
        let rate = Float(playbackRate)
        if startAt > 0.5 {
            isSeekPending = true
            let target = CMTime(seconds: startAt, preferredTimescale: 600)
            newPlayer.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self, weak newPlayer] _ in
                DispatchQueue.main.async {
                    guard let self = self, let p = newPlayer, self.player === p else { return }
                    self.isSeekPending = false
                    if self.isPlaying && self.backgroundPlaybackAllowed {
                        p.play()
                        p.rate = rate
                    }
                }
            }
        } else {
            newPlayer.play()
            newPlayer.rate = rate
        }
    }

    // MARK: - Управление

    func pause() {
        if let p = player {
            p.pause()
        }
        savePlaybackState()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        // Вне TestFlight продолжить звук из фона или с экрана блокировки нельзя
        guard backgroundPlaybackAllowed else { return }

        // Без Premium дальше бесплатной главы продолжать нельзя
        guard isPositionAllowed(currentTime, language: voiceLanguage) else {
            paywallRequested = true
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("⚠️ [NarekPlayer] Ошибка активации AVAudioSession в resume: \(error)")
        }

        if let p = player {
            p.play()
            p.rate = Float(playbackRate)
            isPlaying = true
            updateNowPlayingInfo()
        } else if let currentId = currentlyPlayingId,
                  let prayer = NarekatsiDatabase.shared.prayers.first(where: { $0.id == currentId }) {
            play(prayer: prayer, language: voiceLanguage, startAtSeconds: currentTime)
        }
    }

    func seek(to seconds: Double) {
        let bounded = max(0, seconds)
        // Перемотка за пределы бесплатной главы
        guard isPositionAllowed(bounded, language: voiceLanguage) else {
            if player != nil {
                stopAtFreeLimit()
            } else {
                paywallRequested = true
            }
            return
        }
        currentTime = bounded
        if let p = player {
            let targetTime = CMTime(seconds: bounded, preferredTimescale: 600)
            p.seek(to: targetTime)
        }
        updateNowPlayingInfo()
        savePlaybackState(refreshFromPlayer: false)
    }

    func skipForward(seconds: Double = 15) {
        let newTime = min(currentTime + seconds, duration > 0 ? duration : currentTime + seconds)
        seek(to: newTime)
    }

    func skipBackward(seconds: Double = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    func playNextPrayer() {
        guard let currentId = currentlyPlayingId ?? Optional(savedPrayerId) else { return }
        let nextId = currentId < 95 ? currentId + 1 : 1
        if let nextPrayer = NarekatsiDatabase.shared.prayers.first(where: { $0.id == nextId }) {
            playChapterFromStart(nextPrayer)
        }
    }

    func playPreviousPrayer() {
        guard let currentId = currentlyPlayingId ?? Optional(savedPrayerId) else { return }
        let prevId = currentId > 1 ? currentId - 1 : 95
        if let prevPrayer = NarekatsiDatabase.shared.prayers.first(where: { $0.id == prevId }) {
            playChapterFromStart(prevPrayer)
        }
    }

    /// Явный переход к другой главе (вперёд/назад) — всегда с её начала, без «продолжения».
    private func playChapterFromStart(_ prayer: NarekPrayer) {
        guard backgroundPlaybackAllowed else { return }
        let start = prayer.audioTimestampSeconds(for: voiceLanguage)
        guard isPositionAllowed(start, language: voiceLanguage) else {
            paywallRequested = true
            return
        }
        if let p = player, isLoadedVoice(voiceLanguage) {
            currentlyPlayingId = prayer.id
            savedPrayerId = prayer.id
            seek(to: start)
            if !isPlaying {
                p.play()
                p.rate = Float(playbackRate)
                isPlaying = true
            }
            updateNowPlayingInfo(prayer: prayer)
        } else {
            play(prayer: prayer, language: voiceLanguage, startAtSeconds: start)
        }
    }

    func stop() {
        setSleepTimer(.off)
        savePlaybackState()
        cleanupPlayer()
        isPlaying = false
        isStreaming = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Управление скоростью, автопереходом и таймером сна

    func setPlaybackRate(_ rate: Double) {
        playbackRate = rate
        UserDefaults.standard.set(rate, forKey: kSavedPlaybackRate)
        if isPlaying {
            player?.rate = Float(rate)
        }
        updateNowPlayingInfo()
    }

    func setAutoPlayNextChapter(_ enabled: Bool) {
        autoPlayNextChapter = enabled
        UserDefaults.standard.set(enabled, forKey: kSavedAutoPlayNext)
    }

    func setSleepTimer(_ option: NarekSleepTimerOption) {
        sleepCountdownTimer?.invalidate()
        sleepCountdownTimer = nil
        sleepTimerOption = option

        switch option {
        case .off:
            sleepTimerRemainingSeconds = 0
        case .min15, .min30, .min45, .min60:
            sleepTimerRemainingSeconds = option.rawValue * 60
            startSleepTimerCountdown()
        case .endOfChapter:
            sleepTimerRemainingSeconds = 0
        }
    }

    private func startSleepTimerCountdown() {
        sleepCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            DispatchQueue.main.async {
                if self.sleepTimerRemainingSeconds > 1 {
                    self.sleepTimerRemainingSeconds -= 1
                } else {
                    self.sleepTimerRemainingSeconds = 0
                    self.sleepTimerOption = .off
                    timer.invalidate()
                    self.sleepCountdownTimer = nil
                    self.pause()
                }
            }
        }
    }

    private func cleanupPlayer() {
        statusObservation?.invalidate()
        statusObservation = nil
        isSeekPending = false

        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
            timeObserverToken = nil
        }

        if let p = player {
            p.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
        }
        player = nil
        loadedVoiceIsArmenian = nil
    }

    @objc private func playerItemDidFinishPlaying(notification: Notification) {
        DispatchQueue.main.async {
            if self.sleepTimerOption == .endOfChapter {
                self.setSleepTimer(.off)
                self.pause()
            } else if self.autoPlayNextChapter {
                self.playNextPrayer()
            } else {
                self.pause()
            }
        }
    }

    // MARK: - Системные уведомления AVAudioSession и Жизненного Цикла

    private func setupAudioSessionNotifications() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        center.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        center.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        // Позиция должна пережить любое закрытие приложения
        center.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func handleAppWillResignActive() {
        DispatchQueue.main.async { [weak self] in
            self?.savePlaybackState()
        }
    }

    @objc private func handleAppWillTerminate() {
        // Вызывается на главном потоке; выполняем синхронно, пока процесс не завершён
        savePlaybackState()
    }

    @objc private func handleAppDidBecomeActive() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isAppInForeground = true
            // После возвращения показываем актуальную информацию в Центре управления
            if self.player != nil {
                self.updateNowPlayingInfo()
            }
        }
    }

    @objc private func handleAppDidEnterBackground() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isAppInForeground = false
            self.savePlaybackState()

            // ВАЖНОЕ ТРЕБОВАНИЕ: Фоновое воспроизведение и работа при блокировке экрана
            // активны ТОЛЬКО для пользователей TestFlight (и разработчиков в Debug).
            // В боевом релизе App Store звук останавливается при сворачивании, а элементы
            // управления убираются с экрана блокировки, чтобы продолжить нельзя было и оттуда.
            if !Bundle.isTestFlightOrDebug {
                if self.isPlaying {
                    #if DEBUG
                    print("🛑 [NarekPlayer] Режим App Store: фоновое воспроизведение отключено при сворачивании")
                    #endif
                    self.pause()
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } else if self.isPlaying {
                // Для TestFlight: обновляем информацию на экране блокировки
                self.updateNowPlayingInfo()
            }
        }
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        DispatchQueue.main.async {
            switch type {
            case .began:
                // Системное прерывание (входящий звонок, Siri, будильник)
                self.pause()
            case .ended:
                // Прерывание завершилось
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    self.resume()
                }
            @unknown default:
                break
            }
        }
    }

    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        // По стандартам Apple HIG: если наушники/AirPods отключены, звук ставится на паузу
        if reason == .oldDeviceUnavailable {
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.pause()
                }
            }
        }
    }

    // MARK: - Lock Screen & Control Center Integration

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Пауза разрешена всегда; всё, что запускает звук, — только когда фон разрешён
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.pause()
            }
            return .success
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, self.backgroundPlaybackAllowed else { return .commandFailed }
            DispatchQueue.main.async {
                self.resume()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.pause()
                } else if self.backgroundPlaybackAllowed {
                    self.resume()
                }
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self, self.backgroundPlaybackAllowed else { return .commandFailed }
            DispatchQueue.main.async {
                self.playNextPrayer()
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self, self.backgroundPlaybackAllowed else { return .commandFailed }
            DispatchQueue.main.async {
                self.playPreviousPrayer()
            }
            return .success
        }

        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self = self, self.backgroundPlaybackAllowed else { return .commandFailed }
            DispatchQueue.main.async {
                self.skipForward(seconds: 15)
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self = self, self.backgroundPlaybackAllowed else { return .commandFailed }
            DispatchQueue.main.async {
                self.skipBackward(seconds: 15)
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  self.backgroundPlaybackAllowed,
                  let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            DispatchQueue.main.async {
                self.seek(to: posEvent.positionTime)
            }
            return .success
        }
    }

    func updateNowPlayingInfo(prayer: NarekPrayer? = nil) {
        // Вне TestFlight на экране блокировки плеера быть не должно
        guard backgroundPlaybackAllowed else { return }

        let p = prayer ?? (currentlyPlayingId != nil ? NarekatsiDatabase.shared.prayers.first(where: { $0.id == currentlyPlayingId }) : nil)
        guard let currentPrayer = p else { return }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentPrayer.title(for: voiceLanguage)
        info[MPMediaItemPropertyArtist] = (voiceLanguage == .armenian) ? "Սոս Սարգսյան (Գրիգոր Նարեկացի)" : "Олег Моленко (Григор Нарекаци)"
        info[MPMediaItemPropertyAlbumTitle] = "Մատյան Ողբերգության"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : 300.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

        if let artImage = UIImage(named: "AppIcon") ?? UIImage(systemName: "book.pages.fill") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in artImage }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
