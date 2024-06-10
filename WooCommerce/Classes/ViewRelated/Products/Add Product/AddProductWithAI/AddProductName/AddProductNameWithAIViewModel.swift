import Foundation
import protocol WooFoundation.Analytics

/// View model for `AddProductNameWithAIView`.
///
final class AddProductNameWithAIViewModel: ObservableObject {
    @Published var productNameContent: String

    let siteID: Int64
    private let analytics: Analytics

    var productName: String? {
        guard productNameContent.isNotEmpty else {
            return nil
        }
        return productNameContent
    }

    init(siteID: Int64, analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.productNameContent = ""
        self.analytics = analytics
    }

    func didTapSuggestName() {
        analytics.track(event: .ProductNameAI.entryPointTapped(hasInputName: productNameContent.isNotEmpty, source: .productCreationAI))
    }

    func didTapContinue() {
        analytics.track(event: .ProductCreationAI.productNameContinueTapped())
    }
}
