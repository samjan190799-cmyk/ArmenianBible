import UIKit
import SwiftUI

#if canImport(FBAudienceNetwork)
import FBAudienceNetwork
#endif

// MARK: - Системный AppDelegate для инициализации сервисов до показа сцены
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.beginReceivingRemoteControlEvents()
        
        #if canImport(FBAudienceNetwork)
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        #endif
        
        Task { @MainActor in
            LuysAdManager.shared.initialize()
        }
        return true
    }
}
