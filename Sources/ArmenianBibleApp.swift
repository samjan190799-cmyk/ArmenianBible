import SwiftUI

@main
struct ArmenianBibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var manager = BibleManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(manager.appearanceMode.colorScheme)
                .task {
                    // Предотвращение Watchdog 0x8BADF00D:
                    // Инициализация рекламных сервисов запускается строго после того,
                    // как сцена приложения (UIWindowScene) полностью активна и отрисована.
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    LuysAdManager.shared.initialize()
                }
        }
    }
}
