import Combine
import SwiftUI
import Vision
import Yosemite

/// View model for `AddProductFromImageView` to handle user actions from the view and provide data for the view.
@MainActor
final class AddProductFromImageViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    // MARK: - Product Details

    @Published var name: String = ""
    @Published var description: String = ""

    // MARK: - Product Image

    @Published private(set) var imageState: ImageState = .empty
    var image: MediaPickerImage? {
        imageState.image
    }

    private let onAddImage: (MediaPickingSource) async -> MediaPickerImage?
    private var selectedImageSubscription: AnyCancellable?

    init(onAddImage: @escaping (MediaPickingSource) async -> MediaPickerImage?) {
        self.onAddImage = onAddImage

        selectedImageSubscription = $imageState.compactMap { $0.image?.image }
        .sink { [weak self] image in
            self?.onSelectedImage(image)
        }
    }

    /// Invoked after the user selects a media source to add an image.
    /// - Parameter source: Source of the image.
    func addImage(from source: MediaPickingSource) {
        Task { @MainActor in
            imageState = .loading
            guard let image = await onAddImage(source) else {
                return
            }
            imageState = .success(image)
        }
    }
}

private extension AddProductFromImageViewModel {
    func onSelectedImage(_ image: UIImage) {
        // Gets the CGImage on which to perform requests.
        guard let cgImage = image.cgImage else {
            return
        }

        // Creates a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Creates a new request to recognize text.
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.onScannedTextRequestCompletion(request: request, error: error)
        }

        // TODO-JC: iOS version check
        if #available(iOS 16.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
            request.automaticallyDetectsLanguage = true
        }
        print("langs: \(try? request.supportedRecognitionLanguages())")

        do {
            // Performs the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }

    func onScannedTextRequestCompletion(request: VNRequest, error: Error?) {
        let texts = scannedTexts(from: request)
        // TODO: 10180 - show the list of scanned texts and generate product details
    }

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
