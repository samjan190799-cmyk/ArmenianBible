import Foundation
import UIKit

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

// MARK: - Согласие на персонализированную рекламу (Google UMP)
/// Для пользователей из ЕС, Великобритании и Швейцарии Google требует сертифицированную
/// платформу согласия (CMP); UMP — собственная CMP Google. В остальных странах окно не
/// показывается, и canRequestAds сразу истина. Порядок запуска рекламы:
/// согласие → запрос ATT → запуск Google Mobile Ads SDK → загрузка объявлений.
@MainActor
final class AdConsentManager {
    static let shared = AdConsentManager()
    private init() {}

    /// Можно ли запрашивать рекламу (согласие получено, не требуется или сохранено с прошлого запуска)
    var canRequestAds: Bool {
        #if canImport(UserMessagingPlatform)
        return ConsentInformation.shared.canRequestAds
        #else
        return true
        #endif
    }

    /// Нужно ли показывать в настройках пункт «Параметры конфиденциальности» (требование UMP)
    var isPrivacyOptionsRequired: Bool {
        #if canImport(UserMessagingPlatform)
        return ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        #else
        return false
        #endif
    }

    /// Обновляет сведения о согласии (при каждом запуске) и при необходимости показывает форму.
    /// Повторяет порядок вызовов из официального примера Google (BannerExample).
    func gatherConsent(
        from viewController: UIViewController? = nil,
        completion: @escaping @MainActor (Error?) -> Void
    ) {
        #if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()
        parameters.debugSettings = DebugSettings()

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { requestConsentError in
            guard requestConsentError == nil else {
                Task { @MainActor in
                    completion(requestConsentError)
                }
                return
            }

            Task { @MainActor in
                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: viewController)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
        #else
        completion(nil)
        #endif
    }

    /// Форма «Параметры конфиденциальности», где пользователь меняет своё решение
    func presentPrivacyOptionsForm(from viewController: UIViewController? = nil) async throws {
        #if canImport(UserMessagingPlatform)
        try await ConsentForm.presentPrivacyOptionsForm(from: viewController)
        #endif
    }
}
