import SwiftUI
import UIKit

// MARK: - Генератор обоев для экрана блокировки и автоматизаций
@MainActor
final class BibleWallpaperGenerator {
    static let shared = BibleWallpaperGenerator()
    
    private init() {}
    
    /// Рендеринг обоев в UIImage высокого разрешения (1170x2532)
    func generateWallpaperImage(
        verse: BibleVerse,
        theme: WallpaperTheme? = nil,
        font: WallpaperFont = .serif,
        decor: WallpaperDecor = .cross,
        language: AppLanguage? = nil
    ) -> UIImage {
        let activeTheme = theme ?? getPreferredTheme()
        let activeLang = language ?? BibleManager.shared.appLanguage
        
        let fullResView = FullResolutionWallpaperView(
            verse: verse,
            theme: activeTheme,
            fontDesign: font,
            decor: decor,
            language: activeLang
        )
        .frame(width: 1170, height: 2532)
        
        let hostingController = UIHostingController(rootView: fullResView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1170, height: 2532)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1170, height: 2532))
        return renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
    
    /// Создание временного файла PNG для Apple Shortcuts Intent
    func generateWallpaperFile(
        verse: BibleVerse? = nil,
        theme: WallpaperTheme? = nil,
        language: AppLanguage? = nil
    ) throws -> URL {
        let activeVerse = verse ?? BibleManager.shared.currentVerse
        let uiImage = generateWallpaperImage(verse: activeVerse, theme: theme, language: language)
        
        guard let data = uiImage.pngData() else {
            throw WallpaperGeneratorError.imageEncodingFailed
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("armenian_bible_wallpaper_\(UUID().uuidString.prefix(8)).png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    /// Сохранение в постоянный файл в App Group для фонового доступа
    func exportToAppGroup(verse: BibleVerse? = nil) -> URL? {
        let appGroupSuite = "group.com.samvel.ArmenianBible"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupSuite) else {
            return nil
        }
        do {
            let activeVerse = verse ?? BibleManager.shared.currentVerse
            let uiImage = generateWallpaperImage(verse: activeVerse)
            guard let data = uiImage.pngData() else { return nil }
            let destURL = groupURL.appendingPathComponent("latest_verse_wallpaper.png")
            try data.write(to: destURL, options: .atomic)
            return destURL
        } catch {
            print("Failed to save wallpaper to App Group: \(error)")
            return nil
        }
    }
    
    private func getPreferredTheme() -> WallpaperTheme {
        // Подбираем тему дня гармонично
        let all = WallpaperTheme.allCases
        return all.randomElement() ?? .ararat
    }
}

enum WallpaperGeneratorError: LocalizedError {
    case imageEncodingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "Не удалось закодировать обои в формат PNG."
        }
    }
}
