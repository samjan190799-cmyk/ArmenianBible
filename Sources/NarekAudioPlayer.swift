import Foundation
import AVFoundation
import Combine

// MARK: - Гибридный Аудиоплеер молитв Нарекаци (Официальная декламация + Фоллбек на синтез)
class NarekAudioPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = NarekAudioPlayer()
    
    private var player: AVPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var statusObservation: NSKeyValueObservation?
    
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingId: Int? = nil
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(prayer: NarekPrayer, language: AppLanguage) {
        play(prayer: prayer, language: language)
    }
    
    func play(prayer: NarekPrayer, language: AppLanguage) {
        if isPlaying && currentlyPlayingId == prayer.id {
            stop()
            return
        }
        
        stop()
        
        currentlyPlayingId = prayer.id
        isPlaying = true
        
        // Настройка AVAudioSession для громкого и четкого воспроизведения
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
        
        let urlString: String? = (language == .armenian) ? prayer.audioUrlHy : (prayer.audioUrlRu ?? prayer.audioUrlHy)
        
        if let validUrlString = urlString, let url = URL(string: validUrlString) {
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: playerItem)
            self.player = newPlayer
            
            // Отслеживание успешности и сбоев AVPlayer
            statusObservation = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if item.status == .failed {
                        print("⚠️ AVPlayer не смог загрузить поток, запуск синтеза...")
                        self.fallbackToSpeech(prayer: prayer, language: language)
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
            
            // Таймаут безопасности: если AVPlayer застрял при загрузке сетевого потока более 2.5 сек, включаем дикторский голос
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self, self.currentlyPlayingId == prayer.id else { return }
                if self.player?.timeControlStatus != .playing && !self.synthesizer.isSpeaking {
                    print("⚠️ Таймаут онлайн декламации. Запуск плавного диктора...")
                    self.fallbackToSpeech(prayer: prayer, language: language)
                }
            }
        } else {
            fallbackToSpeech(prayer: prayer, language: language)
        }
    }
    
    private func fallbackToSpeech(prayer: NarekPrayer, language: AppLanguage) {
        statusObservation?.invalidate()
        statusObservation = nil
        
        if let p = player {
            p.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
        }
        player = nil
        
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
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.90
        utterance.pitchMultiplier = 0.98
        
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        statusObservation?.invalidate()
        statusObservation = nil
        
        if let player = player {
            player.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        player = nil
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        isPlaying = false
        currentlyPlayingId = nil
    }
    
    @objc private func playerItemDidFinishPlaying(notification: Notification) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
}
