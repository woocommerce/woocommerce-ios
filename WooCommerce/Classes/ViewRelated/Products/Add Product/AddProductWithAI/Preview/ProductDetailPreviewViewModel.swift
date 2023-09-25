import Combine
import Foundation
import Yosemite

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private var generatedProduct: Product?

    @Published private(set) var productName: String
    @Published private(set) var productDescription: String?
    @Published private(set) var productType: String?
    @Published private(set) var productPrice: String?
    @Published private(set) var productCategories: String?
    @Published private(set) var productTags: String?
    @Published private(set) var productShippingDetails: String?

    private let productFeatures: String?
    private let packagingImage: MediaPickerImage?

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    private var generatedProductSubscription: AnyCancellable?

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
        self.productDescription = productDescription
        self.productFeatures = productFeatures
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

private extension ProductDetailPreviewViewModel {
    func observeGeneratedProduct() {
        generatedProductSubscription = $generatedProduct
            .compactMap { $0 }
            .sink { [weak self] product in
                guard let self else { return }
                self.productName = product.name
                self.productDescription = product.fullDescription ?? product.shortDescription ?? self.productDescription
            }
    }
}

private extension ProductDetailPreviewViewModel {
    enum Localization {
        static let virtualProductType = NSLocalizedString("Virtual", comment: "Display label for simple virtual product type.")
        static let physicalProductType = NSLocalizedString("Physical", comment: "Display label for simple physical product type.")
    }
}
