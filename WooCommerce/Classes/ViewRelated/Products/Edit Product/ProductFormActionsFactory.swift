import Yosemite
import protocol Experiments.FeatureFlagService

/// Edit actions in the product form. Each action allows the user to edit a subset of product properties.
enum ProductFormEditAction: Equatable {
    case images(editable: Bool, isStorePublic: Bool)
    case linkedProductsPromo(viewModel: FeatureAnnouncementCardViewModel)
    case name(editable: Bool)
    case description(editable: Bool)
    case promoteWithBlaze
    case priceSettings(editable: Bool, hideSeparator: Bool)
    case customFields
    case reviews
    case productType(editable: Bool)
    case inventorySettings(editable: Bool)
    case shippingSettings(editable: Bool)
    case addOns(editable: Bool)
    case categories(editable: Bool)
    case tags(editable: Bool)
    case shortDescription(editable: Bool)
    case linkedProducts(editable: Bool)
    // Affiliate products only
    case sku(editable: Bool)
    case externalURL(editable: Bool)
    // Grouped products only
    case groupedProducts(editable: Bool)
    // Variable products only
    case variations(hideSeparator: Bool)
    // Variation only
    case variationName
    case noPriceWarning
    case status(editable: Bool)
    case attributes(editable: Bool)
    // Downloadable products only
    case downloadableFiles(editable: Bool)
    // Bundle products only
    case bundledProducts(actionable: Bool)
    // Composite products only
    case components(actionable: Bool)
    // Subscription products only
    case subscriptionFreeTrial(editable: Bool)
    case subscriptionExpiry(editable: Bool)
    // Variable Subscription products only
    case noVariationsWarning
    case quantityRules
}

/// Creates actions for different sections/UI on the product form.
struct ProductFormActionsFactory: ProductFormActionsFactoryProtocol {

    /// Represents the variation price state.
    ///
    enum VariationsPrice {
        case unknown // Un-fetched variations
        case notSet
        case set
    }

    private let product: EditableProductModel
    private let formType: ProductFormType
    private let canPromoteWithBlaze: Bool
    private let editable: Bool
    private let addOnsFeatureEnabled: Bool
    private let variationsPrice: VariationsPrice

    private let stores: StoresManager

    private let isLinkedProductsPromoEnabled: Bool
    private let linkedProductsPromoCampaign = LinkedProductsPromoCampaign()
    private var linkedProductsPromoViewModel: FeatureAnnouncementCardViewModel {
        .init(analytics: ServiceLocator.analytics,
              configuration: linkedProductsPromoCampaign.configuration)
    }
    private let isCustomFieldsEnabled: Bool

    // TODO: Remove default parameter
    init(product: EditableProductModel,
         formType: ProductFormType,
         canPromoteWithBlaze: Bool = false,
         addOnsFeatureEnabled: Bool = true,
         isLinkedProductsPromoEnabled: Bool = false,
         isCustomFieldsEnabled: Bool =
         ServiceLocator.featureFlagService.isFeatureFlagEnabled(.viewEditCustomFieldsInProductsAndOrders),
         variationsPrice: VariationsPrice = .unknown,
         stores: StoresManager = ServiceLocator.stores) {
        self.product = product
        self.formType = formType
        self.canPromoteWithBlaze = canPromoteWithBlaze
        self.editable = formType != .readonly
        self.addOnsFeatureEnabled = addOnsFeatureEnabled
        self.variationsPrice = variationsPrice
        self.isLinkedProductsPromoEnabled = isLinkedProductsPromoEnabled
        self.isCustomFieldsEnabled = isCustomFieldsEnabled
        self.stores = stores
    }

