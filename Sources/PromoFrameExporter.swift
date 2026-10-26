import SwiftUI
import UIKit

// MARK: - Кадры анимаций для роликов в соцсети
/// Запись экрана симулятора в CI рваная (графика считается процессором, кадры приходят то по пять, то по восемьдесят в секунду),
/// поэтому ролик собирается из кадров, нарисованных по одному в точные моменты времени, ровно тридцать в секунду.
/// Запуск: `-promo_export manuscript` или `-promo_export nativity`. Кадры ложатся в Documents/promo_<имя>/frame_0000.jpg,
/// по окончании появляется Documents/promo_done_<имя>.txt.
@MainActor
enum PromoFrameExporter {
    static let fps = 30.0

    static func runIfRequested() {
        guard let kind = UserDefaults.standard.string(forKey: "promo_export") else { return }
        Task { @MainActor in
            switch kind {
            case "manuscript": await exportManuscript()
            case "nativity": await exportNativity()
            default: break
            }
        }
    }

    // MARK: Рукопись: перо пишет стих
    private static func exportManuscript() async {
        let language = BibleManager.shared.appLanguage
        guard case .curated(let page) = ManuscriptPage.debugSource(fallbackLanguage: language),
              let folder = makeFolder("manuscript") else { return }
        let pen = ManuscriptPen.effective
        let length = ManuscriptTextLayout.cached(for: page, pen: pen).length
        let frames = Int(11.5 * fps)
        for index in 0..<frames {
            let t = Double(index) / fps
            let reveal = ManuscriptReveal.at(time: t, textLength: length, turned: false, speed: .fast)
            // Блик золота медленно гуляет: так лист живёт и без датчика наклона
            let sheen = CGPoint(x: sin(t * 0.7) * 0.85, y: cos(t * 0.45) * 0.35)
            write(ManuscriptPageView(page: page, reveal: reveal, sheen: sheen, pen: pen), size: ManuscriptGeometry.size, scale: 2.6, to: folder, index: index)
            if index % 8 == 0 { await Task.yield() }
        }
        finish("manuscript", frames: frames)
    }

    // MARK: Мультфильм: ангел и пастухи (сцена 4 целиком, с плавным переходом от предыдущей)
    private static func exportNativity() async {
        let language = BibleManager.shared.appLanguage
        guard let folder = makeFolder("nativity") else { return }
        let start = NativityStory.start(of: 3)
        let frames = Int(10.0 * fps)
        for index in 0..<frames {
            let time = start + Double(index) / fps
            write(NativityExportFrame(time: time, language: language), size: CGSize(width: 440, height: 956), scale: 2.1, to: folder, index: index)
            if index % 8 == 0 { await Task.yield() }
        }
        finish("nativity", frames: frames)
    }

    // MARK: Запись кадров
    private static func makeFolder(_ name: String) -> URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = docs.appendingPathComponent("promo_\(name)", isDirectory: true)
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func finish(_ name: String, frames: Int) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? "\(frames)".write(to: docs.appendingPathComponent("promo_done_\(name).txt"), atomically: true, encoding: .utf8)
    }

    private static func write<V: View>(_ view: V, size: CGSize, scale: CGFloat, to folder: URL, index: Int) {
        let content = view.frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        var image = renderer.uiImage
        if image == nil {
            let host = UIHostingController(rootView: content)
            host.view.frame = CGRect(origin: .zero, size: size)
            host.view.backgroundColor = .clear
            host.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
        }
        guard let data = image?.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: folder.appendingPathComponent(String(format: "frame_%04d.jpg", index)), options: .atomic)
    }
}

// MARK: - Кадр мультфильма в заданную секунду истории
/// Тот же рисунок, подписи и полоски сцен, что на экране мультфильма, но без времени от часов: кадр зависит только от `time`
private struct NativityExportFrame: View {
    let time: Double
    let language: AppLanguage

    private let crossfade = 0.9

    var body: some View {
        let place = NativityStory.locate(time)
        ZStack {
            Color.black

            Canvas { context, size in
                if place.index > 0 && place.time < crossfade {
                    let previous = place.index - 1
                    NativityArt.render(scene: previous, time: NativityStory.scenes[previous].duration, ambient: time, size: size, in: &context)
                    context.drawLayer { layer in
                        layer.opacity = place.time / crossfade
                        NativityArt.render(scene: place.index, time: place.time, ambient: time, size: size, in: &layer)
                    }
                } else {
                    NativityArt.render(scene: place.index, time: place.time, ambient: time, size: size, in: &context)
                }
            }

            VStack(spacing: 0) {
                Spacer()
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.80)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 380)
            }

            VStack(spacing: 0) {
                progressBars
                    .padding(.top, 58)
                Spacer(minLength: 0)
                captionView(index: place.index, sceneTime: place.time)
                Color.clear.frame(height: 44)
            }
        }
    }

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<NativityStory.scenes.count, id: \.self) { index in
                let fill = nvClamp((time - NativityStory.start(of: index)) / NativityStory.scenes[index].duration)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.28))
                        Capsule().fill(Color.white.opacity(0.92)).frame(width: geo.size.width * CGFloat(fill))
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func captionView(index: Int, sceneTime: Double) -> some View {
        let captions = NativityStory.scenes[index].captions
        VStack(spacing: 10) {
            if let current = captions.lastIndex(where: { $0.from <= sceneTime }) {
                let end = current + 1 < captions.count ? captions[current + 1].from : NativityStory.scenes[index].duration
                let fadeIn = min(1, (sceneTime - captions[current].from) / 0.7)
                let fadeOut = min(1, (end - sceneTime) / 0.6)
                let alpha = max(0, min(fadeIn, fadeOut))
                let content = NativityStory.text(for: captions[current], language: language)
                Text(content.text)
                    .font(PaperFont.font(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .lineLimit(9)
                    .minimumScaleFactor(0.7)
                    .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 1)
                    .opacity(alpha)
                Text(content.reference.uppercased())
                    .font(PaperFont.font(size: 12, weight: .semibold))
                    .tracking(1.6)
                    .foregroundColor(NP.gold)
                    .opacity(alpha)
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
    }
}
