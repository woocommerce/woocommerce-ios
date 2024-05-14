import Combine
import SwiftUI
import Vision
import Yosemite
import protocol WooFoundation.Analytics

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

            /// Sets text to be unselected if it's empty
            $text.filter { $0.isEmpty }
                .map { _ in false }
                .assign(to: &$isSelected)
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
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: - Scanned Texts

    @Published var scannedTexts: [ScannedTextViewModel] = []

    /// Text detection
    @Published private(set) var textDetectionErrorMessage: String? = nil

    /// Validation to keep track of texts that are non-empty and selected.
    @Published private var scannedTextValidation: [String: Bool] = [:]
    @Published private(set) var regenerateButtonEnabled: Bool = false

    /// Text generation
    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var textGenerationErrorMessage: String? = Localization.defaultError

    var scannedTextInstruction: String {
        selectedScannedTexts.isEmpty ? Localization.scannedTextListEmpty : Localization.scannedTextListInfo
    }

    private var selectedScannedTexts: [String] {
        scannedTexts.filter { $0.isSelected && $0.text.isNotEmpty }.map { $0.text }
    }

    private let siteID: Int64
    private let productName: String?
    private let stores: StoresManager
    private let imageTextScanner: ImageTextScannerProtocol
    private let analytics: Analytics

    /// Language used in the scanned texts
    ///
    private var languageIdentifiedUsingAI: String?

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         productName: String?,
         stores: StoresManager = ServiceLocator.stores,
         imageTextScanner: ImageTextScannerProtocol = ImageTextScanner(),
         analytics: Analytics = ServiceLocator.analytics,
         onAddImage: @escaping (MediaPickingSource) async -> MediaPickerImage?) {
        self.siteID = siteID
        self.stores = stores
        self.productName = productName
        self.addProductSource = source
        self.imageTextScanner = imageTextScanner
        self.analytics = analytics
        self.onAddImage = onAddImage
        self.nameViewModel = .init(text: "", placeholder: Localization.nameFieldPlaceholder)
        self.descriptionViewModel = .init(text: "", placeholder: Localization.descriptionFieldPlaceholder)

        // Track display event
        analytics.track(event: .AddProductFromImage.formDisplayed(source: source))

        $imageState
            .compactMap { $0.image?.image }
            .removeDuplicates()
            .sink { [weak self] image in
                self?.onSelectedImage(image)
            }
            .store(in: &subscriptions)

        $scannedTextValidation
            .map { $0.values.contains { $0 } }
            .assign(to: &$regenerateButtonEnabled)

        $scannedTexts
            .sink { [weak self] texts in
                self?.configureRegenerateButton(with: texts)
            }
            .store(in: &subscriptions)
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
        // Reset scanned texts and generated content from previous image
        scannedTexts = []
        [nameViewModel, descriptionViewModel].forEach { $0.reset() }
        languageIdentifiedUsingAI = nil
        textDetectionErrorMessage = nil

        Task { @MainActor in
            do {
                let texts = try await imageTextScanner.scanText(from: image)
                analytics.track(event: .AddProductFromImage.scanCompleted(source: addProductSource, scannedTextCount: texts.count))

                guard texts.isNotEmpty else {
                    throw ScanError.noTextDetected
                }

                scannedTexts = texts.map { .init(text: $0, isSelected: true) }
                [nameViewModel, descriptionViewModel].forEach { $0.reset() }
                generateProductDetails()
            } catch {
                switch error {
                case ScanError.noTextDetected:
                    textDetectionErrorMessage = Localization.noTextDetected
                    DDLogError("⛔️ No text detected from image.")
                default:
                    analytics.track(event: .AddProductFromImage.scanFailed(source: addProductSource, error: error))
                    textDetectionErrorMessage = Localization.textDetectionFailed
                    DDLogError("⛔️ Error scanning text from image: \(error)")
                }
            }
        }
    }

    func generateAndPopulateProductDetails(from scannedTexts: [String]) async {
        textGenerationErrorMessage = nil
        guard scannedTexts.isNotEmpty else {
            return
        }

        do {
            let language = try await identifyLanguage(from: scannedTexts)
            let details = try await generateProductDetails(from: scannedTexts,
                                                           language: language)
            nameViewModel.onSuggestion(details.name)
            descriptionViewModel.onSuggestion(details.description)
            analytics.track(event: .AddProductFromImage.detailsGenerated(
                source: addProductSource,
                language: language,
                selectedTextCount: selectedScannedTexts.count
            ))
        } catch {
            if case let IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: underlyingError) = error {
                DDLogError("⛔️ Error identifying language: \(error)")
                textGenerationErrorMessage = underlyingError.localizedDescription
            } else {
                DDLogError("⛔️ Error generating product details from scanned text: \(error)")
                textGenerationErrorMessage = Localization.defaultError
                analytics.track(event: .AddProductFromImage.detailGenerationFailed(source: addProductSource, error: error))
            }
        }
    }

    func generateProductDetails(from scannedTexts: [String],
                                language: String) async throws -> ProductDetailsFromScannedTexts {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDetails(siteID: siteID,
                                                                 productName: productName,
                                                                 scannedTexts: scannedTexts,
                                                                 language: language) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func identifyLanguage(from scannedTexts: [String]) async throws -> String {
        if let languageIdentifiedUsingAI,
           languageIdentifiedUsingAI.isNotEmpty {
            return languageIdentifiedUsingAI
        }

        do {
            let language = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(ProductAction.identifyLanguage(siteID: siteID,
                                                               string: scannedTexts.joined(separator: ","),
                                                               feature: .productDetailsFromScannedTexts,
                                                               completion: { result in
                    continuation.resume(with: result)
                }))
            }
            analytics.track(event: .AddProductFromImage.identifiedLanguage(language))
            self.languageIdentifiedUsingAI = language
            return language
        } catch {
            analytics.track(event: .AddProductFromImage.identifyLanguageFailed(error: error))
            throw IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: error)
        }
    }

    /// Enables regenerate button if there is at least one selected and non-empty text
    func configureRegenerateButton(with scannedTexts: [ScannedTextViewModel]) {
        scannedTextValidation = [:]

        for text in scannedTexts {
            text.$text.combineLatest(text.$isSelected)
                .sink { [weak self] content, isSelected in
                    self?.scannedTextValidation[text.id] = content.isNotEmpty && isSelected
                }
                .store(in: &subscriptions)
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
        static let defaultError = NSLocalizedString(
            "Error generating product details. Please try again.",
            comment: "Default error message on the add product from image form."
        )
        static let scannedTextListInfo = NSLocalizedString(
            "Tweak your text: Unselect scans you don't need or tap to edit",
            comment: "Info text about the scanned text list on the add product from image form."
        )
        static let scannedTextListEmpty = NSLocalizedString(
            "Select one or more scans to generate product details",
            comment: "Instruction to select scanned text for product detail generation on the add product from image form."
        )
        static let noTextDetected = NSLocalizedString(
            "No text detected. Please select another packaging photo or enter product details manually.",
            comment: "No text detected message on the add product from image form."
        )
        static let textDetectionFailed = NSLocalizedString(
            "An error occurred while scanning the photo. Please select another packaging photo or enter product details manually.",
            comment: "Text detection failed error message on the add product from image form."
        )
    }
}

private enum ScanError: Error {
    case noTextDetected
}
