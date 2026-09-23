import SwiftUI
import WidgetKit
import LocalAuthentication

// MARK: - Вспомогательное представление: Строка инструкции
struct InstructionRow: View {
    let number: String
    let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var numberBgColor: Color {
        let accentColor = Color(hex: BibleManager.shared.accentTheme.colorHex)
        return colorScheme == .dark ? accentColor.opacity(0.1) : accentColor.opacity(0.08)
    }
    
    private var numberTextColor: Color {
        let accentColor = Color(hex: BibleManager.shared.accentTheme.colorHex)
        let secondaryAccentColor = Color(hex: BibleManager.shared.accentTheme.secondaryColorHex)
        return colorScheme == .dark ? secondaryAccentColor : accentColor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(numberTextColor)
                .frame(width: 20, height: 20)
                .background(numberBgColor)
                .clipShape(Circle())
                .padding(.top, 1)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Вспомогательное представление: Сетка точек (Dot Grid)
struct StaticDotGridView: View {
    let dotColor: Color
    
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let dotSize: CGFloat = 1.0
            let spacing: CGFloat = 22.0
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    path.addRect(CGRect(x: x, y: y, width: dotSize, height: dotSize))
                }
            }
            context.fill(path, with: .color(dotColor))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Эластичный стиль кнопки
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Инициализация цвета по Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Расширение локализации String
extension String {
    func localized(for language: AppLanguage) -> String {
        guard let path = Bundle.main.path(forResource: language.localeCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

// MARK: - Карточка Викторины для Главного Экрана
struct BibleQuizCardView: View {
    let bestScore: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onStartQuiz: () -> Void
    
    var body: some View {
        Button {
            onStartQuiz()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("quiz_title".localized(for: language))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        if bestScore > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("\(bestScore)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(primaryTextColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }
                    
                    Text("quiz_card_subtitle".localized(for: language))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(secondaryAccentColor.opacity(0.6))
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }
}

// MARK: - Всплывающий Экран Инструкции Виджета
struct WidgetInstructionSheetView: View {
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            cardBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(primaryTextColor.opacity(0.4))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 28))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("widget_instruction_title".localized(for: language))
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("widget_instruction_subtitle".localized(for: language))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(number: "1", text: "widget_step_1".localized(for: language))
                    InstructionRow(number: "2", text: "widget_step_2".localized(for: language))
                    InstructionRow(number: "3", text: "widget_step_3".localized(for: language))
                    InstructionRow(number: "4", text: "widget_step_4".localized(for: language))
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("alert_ok_button".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}



// MARK: - Вспомогательное представление: Чип категории экрана блокировки
struct LockCategoryChipView: View {
    let cat: LockScreenCategory
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let inputFieldBgColor: Color
    let inputFieldBorderColor: Color
    let primaryTextColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Text(cat.icon)
                Text(cat.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: themeColorHex).opacity(0.18) : inputFieldBgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: themeColorHex) : inputFieldBorderColor, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color(hex: themeColorHex) : primaryTextColor)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Вспомогательное представление: Чип категории домашнего виджета (Medium 4x2 & Large 4x4)
struct HomeCategoryChipView: View {
    let cat: HomeWidgetCategory
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let inputFieldBgColor: Color
    let inputFieldBorderColor: Color
    let primaryTextColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(cat.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                
                if isLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: themeColorHex).opacity(0.18) : inputFieldBgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: themeColorHex) : inputFieldBorderColor, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color(hex: themeColorHex) : primaryTextColor)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Вспомогательное представление: Карточка выбора стиля виджетов
struct WidgetStyleCardButton: View {
    let style: WidgetVisualStyle
    let isSelected: Bool
    let isLocked: Bool
    let selectedLanguage: AppLanguage
    let themeColorHex: String
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    private var accentColor: Color {
        switch style {
        case .oledStandby: return Color(hex: "F59E0B")
        case .celestialEmerald: return Color(hex: "34D399")
        case .crimsonGospel: return Color(hex: "F472B6")
        case .auroraSunset: return Color(hex: "FB923C")
        case .monasticStone: return Color(hex: "D97706")
        default: return Color(hex: themeColorHex)
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return accentColor.opacity(0.28)
        }
        return Color.black.opacity(0.12)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: style.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: themeColorHex))
                    
                    Spacer()
                    
                    if isLocked {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: "F59E0B").opacity(0.22))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .cornerRadius(5)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(accentColor)
                    }
                }
                
                Spacer(minLength: 2)
                
                Text(style.localizedName(for: selectedLanguage))
                    .font(.system(size: 12.5, weight: .bold, design: style.fontDesign))
                    .foregroundColor(style.primaryTextColor(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(style.localizedSubtitle(for: selectedLanguage))
                    .font(.system(size: 9.5))
                    .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: themeColorHex).opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(11)
            .frame(width: 130, height: 120)
            .background(style.backgroundGradient(for: colorScheme))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ?
                            LinearGradient(
                                colors: [accentColor, Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : style.borderStroke(for: colorScheme),
                        lineWidth: isSelected ? 2.2 : 1.0
                    )
            )
            .shadow(color: shadowColor, radius: isSelected ? 6 : 3, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Вспомогательное представление: Карточка предпросмотра экрана блокировки
struct LockScreenPreviewCardView: View {
    let verse: BibleVerse
    let language: AppLanguage
    let style: WidgetVisualStyle
    let colorScheme: ColorScheme
    var accentHex: String = "6366F1"
    
    private var fontSize: CGFloat {
        let count = verse.text(for: language).count
        if count <= 25 {
            return 16.5
        } else if count <= 42 {
            return 15.0
        } else {
            return 13.5
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verse.text(for: language))
                    .font(.system(size: fontSize, weight: .semibold, design: style.fontDesign))
                    .lineLimit(2)
                    .lineSpacing(-0.5)
                    .foregroundColor(style.primaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 4) {
                Text("✝")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(style.quoteIconColor(for: colorScheme, accentHex: accentHex))
                Text(verse.reference(for: language))
                    .font(.system(size: 11.5, weight: .bold, design: style.fontDesign))
                    .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: accentHex))
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8.5))
                    Text("Lock Screen")
                        .font(.system(size: 9.5, weight: .semibold))
                }
                .foregroundColor(style.secondaryTextColor(for: colorScheme, accentHex: accentHex).opacity(0.85))
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(style.buttonBackground(for: colorScheme))
                .cornerRadius(6)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.backgroundGradient(for: colorScheme))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(style.borderStroke(for: colorScheme), lineWidth: 1.3)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)
    }
}

