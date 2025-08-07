import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product section of shipping label creation form.
///
struct ShippingLabelProduct: Equatable {
    let productID: Int64
    let virtual: Bool
    let weight: String?
    let dimensions: ProductDimensions

    let imageURL: URL?

    init(storageProduct: StorageProduct) {
        self.productID = storageProduct.productID
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
