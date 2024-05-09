import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `ProductNameGenerationView`.
///
final class ProductNameGenerationViewModel: ObservableObject {

    var generateButtonTitle: String {
        hasGeneratedMessage ? Localization.regenerate : Localization.generate
    }

    var generateButtonImage: UIImage {
        hasGeneratedMessage ? UIImage(systemName: "arrow.counterclockwise")! : .sparklesImage
    }

    @Published var keywords: String
    @Published private(set) var suggestedText: String?
    @Published private(set) var generationInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    /// Whether a message has been successfully generated.
    /// This is needed to identify whether the next request is a retry.
    var hasGeneratedMessage: Bool {
        suggestedText != nil
    }

    /// Language used in product identified by AI
    ///
    private var languageIdentifiedUsingAI: String?

    init(siteID: Int64,
         keywords: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.keywords = keywords
        self.stores = stores
        self.analytics = analytics
    }

    @MainActor
    func generateProductName() async {
        analytics.track(event: .ProductNameAI.generateButtonTapped(isRetry: hasGeneratedMessage))

        generationInProgress = true
        errorMessage = nil
        do {
            suggestedText = try await generateProductName(from: keywords)
            analytics.track(event: .ProductNameAI.nameGenerated())
        } catch {
            errorMessage = error.localizedDescription
            analytics.track(event: .ProductNameAI.nameGenerationFailed(error: error))
        }
        generationInProgress = false
    }

    func didTapCopy() {
        analytics.track(event: .ProductNameAI.copyButtonTapped())
    }

    func didTapApply() {
        analytics.track(event: .ProductNameAI.applyButtonTapped())
    }
}

private extension ProductNameGenerationViewModel {
    @MainActor
    func generateProductName(from keywords: String) async throws -> String {
        let language = try await identifyLanguage(from: keywords)
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.generateProductName(siteID: siteID, keywords: keywords, language: language) { result in
                switch result {
                case .success(let name):
                    continuation.resume(returning: name)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    @MainActor
    func identifyLanguage(from keywords: String) async throws -> String {
        if let languageIdentifiedUsingAI,
           languageIdentifiedUsingAI.isNotEmpty {
            return languageIdentifiedUsingAI
        }

        do {
            let language = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(ProductAction.identifyLanguage(siteID: siteID,
                                                               string: keywords,
                                                               feature: .productName,
                                                               completion: { result in
                    continuation.resume(with: result)
                }))
            }
            analytics.track(event: .ProductNameAI.identifiedLanguage(language))
            self.languageIdentifiedUsingAI = language
            return language
        } catch {
            analytics.track(event: .ProductNameAI.identifyLanguageFailed(error: error))
            throw IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: error)
        }
    }
}

extension ProductNameGenerationViewModel {
    enum Localization {
        static let generate = NSLocalizedString(
            "Write with AI",
            comment: "Action button to generate title for a new product with AI."
        )
        static let regenerate = NSLocalizedString(
            "Regenerate",
            comment: "Action button to regenerate title for a new product with AI."
        )
    }
}
