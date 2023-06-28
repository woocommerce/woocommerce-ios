import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import Vision
import Yosemite

@available(iOS 16.0, *)
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
        case success(UIImage)
        case failure(Error)
    }

    enum TransferError: Error {
        case importFailed
    }

    @available(iOS 16.0, *)
    struct ProductImage: Transferable {
        let image: UIImage

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return ProductImage(image: uiImage)
            }
        }
    }

    @Published private(set) var imageState: ImageState = .empty

    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }

    private let siteID: Int64
    private let stores: StoresManager
    private var selectedImageSubscription: AnyCancellable?

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        $imageSelection.map { [weak self] selectedImage in
            guard let self else {
                return .empty
            }
            if let selectedImage {
                let progress = loadTransferable(from: selectedImage)
                return .loading(progress)
            } else {
                return .empty
            }
        }.assign(to: &$imageState)

        selectedImageSubscription = $imageState.compactMap { state -> UIImage? in
            guard case let .success(image) = state else {
                return nil
            }
            return image
        }
        .sink { [weak self] image in
            self?.onSelectedImage(image)
        }
    }
}

@available(iOS 16.0, *)
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
        request.revision = VNRecognizeTextRequestRevision3
        request.automaticallyDetectsLanguage = true
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
        isGeneratingDetails = true
        Task { @MainActor in
            switch await generateProductDetails(from: texts) {
                case .success(let details):
                    name = details.name
                    description = details.description
                case .failure(let error):
                    DDLogError("⛔️ Error generating product details from scanned text \(texts): \(error)")
            }
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

    func generateProductDetails(from scannedTexts: [String]) async -> Result<ProductDetailsFromScannedTexts, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDetails(siteID: siteID,
                                                                 scannedTexts: scannedTexts) { result in
                continuation.resume(returning: result)
            })
        }
    }
}

// MARK: - SwiftUI Photos Picker
//
@available(iOS 16.0, *)
private extension AddProductFromImageViewModel {
    func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProductImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                    case .success(let image?):
                        self.imageState = .success(image.image)
                    case .success(nil):
                        self.imageState = .empty
                    case .failure(let error):
                        self.imageState = .failure(error)
                }
            }
        }
    }
}
