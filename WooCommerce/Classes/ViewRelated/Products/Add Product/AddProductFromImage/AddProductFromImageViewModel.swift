import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import Vision
import Yosemite

@MainActor
final class AddProductFromImageViewModel: ObservableObject {

    // MARK: - Product Details

    @Published var name: String = ""
    @Published var description: String = ""
    @Published var sku: String = ""

    // MARK: - Scanned Texts

    @Published var scannedTexts: [String] = []
    @Published var selectedScannedTexts: Set<String> = []
    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var showsRegenerateButton: Bool = false

    // MARK: - Product Image

    enum ImageState {
        case empty
        case loading(Progress)
        case success(MediaPickerImage)
        case failure(Error)
    }

    @Published private(set) var imageState: ImageState = .empty
    var image: MediaPickerImage? {
        guard case let .success(image) = imageState else {
            return nil
        }
        return image
    }

    private let onAddImage: (MediaPickingSource) async -> MediaPickerImage?

    private let siteID: Int64
    private let stores: StoresManager
    private var selectedImageSubscription: AnyCancellable?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onAddImage: @escaping (MediaPickingSource) async -> MediaPickerImage?) {
        self.siteID = siteID
        self.stores = stores
        self.onAddImage = onAddImage

        selectedImageSubscription = $imageState.compactMap { state -> UIImage? in
            guard case let .success(image) = state else {
                return nil
            }
            return image.image
        }
        .sink { [weak self] image in
            self?.onSelectedImage(image)
        }
    }

    func addImage(from source: MediaPickingSource) async {
        guard let image = await onAddImage(source) else {
            return
        }
        imageState = .success(image)
    }

    func generateProductDetails() {
        Task { @MainActor in
            isGeneratingDetails = true
            await generateAndPopulateProductDetails(from: Array(selectedScannedTexts))
            isGeneratingDetails = false
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
        scannedTexts = texts
        selectedScannedTexts = .init(texts)
        Task { @MainActor in
            isGeneratingDetails = true
            await generateAndPopulateProductDetails(from: texts)
            isGeneratingDetails = false
        }
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

    func generateAndPopulateProductDetails(from scannedTexts: [String]) async {
        switch await generateProductDetails(from: scannedTexts) {
            case .success(let details):
                name = details.name
                description = details.description
            case .failure(let error):
                DDLogError("⛔️ Error generating product details from scanned text \(scannedTexts): \(error)")
        }
    }

    func generateProductDetails(from scannedTexts: [String]) async -> Result<ProductDetailsFromScannedTexts, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDetails(siteID: siteID,
                                                                 scannedTexts: scannedTexts) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
