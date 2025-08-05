import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the Blaze flow.
///
struct BlazeCampaignProduct: Equatable {
    let siteID: Int64
    let productID: Int64
    let name: String
    let permalink: String
    let fullDescription: String?
    let shortDescription: String?

    let price: String

    let firstImage: ProductImage?

    func alternativePermalink(with siteURL: String) -> String {
        String(format: "%@?post_type=product&p=%d", siteURL, productID)
    }

    init(storageProduct: StorageProduct) {
        self.siteID = storageProduct.siteID
        self.productID = storageProduct.productID
        self.name = storageProduct.name
        self.price = storageProduct.price
        self.permalink = storageProduct.permalink
        self.fullDescription = storageProduct.fullDescription
        self.shortDescription = storageProduct.briefDescription
        self.firstImage = storageProduct.imagesArray.first?.toReadOnly()
    }
}
