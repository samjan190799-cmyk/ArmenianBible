import SwiftUI
import UIKit

// MARK: - Модальный экран настройки автоматической смены обоев
struct WallpaperAutomationSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var isExportingSample = false
    @State private var showSampleSuccessToast = false
    @State private var isShowingPaywall = false
    
    private var language: AppLanguage {
        manager.appLanguage
    }
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F")
                    .ignoresSafeArea()
                
                // Фоновые мягкие градиенты
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -100, y: -180)
                
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 120, y: 150)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхняя иконка
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(hex: "F59E0B").opacity(0.4), radius: 16, y: 6)
                            
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 6) {
                            Text(titleText)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitleText)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        // Шаги автоматизации
                        VStack(spacing: 14) {
                            stepRow(
                                number: "1",
                                title: step1Title,
                                subtitle: step1Desc,
                                icon: "clock.badge.checkmark.fill",
                                color: Color(hex: "F59E0B")
                            )
                            
                            stepRow(
                                number: "2",
                                title: step2Title,
                                subtitle: step2Desc,
                                icon: "wand.and.stars",
                                color: Color(hex: "38BDF8")
                            )
                            
                            stepRow(
                                number: "3",
                                title: step3Title,
                                subtitle: step3Desc,
                                icon: "lock.iphone",
                                color: Color(hex: "10B981")
                            )
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Кнопка: Открыть Команды
                        Button {
                            triggerHaptic(.medium)
                            openShortcutsApp()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.forward.app.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(openShortcutsButtonText)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FDE047"), Color(hex: "F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 12, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Кнопка: Проверить и сохранить образец в Фото
                        Button {
                            triggerHaptic(.light)
                            generateAndSaveSample()
                        } label: {
                            HStack(spacing: 6) {
                                if isExportingSample {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Text(testSampleButtonText)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .disabled(isExportingSample)
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Тост подтверждения
                        if showSampleSuccessToast {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(sampleSavedText)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(20)
                            .overlay(
                                Capsule().stroke(Color.green.opacity(0.5), lineWidth: 1)
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Вспомогательный ряд шага
    @ViewBuilder
    private func stepRow(number: String, title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(stepPrefix(for: number))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
    
    private func stepPrefix(for number: String) -> String {
        switch language {
        case .armenian: return "Քայլ \(number):"
        case .russian: return "Шаг \(number):"
        case .english: return "Step \(number):"
        }
    }
    
    // MARK: - Действия
    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/shortcuts/id915254992") {
            UIApplication.shared.open(appStoreURL)
        }
    }
    
    private func generateAndSaveSample() {
        isExportingSample = true
        
        Task { @MainActor in
            let image = BibleWallpaperGenerator.shared.generateWallpaperImage(verse: manager.currentVerse)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            isExportingSample = false
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showSampleSuccessToast = true
            }
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showSampleSuccessToast = false
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Локализация текстов
    private var titleText: String {
        switch language {
        case .armenian: return "Ամենօրյա Ավտո-Պաստառներ"
        case .russian: return "Ежедневная авто-смена обоев"
        case .english: return "Daily Auto-Wallpaper"
        }
    }
    
    private var subtitleText: String {
        switch language {
        case .armenian: return "Ձեր Կողպման էկրանը ամեն առավոտ կթարմացվի նոր ոգեշնչող աստվածաշնչյան տողով"
        case .russian: return "Экран блокировки будет автоматически обновляться новым стихом каждое утро через Команды iOS"
        case .english: return "Your Lock Screen will automatically update with a new Bible verse every morning via iOS Shortcuts"
        }
    }
    
    private var step1Title: String {
        switch language {
        case .armenian: return "Ստեղծեք Ավտոմատացում"
        case .russian: return "Создайте автоматизацию"
        case .english: return "Create Automation"
        }
    }
    
    private var step1Desc: String {
        switch language {
        case .armenian: return "Բացեք «Հրամաններ» հավելվածը → Ավտոմատացում → Ընտրեք «Օրվա ժամ» (օրինակ՝ 08:00)"
        case .russian: return "В приложении «Команды» перейдите в «Автоматизация» → «Время суток» (например, 08:00)"
        case .english: return "In Shortcuts app open \"Automation\" tab → \"Time of Day\" (e.g. 08:00 AM)"
        }
    }
    
    private var step2Title: String {
        switch language {
        case .armenian: return "Ընտրեք Armenian Bible"
        case .russian: return "Выберите действие"
        case .english: return "Choose Armenian Bible action"
        }
    }
    
    private var step2Desc: String {
        switch language {
        case .armenian: return "Ավելացրեք գործողություն՝ «Ստանալ պաստառը տողով» Armenian Bible-ից"
        case .russian: return "Добавьте действие: «Получить обои со стихом» из приложения Armenian Bible"
        case .english: return "Add action: \"Get Bible Verse Wallpaper\" from Armenian Bible"
        }
    }
    
    private var step3Title: String {
        switch language {
        case .armenian: return "Տեղադրել Կողպման էկրանին"
        case .russian: return "Установить обои"
        case .english: return "Set Wallpaper"
        }
    }
    
    private var step3Desc: String {
        switch language {
        case .armenian: return "Ավելացրեք համակարգային գործողություն՝ «Տեղադրել Պաստառ» և անջատեք «Հարցնել գործարկումից առաջ»"
        case .russian: return "Добавьте системное действие «Установить обои» и отключите «Спрашивать до запуска»"
        case .english: return "Add system action \"Set Wallpaper\" and toggle off \"Ask Before Running\""
        }
    }
    
    private var openShortcutsButtonText: String {
        switch language {
        case .armenian: return "Բացել «Հրամաններ» հավելվածը"
        case .russian: return "Открыть приложение «Команды»"
        case .english: return "Open Shortcuts App"
        }
    }
    
    private var testSampleButtonText: String {
        switch language {
        case .armenian: return "Փորձարկել և պահպանել նմուշը Լուսանկարներում"
        case .russian: return "Проверить и сохранить образец в Фото"
        case .english: return "Generate & Save Sample to Photos"
        }
    }
    
    private var sampleSavedText: String {
        switch language {
        case .armenian: return "Օրինակը հաջողությամբ պահպանվեց Լուսանկարներում"
        case .russian: return "Образец обоев сохранен в Фотопленку!"
        case .english: return "Sample wallpaper saved to Photos!"
        }
    }
}
