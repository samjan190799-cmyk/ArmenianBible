import SwiftUI
import StoreKit
import UIKit

// MARK: - Сервис Управления Оценками и Отзывами (Review & Rating Manager)
/// Управляет нативным системным окном оценки Apple (SKStoreReviewController)
/// и прямым переходом на форму отзыва в App Store (action=write-review).
@MainActor
public final class ReviewManager: ObservableObject {
    public static let shared = ReviewManager()
    
    /// App Store ID приложения Luys: Armenian Bible & AI
    public let appStoreID: String = "6790569890"
    
    /// Прямая ссылка на мгновенное открытие окна написания отзыва в App Store
    public var appStoreReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }
    
    private let kActionCounterKey = "review_positive_action_counter"
    private let kLastRequestedDateKey = "review_last_requested_date"
    private let kHasRatedKey = "review_has_rated_app"
    
    @Published public var isShowingReviewSheet: Bool = false
    
    private init() {}
    
    // MARK: - Фиксация полезного действия пользователя
    /// Вызывается после позитивных событий (завершение викторины, сохранение обоев, добавление в закладки)
    public func recordPositiveAction() {
        guard !hasAlreadyRated else { return }
        
        var counter = UserDefaults.standard.integer(forKey: kActionCounterKey)
        counter += 1
        UserDefaults.standard.set(counter, forKey: kActionCounterKey)
        
        // Предлагаем оценить на 3-м и 8-м позитивном действии (мягкий интервал)
        if counter == 3 || counter == 8 || (counter > 8 && counter % 15 == 0) {
            checkAndPresentReviewPrompt()
        }
    }
    
    /// Пользователь уже оценил приложение
    public var hasAlreadyRated: Bool {
        UserDefaults.standard.bool(forKey: kHasRatedKey)
    }
    
    /// Запуск показа окна оценки при соблюдении кулдауна
    public func checkAndPresentReviewPrompt() {
        guard !hasAlreadyRated else { return }
        
        if let lastDate = UserDefaults.standard.object(forKey: kLastRequestedDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            // Не чаще одного раза в 7 дней
            if days < 7 { return }
        }
        
        // Открываем красивое диалоговое окно
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.isShowingReviewSheet = true
        }
    }
    
    // MARK: - Вызов системного окна Apple StoreKit
    public func requestSystemReview() {
        UserDefaults.standard.set(Date(), forKey: kLastRequestedDateKey)
        
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    // MARK: - Открытие формы отзыва в App Store
    public func openAppStoreReviewDirectly() {
        UserDefaults.standard.set(true, forKey: kHasRatedKey)
        UserDefaults.standard.set(Date(), forKey: kLastRequestedDateKey)
        
        // Сначала пробуем системный prompt
        requestSystemReview()
        
        // Через секунду гарантированно открываем страницу написания отзыва в App Store
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if UIApplication.shared.canOpenURL(self.appStoreReviewURL) {
                UIApplication.shared.open(self.appStoreReviewURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    public func dismissLater() {
        UserDefaults.standard.set(Date(), forKey: kLastRequestedDateKey)
        isShowingReviewSheet = false
    }
}

// MARK: - Премиальное Модальное Окно Оценки (Review Prompt Sheet)
public struct ReviewPromptSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var manager = BibleManager.shared
    
    @State private var selectedStars: Int = 5
    @State private var isPulsing: Bool = false
    
    public init() {}
    
    private var language: AppLanguage {
        manager.appLanguage
    }
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var titleText: String {
        switch language {
        case .armenian: return "Ձեզ դո՞ւր է գալիս Luys-ը"
        case .russian: return "Вам нравится Luys?"
        case .english: return "Enjoying Luys?"
        }
    }
    
    private var subtitleText: String {
        switch language {
        case .armenian:
            return "Ձեր գնահատականը և կարծիքը կօգնեն ավելի շատ մարդկանց բացահայտել Աստվածաշունչը և Նարեկացու աղոթքները:"
        case .russian:
            return "Ваша оценка и отзыв помогут большему числу верующих открыть для себя Священное Писание и молитвы Нарекаци."
        case .english:
            return "Your rating and review help more people discover the Holy Scriptures and Narekatsi's prayers."
        }
    }
    
    private var rateButtonText: String {
        switch language {
        case .armenian: return "Գնահատել 5 աստղով App Store-ում"
        case .russian: return "Поставить 5 звёзд в App Store"
        case .english: return "Rate 5 Stars on App Store"
        }
    }
    
    private var laterButtonText: String {
        switch language {
        case .armenian: return "Հիշեցնել ավելի ուշ"
        case .russian: return "Напомнить позже"
        case .english: return "Remind Me Later"
        }
    }
    
    public var body: some View {
        ZStack {
            // Мягкий фон с поддержкой тем
            (colorScheme == .dark ? Color(hex: "0D0E15") : Color(hex: "F8FAFC"))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Верхний декоративный индикатор
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                Spacer()
                
                // Иконка приложения с золотым сиянием
                ZStack {
                    Circle()
                        .fill(Color(hex: "F59E0B").opacity(0.15))
                        .frame(width: 96, height: 96)
                        .scaleEffect(isPulsing ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 8)
                
                // Заголовок и пояснение
                VStack(spacing: 8) {
                    Text(titleText)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                        .multilineTextAlignment(.center)
                    
                    Text(subtitleText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                }
                
                // Интерактивный ряд из 5 золотых звёзд
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectedStars = star
                            let g = UIImpactFeedbackGenerator(style: .medium)
                            g.prepare(); g.impactOccurred()
                        } label: {
                            Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Color(hex: "F59E0B"))
                                .scaleEffect(star == selectedStars ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedStars)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                // Кнопки действия
                VStack(spacing: 12) {
                    Button {
                        let g = UINotificationFeedbackGenerator()
                        g.prepare(); g.notificationOccurred(.success)
                        ReviewManager.shared.openAppStoreReviewDirectly()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(rateButtonText)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 10, y: 5)
                    }
                    
                    Button {
                        let g = UIImpactFeedbackGenerator(style: .light)
                        g.prepare(); g.impactOccurred()
                        ReviewManager.shared.dismissLater()
                        dismiss()
                    } label: {
                        Text(laterButtonText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.fraction(0.55), .medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            isPulsing = true
        }
    }
}
