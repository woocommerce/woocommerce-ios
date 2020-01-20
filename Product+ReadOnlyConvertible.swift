// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import Storage

// MARK: - Storage.Product: ReadOnlyConvertible
//
extension Storage.Product: ReadOnlyConvertible {

    /// Updates the Storage.Product with the ReadOnly.
    ///
    public func update(with product: Yosemite.Product) {
        // Entities.
        averageRating = product.averageRating
        backordered = product.backordered
        backordersAllowed = product.backordersAllowed
        backordersKey = product.backordersKey
        briefDescription = product.briefDescription
        catalogVisibilityKey = product.catalogVisibilityKey
        crossSellIDs = product.crossSellIDs
        dateCreated = product.dateCreated
        dateModified = product.dateModified
        downloadable = product.downloadable
        downloadExpiry = product.downloadExpiry
        downloadLimit = product.downloadLimit
        externalURL = product.externalURL
        featured = product.featured
        fullDescription = product.fullDescription
        groupedProducts = product.groupedProducts
        manageStock = product.manageStock
        menuOrder = product.menuOrder
        name = product.name
        onSale = product.onSale
        parentID = product.parentID
        permalink = product.permalink
        price = product.price
        productID = product.productID
        productTypeKey = product.productTypeKey
        purchasable = product.purchasable
        purchaseNote = product.purchaseNote
        ratingCount = product.ratingCount
        regularPrice = product.regularPrice
        relatedIDs = product.relatedIDs
        reviewsAllowed = product.reviewsAllowed
        salePrice = product.salePrice
        shippingClass = product.shippingClass
        shippingClassID = product.shippingClassID
        shippingRequired = product.shippingRequired
        shippingTaxable = product.shippingTaxable
        siteID = product.siteID
        sku = product.sku
        slug = product.slug
        soldIndividually = product.soldIndividually
        statusKey = product.statusKey
        stockQuantity = product.stockQuantity
        stockStatusKey = product.stockStatusKey
        taxClass = product.taxClass
        taxStatusKey = product.taxStatusKey
        totalSales = product.totalSales
        upsellIDs = product.upsellIDs
        variations = product.variations
        virtual = product.virtual
        weight = product.weight
        // Relationships.
        attributes = product.attributes
        categories = product.categories
        defaultAttributes = product.defaultAttributes
        dimensions = product.dimensions
        downloads = product.downloads
        images = product.images
        productVariations = product.productVariations
        searchResults = product.searchResults
        tags = product.tags
    }


    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariation {
        let attributes = self.attributes?.map { $0.toReadOnly() } ?? [Yosemite.ProductAttribute]()
        let categories = self.categories?.map { $0.toReadOnly() } ?? [Yosemite.ProductCategory]()
        let defaultAttributes = self.defaultAttributes?.map { $0.toReadOnly() } ?? [Yosemite.ProductDefaultAttribute]()
        let dimensions = self.dimensions?.toReadOnly()
        let downloads = self.downloads?.map { $0.toReadOnly() } ?? [Yosemite.ProductDownload]()
        let images = self.images?.map { $0.toReadOnly() } ?? [Yosemite.ProductImage]()
        let productVariations = self.productVariations?.map { $0.toReadOnly() } ?? [Yosemite.ProductVariation]()
        let searchResults = self.searchResults?.map { $0.toReadOnly() } ?? [Yosemite.ProductSearchResults]()
        let tags = self.tags?.map { $0.toReadOnly() } ?? [Yosemite.ProductTag]()

        return Product(averageRating: averageRating,
                                 backordered: Bool,
                                 backordersAllowed: Bool,
                                 backordersKey: String,
                                 briefDescription: String?,
                                 catalogVisibilityKey: String,
                                 crossSellIDs: [Int64]?,
                                 dateCreated: Date,
                                 dateModified: Date?,
                                 downloadable: Bool,
                                 downloadExpiry: Int64,
                                 downloadLimit: Int64,
                                 externalURL: String?,
                                 featured: Bool,
                                 fullDescription: String?,
                                 groupedProducts: [Int64],
                                 manageStock: Bool,
                                 menuOrder: Int64,
                                 name: String,
                                 onSale: Bool,
                                 parentID: Int64,
                                 permalink: String,
                                 price: String,
                                 productID: Int64,
                                 productTypeKey: String,
                                 purchasable: Bool,
                                 purchaseNote: String?,
                                 ratingCount: Int64,
                                 regularPrice: String?,
                                 relatedIDs: [Int64]?,
                                 reviewsAllowed: Bool,
                                 salePrice: String?,
                                 shippingClass: String?,
                                 shippingClassID: Int64,
                                 shippingRequired: Bool,
                                 shippingTaxable: Bool,
                                 siteID: Int64,
                                 sku: String?,
                                 slug: String,
                                 soldIndividually: Bool,
                                 statusKey: String,
                                 stockQuantity: String?,
                                 stockStatusKey: String,
                                 taxClass: String?,
                                 taxStatusKey: String,
                                 totalSales: Int64,
                                 upsellIDs: [Int64]?,
                                 variations: [Int64]?,
                                 virtual: Bool,
                                 weight: String?,
                                 // Relationships.
                                 attributes: attributes?,
                                 categories: categories?,
                                 defaultAttributes: defaultAttributes?,
                                 dimensions: dimensions?,
                                 downloads: downloads?,
                                 images: images?,
                                 productVariations: productVariations?,
                                 searchResults: searchResults?,
                                 tags: tags?)
    }
}
