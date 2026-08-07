import Foundation
import AVFoundation
import Combine

// MARK: - Аудиоплеер официальной студийной декламации молитв Нарекаци (Сос Саргсян / Олег Моленко)
class NarekAudioPlayer: NSObject, ObservableObject {
    static let shared = NarekAudioPlayer()
    
    private var player: AVPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingId: Int? = nil
    
    override private init() {
        super.init()
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
        
        // Армянская декламация: Сос Саргсян, Русская/Английская декламация: Олег Моленко
        let urlString: String? = (language == .armenian) ? prayer.audioUrlHy : (prayer.audioUrlRu ?? prayer.audioUrlHy)
        
        guard let validUrlString = urlString, let url = URL(string: validUrlString) else {
            print("⚠️ URL аудиоисточника не найден для молитвы: \(prayer.banNumber)")
            return
        }
        
        // Настройка AVAudioSession для аудиопотока через фоновый плеер
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer
        
        currentlyPlayingId = prayer.id
        isPlaying = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        newPlayer.play()
    }
    
    func stop() {
        if let player = player {
            player.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        player = nil
        isPlaying = false
        currentlyPlayingId = nil
    }
    
    @objc private func playerItemDidFinishPlaying(notification: Notification) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
}
