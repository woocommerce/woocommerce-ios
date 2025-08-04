import Foundation
import Yosemite

/// Represents a Product Entity with basic details to display in the product list.
///
struct OrderDetailsProduct: Equatable {
    let siteID: Int64
    let productID: Int64
    let name: String

    let productTypeKey: String
//    let statusKey: String        // draft, pending, private, published
    let sku: String?
//
    let price: String
    let virtual: Bool
//
    let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
//    let stockStatusKey: String   // instock, outofstock, backorder
//
//    let reviewsAllowed: Bool
//    let averageRating: String
//    let ratingCount: Int

    let imageURL: URL?

    let addOns: [Yosemite.ProductAddOn] //TODO: migrate AddOns to MetaData

    /// Computed Properties
    ///
//    var productStatus: ProductStatus {
//        return ProductStatus(rawValue: statusKey)
//    }
//
//    var productStockStatus: ProductStockStatus {
//        return ProductStockStatus(rawValue: stockStatusKey)
//    }
//
    var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    /// Product struct initializer.
    ///
    init(siteID: Int64,
         productID: Int64,
         name: String,
         productTypeKey: String,
//         statusKey: String,
         sku: String?,
         price: String,
         virtual: Bool,
         stockQuantity: Decimal?,
//         stockStatusKey: String,
//         reviewsAllowed: Bool,
//         averageRating: String,
//         ratingCount: Int,
         imageURL: URL?,
         addOns: [Yosemite.ProductAddOn]) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.productTypeKey = productTypeKey
//        self.statusKey = statusKey
        self.sku = sku
        self.price = price
        self.virtual = virtual
        self.stockQuantity = stockQuantity
//        self.stockStatusKey = stockStatusKey
//        self.reviewsAllowed = reviewsAllowed
//        self.averageRating = averageRating
//        self.ratingCount = ratingCount
        self.imageURL = imageURL
        self.addOns = addOns
    }

    init(storageProduct: StorageProduct) {
        self.siteID = storageProduct.siteID
        self.productID = storageProduct.productID
        self.name = storageProduct.name
        self.productTypeKey = storageProduct.productTypeKey
//             statusKey: statusKey,
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
//             stockStatusKey: stockStatusKey,
//             reviewsAllowed: reviewsAllowed,
//             averageRating: averageRating,
//             ratingCount: Int(ratingCount),
        self.imageURL = storageProduct.imagesArray.first?.toReadOnly().imageURL

        let addOnsArray: [StorageProductAddOn] = storageProduct.addOns?.toArray() ?? []
        self.addOns = addOnsArray.map { $0.toReadOnly() }
    }
}
