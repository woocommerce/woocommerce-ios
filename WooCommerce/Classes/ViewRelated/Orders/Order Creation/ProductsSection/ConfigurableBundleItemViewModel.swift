import Foundation
import Yosemite

/// View model for `ConfigurableBundleItemView` to configure a bundle item.
final class ConfigurableBundleItemViewModel: ObservableObject, Identifiable {
    struct VariableProductSettings {
        let allowedVariations: [Int64]
        let defaultAttributes: [ProductVariationAttribute]
    }

    /// For rendering the product row.
    let productRowViewModel: ProductRowViewModel

    /// ID of the bundle item.
    let bundledItemID: Int64

    /// Whether the bundle item is optional.
    let isOptional: Bool

    /// Whether the bundle item is a variable product and has variations.
    let isVariable: Bool

    private let product: Product

    @Published var quantity: Decimal
    @Published var isOptionalAndSelected: Bool = false
    @Published var variationSelectorViewModel: ProductVariationSelectorViewModel?
    @Published var selectedVariation: ProductVariation?

    /// Nil if the product is not a variable product.
    private let variableProductSettings: VariableProductSettings?

    init(bundleItem: ProductBundleItem, product: Product, variableProductSettings: VariableProductSettings?, existingOrderItem: OrderItem?) {
        bundledItemID = bundleItem.bundledItemID
        self.product = product
        isOptional = bundleItem.isOptional
        if isOptional {
            isOptionalAndSelected = existingOrderItem != nil
        }
        let quantity = existingOrderItem?.quantity ?? bundleItem.defaultQuantity
        self.quantity = quantity
        self.variableProductSettings = variableProductSettings
        isVariable = product.productType == .variable
        productRowViewModel = .init(productOrVariationID: bundleItem.productID,
                                    name: bundleItem.title,
                                    sku: nil,
                                    price: nil,
                                    stockStatusKey: "",
                                    stockQuantity: nil,
                                    manageStock: false,
                                    quantity: quantity,
                                    canChangeQuantity: true,
                                    imageURL: nil,
                                    isConfigurable: false)
        productRowViewModel.quantityUpdatedCallback = { [weak self] quantity in
            self?.quantity = quantity
        }
    }

    func createVariationSelectorViewModel() {
        let allowedProductVariationIDs = variableProductSettings?.allowedVariations ?? []
        variationSelectorViewModel = .init(siteID: product.siteID,
                                           product: product,
                                           allowedProductVariationIDs: allowedProductVariationIDs,
                                           onVariationSelectionStateChanged: { [weak self] variation, _ in
            guard let self else { return }
            self.selectedVariation = variation
            self.variationSelectorViewModel = nil
        })
    }
}

extension ConfigurableBundleItemViewModel {
    var toConfiguration: BundledProductConfiguration? {
        switch product.productType {
            case .variable:
                guard let variation = selectedVariation else {
                    return nil
                }
                return .init(bundledItemID: bundledItemID,
                             productOrVariation: .variation(productID: product.productID,
                                                            variationID: variation.productVariationID,
                                                            attributes: variation.attributes),
                             quantity: quantity,
                             isOptionalAndSelected: isOptionalAndSelected)
            default:
                return .init(bundledItemID: bundledItemID,
                             productOrVariation: .product(id: product.productID),
                             quantity: quantity,
                             isOptionalAndSelected: isOptionalAndSelected)
        }
    }
}
