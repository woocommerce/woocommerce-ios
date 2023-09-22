import Foundation
import Yosemite

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var generatedProduct: Product?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }

    func generateProductDetails() {
        // TODO
        isGeneratingDetails = true
    }

    func saveProductAsDraft() {
        // TODO
    }

    func handleFeedback(_ vote: FeedbackView.Vote) {
        // TODO
    }
}
