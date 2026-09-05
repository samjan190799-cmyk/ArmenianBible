import SwiftUI

@main
struct ArmenianBibleApp: App {
    init() {
        AdManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
