import Yosemite

/// Creates actions for different sections/UI on the product variation form.
struct ProductVariationFormActionsFactory: ProductFormActionsFactoryProtocol {
    private let productVariation: EditableProductVariationModel
    private let editable: Bool

    init(productVariation: EditableProductVariationModel, editable: Bool) {
        self.productVariation = productVariation
        self.editable = editable
    }

    /// Returns an array of actions that are visible in the product form primary section.
    func primarySectionActions() -> [ProductFormEditAction] {
        return [
            .images(editable: editable),
            .variationName,
            .description(editable: editable)
        ]
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
        let shouldShowNoPriceWarningRow = productVariation.isEnabledAndMissingPrice
        let shouldShowShippingSettingsRow = productVariation.isShippingEnabled()

        let actions: [ProductFormEditAction?] = [
            .priceSettings(editable: editable),
            shouldShowNoPriceWarningRow ? .noPriceWarning: nil,
            .status(editable: editable),
            shouldShowShippingSettingsRow ? .shippingSettings(editable: editable): nil,
            .inventorySettings(editable: editable),
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
        case .priceSettings, .noPriceWarning, .status:
            // The price settings and visibility actions are always visible in the settings section.
            return true
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