// MARK: - Карточка Плана Чтения и Стрика для Главного Экрана
struct ReadingPlanBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenPlans: () -> Void
    
    @ObservedObject private var planManager = ReadingPlanManager.shared
    
    var body: some View {
        Button {
            onOpenPlans()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "EF4444"), Color(hex: "F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(hex: "EF4444").opacity(0.35), radius: 6, y: 2)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("\(planManager.currentStreak) \("streak_days_suffix".localized(for: language))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(primaryTextColor)
                            
                            if planManager.currentStreak > 0 {
                                Text("🔥")
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if let plan = planManager.activePlan,
                           let day = planManager.nextIncompleteDay(for: plan.id) {
                            Text("\("day_label".localized(for: language)) \(day.dayNumber): \(day.title(for: language))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("reading_plan_card_hint".localized(for: language))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                // Если есть активный план — показываем прогресс-бар
                if let plan = planManager.activePlan {
                    let progress = planManager.progress(for: plan.id)
                    let completed = planManager.completedDaysCount(for: plan.id)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(plan.title(for: language))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(completed)/\(plan.daysCount)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 5)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(5, geo.size.width * CGFloat(progress)), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.2)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


// MARK: - Visible API Key Field (high contrast, show/hide button)
struct VisibleApiKeyField: View {
    let placeholder: String
    @Binding var text: String
    let accentColor: Color

    @State private var isRevealed: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var fieldBackground: Color {
        colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.96)
    }

    private var fieldBorderColor: Color {
        text.isEmpty
            ? (colorScheme == .dark ? Color(white: 0.32) : Color(white: 0.7))
            : accentColor.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 0) {
            if isRevealed {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
            }

            Button {
                isRevealed.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(accentColor.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
        .background(fieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(fieldBorderColor, lineWidth: 1.5)
        )
        .keyboardDismissToolbar()
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
    }
}
