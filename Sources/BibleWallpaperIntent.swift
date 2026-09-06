import AppIntents
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Перечисление тем для ярлыков Команд
@available(iOS 16.0, *)
enum WallpaperThemeAppEnum: String, AppEnum {
    case random = "random"
    case ararat = "ararat"
    case tatev = "tatev"
    case khachkar = "khachkar"
    case parchment = "parchment"
    case bethlehem = "bethlehem"
    case sunset = "sunset"
    case graphite = "graphite"
    case royal = "royal"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Wallpaper Theme")
    }
    
    static var caseDisplayRepresentations: [WallpaperThemeAppEnum: DisplayRepresentation] {
        [
            .random: DisplayRepresentation(title: "Случайная тема дня (Random)", subtitle: "Каждый раз новый художественный фон"),
            .ararat: DisplayRepresentation(title: "Արարատ (Арарат)", subtitle: "Священная гора на рассвете"),
            .tatev: DisplayRepresentation(title: "Տաթև (Татев)", subtitle: "Древний монастырь над ущельем"),
            .khachkar: DisplayRepresentation(title: "Խաչքար (Хачкар)", subtitle: "Резной армянский каменный крест"),
            .parchment: DisplayRepresentation(title: "Մագաղաթ (Пергамент)", subtitle: "Манускрипт Матенадарана"),
            .bethlehem: DisplayRepresentation(title: "Բեթղեհեմ (Вифлеем)", subtitle: "Звездная сапфировая ночь"),
            .sunset: DisplayRepresentation(title: "Մայրամուտ (Закат)", subtitle: "Теплый закат в горах"),
            .graphite: DisplayRepresentation(title: "Գրաֆիտ (Графит)", subtitle: "Минималистичный глубокий темный"),
            .royal: DisplayRepresentation(title: "Ծիրանի (Пурпур)", subtitle: "Царский пурпур и золото")
        ]
    }
    
    var theme: WallpaperTheme? {
        switch self {
        case .random: return nil
        case .ararat: return .ararat
        case .tatev: return .tatev
        case .khachkar: return .khachkar
        case .parchment: return .parchment
        case .bethlehem: return .bethlehem
        case .sunset: return .sunset
        case .graphite: return .graphite
        case .royal: return .royal
        }
    }
}

// MARK: - Системное действие Apple Shortcuts: Получить обои со стихом
@available(iOS 16.0, *)
struct GetVerseWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Получить обои со стихом"
    static var description = IntentDescription("Генерирует Ultra-HD обои для Экрана блокировки с армянским стихом из Библии.")
    
    @Parameter(title: "Тема оформления", default: .random)
    var theme: WallpaperThemeAppEnum
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let selectedTheme = theme.theme
        let fileURL = try BibleWallpaperGenerator.shared.generateWallpaperFile(theme: selectedTheme)
        
        let intentFile = IntentFile(
            fileURL: fileURL,
            filename: "armenian_bible_lockscreen.png",
            type: UTType.png
        )
        
        return .result(value: intentFile)
    }
}

// MARK: - Автоматическая регистрация в приложении Команды и Siri
@available(iOS 16.0, *)
struct ArmenianBibleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetVerseWallpaperIntent(),
            phrases: [
                "Обнови обои в \(.applicationName)",
                "Установи обои со стихом в \(.applicationName)",
                "Get Bible wallpaper in \(.applicationName)",
                "Պաստառ \(.applicationName)"
            ],
            shortTitle: "Обои со стихом дня",
            systemImageName: "photo.artframe"
        )
    }
}
