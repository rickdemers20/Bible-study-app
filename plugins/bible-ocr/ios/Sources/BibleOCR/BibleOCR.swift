import Foundation
import Capacitor
import Vision
import ImageIO
import UIKit

/// On-device OCR for the Bible Study app ("Link Bible to our app" / snap a page).
///
/// JS contract — the native bridge injects `window.Capacitor.Plugins.BibleOCR`
/// automatically (see JSExport in @capacitor/ios), so the web side calls
/// `window.Capacitor.Plugins.BibleOCR.recognizeText({ image })` directly,
/// with no `registerPlugin` call needed on native. (On plain web there is no
/// native plugin, so the web side must guard with `Capacitor.isNativePlatform()`.)
///
///   input:  { image: string } — base64 JPEG, no `data:` prefix
///   output: { lines: [{ text: string, x: number, y: number,
///                        width: number, height: number }] }
///           Bounding boxes are normalized 0–1 with origin TOP-LEFT.
///   errors: code "INVALID_IMAGE" when the base64 cannot be decoded as an
///           image; code "RECOGNITION_FAILED" if Vision itself errors.
///           No text found resolves with an empty `lines` array — the JS
///           side decides what that means.
///
/// Nothing leaves the device: the photo is decoded and read in memory only.
@objc(BibleOCR)
public class BibleOCR: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "BibleOCR"
    public let jsName = "BibleOCR"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "recognizeText", returnType: CAPPluginReturnPromise)
    ]

    @objc func recognizeText(_ call: CAPPluginCall) {
        guard let base64 = call.getString("image"), !base64.isEmpty,
              let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else {
            call.reject("Could not decode image", "INVALID_IMAGE")
            return
        }

        // Cap the longest side at 2048 px: printed Bible text stays legible
        // and Vision runs much faster than on a full 12 MP camera photo.
        let scaled = Self.downscale(image, maxDimension: 2048)
        guard let cgImage = scaled.cgImage else {
            call.reject("Could not decode image", "INVALID_IMAGE")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                call.reject("Text recognition failed: \(error.localizedDescription)", "RECOGNITION_FAILED")
                return
            }
            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            let lines = Self.orderLines(Self.extractLines(from: observations))
            let lineDicts: [[String: Any]] = lines.map { line in
                [
                    "text": line.text,
                    "x": line.box.origin.x,
                    "y": line.box.origin.y,
                    "width": line.box.size.width,
                    "height": line.box.size.height
                ]
            }
            call.resolve(["lines": lineDicts])
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: Self.cgOrientation(for: scaled.imageOrientation),
            options: [:]
        )
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                call.reject("Text recognition failed: \(error.localizedDescription)", "RECOGNITION_FAILED")
            }
        }
    }

    // MARK: - Line extraction

    private struct Line {
        let text: String
        /// Normalized 0–1, origin TOP-LEFT.
        let box: CGRect
        var xCenter: CGFloat { box.midX }
    }

    private static func extractLines(from observations: [VNRecognizedTextObservation]) -> [Line] {
        observations.compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string,
                  !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            // Vision's boundingBox is normalized 0–1 with origin BOTTOM-LEFT;
            // flip y so the box origin is TOP-LEFT like the web side expects.
            let vBox = observation.boundingBox
            let box = CGRect(x: vBox.minX, y: 1 - vBox.maxY, width: vBox.width, height: vBox.height)
            return Line(text: text, box: box)
        }
    }

    // MARK: - Reading order (two-column aware)
    //
    // Algorithm:
    //   1. Sort all lines by x-center.
    //   2. Find the largest gap between consecutive x-centers. If that gap is
    //      wider than 12% of the page width AND there are at least 3 lines on
    //      each side of it AND the median x-center of the left group is < 0.5
    //      while the right group's is > 0.5, the page is two-column: emit the
    //      left column top-to-bottom, then the right column top-to-bottom.
    //      (A KJV page's columns sit ~0.04–0.47 and ~0.53–0.96, so the gap
    //      between the columns' line centers is ~0.2; a single-column page's
    //      centers pack densely, and the 3-line minimum keeps one centered
    //      heading from splitting a single column in two.)
    //   3. Otherwise the page is one column: emit top-to-bottom.
    //   Within a column, lines sort by y (top first), then x (left first),
    //   so two lines sharing a row come out left-to-right.

    private static func orderLines(_ lines: [Line]) -> [Line] {
        guard lines.count > 1 else { return lines }

        let byXCenter = lines.sorted { $0.xCenter < $1.xCenter }

        var largestGap = CGFloat(0)
        var splitIndex = 0
        for i in 1..<byXCenter.count {
            let gap = byXCenter[i].xCenter - byXCenter[i - 1].xCenter
            if gap > largestGap {
                largestGap = gap
                splitIndex = i
            }
        }

        let left = Array(byXCenter[..<splitIndex])
        let right = Array(byXCenter[splitIndex...])
        if largestGap > 0.12, left.count >= 3, right.count >= 3,
           median(of: left.map { $0.xCenter }) < 0.5,
           median(of: right.map { $0.xCenter }) > 0.5 {
            return sortColumn(left) + sortColumn(right)
        }

        return sortColumn(lines)
    }

    private static func sortColumn(_ lines: [Line]) -> [Line] {
        lines.sorted {
            if $0.box.origin.y != $1.box.origin.y { return $0.box.origin.y < $1.box.origin.y }
            return $0.box.origin.x < $1.box.origin.x
        }
    }

    private static func median(of values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        if sorted.count % 2 == 1 { return sorted[sorted.count / 2] }
        return (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
    }

    // MARK: - Image helpers

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private static func cgOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
