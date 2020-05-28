import Yosemite

/// Edit actions in the product form.
enum ProductFormEditAction {
    case images
    case name
    case description
    case priceSettings
    case inventorySettings
    case shippingSettings
    case categories
    case briefDescription
}

/// Creates actions for product form bottom sheet.
struct ProductFormActionsFactory {
    private let product: Product
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    private var allSettingsSectionActions: [ProductFormEditAction] {
        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled

        let actions: [ProductFormEditAction?] = [
            .priceSettings,
            shouldShowShippingSettingsRow ? .shippingSettings: nil,
            .inventorySettings,
            shouldShowCategoriesRow ? .categories: nil,
            shouldShowBriefDescriptionRow ? .briefDescription: nil
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
    func primarySectionActions() -> [ProductFormEditAction] {
        guard isEditProductsRelease2Enabled || product.images.isEmpty == false else {
            return [
                .name,
                .description
            ]
        }

        return [
            .images,
            .name,
            .description
        ]
    }

    /// Returns an array of actions that are visible in the product form settings section.
    func settingsSectionActions() -> [ProductFormEditAction] {
        return visibleSettingsSectionActions()
    }

    /// Retruns an array of actions that are visible in the product form bottom sheet.
    func bottomSheetActions() -> [ProductFormBottomSheetAction] {
        return allSettingsSectionActions.filter { settingsSectionActions().contains($0) == false }
            .compactMap { ProductFormBottomSheetAction(productFormAction: $0) }
    }
}

private extension ProductFormActionsFactory {
    func visibleSettingsSectionActions() -> [ProductFormEditAction] {
        return allSettingsSectionActions.compactMap({ $0 }).filter({ isVisibleInSettingsSection(action: $0) })
    }

    func isVisibleInSettingsSection(action: ProductFormEditAction) -> Bool {
        switch action {
        case .priceSettings:
            // The price settings action is always visible.
            return true
        case .inventorySettings:
            let hasStockData = product.manageStock ? product.stockQuantity != nil: true
            return product.sku != nil || hasStockData
        case .shippingSettings:
            return product.weight.isNilOrEmpty == false ||
                product.dimensions.height.isNotEmpty || product.dimensions.width.isNotEmpty || product.dimensions.length.isNotEmpty
        case .categories:
            return product.categories.isNotEmpty
        case .briefDescription:
            return product.briefDescription.isNilOrEmpty == false
        default:
            return false
        }
    }
}

