import Foundation
import Yosemite

/// View model for `ConfigurableBundleItemView` to configure a bundle item.
final class ConfigurableBundleItemViewModel: ObservableObject, Identifiable {
    struct VariableProductSettings {
        let allowedVariations: [Int64]
        let defaultAttributes: [ProductVariationAttribute]
    }

    /// Necessary info about a variation in the bundle item configuration form.
    struct Variation: Equatable {
        let variationID: Int64
        let attributes: [ProductVariationAttribute]
    }

    /// ID of the bundle item.
    let bundledItemID: Int64

    /// Whether the bundle item is optional.
    let isOptional: Bool

    /// Whether the bundle item is a variable product and has variations.
    let isVariable: Bool

    /// For rendering the product row with the quantity setting UI.
    @Published private(set) var productRowViewModel: ProductRowViewModel
    @Published var quantity: Decimal
    @Published var isOptionalAndSelected: Bool = false

    // MARK: - Variable bundle item
    @Published private(set) var variationSelectorViewModel: ProductVariationSelectorViewModel?
    @Published private(set) var selectedVariation: Variation?
    var variationAttributes: [ProductVariationAttribute] {
        guard let selectedVariation else {
            return []
        }
        return selectedVariation.attributes + selectableVariationAttributeViewModels.compactMap { $0.selectedAttribute }
    }
    @Published private(set) var selectableVariationAttributeViewModels: [ConfigurableVariableBundleAttributePickerViewModel] = []

    @Published var errorMessage: String?

    private let product: Product
    private let bundleItem: ProductBundleItem

    /// Nil if the product is not a variable product.
    private let variableProductSettings: VariableProductSettings?

    init(bundleItem: ProductBundleItem, product: Product, variableProductSettings: VariableProductSettings?, existingOrderItem: OrderItem?) {
        bundledItemID = bundleItem.bundledItemID
        self.product = product
        self.bundleItem = bundleItem
        isOptional = bundleItem.isOptional
        let isOptionalAndSelected = existingOrderItem != nil
        self.isOptionalAndSelected = isOptionalAndSelected
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
                                    minimumQuantity: bundleItem.minQuantity,
                                    maximumQuantity: bundleItem.maxQuantity,
                                    canChangeQuantity: !isOptional || isOptionalAndSelected,
                                    imageURL: product.imageURL,
                                    hasParentProduct: false,
                                    isConfigurable: false)
        productRowViewModel.quantityUpdatedCallback = { [weak self] quantity in
            self?.quantity = quantity
        }
        if let existingOrderItem, isVariable && existingOrderItem.variationID != .zero {
            selectedVariation = {
                let variationID = existingOrderItem.variationID
                let allVariationAttributeNames = product.attributesForVariations.map { $0.name }
                let attributes = existingOrderItem.attributes
                    .filter { allVariationAttributeNames.contains($0.name) }
                    .map { ProductVariationAttribute(id: $0.metaID, name: $0.name, option: $0.value) }
                return Variation(variationID: existingOrderItem.variationID,
                                 attributes: attributes)
            }()
        }
        observeSelectedStateForProductRowViewModelIfOptional()
        observeSelectedVariationForSelectableAttributes()
    }

    func createVariationSelectorViewModel() {
        let allowedProductVariationIDs = variableProductSettings?.allowedVariations ?? []
        variationSelectorViewModel = .init(siteID: product.siteID,
                                           product: product,
                                           allowedProductVariationIDs: allowedProductVariationIDs,
                                           selectedProductVariationIDs: selectedVariation.map { [$0.variationID] } ?? [],
                                           onVariationSelectionStateChanged: { [weak self] variation, _ in
            guard let self else { return }
            self.selectedVariation = .init(variationID: variation.productVariationID, attributes: variation.attributes)
            self.variationSelectorViewModel = nil
        })
    }

    /// Validates the configuration of the bundle item based on the quantity and variation requirements.
    /// The validation error is set to the `errorMessage` Published variable so the view can display the message.
    /// Ref: Pe5pgL-3Vd-p2#validation-of-bundle-configuration
    /// - Returns: A boolean that indicates whether the configuration is valid.
    func validate() -> Bool {
        errorMessage = nil

         // The bundle configuration is always considered valid if not selected.
        guard !(isOptional && isOptionalAndSelected == false) else {
            return true
        }

        guard quantity >= bundleItem.minQuantity else {
            errorMessage = createInvalidQuantityErrorMessage()
            return false
        }

        if let maxQuantity = bundleItem.maxQuantity, quantity > maxQuantity {
            errorMessage = createInvalidQuantityErrorMessage()
            return false
        }

        // If this is not a variable product, it's considered valid after the quantity check.
        guard variableProductSettings != nil else {
            return true
        }

        guard selectedVariation != nil else {
            errorMessage = Localization.ErrorMessage.missingVariation
            return false
        }

        guard variationAttributes.count == product.attributesForVariations.count else {
            errorMessage = Localization.ErrorMessage.variationMissingAttributes
            return false
        }

        return true
    }
}

