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

    /// Поворот разрешён на больших экранах (iPad, развёрнутый iPhone Duo); на обычных iPhone приложение, как и раньше, вертикальное.
    /// Модель и `userInterfaceIdiom` не проверяем: решает короткая сторона самого экрана.
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        let screen = window?.windowScene?.screen
            ?? application.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        guard let screen else { return .portrait }
        // fixedCoordinateSpace не зависит от поворота, поэтому ответ не «залипает» в альбомной ориентации
        let size = screen.fixedCoordinateSpace.bounds.size
        return ScreenLayout.supportedOrientations(shortSide: min(size.width, size.height))
    }
}

enum ScreenLayout {
    /// С какой короткой стороны экрана (в pt) приложению разрешён поворот.
    /// Самый большой iPhone — 440 pt, iPad mini — 744 pt; внутренний экран Duo по размеру ближе к маленькому планшету.
    /// Порог стоит проверить на симуляторе iPhone Duo (Xcode 27.1), точных размеров в pt Apple не публиковала.
    static let rotatableShortSide: CGFloat = 500

    static func supportedOrientations(shortSide: CGFloat) -> UIInterfaceOrientationMask {
        shortSide >= rotatableShortSide ? .all : .portrait
    }
}
