import UIKit
import Yosemite

/// View model for `ProductNameGenerationView`.
///
final class ProductNameGenerationViewModel: ObservableObject {

    var generateButtonTitle: String {
        hasGeneratedMessage ? Localization.regenerate : Localization.generate
    }

    var generateButtonImage: UIImage {
        hasGeneratedMessage ? UIImage(systemName: "arrow.counterclockwise")! : .sparklesImage
    }

    @Published var keywords: String = ""
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

    init(siteID: Int64,
         keywords: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.keywords = keywords
        self.stores = stores
        self.analytics = analytics
    }

    func applyGeneratedName() {
        // TODO-10688
    }

    func generateProductName() {
        // TODO-10688
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
