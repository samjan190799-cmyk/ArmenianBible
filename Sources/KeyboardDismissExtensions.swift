import SwiftUI
import UIKit

// MARK: - Глобальные расширения для управления клавиатурой (Keyboard Dismiss Extensions)
extension View {
    /// Программно скрывает системную клавиатуру
    @MainActor
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Добавляет аккуратную кнопку скрытия над клавиатурой (Keyboard Accessory Toolbar)
    func keyboardDismissToolbar(onDismiss: (() -> Void)? = nil) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    onDismiss?()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    /// Закрывает клавиатуру при нажатии на свободную область фона
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
}
