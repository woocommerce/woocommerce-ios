import Yosemite

/// Edit actions in the product form. Each action allows the user to edit a subset of product properties.
enum ProductFormEditAction {
    case images
    case name
    case description
    case priceSettings
    case inventorySettings
    case shippingSettings
    case categories
    case tags
    case briefDescription
    // Affiliate products only
    case sku
    case externalURL
    // Grouped products only
    case groupedProducts
    // Variable products only
    case variations
}

/// Creates actions for different sections/UI on the product form.
struct ProductFormActionsFactory {
    private let product: Product
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

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

    /// Returns an array of actions that are visible in the product form bottom sheet.
    func bottomSheetActions() -> [ProductFormBottomSheetAction] {
        return allSettingsSectionActions().filter { settingsSectionActions().contains($0) == false }
            .compactMap { ProductFormBottomSheetAction(productFormAction: $0) }
    }
}

private extension ProductFormActionsFactory {
    /// All the editable actions in the settings section given the product and feature switches.
    func allSettingsSectionActions() -> [ProductFormEditAction] {
        switch product.productType {
        case .simple:
            return allSettingsSectionActionsForSimpleProduct()
        case .affiliate:
            return allSettingsSectionActionsForAffiliateProduct()
        case .grouped:
            return allSettingsSectionActionsForGroupedProduct()
        case .variable:
            return allSettingsSectionActionsForVariableProduct()
        default:
            assertionFailure("Product of type \(product.productType) should not be editable.")
            return []
        }
    }

    func allSettingsSectionActionsForSimpleProduct() -> [ProductFormEditAction] {
        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let shouldShowTagsRow = isEditProductsRelease3Enabled

        let actions: [ProductFormEditAction?] = [
            .priceSettings,
            shouldShowShippingSettingsRow ? .shippingSettings: nil,
            .inventorySettings,
            shouldShowCategoriesRow ? .categories: nil,
            shouldShowTagsRow ? .tags: nil,
            shouldShowBriefDescriptionRow ? .briefDescription: nil
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForAffiliateProduct() -> [ProductFormEditAction] {
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let shouldShowTagsRow = isEditProductsRelease3Enabled

        let actions: [ProductFormEditAction?] = [
            .priceSettings,
            .externalURL,
            .sku,
            shouldShowCategoriesRow ? .categories: nil,
            shouldShowTagsRow ? .tags: nil,
            shouldShowBriefDescriptionRow ? .briefDescription: nil
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForGroupedProduct() -> [ProductFormEditAction] {
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let shouldShowTagsRow = isEditProductsRelease3Enabled

        let actions: [ProductFormEditAction?] = [
            .groupedProducts,
            .sku,
            shouldShowCategoriesRow ? .categories: nil,
            shouldShowTagsRow ? .tags: nil,
            shouldShowBriefDescriptionRow ? .briefDescription: nil
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForVariableProduct() -> [ProductFormEditAction] {
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let shouldShowTagsRow = isEditProductsRelease3Enabled

        let actions: [ProductFormEditAction?] = [
            .variations,
            shouldShowCategoriesRow ? .categories: nil,
            shouldShowTagsRow ? .tags: nil,
            shouldShowBriefDescriptionRow ? .briefDescription: nil
        ]
        return actions.compactMap { $0 }
    }
}

private extension ProductFormActionsFactory {
    func visibleSettingsSectionActions() -> [ProductFormEditAction] {
        return allSettingsSectionActions().compactMap({ $0 }).filter({ isVisibleInSettingsSection(action: $0) })
    }

    func isVisibleInSettingsSection(action: ProductFormEditAction) -> Bool {
        switch action {
        case .priceSettings:
            // The price settings action is always visible in the settings section.
            return true
        case .inventorySettings:
            let hasStockData = product.manageStock ? product.stockQuantity != nil: true
            return product.sku != nil || hasStockData
        case .shippingSettings:
            return product.weight.isNilOrEmpty == false ||
                product.dimensions.height.isNotEmpty || product.dimensions.width.isNotEmpty || product.dimensions.length.isNotEmpty
        case .categories:
            return product.categories.isNotEmpty
        case .tags:
            return product.tags.isNotEmpty
        case .briefDescription:
            return product.briefDescription.isNilOrEmpty == false
        // Affiliate products only.
        case .externalURL:
            // The external URL action is always visible in the settings section for an affiliate product.
            return true
        case .sku:
            return product.sku?.isNotEmpty == true
        // Grouped products only.
        case .groupedProducts:
            // The grouped products action is always visible in the settings section for a grouped product.
            return true
        // Variable products only.
        case .variations:
            // The variations row is always visible in the settings section for a variable product.
            return true
        default:
            return false
        }
    }
}
