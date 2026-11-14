import SwiftUI
import AVFoundation
import UIKit

// MARK: - Видео письма: как перо выводит страницу
// Главное зрелище «Рукописи» — буквы, которые выводятся пером. Его можно отправить видео (9:16, для сторис и
// мессенджеров): те же кадры, что на экране, собранные в MP4. Кадры рисуются теми же ManuscriptPageView и
// ManuscriptReveal, поэтому в видео ровно то, что человек видел в мастерской.

enum ManuscriptVideoError: Error {
    case cannotCreate
    case renderFailed
    case writingFailed
}

enum ManuscriptVideoExporter {
    /// 60 кадров в секунду: перо и блик на золоте двигаются плавно; сборка идёт дольше, чем при 24, зато видео как на экране
    static let framesPerSecond = 60
    /// Двойной масштаб листа 360×640: 720×1280, достаточно для сторис и вдвое легче, чем 1080×1920
    static let scale: CGFloat = 2
    /// Сколько секунд после письма остаётся готовый лист с бликом
    static let holdSeconds: Double = 2.5

    /// Собирает видео страницы во временный файл. Отмена задачи останавливает сборку.
    /// `progress` вызывается на главном потоке: 0…1.
    @MainActor
    static func export(
        page: ManuscriptPage,
        pen: ManuscriptPen,
        speed: ManuscriptWritingSpeed,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let length = ManuscriptTextLayout.cached(for: page, pen: pen).length
        let writingSeconds = ManuscriptReveal.totalDuration(textLength: length, turned: false, speed: speed)
        let totalFrames = max(1, Int((writingSeconds + holdSeconds) * Double(framesPerSecond)))

        let width = Int(ManuscriptGeometry.size.width * scale)
        let height = Int(ManuscriptGeometry.size.height * scale)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("luys-manuscript-\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoExpectedSourceFrameRateKey: framesPerSecond,
                AVVideoMaxKeyFrameIntervalKey: framesPerSecond
            ]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        guard writer.canAdd(input) else { throw ManuscriptVideoError.cannotCreate }
        writer.add(input)
        guard writer.startWriting() else { throw ManuscriptVideoError.cannotCreate }
        writer.startSession(atSourceTime: .zero)

        for index in 0 ..< totalFrames {
            if Task.isCancelled {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: url)
                throw CancellationError()
            }
            let time = Double(index) / Double(framesPerSecond)
            let reveal = ManuscriptReveal.at(time: time, textLength: length, turned: false, speed: speed)
            // Блик на золоте медленно гуляет, как у телефона без датчика наклона
            let sheen = CGPoint(x: sin(time * 0.9) * 0.8, y: cos(time * 0.5) * 0.3)
            guard let image = ManuscriptExport.frameImage(page, reveal: reveal, sheen: sheen, pen: pen, scale: scale) else {
                throw ManuscriptVideoError.renderFailed
            }
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
            }
            guard let buffer = pixelBuffer(from: image, pool: adaptor.pixelBufferPool, width: width, height: height) else {
                throw ManuscriptVideoError.renderFailed
            }
            _ = adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(framesPerSecond)))
            progress(Double(index + 1) / Double(totalFrames))
            // Даём главному потоку вздохнуть: иначе экран замирает на всё время сборки
            await Task.yield()
        }

        input.markAsFinished()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting {
                continuation.resume()
            }
        }
        guard writer.status == .completed else {
            try? FileManager.default.removeItem(at: url)
            throw ManuscriptVideoError.writingFailed
        }
        return url
    }

    private static func pixelBuffer(from image: UIImage, pool: CVPixelBufferPool?, width: Int, height: Int) -> CVPixelBuffer? {
        guard let pool = pool, let cgImage = image.cgImage else { return nil }
        var created: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &created)
        guard let buffer = created else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

// MARK: - Сколько видео бесплатно
/// Первые видео бесплатны (на них подпись Luys: это и есть реклама), дальше видео письма входит в Premium
enum ManuscriptVideoAccess {
    static let freeVideos = 3
    private static let countKey = "luys_manuscript_free_videos"

    static var madeCount: Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    static var hasFreeLeft: Bool {
        madeCount < freeVideos
    }

    static func recordMade() {
        UserDefaults.standard.set(madeCount + 1, forKey: countKey)
    }
}