    /// Returns an array of actions that are visible in the product form primary section.
    func primarySectionActions() -> [ProductFormEditAction] {
        let shouldShowImagesRow = editable || product.images.isNotEmpty
        let shouldShowDescriptionRow = editable || product.description?.isNotEmpty == true

        let newLinkedProductsPromoViewModel = linkedProductsPromoViewModel
        let shouldShowLinkedProductsPromo = isLinkedProductsPromoEnabled
        && newLinkedProductsPromoViewModel.shouldBeVisible
        && product.upsellIDs.isEmpty
        && product.crossSellIDs.isEmpty

        let shouldShowPromoteWithBlaze = canPromoteWithBlaze

        var isStorePublic = true

        if let site = stores.sessionManager.defaultSite {
            isStorePublic = !site.isPrivateWPCOMSite
        }

        let actions: [ProductFormEditAction?] = [
            shouldShowImagesRow ? .images(editable: editable, isStorePublic: isStorePublic): nil,
            shouldShowLinkedProductsPromo ? .linkedProductsPromo(viewModel: newLinkedProductsPromoViewModel) : nil,
            .name(editable: editable),
            shouldShowDescriptionRow ? .description(editable: editable): nil,
            shouldShowPromoteWithBlaze ? .promoteWithBlaze : nil
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

private extension ProductFormActionsFactory {
    /// All the editable actions in the settings section given the product and feature switches.
    func allSettingsSectionActions() -> [ProductFormEditAction] {
        switch product.product.productType {
        case .simple:
            return allSettingsSectionActionsForSimpleProduct()
        case .affiliate:
            return allSettingsSectionActionsForAffiliateProduct()
        case .grouped:
            return allSettingsSectionActionsForGroupedProduct()
        case .variable:
            return allSettingsSectionActionsForVariableProduct()
        case .bundle:
            return allSettingsSectionActionsForBundleProduct()
        case .composite:
            return allSettingsSectionActionsForCompositeProduct()
        case .subscription:
            return allSettingsSectionActionsForSubscriptionProduct()
        case .variableSubscription:
            return allSettingsSectionActionsForVariableSubscriptionProduct()
        default:
            return allSettingsSectionActionsForNonCoreProduct()
        }
    }

    func allSettingsSectionActionsForSimpleProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let canEditProductType = editable
        let shouldShowShippingSettingsRow = product.isShippingEnabled()
        let canEditInventorySettingsRow = editable
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .priceSettings(editable: editable, hideSeparator: false),
            isCustomFieldsEnabled ? .customFields: nil,
            shouldShowReviewsRow ? .reviews: nil,
            shouldShowShippingSettingsRow ? .shippingSettings(editable: editable): nil,
            .inventorySettings(editable: canEditInventorySettingsRow),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .addOns(editable: editable),
            .categories(editable: editable),
            .tags(editable: editable),
            .downloadableFiles(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: canEditProductType)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForAffiliateProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowExternalURLRow = editable || product.product.externalURL?.isNotEmpty == true
        let shouldShowSKURow = editable || product.sku?.isNotEmpty == true
        let canEditProductType = editable
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .priceSettings(editable: editable, hideSeparator: false),
            shouldShowReviewsRow ? .reviews: nil,
            shouldShowExternalURLRow ? .externalURL(editable: editable): nil,
            shouldShowSKURow ? .sku(editable: editable): nil,
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .addOns(editable: editable),
            .categories(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: canEditProductType)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForGroupedProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowSKURow = editable || product.sku?.isNotEmpty == true
        let canEditProductType = editable
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .groupedProducts(editable: editable),
            shouldShowReviewsRow ? .reviews: nil,
            shouldShowSKURow ? .sku(editable: editable): nil,
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .addOns(editable: editable),
            .categories(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: canEditProductType)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForVariableProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let canEditProductType = editable
        let canEditInventorySettingsRow = editable
        let shouldShowAttributesRow = product.product.attributesForVariations.isNotEmpty
        let shouldShowNoPriceWarningRow: Bool = {
            let variationsHaveNoPriceSet = variationsPrice == .notSet
            let productHasNoPriceSet = variationsPrice == .unknown && product.product.variations.isNotEmpty && product.product.price.isEmpty
            return canEditProductType && (variationsHaveNoPriceSet || productHasNoPriceSet)
        }()
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .variations(hideSeparator: shouldShowNoPriceWarningRow),
            shouldShowNoPriceWarningRow ? .noPriceWarning : nil,
            shouldShowAttributesRow ? .attributes(editable: editable) : nil,
            shouldShowReviewsRow ? .reviews: nil,
            .shippingSettings(editable: editable),
            .inventorySettings(editable: canEditInventorySettingsRow),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .addOns(editable: editable),
            .categories(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: canEditProductType)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForBundleProduct() -> [ProductFormEditAction] {
        let canOpenBundledProducts = product.bundledItems.isNotEmpty
        let shouldShowPriceSettingsRow = product.regularPrice.isNilOrEmpty == false
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .bundledProducts(actionable: canOpenBundledProducts),
            shouldShowPriceSettingsRow ? .priceSettings(editable: false, hideSeparator: false): nil,
            shouldShowReviewsRow ? .reviews: nil,
            .inventorySettings(editable: false),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .categories(editable: editable),
            .addOns(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: false)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForCompositeProduct() -> [ProductFormEditAction] {
        let canOpenComponents = product.compositeComponents.isNotEmpty
        let shouldShowPriceSettingsRow = product.regularPrice.isNilOrEmpty == false
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            .components(actionable: canOpenComponents),
            shouldShowPriceSettingsRow ? .priceSettings(editable: false, hideSeparator: false): nil,
            shouldShowReviewsRow ? .reviews: nil,
            .inventorySettings(editable: false),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .categories(editable: editable),
            .addOns(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: false)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForSubscriptionProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowQuantityRulesRow = product.canEditQuantityRules
        let canEditInventorySettingsRow = editable
        let canEditProductType = editable
        let shouldShowShippingSettingsRow = product.isShippingEnabled()

        let actions: [ProductFormEditAction?] = [
            .priceSettings(editable: editable, hideSeparator: false),
            .subscriptionFreeTrial(editable: editable),
            .subscriptionExpiry(editable: editable),
            shouldShowReviewsRow ? .reviews: nil,
            shouldShowShippingSettingsRow ? .shippingSettings(editable: editable): nil,
            .inventorySettings(editable: canEditInventorySettingsRow),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .categories(editable: editable),
            .addOns(editable: editable),
            .tags(editable: editable),
            .downloadableFiles(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: canEditProductType)
        ]
        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForVariableSubscriptionProduct() -> [ProductFormEditAction] {
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowAttributesRow = product.product.attributesForVariations.isNotEmpty
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = {
            let canEditProductType = editable
            let canEditInventorySettingsRow = editable
            let shouldShowNoPriceWarningRow: Bool = {
                let variationsHaveNoPriceSet = variationsPrice == .notSet
                let productHasNoPriceSet = variationsPrice == .unknown && product.product.variations.isNotEmpty && product.product.price.isEmpty
                return canEditProductType && (variationsHaveNoPriceSet || productHasNoPriceSet)
            }()

            return [
                .variations(hideSeparator: shouldShowNoPriceWarningRow),
                shouldShowNoPriceWarningRow ? .noPriceWarning : nil,
                shouldShowAttributesRow ? .attributes(editable: editable) : nil,
                shouldShowReviewsRow ? .reviews: nil,
                .shippingSettings(editable: editable),
                .inventorySettings(editable: canEditInventorySettingsRow),
                shouldShowQuantityRulesRow ? .quantityRules : nil,
                .addOns(editable: editable),
                .categories(editable: editable),
                .tags(editable: editable),
                .shortDescription(editable: editable),
                .linkedProducts(editable: editable),
                .productType(editable: canEditProductType)
            ]
        }()

        return actions.compactMap { $0 }
    }

    func allSettingsSectionActionsForNonCoreProduct() -> [ProductFormEditAction] {
        let shouldShowPriceSettingsRow = product.regularPrice.isNilOrEmpty == false
        let shouldShowReviewsRow = product.reviewsAllowed
        let shouldShowQuantityRulesRow = product.canEditQuantityRules

        let actions: [ProductFormEditAction?] = [
            shouldShowPriceSettingsRow ? .priceSettings(editable: false, hideSeparator: false): nil,
            shouldShowReviewsRow ? .reviews: nil,
            .inventorySettings(editable: false),
            shouldShowQuantityRulesRow ? .quantityRules : nil,
            .categories(editable: editable),
            .addOns(editable: editable),
            .tags(editable: editable),
            .shortDescription(editable: editable),
            .linkedProducts(editable: editable),
            .productType(editable: false)
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
        case .customFields:
            // The custom fields action is always visible in the settings section.
            return true
        case .subscriptionFreeTrial:
            // The Free trial row is always visible in the settings section for a subscription product.
            return true
        case .subscriptionExpiry:
            // The expiry is always visible in the settings section for a subscription product.
            return true
        case .reviews:
            // The reviews action is always visible in the settings section.
            return true
        case .productType:
            // The product type action is always visible in the settings section.
            return true
        case .inventorySettings(let editable):
            guard editable else {
                // The inventory row is always visible when readonly.
                return true
            }
            let hasStockData = product.manageStock ? product.stockQuantity != nil: true
            return product.sku != nil || hasStockData
        case .shippingSettings:
            let shouldShowOneTimeShipping = {
                guard product.productType == .subscription || product.productType == .variableSubscription else {
                    return false
                }
                return product.subscription?.oneTimeShipping == true
            }()

            return product.weight.isNilOrEmpty == false
            || product.dimensions.height.isNotEmpty || product.dimensions.width.isNotEmpty || product.dimensions.length.isNotEmpty
            || shouldShowOneTimeShipping
        case .addOns:
            return addOnsFeatureEnabled && product.hasAddOns
        case .categories:
            return product.product.categories.isNotEmpty
        case .tags:
            return product.product.tags.isNotEmpty
        case .linkedProducts:
            return (product.upsellIDs.count > 0 || product.crossSellIDs.count > 0)
        // Downloadable files. Only core product types for downloadable files are able to handle downloadable files.
        case .downloadableFiles:
            return product.downloadable
        case .shortDescription:
            return product.shortDescription.isNilOrEmpty == false
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
        case .noPriceWarning:
            // Always visible when available
            return true
        case .attributes:
            // Always visible when available
            return true
        case .bundledProducts:
            // The bundled products row is always visible in the settings section for a bundle product.
            return true
        case .components:
            // The components row is always visible in the settings section for a composite product.
            return true
        case .noVariationsWarning:
            // Always visible when available
            return true
        case .quantityRules:
            // Always visible when available
            return true
        default:
            return false
        }
    }
}
