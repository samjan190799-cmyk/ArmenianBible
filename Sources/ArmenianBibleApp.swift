import SwiftUI

@main
struct ArmenianBibleApp: App {
    @ObservedObject private var manager = BibleManager.shared
    
    init() {
        AdManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(manager.appearanceMode.colorScheme)
        }
    }
}
