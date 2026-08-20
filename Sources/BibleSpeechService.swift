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
        // Очищаем текст от лишних символов и нумераций
        let cleanedText = cleanSpokenText(text)
        guard !cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
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
        
        configureAudioSession()
        
        var textToUtter = cleanedText
        var chosenVoice: AVSpeechSynthesisVoice? = nil
        
        switch language {
        case .armenian:
            // Ищем установленный армянский голос в системе
            if let armenianVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.lowercased().hasPrefix("hy") }) ?? AVSpeechSynthesisVoice(language: "hy-AM") {
                chosenVoice = armenianVoice
            } else {
                // Если армянский голос не установлен в iOS, используем фонетическую транслитерацию с европейским голосом
                textToUtter = transliterateArmenianToPhonetic(cleanedText)
                chosenVoice = AVSpeechSynthesisVoice(language: "it-IT") ?? AVSpeechSynthesisVoice(language: "el-GR") ?? AVSpeechSynthesisVoice(language: "en-US")
            }
            
        case .russian:
            chosenVoice = AVSpeechSynthesisVoice(language: "ru-RU")
            
        case .english:
            chosenVoice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice(language: "en-GB")
        }
        
        let utterance = AVSpeechUtterance(string: textToUtter)
        utterance.rate = 0.46 // Спокойная, уважительная библейская скорость речи
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        if let voice = chosenVoice {
            utterance.voice = voice
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
    
    // MARK: - Очистка текста от номеров стихов перед чтением
    private func cleanSpokenText(_ raw: String) -> String {
        var text = raw
        // Убираем регулярные вкрапления цифр номеров стихов в начале строк
        text = text.replacingOccurrences(of: "\\b\\d+\\b[\\.\\:\\)]?", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n", with: " ")
        text = text.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Фонетическая транслитерация армянского текста для синтезатора
    private func transliterateArmenianToPhonetic(_ text: String) -> String {
        let map: [Character: String] = [
            "ա": "a", "բ": "b", "գ": "g", "դ": "d", "ե": "e", "զ": "z", "է": "e", "ը": "u",
            "թ": "t", "ժ": "zh", "ի": "i", "լ": "l", "խ": "kh", "ծ": "ts", "կ": "k", "հ": "h",
            "ձ": "dz", "ղ": "gh", "ճ": "ch", "մ": "m", "յ": "y", "ն": "n", "շ": "sh", "ո": "o",
            "չ": "ch", "պ": "p", "ջ": "j", "ռ": "r", "ս": "s", "վ": "v", "տ": "t", "ր": "r",
            "ց": "ts", "ւ": "v", "փ": "p", "ք": "k", "և": "yev", "օ": "o", "ֆ": "f",
            "Ա": "A", "Բ": "B", "Գ": "G", "Դ": "D", "Ե": "Ye", "Զ": "Z", "Է": "E", "Ը": "U",
            "Թ": "T", "Ժ": "Zh", "Ի": "I", "Լ": "L", "Խ": "Kh", "Ծ": "Ts", "Կ": "K", "Հ": "H",
            "Ձ": "Dz", "Ղ": "Gh", "Ճ": "Ch", "Մ": "M", "Յ": "Y", "Ն": "N", "Շ": "Sh", "Ո": "Vo",
            "Չ": "Ch", "Պ": "P", "Ջ": "J", "Ռ": "R", "Ս": "S", "Վ": "V", "Տ": "T", "Ր": "R",
            "Ց": "Ts", "Ւ": "V", "Փ": "P", "Ք": "K", "Օ": "O", "Ֆ": "F",
            "։": ".", "՝": ",", "․": ".", "«": "", "»": "", "—": " - "
        ]
        
        var result = ""
        for char in text {
            if let replacement = map[char] {
                result.append(replacement)
            } else {
                result.append(char)
            }
        }
        return result
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
