#if canImport(SwiftUI) && DEBUG

import Yosemite

extension ProductBundleItem {
    /// Initializes a product bundle item with default properties.
    static func swiftUIPreviewSample() -> ProductBundleItem {
        ProductBundleItem(bundledItemID: 6,
                          productID: 16,
                          menuOrder: 1,
                          title: "Scarf",
                          stockStatus: .inStock,
                          minQuantity: 2,
                          maxQuantity: nil,
                          defaultQuantity: 6,
                          isOptional: true,
                          overridesVariations: true,
                          allowedVariations: [12, 18],
                          overridesDefaultVariationAttributes: true,
                          defaultVariationAttributes: [.init(id: 2, name: "Material", option: "Silk")],
                          pricedIndividually: false)
    }
}

#endif
