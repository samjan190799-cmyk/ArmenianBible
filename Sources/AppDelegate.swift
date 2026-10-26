import UIKit
import SwiftUI

// MARK: - Системный AppDelegate для инициализации сервисов до показа сцены
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.beginReceivingRemoteControlEvents()
        PaperAppearance.apply()
        return true
    }
}
