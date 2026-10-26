import SwiftUI

@main
struct ArmenianBibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .paperMotionRoot()
                .preferredColorScheme(manager.appearanceMode.colorScheme)
                .tint(manager.accentTheme.color)
                .overlay(alignment: .top) { PomegranateTaskToastView() }
                .task {
                    // Предотвращение Watchdog 0x8BADF00D: тяжёлые сервисы стартуют строго после того,
                    // как сцена приложения (UIWindowScene) полностью активна и отрисована.
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    CloudSyncManager.shared.start()
                    Funnel.start()
                    PromoFrameExporter.runIfRequested()
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .background { Funnel.flushNow() }
                }
        }
    }
}
