import Combine
import SwiftUI
import Vision
import Yosemite

/// View model for `AddProductFromImageView` to handle user actions from the view and provide data for the view.
@MainActor
final class AddProductFromImageViewModel: ObservableObject {
    /// View model for `AddProductFromImageScannedTextView`.
    final class ScannedTextViewModel: ObservableObject, Identifiable {
        let id: String = UUID().uuidString
        @Published var text: String
        @Published var isSelected: Bool

        init(text: String, isSelected: Bool) {
            self.text = text
            self.isSelected = isSelected
        }
    }

    typealias TextFieldViewModel = AddProductFromImageTextFieldViewModel
    typealias ImageState = EditableImageViewState

    // MARK: - Product Details

    let nameViewModel: TextFieldViewModel
    let descriptionViewModel: TextFieldViewModel

    var name: String {
        nameViewModel.text
    }
    var description: String {
        descriptionViewModel.text
    }

    // MARK: - Product Image

    @Published private(set) var imageState: ImageState = .empty
    var image: MediaPickerImage? {
        imageState.image
    }

    private let addProductSource: AddProductCoordinator.Source
    private let onAddImage: (MediaPickingSource) async -> MediaPickerImage?
    private var selectedImageSubscription: AnyCancellable?

    // MARK: - Scanned Texts

    @Published var scannedTexts: [ScannedTextViewModel] = []
    @Published private(set) var isGeneratingDetails: Bool = false

    private var selectedScannedTexts: [String] {
        scannedTexts.filter { $0.isSelected && $0.text.isNotEmpty }.map { $0.text }
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let imageTextScanner: ImageTextScannerProtocol
    private let analytics: Analytics

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         stores: StoresManager = ServiceLocator.stores,
         imageTextScanner: ImageTextScannerProtocol = ImageTextScanner(),
         analytics: Analytics = ServiceLocator.analytics,
         onAddImage: @escaping (MediaPickingSource) async -> MediaPickerImage?) {
        self.siteID = siteID
        self.stores = stores
        self.addProductSource = source
        self.imageTextScanner = imageTextScanner
        self.analytics = analytics
        self.onAddImage = onAddImage
        self.nameViewModel = .init(text: "", placeholder: Localization.nameFieldPlaceholder)
        self.descriptionViewModel = .init(text: "", placeholder: Localization.descriptionFieldPlaceholder)

        // Track display event
        analytics.track(event: .AddProductFromImage.formDisplayed(source: source))

        selectedImageSubscription = $imageState.compactMap { $0.image?.image }
        .sink { [weak self] image in
            self?.onSelectedImage(image)
        }
    }

    /// Invoked after the user selects a media source to add an image.
    /// - Parameter source: Source of the image.
    func addImage(from source: MediaPickingSource) {
        let previousState = imageState
        imageState = .loading
        Task { @MainActor in
            guard let image = await onAddImage(source) else {
                return imageState = previousState
            }
            imageState = .success(image)
        }
    }

    /// Generates product details with the currently selected scanned texts.
    func generateProductDetails() {
        Task { @MainActor in
            isGeneratingDetails = true
            await generateAndPopulateProductDetails(from: Array(selectedScannedTexts))
            isGeneratingDetails = false
        }
    }

    /// Tracks when the continue button is tapped
    func trackContinueButtonTapped() {
        analytics.track(event: .AddProductFromImage.continueButtonTapped(
            source: addProductSource,
            isNameEmpty: name.isEmpty,
            isDescriptionEmpty: description.isEmpty,
            hasScannedText: selectedScannedTexts.isNotEmpty,
            hasGeneratedDetails: nameViewModel.hasAppliedGeneratedContent || descriptionViewModel.hasAppliedGeneratedContent))
    }
}

private extension AddProductFromImageViewModel {
    func onSelectedImage(_ image: UIImage) {
        Task { @MainActor in
            do {
                let texts = try await imageTextScanner.scanText(from: image)
                analytics.track(event: .AddProductFromImage.scanCompleted(source: addProductSource, scannedTextCount: texts.count))
                scannedTexts = texts.map { .init(text: $0, isSelected: true) }
                generateProductDetails()
            } catch {
                analytics.track(event: .AddProductFromImage.scanFailed(source: addProductSource, error: error))
                DDLogError("⛔️ Error scanning text from image: \(error)")
            }
        }
    }

    func generateAndPopulateProductDetails(from scannedTexts: [String]) async {
        guard scannedTexts.isNotEmpty else {
            return
        }
        switch await generateProductDetails(from: scannedTexts) {
        case .success(let details):
            nameViewModel.onSuggestion(details.name)
            descriptionViewModel.onSuggestion(details.description)
            analytics.track(event: .AddProductFromImage.detailsGenerated(
                source: addProductSource,
                language: details.language,
                selectedTextCount: selectedScannedTexts.count
            ))
        case .failure(let error):
            analytics.track(event: .AddProductFromImage.detailGenerationFailed(source: addProductSource, error: error))
            DDLogError("⛔️ Error generating product details from scanned text: \(error)")
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

private extension AddProductFromImageViewModel {
    enum Localization {
        static let nameFieldPlaceholder = NSLocalizedString(
            "Name",
            comment: "Product name placeholder on the add product from image form."
        )
        static let descriptionFieldPlaceholder = NSLocalizedString(
            "Description",
            comment: "Product description placeholder on the add product from image form."
        )
    }
}
