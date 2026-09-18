import UIKit
import SwiftUI

#if canImport(YandexMobileAds)
import YandexMobileAds
#endif

// MARK: - Системный AppDelegate для безопасной инициализации SDK до показа сцены
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(YandexMobileAds)
        // В строгом соответствии с официальным руководством Яндекс:
        // YandexAds.initializeSDK() ОБЯЗАН выполняться на Главном потоке (Main Thread)
        // в didFinishLaunchingWithOptions ДО активации сцены UIKit.
        YandexAds.initializeSDK {
            Task { @MainActor in
                LuysAdManager.shared.isYandexInitialized = true
                LuysAdManager.shared.preloadYandexRewarded()
            }
        }
        #endif
        return true
    }
}
