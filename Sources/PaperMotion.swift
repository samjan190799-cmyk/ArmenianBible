import SwiftUI
import UIKit

// MARK: - Единый язык движения «Бумаги и чернил»
// Спокойное, книжное движение: мягкие пружины без «резинового» отскока,
// плавные растворения вместо резких переворотов. Всё уважает «Уменьшение движения».
enum PaperMotion {
    /// Системная настройка «Уменьшение движения»
    static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    /// Нажатие кнопки, карточки
    static let press = Animation.spring(response: 0.26, dampingFraction: 0.82)
    /// Появление элементов, смена содержимого
    static let appear = Animation.spring(response: 0.5, dampingFraction: 0.88)
    /// Мягкая смена состояния (растворение)
    static let swap = Animation.easeInOut(duration: 0.28)

    /// Анимация или nil, если пользователь просит уменьшить движение
    static func animation(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension Animation {
    /// Бесконечное повторение. В режиме «Уменьшение движения» анимация проигрывается один раз и замирает.
    func loops(autoreverses: Bool = true) -> Animation {
        PaperMotion.reduceMotion ? self : self.repeatForever(autoreverses: autoreverses)
    }
}

// MARK: - «Уменьшение движения» для всего дерева экрана
struct ReduceMotionGate: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }
}

extension View {
    /// Отключает анимации всего поддерева, если включено «Уменьшение движения»
    func paperMotionRoot() -> some View {
        modifier(ReduceMotionGate())
    }

    /// Плавная смена SF Symbol (play ⇄ pause, сердце и т.п.); на iOS 16 — без эффекта
    @ViewBuilder
    func symbolReplace() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.symbolEffect(.replace))
        } else {
            self
        }
    }
}

// MARK: - Тактильный отклик с учётом настройки «Вибрация»
enum Haptics {
    private static var isEnabled: Bool {
        BibleManager.shared.isHapticsEnabled
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