private extension ConfigurableBundleItemViewModel {
    func observeSelectedStateForProductRowViewModelIfOptional() {
        guard isOptional else {
            return
        }
        $isOptionalAndSelected.compactMap { [weak self] isOptionalAndSelected in
            guard let self else { return nil }
            let productRowViewModel = ProductRowViewModel(productOrVariationID: self.product.productID,
                                                          name: self.bundleItem.title,
                                                          sku: nil,
                                                          price: nil,
                                                          stockStatusKey: "",
                                                          stockQuantity: nil,
                                                          manageStock: false,
                                                          quantity: self.quantity,
                                                          minimumQuantity: self.bundleItem.minQuantity,
                                                          maximumQuantity: self.bundleItem.maxQuantity,
                                                          canChangeQuantity: isOptionalAndSelected,
                                                          imageURL: self.product.imageURL,
                                                          hasParentProduct: false,
                                                          isConfigurable: false)
            productRowViewModel.quantityUpdatedCallback = { [weak self] quantity in
                self?.quantity = quantity
            }
            return productRowViewModel
        }
        .assign(to: &$productRowViewModel)
    }

    func observeSelectedVariationForSelectableAttributes() {
        $selectedVariation.compactMap { [weak self] selectedVariation in
            guard let self, let selectedVariation else { return nil }

            let fixedAttributeNames = selectedVariation.attributes.map { $0.name }
            let allAttributes = self.product.attributesForVariations
            let selectableAttributeViewModels = allAttributes.filter { !fixedAttributeNames.contains($0.name) }
                .map { attribute in
                    let defaultOption = self.variableProductSettings?.defaultAttributes.first(where: { $0.name == attribute.name })?.option
                    return ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute, selectedOption: defaultOption)
                }
            return selectableAttributeViewModels
        }
        .assign(to: &$selectableVariationAttributeViewModels)
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
                                                            variationID: variation.variationID,
                                                            attributes: variationAttributes),
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

private extension ConfigurableBundleItemViewModel {
    func createInvalidQuantityErrorMessage() -> String {
        let minQuantityString = NumberFormatter.localizedString(from: bundleItem.minQuantity as NSDecimalNumber, number: .decimal)
        if let maxQuantity = bundleItem.maxQuantity {
            let maxQuantityString = NumberFormatter.localizedString(from: maxQuantity as NSDecimalNumber, number: .decimal)
            return String(format: Localization.ErrorMessage.invalidQuantityWithMinAndMaxQuantityRules, minQuantityString, maxQuantityString)
        } else {
            return String(format: Localization.ErrorMessage.invalidQuantityWithMinQuantityRule, minQuantityString)
        }
    }
}

private extension ConfigurableBundleItemViewModel {
    enum Localization {
        enum ErrorMessage {
            static let invalidQuantityWithMinQuantityRule = NSLocalizedString(
                "configureBundleItemError.invalidQuantityWithMinQuantityRule",
                value: "The quantity needs to be at least %1$@",
                comment: "Error message when setting a bundle item's quantity with a minimum quantity rule."
            )
            static let invalidQuantityWithMinAndMaxQuantityRules = NSLocalizedString(
                "configureBundleItemError.invalidQuantityWithMinAndMaxQuantityRules",
                value: "The quantity needs to be within %1$@ and %2$@",
                comment: "Error message when setting a bundle item's quantity with minimum and maximum quantity rules."
            )
            static let missingVariation = NSLocalizedString(
                "configureBundleItemError.missingVariation",
                value: "Please select a variation",
                comment: "Error message when a variable bundle item is missing a variation."
            )
            static let variationMissingAttributes = NSLocalizedString(
                "configureBundleItemError.variationMissingAttributes",
                value: "Please select an option for all variation attributes",
                comment: "Error message when a variable bundle item is missing some attributes."
            )
        }
    }
}
