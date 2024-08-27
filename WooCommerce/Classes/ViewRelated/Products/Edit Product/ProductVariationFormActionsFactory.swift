import Yosemite

/// Creates actions for different sections/UI on the product variation form.
struct ProductVariationFormActionsFactory: ProductFormActionsFactoryProtocol {
    private let productVariation: EditableProductVariationModel
    private let editable: Bool

    private let isMinMaxQuantitiesEnabled: Bool

    private let stores: StoresManager

    init(productVariation: EditableProductVariationModel,
         editable: Bool,
         isMinMaxQuantitiesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.readOnlyMinMaxQuantities),
         stores: StoresManager = ServiceLocator.stores) {
        self.productVariation = productVariation
        self.editable = editable
        self.isMinMaxQuantitiesEnabled = isMinMaxQuantitiesEnabled
        self.stores = stores
    }

    /// Returns an array of actions that are visible in the product form primary section.
    func primarySectionActions() -> [ProductFormEditAction] {

        var isStorePublic = true

        if let site = stores.sessionManager.defaultSite {
            isStorePublic = !site.isPrivateWPCOMSite
        }

        let shouldShowImagesRow = editable || productVariation.images.isNotEmpty
        let shouldShowDescriptionRow = editable || productVariation.description?.isNotEmpty == true
        let actions: [ProductFormEditAction?] = [
            shouldShowImagesRow ? .images(editable: editable, isStorePublic: isStorePublic): nil,
            .variationName,
            shouldShowDescriptionRow ? .description(editable: editable): nil
        ]
        return actions.compactMap { $0 }
    }

    /// Returns an array of actions that are visible in the product form settings section.
    func settingsSectionActions() -> [ProductFormEditAction] {
        return visibleSettingsSectionActions()
    }

    /// Returns an array of actions that are visible in the product form bottom sheet.
    func bottomSheetActions() -> [ProductFormBottomSheetAction] {
        guard editable else {
            return []
        }
        return allSettingsSectionActions().filter { settingsSectionActions().contains($0) == false }
            .compactMap { ProductFormBottomSheetAction(productFormAction: $0) }
    }
}

private extension ProductVariationFormActionsFactory {
    /// All the editable actions in the settings section given the product variation.
    func allSettingsSectionActions() -> [ProductFormEditAction] {
        let shouldShowSubscriptionRow = productVariation.subscription != nil
        let shouldShowPriceSettingsRow = editable || productVariation.regularPrice?.isNotEmpty == true
        let shouldShowNoPriceWarningRow = productVariation.isEnabledAndMissingPrice
        let shouldShowShippingSettingsRow = productVariation.isShippingEnabled()
        let canEditInventorySettingsRow = editable
        let subscriptionOrPriceRow: ProductFormEditAction? = {
            if shouldShowPriceSettingsRow {
                return .priceSettings(editable: editable, hideSeparator: shouldShowNoPriceWarningRow)
            } else {
                return nil
            }
        }()
        let shouldShowQuantityRulesRow = isMinMaxQuantitiesEnabled && productVariation.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            subscriptionOrPriceRow,
            shouldShowNoPriceWarningRow ? .noPriceWarning: nil,
            shouldShowSubscriptionRow ? .subscriptionFreeTrial(editable: editable) : nil,
            shouldShowSubscriptionRow ? .subscriptionExpiry(editable: editable) : nil,
            .attributes(editable: editable),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .status(editable: editable),
            shouldShowShippingSettingsRow ? .shippingSettings(editable: editable): nil,
            .inventorySettings(editable: canEditInventorySettingsRow),
        ]
        return actions.compactMap { $0 }
    }
}

private extension ProductVariationFormActionsFactory {
    func visibleSettingsSectionActions() -> [ProductFormEditAction] {
        return allSettingsSectionActions().compactMap({ $0 }).filter({ isVisibleInSettingsSection(action: $0) })
    }

    func isVisibleInSettingsSection(action: ProductFormEditAction) -> Bool {
        switch action {
        case .priceSettings, .noPriceWarning, .status, .attributes, .quantityRules:
            // The price settings, attributes, and visibility actions are always visible in the settings section.
            return true
        case .subscriptionFreeTrial, .subscriptionExpiry:
            return productVariation.subscription != nil
        case .inventorySettings:
            let hasStockData = productVariation.manageStock ? productVariation.stockQuantity != nil: true
            return productVariation.sku != nil || hasStockData
        case .shippingSettings:
            return productVariation.weight.isNilOrEmpty == false ||
                productVariation.dimensions.height.isNotEmpty || productVariation.dimensions.width.isNotEmpty || productVariation.dimensions.length.isNotEmpty
        default:
            return false
        }
    }
}
