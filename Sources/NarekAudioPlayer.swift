import Foundation
import AVFoundation
import Combine

// MARK: - Аудиоплеер озвучки молитв Нарекаци (Apple Speech Synthesizer)
class NarekAudioPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = NarekAudioPlayer()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingId: Int? = nil
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(prayer: NarekPrayer, language: AppLanguage) {
        if isPlaying && currentlyPlayingId == prayer.id {
            stop()
            return
        }
        
        stop()
        
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
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92 // Слегка спокойный размеренный темп для духовных молитв
        utterance.pitchMultiplier = 0.98
        
        // Настройка AVAudioSession для воспроизведения звука через динамик даже в бесшумном режиме
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
        
        currentlyPlayingId = prayer.id
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        currentlyPlayingId = nil
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingId = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlayingId = nil
        }
    }
}
