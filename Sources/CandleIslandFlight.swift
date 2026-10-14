import SwiftUI
import UIKit

// MARK: - Свеча взлетает в Dynamic Island
/// Когда свеча зажжена, она отрывается от листа, дугой летит вверх и уменьшается до размера свечи
/// в острове; в момент посадки запускается Live Activity. Полёт идёт в отдельном прозрачном окне
/// поверх всего, поэтому не ограничен листом, из которого свеча взлетает.
@MainActor
enum CandleIslandFlight {
    private static var overlayWindow: UIWindow?

    private static var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    /// Остров есть у моделей, у которых верхний отступ безопасной зоны не меньше 51 pt
    static var hasIsland: Bool {
        guard let window = activeScene?.windows.first else { return false }
        return window.safeAreaInsets.top >= 51
    }

    /// Можно ли лететь: остров есть, Live Activity разрешены, анимации не отключены
    static var canFly: Bool {
        hasIsland && CandleIslandManager.shared.isAvailable && !UIAccessibility.isReduceMotionEnabled
    }

    /// `start` — рамка свечи на экране (в глобальных координатах). `landed` вызывается, когда свеча села.
    static func play(tier: CandleTier, from start: CGRect, landed: @escaping () -> Void) {
        guard canFly, let scene = activeScene else {
            landed()
            return
        }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        let host = UIHostingController(rootView: FlightView(
            tier: tier,
            start: start,
            screen: scene.screen.bounds.size,
            onLanded: {
                window.isHidden = true
                overlayWindow = nil
                landed()
            }
        ))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        overlayWindow = window
    }
}

private struct FlightView: View {
    let tier: CandleTier
    let start: CGRect
    let screen: CGSize
    let onLanded: () -> Void

    @State private var began = Date()
    private let duration: TimeInterval = 1.05

    /// Где в острове садится свеча: слева, как в свёрнутом виде Live Activity
    private var target: CGPoint {
        CGPoint(x: screen.width / 2 - 72, y: 32)
    }

    private func bezier(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
            y: u * u * a.y + 2 * u * t * c.y + t * t * b.y
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let raw = CGFloat(min(1, max(0, timeline.date.timeIntervalSince(began) / duration)))
            // Сначала свеча чуть приподнимается, потом разгоняется к острову
            let eased = raw < 0.5 ? 2 * raw * raw : 1 - pow(-2 * raw + 2, 2) / 2
            let from = CGPoint(x: start.midX, y: start.midY)
            let control = CGPoint(x: from.x + (target.x - from.x) * 0.1 + 28, y: from.y - (from.y - target.y) * 0.55)
            let position = bezier(from, control, target, eased)
            let scale = 1 - eased * 0.885
            // В конце свеча растворяется: на её месте уже загорается остров
            let fade = raw > 0.88 ? max(0, 1 - (raw - 0.88) / 0.12) : 1

            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.5), Color.clear],
                        center: .center, startRadius: 0, endRadius: 150
                    ))
                    .frame(width: 300, height: 300)
                RealisticArmenianCandleView(
                    tier: tier,
                    burnProgress: 0,
                    isLit: true,
                    randomSeed: 3,
                    quality: .hero,
                    ignitesOnAppear: false
                )
                .frame(width: 180, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .scaleEffect(scale)
            .opacity(Double(fade))
            .position(position)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            began = Date()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                onLanded()
            }
        }
    }
}
