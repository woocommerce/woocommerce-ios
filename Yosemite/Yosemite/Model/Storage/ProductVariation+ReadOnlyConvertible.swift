import Foundation
import Storage


// MARK: - ProductVariation: ReadOnlyConvertible
//
extension Storage.ProductVariation: ReadOnlyConvertible {

    /// Updates the Storage.ProductVariation with the ReadOnly.
    ///
    public func update(with productVariation: Yosemite.ProductVariation) {
        siteID = Int64(productVariation.siteID)
        variationID = Int64(productVariation.variationID)
        productID = Int64(productVariation.productID)
        permalink = productVariation.permalink
        dateCreated = productVariation.dateCreated
        dateModified = productVariation.dateModified
        dateOnSaleFrom = productVariation.dateOnSaleFrom
        dateOnSaleTo = productVariation.dateOnSaleTo
        statusKey = productVariation.statusKey
        fullDescription = productVariation.fullDescription
        sku = productVariation.sku
        price = productVariation.price
        regularPrice = productVariation.regularPrice
        salePrice = productVariation.salePrice
        onSale = productVariation.onSale
        purchasable = productVariation.purchasable
        virtual = productVariation.virtual
        downloadable = productVariation.downloadable
        downloadLimit = Int64(productVariation.downloadLimit)
        downloadExpiry = Int64(productVariation.downloadExpiry)
        taxStatusKey = productVariation.taxStatusKey
        taxClass = productVariation.taxClass
        manageStock = productVariation.manageStock
        stockQuantity = Int64(productVariation.stockQuantity ?? 0)
        stockStatusKey = productVariation.stockStatusKey
        backordersKey = productVariation.backordersKey
        backordersAllowed = productVariation.backordersAllowed
        backordered = productVariation.backordered
        weight = productVariation.weight
        shippingClass = productVariation.shippingClass ?? ""
        shippingClassID = String(productVariation.shippingClassID)
        menuOrder = Int64(productVariation.menuOrder)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductVariation {

        let productVariationAttributes = attributes?.map { $0.toReadOnly() } ?? [Yosemite.ProductVariationAttribute]()

        return ProductVariation(siteID: Int(siteID),
                                variationID: Int(variationID),
                                productID: Int(productID),
                                permalink: permalink ?? "",
                                dateCreated: dateCreated,
                                dateModified: dateModified,
                                dateOnSaleFrom: dateOnSaleFrom,
                                dateOnSaleTo: dateOnSaleTo,
                                statusKey: statusKey ?? "",
                                fullDescription: fullDescription,
                                sku: sku,
                                price: price,
                                regularPrice: regularPrice,
                                salePrice: salePrice,
                                onSale: onSale,
                                purchasable: purchasable,
                                virtual: virtual,
                                downloadable: downloadable,
                                downloadLimit: Int(downloadLimit),
                                downloadExpiry: Int(downloadExpiry),
                                taxStatusKey: taxStatusKey ?? "",
                                taxClass: taxClass,
                                manageStock: manageStock,
                                stockQuantity: Int(stockQuantity),
                                stockStatusKey: stockStatusKey ?? "",
                                backordersKey: backordersKey,
                                backordersAllowed: backordersAllowed,
                                backordered: backordered,
                                weight: weight,
                                dimensions: createReadOnlyDimensions(),
                                shippingClass: shippingClass,
                                shippingClassID: Int(shippingClassID) ?? 0,
                                image: createReadOnlyImage(),
                                attributes: productVariationAttributes,
                                menuOrder: Int(menuOrder))
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

    func createReadOnlyImage() -> Yosemite.ProductImage? {
        guard let image = image else {
            return nil
        }

        return ProductImage(imageID: Int(image.imageID),
                            dateCreated: image.dateCreated,
                            dateModified: image.dateModified,
                            src: image.src,
                            name: image.name,
                            alt: image.alt)
    }
}
