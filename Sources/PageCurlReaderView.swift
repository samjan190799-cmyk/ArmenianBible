import SwiftUI
import UIKit

// MARK: - UIPageViewController обертка для эффекта перелистывания страниц (Page Curl)

struct PageCurlReaderView<Content: View>: UIViewControllerRepresentable {
    let book: BibleBook
    @Binding var currentChapterIndex: Int
    let initialChapter: Int
    let targetVerse: Int?
    let contentBuilder: (BibleBook, Int, Int?) -> Content
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.backgroundColor = .clear
        
        let initialVC = context.coordinator.viewController(for: currentChapterIndex)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false, completion: nil)
        
        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        
        if context.coordinator.currentBookId != book.id {
            context.coordinator.currentBookId = book.id
            context.coordinator.controllersMap.removeAll()
        }
        
        let displayedVC = uiViewController.viewControllers?.first as? PageViewControllerContainer<Content>
        if let currentChapter = displayedVC?.chapter, currentChapter - 1 != currentChapterIndex {
            let direction: UIPageViewController.NavigationDirection = (currentChapter - 1 < currentChapterIndex) ? .forward : .reverse
            let targetVC = context.coordinator.viewController(for: currentChapterIndex)
            uiViewController.setViewControllers([targetVC], direction: direction, animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlReaderView
        var currentBookId: Int
        var controllersMap: [Int: PageViewControllerContainer<Content>] = [:]
        
        init(_ parent: PageCurlReaderView) {
            self.parent = parent
            self.currentBookId = parent.book.id
        }
        
        func viewController(for index: Int) -> UIViewController {
            // Ограничиваем кэш до 5 страниц вокруг текущей, предотвращая утечку памяти
            if controllersMap.count > 5 {
                let keepRange = max(0, index - 2)...min(parent.book.chaptersCount, index + 2)
                for k in Array(controllersMap.keys) {
                    if !keepRange.contains(k) {
                        controllersMap.removeValue(forKey: k)
                    }
                }
            }
            
            let targetV = (index + 1 == parent.initialChapter) ? parent.targetVerse : nil
            let contentView = parent.contentBuilder(parent.book, index + 1, targetV)
            
            if let cached = controllersMap[index] {
                cached.rootView = contentView
                return cached
            }
            
            let hostVC = PageViewControllerContainer(rootView: contentView, chapter: index + 1)
            controllersMap[index] = hostVC
            return hostVC
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? PageViewControllerContainer<Content> else { return nil }
            let index = currentVC.chapter - 1
            guard index > 0 else { return nil }
            return self.viewController(for: index - 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? PageViewControllerContainer<Content> else { return nil }
            let index = currentVC.chapter - 1
            guard index < parent.book.chaptersCount - 1 else { return nil }
            return self.viewController(for: index + 1)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleVC = pageViewController.viewControllers?.first as? PageViewControllerContainer<Content> {
                let newIndex = visibleVC.chapter - 1
                if parent.currentChapterIndex != newIndex {
                    parent.currentChapterIndex = newIndex
                }
            }
        }
    }
}

class PageViewControllerContainer<Content: View>: UIHostingController<Content> {
    var chapter: Int
    
    init(rootView: Content, chapter: Int) {
        self.chapter = chapter
        super.init(rootView: rootView)
        self.view.backgroundColor = .clear
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

