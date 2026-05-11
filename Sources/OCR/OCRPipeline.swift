import AppKit
import Vision
import CoreML

/// OCR processing pipeline for dialog detection
actor OCRPipeline {
    // MARK: - Configuration

    private let confidenceThreshold: Double = 0.75
    private let ocrQueue = DispatchQueue(label: "com.permissionpilot.ocr", qos: .userInitiated)

    // MARK: - OCR Result

    struct OCRResult {
        let title: String
        let text: String
        let buttons: [DialogButton]
        let confidence: Double
    }

    // MARK: - Public API

    func processImage(_ image: NSImage) async -> OCRResult {
        await ocrQueue.async { [weak self] in
            self?.performOCR(image) ?? OCRResult(title: "", text: "", buttons: [], confidence: 0)
        }
    }

    // MARK: - Private Implementation

    private func performOCR(_ image: NSImage) -> OCRResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return OCRResult(title: "", text: "", buttons: [], confidence: 0)
        }

        // Preprocess image for better OCR
        let processedImage = preprocessImage(cgImage)

        // Run text recognition
        let textResults = recognizeText(in: processedImage)
        let allText = textResults.map { $0.text }.joined(separator: " ")

        // Extract buttons from recognized text
        let buttons = extractButtons(from: textResults, imageSize: image.size)

        // Estimate confidence
        let confidence = estimateConfidence(textResults)

        // Parse title (first line is usually title)
        let title = textResults.first?.text ?? ""

        return OCRResult(
            title: title,
            text: allText,
            buttons: buttons,
            confidence: confidence
        )
    }

    private func preprocessImage(_ cgImage: CGImage) -> CGImage {
        // In a production system, this would apply:
        // - Contrast enhancement
        // - Brightness normalization
        // - Noise reduction
        // - Threshold optimization
        // For now, return as-is
        return cgImage
    }

    private func recognizeText(in cgImage: CGImage) -> [TextResult] {
        var results: [TextResult] = []

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true

            try requestHandler.perform([request])

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return results
            }

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let text = candidate.string
                let confidence = Double(observation.confidence)

                // Filter low-confidence results
                guard confidence >= confidenceThreshold else { continue }

                // Get bounding box
                let boundingBox = observation.boundingBox
                let frame = CGRect(
                    x: boundingBox.origin.x,
                    y: boundingBox.origin.y,
                    width: boundingBox.width,
                    height: boundingBox.height
                )

                results.append(TextResult(text: text, confidence: confidence, boundingBox: frame))
            }
        } catch {
            Logger.error("OCR error: \(error)")
        }

        return results
    }

    private func extractButtons(from textResults: [TextResult], imageSize: NSSize) -> [DialogButton] {
        var buttons: [DialogButton] = []

        for result in textResults {
            // Check if this text looks like a button
            guard isLikelyButtonLabel(result.text) else { continue }

            // Convert normalized coordinates to screen coordinates
            let frame = denormalizeCoordinates(result.boundingBox, imageSize: imageSize)
            let center = CGPoint(x: frame.midX, y: frame.midY)

            let button = DialogButton(
                label: result.text.trimmingCharacters(in: .whitespaces),
                position: center,
                frame: frame,
                confidence: result.confidence
            )

            buttons.append(button)
        }

        return buttons
    }

    private func isLikelyButtonLabel(_ text: String) -> Bool {
        let cleaned = text.lowercased().trimmingCharacters(in: .whitespaces)

        // Button labels are typically short (< 30 chars)
        guard cleaned.count < 30 else { return false }

        // Look for common button keywords
        let buttonKeywords = SafeButtonKeywords.keywords + ["cancel", "later", "skip", "dismiss"]
        return buttonKeywords.contains { keyword in
            cleaned.contains(keyword)
        }
    }

    private func denormalizeCoordinates(_ normalizedBox: CGRect, imageSize: NSSize) -> CGRect {
        // VNRecognizeTextRequest returns normalized coordinates (0-1 range)
        // Convert to actual pixel coordinates
        let x = normalizedBox.origin.x * imageSize.width
        let y = (1 - normalizedBox.origin.y - normalizedBox.height) * imageSize.height
        let width = normalizedBox.width * imageSize.width
        let height = normalizedBox.height * imageSize.height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func estimateConfidence(_ results: [TextResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let avgConfidence = results.map { $0.confidence }.reduce(0, +) / Double(results.count)
        return min(avgConfidence, 1.0)
    }

    // MARK: - Helper Types

    struct TextResult {
        let text: String
        let confidence: Double
        let boundingBox: CGRect
    }
}
