import Yosemite

/// Creates actions for product form bottom sheet.
struct ProductFormBottomSheetActionsFactory {
    /// Retruns an array of actions that are visible in the product form bottom sheet.
    static func actions(product: Product, isEditProductsRelease2Enabled: Bool, isEditProductsRelease3Enabled: Bool) -> [ProductFormBottomSheetAction] {
        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let shouldShowShortDescriptionRow = isEditProductsRelease2Enabled
        let actions: [ProductFormBottomSheetAction?] = [
            .editInventorySettings,
            shouldShowShippingSettingsRow ? .editShippingSettings: nil,
            shouldShowCategoriesRow ? .editCategories: nil,
            shouldShowShortDescriptionRow ? .editBriefDescription: nil
        ]
        return actions.compactMap({ $0 }).filter({ $0.isVisible(product: product) })
    }
}
