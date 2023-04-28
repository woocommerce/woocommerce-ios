import Foundation
import Yosemite

/// View model for `ProductDescriptionGenerationView`.
final class ProductDescriptionGenerationViewModel: ObservableObject {
    /// Product name, editable.
    @Published var name: String

    /// Product features, editable. The default value is the pre-existing product description.
    @Published var features: String

    /// AI-generated product description.
    @Published private(set) var suggestedText: String?

    /// Error message from generating product description.
    @Published private(set) var errorMessage: String?

    /// Whether product description generation API request is still in progress.
    @Published private(set) var isGenerationInProgress: Bool = false

    /// Whether the text generation CTA is enabled.
    var isGenerationEnabled: Bool {
        name.isNotEmpty && features.isNotEmpty
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let onApply: (_ output: ProductDescriptionGenerationOutput) -> Void

    private var task: Task<Void, Error>?

    init(siteID: Int64,
         name: String,
         description: String,
         stores: StoresManager = ServiceLocator.stores,
         onApply: @escaping (ProductDescriptionGenerationOutput) -> Void) {
        self.name = name
        self.features = description
        self.siteID = siteID
        self.stores = stores
        self.onApply = onApply
    }

    /// Generates product description async.
    func generateDescription() {
        isGenerationInProgress = true
        errorMessage = nil
        task = Task { @MainActor in
            let result = await generateProductDescription()
            handleGenerationResult(result)
        }
    }

    /// Stops or starts product description generation, depending on whether it is in progress.
    func toggleDescriptionGeneration() {
        if isGenerationInProgress {
            task?.cancel()
            isGenerationInProgress = false
        } else {
            generateDescription()
        }
    }

    /// Applies the generated product description and product name to the product.
    func applyToProduct() {
        onApply(.init(name: name, description: suggestedText ?? ""))
    }
}

private extension ProductDescriptionGenerationViewModel {
    @MainActor
    func generateProductDescription() async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDescription(siteID: siteID,
                                                                     name: name,
                                                                     features: features,
                                                                     languageCode: Locale.current.identifier) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func handleGenerationResult(_ result: Result<String, Error>) {
        switch result {
        case let .success(text):
            suggestedText = text
        case let .failure(error):
            errorMessage = error.localizedDescription
            DDLogError("Error generating product description: \(error)")
        }
        isGenerationInProgress = false
    }
}
