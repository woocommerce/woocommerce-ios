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

    /// Whether feedback banner for the generated text should be displayed.
    @Published private(set) var shouldShowFeedbackView = false

    /// Whether the text generation CTA is enabled.
    var isGenerationEnabled: Bool {
        name.isNotEmpty && features.isNotEmpty
    }

    let isProductNameEditable: Bool

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let onApply: (_ output: ProductDescriptionGenerationOutput) -> Void

    private var task: Task<Void, Error>?

    init(siteID: Int64,
         name: String,
         description: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onApply: @escaping (ProductDescriptionGenerationOutput) -> Void) {
        self.name = name
        self.features = description
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.onApply = onApply
        self.isProductNameEditable = name.isEmpty
    }

    /// Generates product description async.
    func generateDescription() {
        analytics.track(event: .ProductFormAI.productDescriptionAIGenerateButtonTapped(isRetry: suggestedText?.isNotEmpty == true))

        isGenerationInProgress = true
        shouldShowFeedbackView = false
        errorMessage = nil
        task = Task { @MainActor in
            let result = await generateProductDescription()
            handleGenerationResult(result)
        }
    }

    /// Applies the generated product description and product name to the product.
    func applyToProduct() {
        analytics.track(event: .ProductFormAI.productDescriptionAIApplyButtonTapped())
        onApply(.init(name: name, description: suggestedText ?? ""))
    }

    /// Handles when a feedback is sent.
    func handleFeedback(_ vote: FeedbackView.Vote) {
        analytics.track(event: .AIFeedback.feedbackSent(source: .productDescription,
                                                        isUseful: vote == .up))
        // Delay the disappearance of the banner for a better UX.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.shouldShowFeedbackView = false
        }
    }
}

private extension ProductDescriptionGenerationViewModel {
    @MainActor
    func generateProductDescription() async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.generateProductDescription(siteID: siteID,
                                                                     name: name,
                                                                     features: features) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func handleGenerationResult(_ result: Result<String, Error>) {
        switch result {
        case let .success(text):
            suggestedText = text
            analytics.track(event: .ProductFormAI.productDescriptionAIGenerationSuccess())
            shouldShowFeedbackView = true
        case let .failure(error):
            errorMessage = error.localizedDescription
            DDLogError("Error generating product description: \(error)")
            analytics.track(event: .ProductFormAI.productDescriptionAIGenerationFailed(error: error))
        }
        isGenerationInProgress = false
    }
}
