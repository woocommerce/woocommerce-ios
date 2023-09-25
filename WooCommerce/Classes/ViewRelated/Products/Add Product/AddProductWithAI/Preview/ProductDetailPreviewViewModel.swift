import Foundation
import Yosemite

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var generatedProduct: Product?

    @Published private(set) var productName: String
    @Published private(set) var productDescription: String

    private let productFeatures: String
    private let packagingImage: MediaPickerImage?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteID: Int64,
         productName: String,
         productDescription: String?,
         productFeatures: String?,
         packagingImage: MediaPickerImage? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics

        self.productName = productName
        self.productDescription = productDescription ?? ""
        self.productFeatures = productFeatures ?? ""
        self.packagingImage = packagingImage
    }

    func generateProductDetails() {
        // TODO
    }

    func saveProductAsDraft() {
        // TODO
    }

    func handleFeedback(_ vote: FeedbackView.Vote) {
        // TODO
    }
}
