import Foundation
import SwiftUI
import WidgetKit

extension BibleManager {
    /// Перечитывает данные, которые синхронизация iCloud записала в общее хранилище,
    /// и обновляет состояние экрана. Сохранение обратно не вызывается, поэтому петель не возникает.
    func reloadFromCloudSync() {
        let defaults = AppGroupConstants.sharedDefaults

        if let data = defaults.data(forKey: favoritesKey),
           let items = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            favoriteVerses = items
        }
        if let map = defaults.dictionary(forKey: "highlighted_verses_map") as? [String: String] {
            highlightedVerses = map
        }
        if let data = defaults.data(forKey: "verse_annotations_map"),
           let map = try? JSONDecoder().decode([String: VerseAnnotation].self, from: data) {
            annotations = map
        }
        if let saved = defaults.dictionary(forKey: "bible_read_chapters_by_book") as? [String: [Int]] {
            var loaded: [Int: Set<Int>] = [:]
            for (key, values) in saved {
                if let bookId = Int(key) {
                    loaded[bookId] = Set(values)
                }
            }
            readChaptersByBook = loaded
        }

        if let raw = defaults.string(forKey: appLanguageKey), let value = AppLanguage(rawValue: raw) {
            appLanguage = value
        }
        if let raw = defaults.string(forKey: appearanceModeKey), let value = AppAppearanceMode(rawValue: raw) {
            appearanceMode = value
        }
        if let raw = defaults.string(forKey: accentThemeKey), let value = AccentColorTheme(rawValue: raw) {
            accentTheme = value
        }
        let fontSize = defaults.double(forKey: "bible_font_size")
        if fontSize > 0 {
            bibleFontSize = fontSize
        }
        if let raw = defaults.string(forKey: "armenian_bible_edition"), let value = ArmenianBibleEdition(rawValue: raw) {
            armenianEdition = value
        }
        if let raw = defaults.string(forKey: verseSourceScopeKey), let value = VerseSourceScope(rawValue: raw) {
            verseSourceScope = value
        }
        quizBestScore = max(quizBestScore, defaults.integer(forKey: "quiz_best_score"))

        objectWillChange.send()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
