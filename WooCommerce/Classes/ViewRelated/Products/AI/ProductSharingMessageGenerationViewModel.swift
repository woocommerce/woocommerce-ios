import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `ProductSharingMessageGenerationView`
final class ProductSharingMessageGenerationViewModel: ObservableObject {
    @Published var isSharePopoverPresented = false
    @Published var isShareSheetPresented = false

    /// Whether feedback banner for the generated text should be displayed.
    @Published private(set) var shouldShowFeedbackView = false

    let viewTitle: String

    var generateButtonTitle: String {
        hasGeneratedMessage ? Localization.regenerate : Localization.generate
    }

    var generateButtonImage: UIImage {
        hasGeneratedMessage ? UIImage(systemName: "arrow.counterclockwise")! : .sparklesImage
    }

    var shareSheet: ShareSheet {
        let activityItems: [Any]
        if let url = URL(string: url) {
            activityItems = [messageContent, url]
        } else {
            activityItems = [messageContent]
        }
        return ShareSheet(activityItems: activityItems)
    }

    @Published var messageContent: String = ""
    @Published private(set) var generationInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private let siteID: Int64
    private let url: String
    private let productName: String
    private let productDescription: String
    private let stores: StoresManager
    private let isPad: Bool
    private let analytics: Analytics
    private let delayBeforeDismissingFeedbackBanner: TimeInterval

    /// Whether a message has been successfully generated.
    /// This is needed to identify whether the next request is a retry.
    private var hasGeneratedMessage = false

    /// Language used in product identified by AI
    ///
    private var languageIdentifiedUsingAI: String?

    init(siteID: Int64,
         url: String,
         productName: String,
         productDescription: String,
         isPad: Bool = UIDevice.isPad(),
         delayBeforeDismissingFeedbackBanner: TimeInterval = 0.5,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.url = url
        self.productName = productName
        self.productDescription = productDescription
        self.isPad = isPad
        self.stores = stores
        self.analytics = analytics
        self.viewTitle = String.localizedStringWithFormat(Localization.title, productName)
        self.delayBeforeDismissingFeedbackBanner = delayBeforeDismissingFeedbackBanner
    }

    @MainActor
    func generateShareMessage() async {
        shouldShowFeedbackView = false
        analytics.track(event: .ProductSharingAI.generateButtonTapped(isRetry: hasGeneratedMessage))
        errorMessage = nil
        generationInProgress = true
        do {
            messageContent = try await requestMessageFromAI()
            hasGeneratedMessage = true
            analytics.track(event: .ProductSharingAI.messageGenerated())
            shouldShowFeedbackView = true
        } catch {
            if case let IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: underlyingError) = error {
                DDLogError("⛔️ Error identifying language: \(error)")
                errorMessage = underlyingError.localizedDescription
                analytics.track(event: .ProductSharingAI.identifyLanguageFailed(error: underlyingError))
            } else {
                DDLogError("⛔️ Error generating product sharing message: \(error)")
                errorMessage = error.localizedDescription
                analytics.track(event: .ProductSharingAI.messageGenerationFailed(error: error))
            }
        }
        generationInProgress = false
    }

    func didTapShare() {
        if isPad {
            isSharePopoverPresented = true
        } else {
            isShareSheetPresented = true
        }
        analytics.track(event: .ProductSharingAI.shareButtonTapped(withMessage: messageContent.isNotEmpty))
    }

    /// Handles when a feedback is sent.
    func handleFeedback(_ vote: FeedbackView.Vote) {
        analytics.track(event: .AIFeedback.feedbackSent(source: .productSharingMessage,
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

private extension ProductSharingMessageGenerationViewModel {

    @MainActor
    func requestMessageFromAI() async throws -> String {
        let language = try await identifyLanguage()
        return try await withCheckedThrowingContinuation { continuation in

            stores.dispatch(ProductAction.generateProductSharingMessage(siteID: siteID,
                                                                        url: url,
                                                                        name: productName,
                                                                        description: productDescription,
                                                                        language: language,
                                                                        completion: { result in
                continuation.resume(with: result)
            }))
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
                                                               string: productName + " " + productDescription,
                                                               feature: .productSharing,
                                                               completion: { result in
                    continuation.resume(with: result)
                }))
            }
            analytics.track(event: .ProductSharingAI.identifiedLanguage(language))
            self.languageIdentifiedUsingAI = language
            return language
        } catch {
            throw IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: error)
        }
    }
}

extension ProductSharingMessageGenerationViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Share %1$@",
            comment: "Title of the product sharing message generation screen. " +
            "The placeholder is the name of the product"
        )
        static let generate = NSLocalizedString(
            "Write with AI",
            comment: "Action button to generate message on the product sharing message generation screen"
        )
        static let regenerate = NSLocalizedString(
            "Regenerate",
            comment: "Action button to regenerate message on the product sharing message generation screen"
        )
    }
}
