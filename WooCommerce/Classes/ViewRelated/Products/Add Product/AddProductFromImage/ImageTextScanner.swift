import UIKit
import Vision

protocol ImageTextScannerProtocol {
    /// Scans text from the given image.
    /// - Parameter image: Image that can contain text.
    /// - Returns: An array of texts detected in the image.
    func scanText(from image: UIImage) async throws -> [String]
}

/// Scans text from an image using the Vision framework.
final class ImageTextScanner: ImageTextScannerProtocol {
    func scanText(from image: UIImage) async throws -> [String] {
        // Gets the CGImage on which to perform requests.
        guard let cgImage = image.cgImage else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            // Creates a new image-request handler.
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)

            // Creates a new request to recognize text.
            let request = VNRecognizeTextRequest { [weak self] request, error in
                if let error {
                    return continuation.resume(throwing: error)
                }
                guard let self else {
                    return continuation.resume(returning: [])
                }
                let scannedTexts = self.scannedTexts(from: request)
                continuation.resume(returning: scannedTexts)
            }

            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
                request.automaticallyDetectsLanguage = true
            }

            do {
                // Performs the text-recognition request.
                try requestHandler.perform([request])
            } catch {
                DDLogError("⛔️ Unable to perform image text generation request: \(error)")
            }
        }
    }
}

private extension ImageTextScanner {
    func scannedTexts(from request: VNRequest) -> [String] {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }
        let recognizedStrings = observations.compactMap { observation in
            // Returns the string of the top VNRecognizedText instance.
            observation.topCandidates(1).first?.string
        }
        return recognizedStrings
    }
}
