// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import Storage

// MARK: - Storage.ProductVariation: ReadOnlyConvertible
//
extension Storage.ProductVariation: ReadOnlyConvertible {

    /// Updates the Storage.ProductVariation with the ReadOnly.
    ///
    public func update(with productVariation: Yosemite.ProductVariation) {
        // Entities.
        backordered = productVariation.backordered
        backordersAllowed = productVariation.backordersAllowed
        backordersKey = productVariation.backordersKey
        dateCreated = productVariation.dateCreated
        dateModified = productVariation.dateModified
        dateOnSaleEnd = productVariation.dateOnSaleEnd
        dateOnSaleStart = productVariation.dateOnSaleStart
        downloadable = productVariation.downloadable
        downloadExpiry = productVariation.downloadExpiry
        downloadLimit = productVariation.downloadLimit
        fullDescription = productVariation.fullDescription
        manageStock = productVariation.manageStock
        menuOrder = productVariation.menuOrder
        onSale = productVariation.onSale
        permalink = productVariation.permalink
        price = productVariation.price
        productID = productVariation.productID
        productVariationID = productVariation.productVariationID
        purchasable = productVariation.purchasable
        regularPrice = productVariation.regularPrice
        salePrice = productVariation.salePrice
        shippingClass = productVariation.shippingClass
        shippingClassID = productVariation.shippingClassID
        siteID = productVariation.siteID
        sku = productVariation.sku
        statusKey = productVariation.statusKey
        stockQuantity = productVariation.stockQuantity
        stockStatusKey = productVariation.stockStatusKey
        taxClass = productVariation.taxClass
        taxStatusKey = productVariation.taxStatusKey
        virtual = productVariation.virtual
        weight = productVariation.weight
        // Relationships.
        attributes = productVariation.attributes
        dimensions = productVariation.dimensions
        downloads = productVariation.downloads
        image = productVariation.image
        product = productVariation.product
    }


    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariation {
        let attributes = self.attributes.map { $0.toReadOnly() }
        let dimensions = self.dimensions?.toReadOnly()
        let downloads = self.downloads?.map { $0.toReadOnly() } ?? [Yosemite.ProductDownload]()
        let image = self.image?.toReadOnly()
        let product = self.product?.toReadOnly()

        return ProductVariation(backordered: backordered,
                                 backordersAllowed: Bool,
                                 backordersKey: String,
                                 dateCreated: Date,
                                 dateModified: Date?,
                                 dateOnSaleEnd: Date?,
                                 dateOnSaleStart: Date?,
                                 downloadable: Bool,
                                 downloadExpiry: Int64,
                                 downloadLimit: Int64,
                                 fullDescription: String?,
                                 manageStock: Bool,
                                 menuOrder: Int64,
                                 onSale: Bool,
                                 permalink: String,
                                 price: String,
                                 productID: Int64,
                                 productVariationID: Int64?,
                                 purchasable: Bool,
                                 regularPrice: String?,
                                 salePrice: String?,
                                 shippingClass: String?,
                                 shippingClassID: Int64?,
                                 siteID: Int64,
                                 sku: String?,
                                 statusKey: String,
                                 stockQuantity: Int64?,
                                 stockStatusKey: String,
                                 taxClass: String?,
                                 taxStatusKey: String,
                                 virtual: Bool,
                                 weight: String?,
                                 // Relationships.
                                 attributes: attributes,
                                 dimensions: dimensions?,
                                 downloads: downloads?,
                                 image: image?,
                                 product: product?)
    }
}
