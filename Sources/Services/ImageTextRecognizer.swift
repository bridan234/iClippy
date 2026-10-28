import Foundation
import Vision
import ImageIO

enum ImageTextRecognizer {
    static func recognize(_ data: Data) -> String? {
        // Downsample before recognition to bound memory for large screenshots.
        var recognized: String?
        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2400, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
                recognized = request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n") ?? ""
            } catch { /* Leave nil so recognition can be retried later. */ }
        }
        let text = recognized
        return text
    }
}
