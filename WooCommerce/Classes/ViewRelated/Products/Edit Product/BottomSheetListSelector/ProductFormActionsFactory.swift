import Yosemite

/// Actions in the product form bottom sheet to add more product details.
enum ProductFormAction {
    case editImages
    case editName
    case editDescription
    case editPriceSettings
    case editInventorySettings
    case editShippingSettings
    case editCategories
    case editBriefDescription
}

/// Creates actions for product form bottom sheet.
struct ProductFormActionsFactory {
    private let product: Product
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    private var allSettingsSectionActions: [ProductFormAction] {
        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled

        let actions: [ProductFormAction?] = [
            .editPriceSettings,
            shouldShowShippingSettingsRow ? .editShippingSettings: nil,
            .editInventorySettings,
            shouldShowCategoriesRow ? .editCategories: nil,
            shouldShowBriefDescriptionRow ? .editBriefDescription: nil
        ]
        return actions.compactMap { $0 }
    }

    init(product: Product,
         isEditProductsRelease2Enabled: Bool,
         isEditProductsRelease3Enabled: Bool) {
        self.product = product
        self.isEditProductsRelease2Enabled = isEditProductsRelease2Enabled
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
    }

    /// Returns an array of actions that are visible in the product form primary section.
    func primarySectionActions() -> [ProductFormAction] {
        guard isEditProductsRelease2Enabled || product.images.isEmpty == false else {
            return [
                .editName,
                .editDescription
            ]
        }

        return [
            .editImages,
            .editName,
            .editDescription
        ]
    }

    /// Returns an array of actions that are visible in the product form settings section.
    func settingsSectionActions() -> [ProductFormAction] {
        return visibleSettingsSectionActions()
    }

    /// Retruns an array of actions that are visible in the product form bottom sheet.
    func bottomSheetActions() -> [ProductFormAction] {
        return allSettingsSectionActions.filter { settingsSectionActions().contains($0) == false }
    }
}

private extension ProductFormActionsFactory {
    func visibleSettingsSectionActions() -> [ProductFormAction] {
        return allSettingsSectionActions.compactMap({ $0 }).filter({ isVisibleInSettingsSection(action: $0) })
    }

    func isVisibleInSettingsSection(action: ProductFormAction) -> Bool {
        switch action {
        case .editPriceSettings:
            // The price settings action is always visible.
            return true
        case .editInventorySettings:
            let hasStockData = product.manageStock ? product.stockQuantity != nil: true
            return product.sku != nil || hasStockData
        case .editShippingSettings:
            return product.weight.isNilOrEmpty == false ||
                product.dimensions.height.isNotEmpty || product.dimensions.width.isNotEmpty || product.dimensions.length.isNotEmpty
        case .editCategories:
            return product.categories.isNotEmpty
        case .editBriefDescription:
            return product.briefDescription.isNilOrEmpty == false
        default:
            return false
        }
    }
}

