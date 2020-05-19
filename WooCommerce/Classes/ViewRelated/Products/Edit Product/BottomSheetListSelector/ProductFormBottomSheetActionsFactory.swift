import Yosemite

/// Creates actions for product form bottom sheet.
struct ProductFormBottomSheetActionsFactory {
    private let product: Product
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    init(product: Product, isEditProductsRelease2Enabled: Bool, isEditProductsRelease3Enabled: Bool) {
        self.product = product
        self.isEditProductsRelease2Enabled = isEditProductsRelease2Enabled
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
    }

    /// Retruns an array of actions that are visible in the product form bottom sheet.
    func actions() -> [ProductFormBottomSheetAction] {
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
