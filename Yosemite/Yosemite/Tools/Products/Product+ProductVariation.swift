import Foundation

public extension Product {
    /// In some endpoints, such as the products request with the sku parameters we get Product Variations as products.
    /// Here we convert it to our ProductVariation entity.
    ///
    func toProductVariation() -> ProductVariation? {
        guard productType == .custom("variation") else {
            return nil
        }

        return ProductVariation(siteID: siteID,
                         productID: parentID,
                         productVariationID: productID,
                         attributes: attributes.map { ProductVariationAttribute(id: $0.attributeID, name: $0.name, option: $0.options.first ?? "") },
                         image: nil,
                         permalink: permalink,
                         dateCreated: dateCreated,
                         dateModified: dateModified,
                         dateOnSaleStart: dateOnSaleStart,
                         dateOnSaleEnd: dateOnSaleEnd,
                         status: productStatus,
                         description: fullDescription,
                         sku: sku,
                         price: price,
                         regularPrice: regularPrice,
                         salePrice: salePrice,
                         onSale: onSale,
                         purchasable: purchasable,
                         virtual: virtual,
                         downloadable: downloadable,
                         downloads: downloads,
                         downloadLimit: downloadLimit,
                         downloadExpiry: downloadExpiry,
                         taxStatusKey: taxStatusKey,
                         taxClass: taxClass,
                         manageStock: manageStock,
                         stockQuantity: stockQuantity,
                         stockStatus: productStockStatus,
                         backordersKey: backordersKey,
                         backordersAllowed: backordersAllowed,
                         backordered: backordered,
                         weight: weight,
                         dimensions: dimensions,
                         shippingClass: shippingClass,
                         shippingClassID: shippingClassID,
                         menuOrder: Int64(menuOrder),
                         subscription: subscription,
                         minAllowedQuantity: minAllowedQuantity,
                         maxAllowedQuantity: maxAllowedQuantity,
                         groupOfQuantity: groupOfQuantity,
                         overrideProductQuantities: false)
    }
}
