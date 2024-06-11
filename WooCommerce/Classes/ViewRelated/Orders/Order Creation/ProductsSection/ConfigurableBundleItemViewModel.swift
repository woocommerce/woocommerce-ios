import Combine
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

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

    /// Whether the bundle item is included in the bundle. For non-optional item, it's always included.
    /// For optional item, it's based on the `isOptionalAndSelected` state.
    var isIncludedInBundle: Bool {
        isOptional ? isOptionalAndSelected: true
    }

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    @Published private(set) var canChangeQuantity: Bool
    /// For rendering the product row with the quantity setting UI.
    @Published private(set) var productWithStepperViewModel: ProductWithQuantityStepperViewModel
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

    /// Tracks the selection option for each variation attribute manually because any changes on
    /// `ConfigurableVariableBundleAttributePickerViewModel`'s observable property does not trigger an update in the
    /// `selectableVariationAttributeViewModels` observation.
    @Published private var selectableVariationOptionsByName: [String: ProductVariationAttribute?] = [:]
    private var selectableVariationOptionsSubscriptions: Set<AnyCancellable> = []
    private var selectableVariationAttributeViewModelsSubscription: AnyCancellable?

    // MARK: - Validation
    /// The actual quantity when being counted for the bundle. When the item is optional and not selected, the quantity is considered 0.
    @Published private(set) var quantityInBundle: Decimal = 0
    @Published private(set) var errorMessage: String?

    private let product: Product
    private let bundleItem: ProductBundleItem
    private let analytics: Analytics

    /// Nil if the product is not a variable product.
    private let variableProductSettings: VariableProductSettings?

    init(bundleItem: ProductBundleItem,
         product: Product,
         variableProductSettings: VariableProductSettings?,
         existingParentOrderItem: OrderItem?,
         existingOrderItem: OrderItem?,
         analytics: Analytics = ServiceLocator.analytics) {
        bundledItemID = bundleItem.bundledItemID
        self.product = product
        self.bundleItem = bundleItem
        isOptional = bundleItem.isOptional
        let isOptionalAndSelected = existingOrderItem != nil
        self.isOptionalAndSelected = isOptionalAndSelected
        let quantity: Decimal = {
            guard let orderItemQuantity = existingOrderItem?.quantity else {
                return bundleItem.defaultQuantity
            }
            let parentOrderItemQuantity = max(existingParentOrderItem?.quantity ?? 1, 1)

            // When the parent order item quantity is incremented without configuring the bundle, the quantity of the child items
            // are not multiplied. Thus, we want to return the child item quantity when its quantity is smaller than the parent order
            // item quantity.
            guard orderItemQuantity >= parentOrderItemQuantity else {
                return orderItemQuantity
            }
            return orderItemQuantity * 1.0 / parentOrderItemQuantity
        }()
        self.quantity = quantity
        self.variableProductSettings = variableProductSettings
        self.analytics = analytics
        isVariable = product.productType == .variable

        let canChangeQuantity = !isOptional || isOptionalAndSelected
        self.canChangeQuantity = canChangeQuantity
        let productRowViewModel = ProductRowViewModel(productOrVariationID: bundleItem.productID,
                                                      name: bundleItem.title,
                                                      sku: nil,
                                                      price: nil,
                                                      stockStatusKey: "",
                                                      stockQuantity: nil,
                                                      manageStock: false,
                                                      quantity: quantity,
                                                      imageURL: product.imageURL,
                                                      isConfigurable: false)
        let stepperViewModel = ProductStepperViewModel(quantity: quantity,
                                                       name: bundleItem.title,
                                                       minimumQuantity: bundleItem.minQuantity,
                                                       maximumQuantity: bundleItem.maxQuantity,
                                                       quantityUpdatedCallback: { _ in })
        self.productWithStepperViewModel = .init(stepperViewModel: stepperViewModel, rowViewModel: productRowViewModel)
        stepperViewModel.quantityUpdatedCallback = { [weak self] quantity in
            guard let self else { return }
            self.quantity = quantity
            self.analytics.track(event: .Orders.orderFormBundleProductConfigurationChanged(changedField: .quantity))
        }
        if let existingOrderItem, isVariable && existingOrderItem.variationID != .zero {
            selectedVariation = {
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
        observeStatesForValidationErrorMessage()
        observeQuantityAndOptionalSelectedStatesForQuantityInBundle()
        observeSelectableVariationAttributesForSelectedOptions()
    }

    func createVariationSelectorViewModel() {
        let allowedProductVariationIDs = variableProductSettings?.allowedVariations ?? []
        variationSelectorViewModel = .init(siteID: product.siteID,
                                           product: product,
                                           allowedProductVariationIDs: allowedProductVariationIDs,
                                           selectedProductVariationIDs: selectedVariation.map { [$0.variationID] } ?? [],
                                           orderSyncState: nil,
                                           onVariationSelectionStateChanged: { [weak self] variation, _, _ in
            guard let self else { return }
            self.selectedVariation = .init(variationID: variation.productVariationID, attributes: variation.attributes)
            self.variationSelectorViewModel = nil
            self.analytics.track(event: .Orders.orderFormBundleProductConfigurationChanged(changedField: .variation))
        })
    }
}

private extension ConfigurableBundleItemViewModel {
    func observeSelectedStateForProductRowViewModelIfOptional() {
        guard isOptional else {
            return
        }
        $isOptionalAndSelected
            .assign(to: &$canChangeQuantity)
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

    /// Validates the configuration of the bundle item based on the quantity and variation requirements.
    /// The validation error is set to the `errorMessage` Published variable so the view can display the message.
    /// Ref: Pe5pgL-3Vd-p2#validation-of-bundle-configuration
    func observeStatesForValidationErrorMessage() {
        Publishers.CombineLatest4($isOptionalAndSelected, $quantity, $selectedVariation, $selectableVariationOptionsByName)
            .map { [weak self] isOptionalAndSelected, quantity, selectedVariation, selectableVariationOptionsByName -> String? in
                guard let self else { return nil }

                // The bundle configuration is always considered valid if not selected.
                let isIncludedInBundle = isOptional ? isOptionalAndSelected: true
                guard isIncludedInBundle && quantity > 0 else {
                    return nil
                }

                guard quantity >= bundleItem.minQuantity else {
                    return createInvalidQuantityErrorMessage()
                }

                if let maxQuantity = bundleItem.maxQuantity, quantity > maxQuantity {
                    return createInvalidQuantityErrorMessage()
                }

                // If this is not a variable product, it's considered valid after the quantity check.
                guard variableProductSettings != nil else {
                    return nil
                }

                guard selectedVariation != nil else {
                    return String(format: Localization.ErrorMessage.missingVariationFormat, product.name)
                }

                let variationAttributes = (selectedVariation?.attributes ?? []) + selectableVariationOptionsByName.compactMap { $0.value }
                guard variationAttributes.count == product.attributesForVariations.count else {
                    return String(format: Localization.ErrorMessage.variationMissingAttributesFormat, product.name)
                }

                return nil
            }
            .assign(to: &$errorMessage)
    }

    func observeQuantityAndOptionalSelectedStatesForQuantityInBundle() {
        Publishers.CombineLatest($isOptionalAndSelected, $quantity)
            .map { [weak self] isOptionalAndSelected, quantity -> Decimal in
                guard let self else { return 0 }

                let isIncludedInBundle = isOptional ? isOptionalAndSelected: true
                return isIncludedInBundle ? quantity: 0
            }
            .assign(to: &$quantityInBundle)
    }

    func observeSelectableVariationAttributesForSelectedOptions() {
        selectableVariationAttributeViewModelsSubscription = $selectableVariationAttributeViewModels
            .sink { [weak self] viewModels in
                self?.observeSelectableVariationAttributeSelectionOptions(viewModels: viewModels)
            }
    }

    func observeSelectableVariationAttributeSelectionOptions(viewModels: [ConfigurableVariableBundleAttributePickerViewModel]) {
        selectableVariationOptionsByName = [:]
        selectableVariationOptionsSubscriptions = []

        viewModels.forEach { viewModel in
            viewModel.$selectedAttribute.sink { [weak self] selectedAttribute in
                self?.selectableVariationOptionsByName[viewModel.name] = selectedAttribute
            }
            .store(in: &selectableVariationOptionsSubscriptions)
        }
    }
}

extension ConfigurableBundleItemViewModel {
    var toConfiguration: BundledProductConfiguration? {
        switch product.productType {
            case .variable:
                guard let variation = selectedVariation else {
                    // When no variation is selected when the variable bundle item is not selected, a configuration
                    // is still required in the API.
                    return .init(bundledItemID: bundledItemID,
                                 productOrVariation: .product(id: product.productID),
                                 quantity: 0,
                                 isOptionalAndSelected: isOptionalAndSelected)
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
            return String(format: Localization.ErrorMessage.invalidQuantityWithMinAndMaxQuantityRulesFormat, product.name, minQuantityString, maxQuantityString)
        } else {
            return String(format: Localization.ErrorMessage.invalidQuantityWithMinQuantityRuleFormat, product.name, minQuantityString)
        }
    }
}

private extension ConfigurableBundleItemViewModel {
    enum Localization {
        enum ErrorMessage {
            static let invalidQuantityWithMinQuantityRuleFormat = NSLocalizedString(
                "configureBundleItemError.invalidQuantityWithMinQuantityRuleFormat",
                value: "The quantity of %1$@ needs to be at least %2$@.",
                comment: "Error message when setting a bundle item's quantity with a minimum quantity rule. " +
                "%1$@ is the product name. %2$@ is the minimum quantity."
            )
            static let invalidQuantityWithMinAndMaxQuantityRulesFormat = NSLocalizedString(
                "configureBundleItemError.invalidQuantityWithMinAndMaxQuantityRulesFormat",
                value: "The quantity of %1$@ needs to be within %2$@ and %3$@.",
                comment: "Error message when setting a bundle item's quantity with minimum and maximum quantity rules. " +
                "%1$@ is the product name. %2$@ is the minimum quantity, and %3$@ is the maximum quantity"
            )
            static let missingVariationFormat = NSLocalizedString(
                "configureBundleItemError.missingVariationFormat",
                value: "Choose a variation for %1$@.",
                comment: "Error message format when a variable bundle item is missing a variation. " +
                "%1$@ is the variable product name."
            )
            static let variationMissingAttributesFormat = NSLocalizedString(
                "configureBundleItemError.variationMissingAttributesFormat",
                value: "Choose an option for all variation attributes for %1$@.",
                comment: "Error message format when a variable bundle item is missing some attributes. " +
                "%1$@ is the variable product name."
            )
        }
    }
}
