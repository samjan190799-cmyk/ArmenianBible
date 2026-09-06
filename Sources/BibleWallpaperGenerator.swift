import SwiftUI
import UIKit
import Photos

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
    
    /// Генерация пака обоев для Photo Shuffle с сохранением в отдельный альбом в галерее
    func exportBatchToPhotoAlbum(
        count: Int,
        albumName: String = "Armenian Bible",
        language: AppLanguage? = nil,
        onProgress: @escaping (Int, Int) -> Void
    ) async throws -> Int {
        // 1. Проверяем / запрашиваем доступ к Галерее
        let authStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard authStatus == .authorized || authStatus == .limited else {
            throw WallpaperGeneratorError.photosPermissionDenied
        }
        
        // 2. Ищем или создаем альбом
        let album = try await getOrCreateAlbum(named: albumName)
        
        // 3. Собираем пул стихов
        let activeLang = language ?? BibleManager.shared.appLanguage
        var candidateVerses: [BibleVerse] = []
        candidateVerses.append(contentsOf: BibleVerse.shortPearls)
        candidateVerses.append(contentsOf: BibleVerse.shortPsalms)
        candidateVerses.append(contentsOf: BibleVerse.shortLove)
        candidateVerses.append(contentsOf: BibleVerse.shortFaith)
        candidateVerses.append(contentsOf: BibleVerse.shortWisdom)
        candidateVerses.append(contentsOf: BibleVerse.database.filter { $0.textHy.count <= 110 })
        
        var seenTexts = Set<String>()
        var uniqueVerses: [BibleVerse] = []
        for v in candidateVerses.shuffled() {
            if !seenTexts.contains(v.textHy) {
                seenTexts.insert(v.textHy)
                uniqueVerses.append(v)
            }
        }
        
        if uniqueVerses.isEmpty {
            uniqueVerses = BibleVerse.shortPearls
        }
        
        let themes = WallpaperTheme.allCases
        let fonts = WallpaperFont.allCases
        let decors: [WallpaperDecor] = [.cross, .laurel, .quote, .minimal]
        
        let totalToGenerate = count
        var savedCount = 0
        
        // 4. Поочередная генерация и сохранение в альбом
        for i in 0..<totalToGenerate {
            let verse = uniqueVerses[i % uniqueVerses.count]
            let theme = themes[i % themes.count]
            let font = fonts[i % fonts.count]
            let decor = decors[i % decors.count]
            
            let image = autoreleasepool {
                generateWallpaperImage(
                    verse: verse,
                    theme: theme,
                    font: font,
                    decor: decor,
                    language: activeLang
                )
            }
            
            try await saveImageToAlbum(image: image, album: album)
            savedCount += 1
            
            onProgress(savedCount, totalToGenerate)
            
            // Yield для плавности интерфейса
            await Task.yield()
        }
        
        return savedCount
    }
    
    // MARK: - Вспомогательные методы Photos
    private func getOrCreateAlbum(named title: String) async throws -> PHAssetCollection {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existing = collections.firstObject {
            return existing
        }
        
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        }
        
        guard let localId = placeholder?.localIdentifier else {
            throw WallpaperGeneratorError.albumCreationFailed
        }
        
        let created = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localId], options: nil)
        guard let collection = created.firstObject else {
            throw WallpaperGeneratorError.albumCreationFailed
        }
        return collection
    }
    
    private func saveImageToAlbum(image: UIImage, album: PHAssetCollection) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset,
                  let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                return
            }
            albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
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
    case photosPermissionDenied
    case albumCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "Не удалось закодировать обои в формат PNG."
        case .photosPermissionDenied:
            return "Нет разрешения на запись в Фотопленку. Разрешите доступ в Настройках iPhone."
        case .albumCreationFailed:
            return "Не удалось создать альбом в приложении Фото."
        }
    }
}
