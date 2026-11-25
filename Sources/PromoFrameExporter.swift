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
            case "treestages": await exportTreeStages()
            case "treedaily": await exportTreeDaily()
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

    // MARK: Гранатовое древо: рост по ступеням и рост за одно задание
    /// Кадр дерева в пропорциях 9:16, чтобы крона занимала весь экран ролика
    private static let treeFrameSize = CGSize(width: 440, height: 782)
    private static let treeFrameScale: CGFloat = 2.2

    private static func treeSnapshot(_ stage: PomegranateStage, within: Double, fruits: Int = 0) -> PomegranateGrowthSnapshot {
        PomegranateGrowthSnapshot(stage: stage, within: within, fruits: fruits, day: "2026-01-01")
    }

    /// Замедленная съёмка: от зёрнышка до Древа Жизни. Время идёт быстрее обычного, каждая ступень вырастает из прежней так же, как на экране сада
    private static func exportTreeStages() async {
        guard let folder = makeFolder("treestages") else { return }
        let size = treeFrameSize
        let stages: [PomegranateStage] = [.seed, .sprout, .youngTree, .bloomingTree, .fruitfulTree, .treeOfLife]
        let speed = 1.8
        var index = 0
        for _ in 0..<Int(0.8 * fps) {
            let still = PomegranateGrowthFrame(resting: treeSnapshot(.seed, within: 0))
            write(TreeExportFrame(frame: still, time: Double(index) / fps, size: size), size: size, scale: treeFrameScale, to: folder, index: index)
            index += 1
            if index % 8 == 0 { await Task.yield() }
        }
        for step in 1..<stages.count {
            let plan = PomegranateGrowthPlan(
                from: treeSnapshot(stages[step - 1], within: 1),
                to: treeSnapshot(stages[step], within: 0.5),
                start: Date(),
                delay: 0
            )
            let count = Int(plan.total / speed * fps)
            for i in 0..<count {
                let frame = plan.frame(at: Double(i) / fps * speed)
                write(TreeExportFrame(frame: frame, time: Double(index) / fps, size: size), size: size, scale: treeFrameScale, to: folder, index: index)
                index += 1
                if index % 8 == 0 { await Task.yield() }
            }
        }
        for _ in 0..<Int(2.4 * fps) {
            let still = PomegranateGrowthFrame(resting: treeSnapshot(.treeOfLife, within: 0.5))
            write(TreeExportFrame(frame: still, time: Double(index) / fps, size: size), size: size, scale: treeFrameScale, to: folder, index: index)
            index += 1
            if index % 8 == 0 { await Task.yield() }
        }
        finish("treestages", frames: index)
    }

    /// Рост за одно задание: к корням падает росинка, по кроне проходит волна роста, на ветках вырастают три граната
    private static func exportTreeDaily() async {
        guard let folder = makeFolder("treedaily") else { return }
        let size = treeFrameSize
        let plan = PomegranateGrowthPlan(
            from: treeSnapshot(.fruitfulTree, within: 0.45, fruits: 0),
            to: treeSnapshot(.fruitfulTree, within: 0.6, fruits: 3),
            start: Date(),
            delay: 0.8
        )
        let count = Int((plan.total + 1.6) * fps)
        for index in 0..<count {
            let frame = plan.frame(at: Double(index) / fps)
            write(TreeExportFrame(frame: frame, time: Double(index) / fps, size: size), size: size, scale: treeFrameScale, to: folder, index: index)
            if index % 8 == 0 { await Task.yield() }
        }
        finish("treedaily", frames: count)
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

// MARK: - Кадр гранатового древа
/// Древо на том же тёмном фоне, что и экран сада; кадр зависит только от кадра роста и времени ветра
private struct TreeExportFrame: View {
    let frame: PomegranateGrowthFrame
    let time: Double
    let size: CGSize

    var body: some View {
        let scene = PomegranateScene(stage: frame.stage, size: size, time: time, thirst: false, compact: false, frame: frame)
        ZStack {
            SanctuaryBackground()
            Canvas { context, _ in
                PomegranateRenderer.draw(scene, palette: PomegranatePalette.dark, in: context)
            }
        }
        .environment(\.colorScheme, .dark)
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
