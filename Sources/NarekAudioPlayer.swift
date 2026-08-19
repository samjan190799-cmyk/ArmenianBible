import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Полнофункциональный Аудиоплеер Нарекаци (Запоминание позиции, перемотка, плейлист)
class NarekAudioPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = NarekAudioPlayer()
    
    private var player: AVPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var statusObservation: NSKeyValueObservation?
    private var timeObserverToken: Any?
    
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingId: Int? = nil
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var isStreaming: Bool = false
    @Published var voiceLanguage: AppLanguage = .armenian
    
    // Запоминание последнего прослушанного состояния
    @Published var savedPrayerId: Int = 1
    @Published var savedTimeSeconds: Double = 0.0
    
    private let kSavedPrayerId = "narek_last_prayer_id"
    private let kSavedTimeSeconds = "narek_last_time_seconds"
    private let kSavedVoiceLang = "narek_voice_language"
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        restorePlaybackState()
        setupRemoteCommandCenter()
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
        
        // Настройка AVAudioSession для фонового и громкого звука
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
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
                        print("⚠️ Ошибка потока Нарекаци, запуск офлайн-синтеза...")
                        self.fallbackToSpeech(prayer: prayer, language: language)
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
            
            // Таймаут на случай отсутствия сети
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self, self.currentlyPlayingId == prayer.id else { return }
                if self.isStreaming && self.player?.timeControlStatus != .playing && !self.synthesizer.isSpeaking {
                    print("⚠️ Сетевой таймаут аудио, переключение на локальный голос...")
                    self.fallbackToSpeech(prayer: prayer, language: language)
                }
            }
        } else {
            fallbackToSpeech(prayer: prayer, language: language)
        }
    }
    
    func speak(prayer: NarekPrayer, language: AppLanguage) {
        togglePlay(prayer: prayer, language: language)
    }
    
    private func fallbackToSpeech(prayer: NarekPrayer, language: AppLanguage) {
        cleanupPlayer()
        isStreaming = false
        
        let textToSpeak = "\(prayer.title(for: language)). \(prayer.text(for: language))"
        let utterance = AVSpeechUtterance(string: textToSpeak)
        
        let localeCode: String
        switch language {
        case .armenian:
            localeCode = "hy-AM"
        case .russian:
            localeCode = "ru-RU"
        case .english:
            localeCode = "en-US"
        }
        
        utterance.voice = AVSpeechSynthesisVoice(language: localeCode) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 0.96
        
        duration = Double(textToSpeak.count) * 0.08
        isPlaying = true
        synthesizer.speak(utterance)
        updateNowPlayingInfo(prayer: prayer)
    }
    
    // MARK: - Управление
    
    func pause() {
        if let p = player {
            p.pause()
        }
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
        isPlaying = false
        savePlaybackState()
    }
    
    func resume() {
        if let p = player {
            p.play()
            isPlaying = true
        } else if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
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
        savePlaybackState()
        cleanupPlayer()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isStreaming = false
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
            self.playNextPrayer()
        }
    }
    
    // MARK: - Lock Screen & Control Center Integration
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else {
                self.resume()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNextPrayer()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPreviousPrayer()
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 15)
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: 15)
            return .success
        }
    }
    
    private func updateNowPlayingInfo(prayer: NarekPrayer) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = prayer.title(for: voiceLanguage)
        info[MPMediaItemPropertyArtist] = (voiceLanguage == .armenian) ? "Սոս Սարգսյան (Գրիգոր Նարեկացի)" : "Олег Моленко (Григор Нарекаци)"
        info[MPMediaItemPropertyAlbumTitle] = "Մատյան Ողբերգության"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : 300.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playNextPrayer()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
