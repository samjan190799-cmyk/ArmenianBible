import SwiftUI
import UIKit

// MARK: - Листы рукописи как картинки и том кодекса как PDF
enum ManuscriptExport {
    /// Готовая страница с золотом, бликом и подписью Luys
    @MainActor
    static func pageImage(_ page: ManuscriptPage, pen: ManuscriptPen, scale: CGFloat) -> UIImage? {
        render(ManuscriptPageView(page: page, reveal: .complete, sheen: CGPoint(x: 0.18, y: -0.12), showsWatermark: true, pen: pen), scale: scale)
    }

    @MainActor
    static func render<Content: View>(_ content: Content, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        if let image = renderer.uiImage {
            return image
        }
        let host = UIHostingController(rootView: content)
        host.view.frame = CGRect(origin: .zero, size: ManuscriptGeometry.size)
        host.view.backgroundColor = .clear
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: ManuscriptGeometry.size, format: format).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Том одним файлом: титульный лист и страницы в том порядке, в каком они стоят в книге.
    /// volume — номер тома для титула; nil, когда том единственный
    @MainActor
    static func codexPDF(pages: [ManuscriptPage], owner: String, language: AppLanguage, pen: ManuscriptPen, volume: Int?) -> URL? {
        var images: [UIImage] = []
        if let cover = render(ManuscriptCodexTitleView(count: pages.count, volume: volume, owner: owner, language: language), scale: 2) {
            images.append(cover)
        }
        for page in pages {
            if let image = pageImage(page, pen: pen, scale: 2) {
                images.append(image)
            }
        }
        guard images.count > 1 else { return nil }

        let bounds = CGRect(origin: .zero, size: ManuscriptGeometry.size)
        let fileName = volume.map { "Luys-Matenadaran-\($0).pdf" } ?? "Luys-Matenadaran.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try UIGraphicsPDFRenderer(bounds: bounds).writePDF(to: url) { context in
                for image in images {
                    context.beginPage()
                    // Через JPEG том из двенадцати страниц занимает несколько мегабайт, а не сотни
                    let compact = image.jpegData(compressionQuality: 0.85).flatMap { UIImage(data: $0) } ?? image
                    compact.draw(in: bounds)
                }
            }
            return url
        } catch {
            return nil
        }
    }
}

extension ManuscriptText {
    /// «Том 2»: название тома кодекса
    static func volume(_ number: Int, _ language: AppLanguage) -> String {
        pick(language, hy: "Հատոր \(number)", ru: "Том \(number)", en: "Volume \(number)")
    }
}

/// Файл для окна «Поделиться»
struct CodexFile: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Титульный лист тома: переплёт, название, имя владельца
struct ManuscriptCodexTitleView: View {
    let count: Int
    let volume: Int?
    let owner: String
    let language: AppLanguage

    private static let gold = ManuscriptPalette.color(0xE2C36C)

    private var subtitle: String {
        let pages = ManuscriptText.pick(language, hy: "\(count) էջ", ru: "\(count) стр.", en: "\(count) pages")
        return owner.isEmpty ? pages : "\(owner) · \(pages)"
    }

    var body: some View {
        ZStack(alignment: .top) {
            ManuscriptCodexCover(isBound: true)
            VStack(spacing: 8) {
                Text(ManuscriptText.pick(language, hy: "Մատենադարան", ru: "Матенадаран", en: "Matenadaran"))
                    .font(PaperFont.font(size: 34, weight: .semibold))
                    .foregroundColor(Self.gold)
                if let volume {
                    Text(ManuscriptText.volume(volume, language))
                        .font(PaperFont.font(size: 20, weight: .semibold))
                        .foregroundColor(Self.gold.opacity(0.9))
                }
                Text(subtitle)
                    .font(PaperFont.font(size: 15))
                    .foregroundColor(Self.gold.opacity(0.8))
                Text("Luys")
                    .font(PaperFont.font(size: 12, weight: .semibold))
                    .tracking(3)
                    .foregroundColor(Self.gold.opacity(0.55))
                    .padding(.top, 18)
            }
            .padding(.top, 440)
        }
        .frame(width: ManuscriptGeometry.size.width, height: ManuscriptGeometry.size.height)
    }
}
