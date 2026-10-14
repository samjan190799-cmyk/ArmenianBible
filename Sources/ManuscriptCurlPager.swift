import SwiftUI
import UIKit

// MARK: - Листание «как страница»: загиб листа, как в книге
/// Обёртка над UIPageViewController в режиме pageCurl: лист загибается у края, под ним виден следующий.
/// Сам лист рисует SwiftUI (пишется пером, блестит золото); здесь только перелистывание.
struct ManuscriptCurlPager: UIViewControllerRepresentable {
    /// Номера листов по порядку
    let ids: [UUID]
    @Binding var currentId: UUID
    /// Меняется, когда у всех листов меняется вид (стиль, основа, имя): соседние листы пересоздаются
    let refreshToken: String
    /// Содержимое листа: второй параметр — этот лист сейчас открыт (на нём пишет перо)
    let page: (UUID, Bool) -> AnyView

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        controller.isDoubleSided = false
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.view.backgroundColor = .clear
        // Касание у края листа само переворачивает страницу, а здесь касание значит «переписать заново»
        for recognizer in controller.gestureRecognizers where recognizer is UITapGestureRecognizer {
            recognizer.isEnabled = false
        }
        controller.setViewControllers([context.coordinator.controller(for: currentId)], direction: .forward, animated: false)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        // Пока лист загибается, содержимое не трогаем: UIKit не любит смену экранов посреди перехода
        guard !coordinator.isTurning,
              let visible = controller.viewControllers?.first as? UIHostingController<AnyView>,
              let visibleId = coordinator.id(of: visible) else { return }

        if visibleId == currentId {
            visible.rootView = page(visibleId, true)
            if coordinator.refreshToken != refreshToken {
                coordinator.refreshToken = refreshToken
                // UIKit хранит соседние листы готовыми; пересборка заставит его запросить их заново
                controller.setViewControllers([visible], direction: .forward, animated: false)
            }
            return
        }
        // Лист сменили не пальцем (кнопка, «Мой Матенадаран»): переходим к нему
        let from = ids.firstIndex(of: visibleId) ?? 0
        let to = ids.firstIndex(of: currentId) ?? 0
        coordinator.isTurning = true
        controller.setViewControllers(
            [coordinator.controller(for: currentId)],
            direction: to >= from ? .forward : .reverse,
            animated: context.transaction.animation != nil
        ) { _ in
            coordinator.isTurning = false
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: ManuscriptCurlPager
        var isTurning = false
        var refreshToken: String

        init(_ parent: ManuscriptCurlPager) {
            self.parent = parent
            self.refreshToken = parent.refreshToken
        }

        /// Номер листа хранится в заголовке контроллера: так не нужен свой подкласс
        func id(of controller: UIViewController) -> UUID? {
            controller.title.flatMap { UUID(uuidString: $0) }
        }

        func controller(for id: UUID) -> UIViewController {
            let controller = UIHostingController(rootView: parent.page(id, id == parent.currentId))
            controller.title = id.uuidString
            controller.view.backgroundColor = .clear
            return controller
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let id = id(of: viewController), let index = parent.ids.firstIndex(of: id), index > 0 else { return nil }
            return controller(for: parent.ids[index - 1])
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let id = id(of: viewController), let index = parent.ids.firstIndex(of: id),
                  index + 1 < parent.ids.count else { return nil }
            return controller(for: parent.ids[index + 1])
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                willTransitionTo pendingViewControllers: [UIViewController]) {
            isTurning = true
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            isTurning = false
            guard completed, let visible = pageViewController.viewControllers?.first, let id = id(of: visible) else { return }
            DispatchQueue.main.async {
                self.parent.currentId = id
            }
        }
    }
}
