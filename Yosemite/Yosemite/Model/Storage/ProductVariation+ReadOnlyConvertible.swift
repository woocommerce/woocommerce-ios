import Foundation
import Storage

extension Storage.ProductVariation {
    var attributesArray: [Attribute] {
        guard let attributes = attributes.array as? [Attribute] else {
            return []
        }
        return attributes
    }
}

// MARK: - Storage.ProductVariation: ReadOnlyConvertible
//
extension Storage.ProductVariation: ReadOnlyConvertible {

    /// Updates the Storage.ProductVariation with the ReadOnly.
    ///
    public func update(with productVariation: Yosemite.ProductVariation) {
        siteID = productVariation.siteID
        productID = productVariation.productID
        productVariationID = productVariation.productVariationID

        permalink = productVariation.permalink

        dateCreated = productVariation.dateCreated
        dateModified = productVariation.dateModified
        dateOnSaleStart = productVariation.dateOnSaleStart
        dateOnSaleEnd = productVariation.dateOnSaleEnd

        statusKey = productVariation.status.rawValue

        fullDescription = productVariation.description
        sku = productVariation.sku

        price = productVariation.price
        regularPrice = productVariation.regularPrice
        salePrice = productVariation.salePrice
        onSale = productVariation.onSale

        purchasable = productVariation.purchasable
        virtual = productVariation.virtual

        downloadable = productVariation.downloadable
        downloadLimit = productVariation.downloadLimit
        downloadExpiry = productVariation.downloadExpiry

        taxStatusKey = productVariation.taxStatusKey
        taxClass = productVariation.taxClass

        manageStock = productVariation.manageStock
        stockQuantity = productVariation.stockQuantity ?? 0
        stockStatusKey = productVariation.stockStatus.rawValue

        backordersKey = productVariation.backordersKey
        backordersAllowed = productVariation.backordersAllowed
        backordered = productVariation.backordered

        weight = productVariation.weight

        shippingClass = productVariation.shippingClass
        shippingClassID = productVariation.shippingClassID

        menuOrder = productVariation.menuOrder
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariation {
        let productDownloads = downloads?.map { $0.toReadOnly() } ?? [Yosemite.ProductDownload]()
        let productImage = image?.toReadOnly()
        let productAttributes = attributesArray.map { $0.toReadOnly() }
        let productDimensions = createReadOnlyDimensions()

        return ProductVariation(siteID: siteID,
                                productID: productID,
                                productVariationID: productVariationID,
                                attributes: productAttributes,
                                image: productImage,
                                permalink: permalink,
                                dateCreated: dateCreated,
                                dateModified: dateModified,
                                dateOnSaleStart: dateOnSaleStart,
                                dateOnSaleEnd: dateOnSaleEnd,
                                status: ProductStatus(rawValue: statusKey),
                                description: fullDescription,
                                sku: sku,
                                price: price,
                                regularPrice: regularPrice,
                                salePrice: salePrice,
                                onSale: onSale,
                                purchasable: purchasable,
                                virtual: virtual,
                                downloadable: downloadable,
                                downloads: productDownloads,
                                downloadLimit: downloadLimit,
                                downloadExpiry: downloadExpiry,
                                taxStatusKey: taxStatusKey,
                                taxClass: taxClass,
                                manageStock: manageStock,
                                stockQuantity: stockQuantity,
                                stockStatus: ProductStockStatus(rawValue: stockStatusKey),
                                backordersKey: backordersKey,
                                backordersAllowed: backordersAllowed,
                                backordered: backordered,
                                weight: weight,
                                dimensions: productDimensions,
                                shippingClass: shippingClass,
                                shippingClassID: shippingClassID,
                                menuOrder: menuOrder)
    }
}

// MARK: - Private Helpers
//
private extension Storage.ProductVariation {
    func createReadOnlyDimensions() -> Yosemite.ProductDimensions {
        guard let dimensions = dimensions else {
            return ProductDimensions(length: "", width: "", height: "")
        }

        return ProductDimensions(length: dimensions.length, width: dimensions.width, height: dimensions.height)
    }
}
