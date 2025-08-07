import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product section of order details screen.
///
struct OrderDetailsProduct: Equatable {
    let productID: Int64
    let productTypeKey: String
    let sku: String?

    let price: String
    let virtual: Bool

    let imageURL: URL?

    let addOns: [Yosemite.ProductAddOn]

    var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    /// periphery: ignore - used in test module
    init(productID: Int64,
         productTypeKey: String,
         sku: String?,
         price: String,
         virtual: Bool,
         imageURL: URL?,
         addOns: [Yosemite.ProductAddOn]) {
        self.productID = productID
        self.productTypeKey = productTypeKey
        self.sku = sku
        self.price = price
        self.virtual = virtual
        self.imageURL = imageURL
        self.addOns = addOns
    }

    init(storageProduct: StorageProduct) {
        self.productID = storageProduct.productID
        self.productTypeKey = storageProduct.productTypeKey
        self.sku = storageProduct.sku
        self.price = storageProduct.price
        self.virtual = storageProduct.virtual

        self.imageURL = storageProduct.imagesArray.first?.toReadOnly().imageURL

        let addOnsArray: [StorageProductAddOn] = storageProduct.addOns?.toArray() ?? []
        self.addOns = addOnsArray.map { $0.toReadOnly() }
    }
}
