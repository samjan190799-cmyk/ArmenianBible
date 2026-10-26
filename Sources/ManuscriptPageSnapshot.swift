import SwiftUI
import UIKit

// MARK: - Картинка листа для виджета
/// Верхняя часть страницы (заставка, буквица и текст молитвы) готовой картинкой: виджет не умеет
/// рисовать рукопись сам, а показывать готовую картинку из общего контейнера может.
@MainActor
enum ManuscriptPageSnapshot {
    /// Часть страницы, которая попадает в картинку: от заставки до конца области текста
    private static let cropTop: CGFloat = 70
    private static let cropHeight: CGFloat = 400

    static func widgetImage(page: ManuscriptPage, pen: ManuscriptPen) -> UIImage? {
        let content = ManuscriptPageView(
            page: page,
            reveal: .complete,
            sheen: CGPoint(x: 0.18, y: -0.12),
            pen: pen,
            isLiveWriting: true
        )
        .offset(y: -cropTop)
        .frame(width: ManuscriptGeometry.size.width, height: cropHeight, alignment: .top)
        .clipped()

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        if let image = renderer.uiImage {
            return image
        }
        // Запасной путь: снимок через UIHostingController
        let host = UIHostingController(rootView: content)
        let size = CGSize(width: ManuscriptGeometry.size.width, height: cropHeight)
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .clear
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
    }
}
