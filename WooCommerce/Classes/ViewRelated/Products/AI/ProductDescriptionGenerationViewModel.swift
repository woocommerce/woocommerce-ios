import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `ProductDescriptionGenerationView`.
final class ProductDescriptionGenerationViewModel: ObservableObject {
    /// Product name, editable.
    @Published var name: String {
        didSet {
            missingName = false
        }
    }

    /// Product features, editable. The default value is the pre-existing product description.
    @Published var features: String {
        didSet {
            missingFeatures = false
        }
    }

    /// AI-generated product description.
    @Published private(set) var suggestedText: String?

    /// Error message from generating product description.
    @Published private(set) var errorMessage: String?

    /// Whether product description generation API request is still in progress.
    @Published private(set) var isGenerationInProgress: Bool = false

    /// Whether feedback banner for the generated text should be displayed.
    @Published private(set) var shouldShowFeedbackView = false

    /// Whether product name is missing
    @Published private(set) var missingName: Bool = false

    /// Whether product features are missing
    @Published private(set) var missingFeatures: Bool = false

    let isProductNameEditable: Bool

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let onApply: (_ output: ProductDescriptionGenerationOutput) -> Void
    private let delayBeforeDismissingFeedbackBanner: TimeInterval

    private var task: Task<Void, Error>?

    /// Language used in product identified by AI
    ///
    private var languageIdentifiedUsingAI: String?

    init(siteID: Int64,
         name: String,
         description: String,
         delayBeforeDismissingFeedbackBanner: TimeInterval = 0.5,
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
        self.delayBeforeDismissingFeedbackBanner = delayBeforeDismissingFeedbackBanner
    }

    /// Generates product description async.
    func generateDescription() {
        guard name.isNotEmpty else {
            return missingName = true
        }
        guard features.isNotEmpty else {
            return missingFeatures = true
        }
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
        if vote == .down {
            // User down voting could be because the identified language is incorrect.
            // Setting it as `nil` to identify language again during next generation attempt.
            // pe5sF9-1GF-p2
            languageIdentifiedUsingAI = nil
        }

        // Delay the disappearance of the banner for a better UX.
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeDismissingFeedbackBanner) { [weak self] in
            self?.shouldShowFeedbackView = false
        }
    }
}

private extension ProductDescriptionGenerationViewModel {
    @MainActor
    func generateProductDescription() async -> Result<String, Error> {
        do {
            let language = try await identifyLanguage()
            return await withCheckedContinuation { continuation in
                stores.dispatch(ProductAction.generateProductDescription(siteID: siteID,
                                                                         name: name,
                                                                         features: features,
                                                                         language: language) { result in
                    continuation.resume(returning: result)
                })
            }
        } catch {
            return .failure(error)
        }
    }

    @MainActor
    func identifyLanguage() async throws -> String {
        if let languageIdentifiedUsingAI,
           languageIdentifiedUsingAI.isNotEmpty {
            return languageIdentifiedUsingAI
        }

        do {
            let language = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(ProductAction.identifyLanguage(siteID: siteID,
                                                               string: name + " " + features,
                                                               feature: .productDescription,
                                                               completion: { result in
                    continuation.resume(with: result)
                }))
            }
            analytics.track(event: .ProductFormAI.identifiedLanguage(language))
            self.languageIdentifiedUsingAI = language
            return language
        } catch {
            throw IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: error)
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
            if case let IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: underlyingError) = error {
                DDLogError("⛔️ Error identifying language: \(error)")
                errorMessage = underlyingError.localizedDescription
                analytics.track(event: .ProductFormAI.identifyLanguageFailed(error: underlyingError))
            } else {
                DDLogError("⛔️ Error generating product description: \(error)")
                errorMessage = error.localizedDescription
                analytics.track(event: .ProductFormAI.productDescriptionAIGenerationFailed(error: error))
            }
        }
        isGenerationInProgress = false
    }
}

enum IdentifyLanguageError: Error {
    case failedToIdentifyLanguage(underlyingError: Error)
}
