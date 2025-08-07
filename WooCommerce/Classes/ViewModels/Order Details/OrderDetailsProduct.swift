import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product section of order details screen.
///
struct OrderDetailsProduct: Equatable {
    let siteID: Int64
    let productID: Int64
    let name: String

    let productTypeKey: String
    let sku: String?

    let price: String
    let virtual: Bool

    let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well

    let imageURL: URL?

    let addOns: [Yosemite.ProductAddOn] //TODO: migrate AddOns to MetaData

    var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    init(siteID: Int64,
         productID: Int64,
         name: String,
         productTypeKey: String,
         sku: String?,
         price: String,
         virtual: Bool,
         stockQuantity: Decimal?,
         imageURL: URL?,
         addOns: [Yosemite.ProductAddOn]) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.productTypeKey = productTypeKey
        self.sku = sku
        self.price = price
        self.virtual = virtual
        self.stockQuantity = stockQuantity
        self.imageURL = imageURL
        self.addOns = addOns
    }

    init(storageProduct: StorageProduct) {
        self.siteID = storageProduct.siteID
        self.productID = storageProduct.productID
        self.name = storageProduct.name
        self.productTypeKey = storageProduct.productTypeKey
        self.sku = storageProduct.sku
        self.price = storageProduct.price
        self.virtual = storageProduct.virtual

        self.stockQuantity = {
            var quantity: Decimal?
            if let stockQuantity = storageProduct.stockQuantity {
                quantity = Decimal(string: stockQuantity)
            }
            return quantity
        }()

        self.imageURL = storageProduct.imagesArray.first?.toReadOnly().imageURL

        let addOnsArray: [StorageProductAddOn] = storageProduct.addOns?.toArray() ?? []
        self.addOns = addOnsArray.map { $0.toReadOnly() }
    }
}
