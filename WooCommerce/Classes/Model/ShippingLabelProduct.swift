import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product section of shipping label creation form.
///
struct ShippingLabelProduct: Equatable {
    let siteID: Int64
    let productID: Int64
    let name: String

    let price: String
    let virtual: Bool
    let weight: String?
    let dimensions: ProductDimensions

    let imageURL: URL?

    init(storageProduct: StorageProduct) {
        self.siteID = storageProduct.siteID
        self.productID = storageProduct.productID
        self.name = storageProduct.name
        self.price = storageProduct.price
        self.virtual = storageProduct.virtual
        self.weight = storageProduct.weight
        self.dimensions = {
            guard let dimensions = storageProduct.dimensions else {
                return ProductDimensions(length: "", width: "", height: "")
            }

            return ProductDimensions(length: dimensions.length, width: dimensions.width, height: dimensions.height)
        }()
        self.imageURL = storageProduct.imagesArray.first?.toReadOnly().imageURL
    }
}
