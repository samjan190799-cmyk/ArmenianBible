import Foundation
import AVFoundation
import MediaPlayer
import Combine

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
    
    private let kSavedPrayerId = "narek_last_prayer_id"
    private let kSavedTimeSeconds = "narek_last_time_seconds"
    private let kSavedVoiceLang = "narek_voice_language"
    private let kSavedPlaybackRate = "narek_playback_rate"
    private let kSavedAutoPlayNext = "narek_autoplay_next_chapter"
    
    override private init() {
        super.init()
        restorePlaybackState()
        setupRemoteCommandCenter()
        setupAudioSessionNotifications()
        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }
    
    // MARK: - Сохранение и Восстановление состояния
    
    func restorePlaybackState() {
        let prayerId = UserDefaults.standard.integer(forKey: kSavedPrayerId)
        savedPrayerId = prayerId > 0 ? prayerId : 1
        savedTimeSeconds = UserDefaults.standard.double(forKey: kSavedTimeSeconds)
        
        if let rawLang = UserDefaults.standard.string(forKey: kSavedVoiceLang),
           let lang = AppLanguage(rawValue: rawLang) {
            voiceLanguage = lang
        }
        
        let savedRate = UserDefaults.standard.double(forKey: kSavedPlaybackRate)
        playbackRate = savedRate > 0 ? savedRate : 1.0
        
        if UserDefaults.standard.object(forKey: kSavedAutoPlayNext) != nil {
            autoPlayNextChapter = UserDefaults.standard.bool(forKey: kSavedAutoPlayNext)
        } else {
            autoPlayNextChapter = true
        }
        
        currentTime = savedTimeSeconds
        currentlyPlayingId = savedPrayerId
    }
    
    func savePlaybackState() {
        if let currentId = currentlyPlayingId {
            savedPrayerId = currentId
            savedTimeSeconds = currentTime
            UserDefaults.standard.set(savedPrayerId, forKey: kSavedPrayerId)
            UserDefaults.standard.set(savedTimeSeconds, forKey: kSavedTimeSeconds)
            UserDefaults.standard.set(voiceLanguage.rawValue, forKey: kSavedVoiceLang)
            UserDefaults.standard.set(playbackRate, forKey: kSavedPlaybackRate)
            UserDefaults.standard.set(autoPlayNextChapter, forKey: kSavedAutoPlayNext)
        }
    }
    
    // MARK: - Воспроизведение
    
    func togglePlay(prayer: NarekPrayer, language: AppLanguage? = nil) {
        let lang = language ?? voiceLanguage
        voiceLanguage = lang
        
        if isPlaying && currentlyPlayingId == prayer.id {
            pause()
            return
        }
        
        if !isPlaying && currentlyPlayingId == prayer.id && player != nil {
            resume()
            return
        }
        
        playPrayer(prayer, language: lang)
    }
    
    func playPrayer(_ prayer: NarekPrayer, language: AppLanguage? = nil) {
        let lang = language ?? voiceLanguage
        voiceLanguage = lang
        currentlyPlayingId = prayer.id
        savedPrayerId = prayer.id
        let targetTime = prayer.audioTimestampSeconds(for: lang)
        
        if let p = player {
            seek(to: targetTime)
            if !isPlaying {
                p.play()
                p.rate = Float(playbackRate)
                isPlaying = true
            }
            updateNowPlayingInfo(prayer: prayer)
        } else {
            play(prayer: prayer, language: lang, startAtSeconds: targetTime)
        }
    }
    
    func play(prayer: NarekPrayer, language: AppLanguage, startAtSeconds: Double = 0.0) {
        stop()
        
        currentlyPlayingId = prayer.id
        voiceLanguage = language
        isPlaying = true
        currentTime = startAtSeconds
        
        // Настройка AVAudioSession для полноценного системного плеера на Lock Screen
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            DispatchQueue.main.async {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
        
        // Проверяем наличие встроенного файла в бандле приложения
        let resourceName = (language == .armenian) ? "narek_sos_sargsyan" : "narek_oleg_molenko"
        var targetUrl = Bundle.main.url(forResource: resourceName, withExtension: "mp3")
        if targetUrl == nil {
            targetUrl = Bundle.main.url(forResource: resourceName, withExtension: "mp3", subdirectory: "Audio")
        }
        if targetUrl == nil {
            targetUrl = Bundle.main.url(forResource: "narek_russian_prayers", withExtension: "mp3")
        }
        if targetUrl == nil {
            let urlString: String? = (language == .armenian) ? prayer.audioUrlHy : (prayer.audioUrlRu ?? prayer.audioUrlHy)
            if let validUrlString = urlString {
                targetUrl = URL(string: validUrlString)
            }
        }
        
        if let url = targetUrl {
            isStreaming = url.scheme == "http" || url.scheme == "https"
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: playerItem)
            self.player = newPlayer
            
            // Наблюдение за статусом
            statusObservation = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if item.status == .readyToPlay {
                        let dur = item.duration.seconds
                        if !dur.isNaN && dur > 0 {
                            self.duration = dur
                        }
                        if startAtSeconds > 0 {
                            let seekTime = CMTime(seconds: startAtSeconds, preferredTimescale: 600)
                            newPlayer.seek(to: seekTime)
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
                guard let self = self, self.isPlaying else { return }
                let currentSec = time.seconds
                if !currentSec.isNaN {
                    self.currentTime = currentSec
                    self.savePlaybackState()
                    
                    // Автоматически синхронизируем активную главу с текущим таймкодом
                    if let active = NarekatsiDatabase.shared.prayers.last(where: { $0.audioTimestampSeconds(for: self.voiceLanguage) <= currentSec }) {
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
                        }
                    }
                }
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            newPlayer.play()
            newPlayer.rate = Float(playbackRate)
        } else {
            print("⚠️ Аудиофайл для главы Нарекаци не найден")
            isPlaying = false
        }
    }
    
    // MARK: - Управление
    
    func pause() {
        if let p = player {
            p.pause()
        }
        isPlaying = false
        updateNowPlayingInfo()
        savePlaybackState()
    }
    
    func resume() {
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
        currentTime = seconds
        if let p = player {
            let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
            p.seek(to: targetTime)
        }
        updateNowPlayingInfo()
        savePlaybackState()
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
            playPrayer(nextPrayer, language: voiceLanguage)
        }
    }
    
    func playPreviousPrayer() {
        guard let currentId = currentlyPlayingId ?? Optional(savedPrayerId) else { return }
        let prevId = currentId > 1 ? currentId - 1 : 95
        if let prevPrayer = NarekatsiDatabase.shared.prayers.first(where: { $0.id == prevId }) {
            playPrayer(prevPrayer, language: voiceLanguage)
        }
    }
    
    func stop() {
        setSleepTimer(.off)
        savePlaybackState()
        cleanupPlayer()
        isPlaying = false
        isStreaming = false
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
        
        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        if let p = player {
            p.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
        }
        player = nil
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
    
    // MARK: - Системные уведомления AVAudioSession (Прерывания и отключение наушников)
    
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
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
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.resume()
            }
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.pause()
            }
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.isPlaying {
                    self.pause()
                } else {
                    self.resume()
                }
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.playNextPrayer()
            }
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.playPreviousPrayer()
            }
            return .success
        }
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.skipForward(seconds: 15)
            }
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.skipBackward(seconds: 15)
            }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            DispatchQueue.main.async {
                self.seek(to: posEvent.positionTime)
            }
            return .success
        }
    }
    
    func updateNowPlayingInfo(prayer: NarekPrayer? = nil) {
        let p = prayer ?? (currentlyPlayingId != nil ? NarekatsiDatabase.shared.prayers.first(where: { $0.id == currentlyPlayingId }) : nil)
        guard let currentPrayer = p else { return }
        
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentPrayer.title(for: voiceLanguage)
        info[MPMediaItemPropertyArtist] = (voiceLanguage == .armenian) ? "Սոս Սարգսյան (Գրիգոր Նարեկացի)" : "Олег Моленко (Григор Нарекаци)"
        info[MPMediaItemPropertyAlbumTitle] = "Մատյան Ողբերգության"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : 300.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        
        if let artImage = UIImage(named: "AppIcon") ?? UIImage(systemName: "book.pages.fill") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in artImage }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

