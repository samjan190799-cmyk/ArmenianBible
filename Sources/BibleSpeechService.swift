import Foundation
import AVFoundation
import SwiftUI

// MARK: - Сервис аудио-озвучки стихов и глав Библии (Text-to-Speech)
@MainActor
final class BibleSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = BibleSpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isSpeaking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentSpokenText: String = ""
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Воспроизведение текста
    func speak(text: String, language: AppLanguage) {
        // Если уже читается этот же текст — ставим на паузу или возобновляем
        if isSpeaking && currentSpokenText == text {
            if isPaused {
                resume()
            } else {
                pause()
            }
            return
        }
        
        // Останавливаем предыдущую озвучку
        stop()
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        configureAudioSession()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48 // Спокойная, уважительная библейская скорость речи
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Подбираем системный голос для языка
        let bcp47Code: String
        switch language {
        case .armenian:
            bcp47Code = "hy-AM"
        case .russian:
            bcp47Code = "ru-RU"
        case .english:
            bcp47Code = "en-US"
        }
        
        if let voice = AVSpeechSynthesisVoice(language: bcp47Code) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "hy") {
            utterance.voice = fallbackVoice
        }
        
        currentSpokenText = text
        isSpeaking = true
        isPaused = false
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - Пауза
    func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    // MARK: - Возобновление
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    // MARK: - Остановка
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
        currentSpokenText = ""
    }
    
    // MARK: - Настройка аудио-сессии
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for BibleSpeechService: \(error)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentSpokenText = ""
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentSpokenText = ""
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = false
        }
    }
}
