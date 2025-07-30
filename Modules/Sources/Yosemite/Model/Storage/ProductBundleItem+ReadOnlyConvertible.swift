import Foundation
import Networking
import Storage

// MARK: - Storage.ProductBundleItem: ReadOnlyConvertible
//
extension Storage.ProductBundleItem: ReadOnlyConvertible {

    /// Updates the Storage.ProductBundleItem with the ReadOnly.
    ///
    public func update(with bundleItem: Yosemite.ProductBundleItem) {
        bundledItemID = bundleItem.bundledItemID
        productID = bundleItem.productID
        menuOrder = bundleItem.menuOrder
        title = bundleItem.title
        stockStatus = bundleItem.stockStatus.rawValue
        minQuantity = NSDecimalNumber(decimal: bundleItem.minQuantity)
        maxQuantity = bundleItem.maxQuantity.map { NSDecimalNumber(decimal: $0) }
        defaultQuantity = NSDecimalNumber(decimal: bundleItem.defaultQuantity)
        isOptional = bundleItem.isOptional
        overridesVariations = bundleItem.overridesVariations
        allowedVariations = bundleItem.allowedVariations
        overridesDefaultVariationAttributes = bundleItem.overridesDefaultVariationAttributes
        pricedIndividually = bundleItem.pricedIndividually
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductBundleItem {
        let defaultVariationAttributes = defaultVariationAttributesArray
            .map { ProductVariationAttribute(id: $0.id, name: $0.key, option: $0.value) }
        return ProductBundleItem(bundledItemID: bundledItemID,
                                 productID: productID,
                                 menuOrder: menuOrder,
                                 title: title ?? "",
                                 stockStatus: ProductBundleItemStockStatus(rawValue: stockStatus ?? "in_stock") ?? .inStock,
                                 minQuantity: minQuantity.decimalValue,
                                 maxQuantity: maxQuantity?.decimalValue,
                                 defaultQuantity: defaultQuantity.decimalValue,
                                 isOptional: isOptional,
                                 overridesVariations: overridesVariations,
                                 allowedVariations: allowedVariations ?? [],
                                 overridesDefaultVariationAttributes: overridesDefaultVariationAttributes,
                                 defaultVariationAttributes: defaultVariationAttributes,
                                 pricedIndividually: pricedIndividually)
    }
}

private extension Storage.ProductBundleItem {
    var defaultVariationAttributesArray: [Storage.GenericAttribute] {
        return defaultVariationAttributes?.toArray() ?? []
    }
}
