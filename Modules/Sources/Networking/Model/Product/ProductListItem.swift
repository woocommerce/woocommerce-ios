import Foundation
import CocoaLumberjackSwift
import Codegen

/// Represents a Product Entity with basic details to display in the product list.
///
public struct ProductListItem: GeneratedCopiable, Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64
    public let name: String
    public let permalink: String
    public let date: Date

    public let productTypeKey: String
    public let statusKey: String        // draft, pending, private, published

    public let fullDescription: String?
    public let shortDescription: String?
    public let sku: String?

    public let price: String
    public let virtual: Bool

    public let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
    public let stockStatusKey: String   // instock, outofstock, backorder

    public let reviewsAllowed: Bool
    public let averageRating: String
    public let ratingCount: Int

    public let weight: String?
    public let dimensions: ProductDimensions

    public let images: [ProductImage]

    public let addOns: [ProductAddOn] //TODO: migrate AddOns to MetaData

    /// Computed Properties
    ///
    public var productStatus: ProductStatus {
        return ProductStatus(rawValue: statusKey)
    }

    public var productStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }

    public var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    /// Product struct initializer.
    ///
    public init(siteID: Int64,
                productID: Int64,
                name: String,
                permalink: String,
                date: Date,
                productTypeKey: String,
                statusKey: String,
                fullDescription: String?,
                shortDescription: String?,
                sku: String?,
                price: String,
                virtual: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String,
                reviewsAllowed: Bool,
                averageRating: String,
                ratingCount: Int,
                weight: String?,
                dimensions: ProductDimensions,
                images: [ProductImage],
                addOns: [ProductAddOn]) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.permalink = permalink
        self.date = date
        self.productTypeKey = productTypeKey
        self.statusKey = statusKey
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.price = price
        self.virtual = virtual
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.reviewsAllowed = reviewsAllowed
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.weight = weight
        self.dimensions = dimensions
        self.images = images
        self.addOns = addOns
    }

}

public extension ProductListItem {
    /// Default product URL {site_url}?post_type=product&p={product_id} works for all sites.
    func alternativePermalink(with siteURL: String) -> String {
        String(format: "%@?post_type=product&p=%d", siteURL, productID)
    }
}

// MARK: - Hashable Conformance
//
extension ProductListItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(siteID)
        hasher.combine(productID)
    }
}
