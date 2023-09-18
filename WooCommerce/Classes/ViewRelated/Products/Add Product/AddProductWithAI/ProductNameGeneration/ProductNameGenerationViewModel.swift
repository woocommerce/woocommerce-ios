import UIKit
import Yosemite

/// View model for `ProductNameGenerationView`.
///
final class ProductNameGenerationViewModel {

    var generateButtonTitle: String {
        hasGeneratedMessage ? Localization.regenerate : Localization.generate
    }

    var generateButtonImage: UIImage {
        hasGeneratedMessage ? UIImage(systemName: "arrow.counterclockwise")! : .sparklesImage
    }

    @Published var messageContent: String = ""
    @Published private(set) var generationInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    /// Whether a message has been successfully generated.
    /// This is needed to identify whether the next request is a retry.
    private var hasGeneratedMessage = false

    /// Language used in product identified by AI
    ///
    private var languageIdentifiedUsingAI: String?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
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
