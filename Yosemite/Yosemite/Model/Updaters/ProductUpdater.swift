import Foundation

public protocol ProductUpdater {
    func nameUpdated(name: String) -> Product
    func descriptionUpdated(description: String) -> Product
    func shippingSettingsUpdated(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) -> Product
    func priceSettingsUpdated(regularPrice: String?,
                              salePrice: String?,
                              dateOnSaleStart: Date?,
                              dateOnSaleEnd: Date?,
                              taxStatus: ProductTaxStatus,
                              taxClass: TaxClass?) -> Product
    func inventorySettingsUpdated(sku: String?,
                                  manageStock: Bool,
                                  soldIndividually: Bool,
                                  stockQuantity: Int?,
                                  backordersSetting: ProductBackordersSetting?,
                                  stockStatus: ProductStockStatus?) -> Product
    func imagesUpdated(images: [ProductImage]) -> Product
    func briefDescriptionUpdated(briefDescription: String) -> Product
    func productSettingsUpdated(settings: ProductSettings) -> Product
}

extension Product: ProductUpdater {
    public func nameUpdated(name: String) -> Product {
        copy(name: name)
    }

    public func descriptionUpdated(description: String) -> Product {
        copy(fullDescription: description)
    }

    public func shippingSettingsUpdated(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) -> Product {
        copy(
            weight: weight,
            dimensions: dimensions,
            shippingClass: shippingClass?.slug,
            shippingClassID: shippingClass?.shippingClassID ?? 0,
            productShippingClass: shippingClass
        )
    }

    public func priceSettingsUpdated(regularPrice: String?,
                                     salePrice: String?,
                                     dateOnSaleStart: Date?,
                                     dateOnSaleEnd: Date?,
                                     taxStatus: ProductTaxStatus,
                                     taxClass: TaxClass?) -> Product {
        copy(
            dateOnSaleStart: dateOnSaleStart,
            dateOnSaleEnd: dateOnSaleEnd,
            regularPrice: regularPrice,
            salePrice: salePrice,
            taxStatusKey: taxStatus.rawValue,
            taxClass: taxClass?.slug
        )
    }

    public func inventorySettingsUpdated(sku: String?,
                                         manageStock: Bool,
                                         soldIndividually: Bool,
                                         stockQuantity: Int?,
                                         backordersSetting: ProductBackordersSetting?,
                                         stockStatus: ProductStockStatus?) -> Product {
        copy(
            sku: sku,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatus?.rawValue ?? stockStatusKey,
            backordersKey: backordersSetting?.rawValue ?? backordersKey,
            soldIndividually: soldIndividually
        )
    }

    public func imagesUpdated(images: [ProductImage]) -> Product {
        copy(images: images)
    }

    public func briefDescriptionUpdated(briefDescription: String) -> Product {
        copy(briefDescription: briefDescription)
    }
    public func productSettingsUpdated(settings: ProductSettings) -> Product {
        copy(
            statusKey: settings.status.rawValue,
            featured: settings.featured,
            catalogVisibilityKey: settings.catalogVisibility.rawValue
        )
    }
}
