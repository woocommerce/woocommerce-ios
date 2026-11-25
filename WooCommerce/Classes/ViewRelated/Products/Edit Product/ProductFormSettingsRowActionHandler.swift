import UIKit
import protocol WooFoundation.Analytics

enum ProductFormSettingsDestination {
    case price, customFields, reviews
    case downloadableFiles, linkedProducts
    case productType(sourceView: UIView?)
    case shipping, inventory, addOns
    case categories, tags, shortDescription
    case externalURL, simplifiedInventory, groupedProducts
    case variations, attributes
    case bundledProducts, components
    case subscriptionFreeTrial, subscriptionExpiry, quantityRules
}

@MainActor
protocol ProductFormSettingsNavigating: AnyObject { func navigate(to destination: ProductFormSettingsDestination) }

@MainActor
final class ProductFormSettingsRowActionHandler {
    private weak var navigator: ProductFormSettingsNavigating?
    private let eventLogger: ProductFormEventLoggerProtocol
    private let analytics: Analytics

    init(navigator: ProductFormSettingsNavigating,
         eventLogger: ProductFormEventLoggerProtocol,
         analytics: Analytics = ServiceLocator.analytics) {
        self.navigator = navigator
        self.eventLogger = eventLogger
        self.analytics = analytics
    }

    func handle(_ row: ProductFormSection.SettingsRow, sourceView: UIView?, productID: Int64) {
        switch row {
        case .price(_, let isEditable):
            guard isEditable else { return }
            eventLogger.logPriceSettingsTapped()
            navigator?.navigate(to: .price)
        case .customFields:
            analytics.track(.productDetailCustomFieldsTapped)
            navigator?.navigate(to: .customFields)
        case .reviews:
            analytics.track(.productDetailViewReviewsTapped)
            navigator?.navigate(to: .reviews)
        case .downloadableFiles(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewDownloadableFilesTapped)
            navigator?.navigate(to: .downloadableFiles)
        case .linkedProducts(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewLinkedProductsTapped)
            navigator?.navigate(to: .linkedProducts)
        case .productType(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewProductTypeTapped)
            navigator?.navigate(to: .productType(sourceView: sourceView))
        case .shipping(_, let isEditable):
            guard isEditable else { return }
            eventLogger.logShippingSettingsTapped()
            navigator?.navigate(to: .shipping)
        case .inventory(_, let isEditable):
            guard isEditable else { return }
            eventLogger.logInventorySettingsTapped()
            navigator?.navigate(to: .inventory)
        case .addOns(_, let isEditable):
            guard isEditable else { return }
            analytics.track(event: .ProductDetailAddOns.productAddOnsButtonTapped(productID: productID))
            navigator?.navigate(to: .addOns)
        case .categories(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewCategoriesTapped)
            navigator?.navigate(to: .categories)
        case .tags(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewTagsTapped)
            navigator?.navigate(to: .tags)
        case .shortDescription(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewShortDescriptionTapped)
            navigator?.navigate(to: .shortDescription)
        case .externalURL(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewExternalProductLinkTapped)
            navigator?.navigate(to: .externalURL)
        case .simplifiedInventory(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewSKUTapped)
            navigator?.navigate(to: .simplifiedInventory)
        case .groupedProducts(_, let isEditable):
            guard isEditable else { return }
            analytics.track(.productDetailViewGroupedProductsTapped)
            navigator?.navigate(to: .groupedProducts)
        case .variations(let viewModel):
            guard viewModel.isActionable else { return }
            analytics.track(.productDetailViewVariationsTapped)
            navigator?.navigate(to: .variations)
        case .noPriceWarning(let viewModel):
            guard viewModel.isActionable else { return }
            analytics.track(.productDetailViewVariationsTapped)
            navigator?.navigate(to: .variations)
        case .attributes(_, let isEditable):
            guard isEditable else { return }
            navigator?.navigate(to: .attributes)
        case .bundledProducts(_, let isActionable):
            guard isActionable else { return }
            analytics.track(event: .ProductDetail.bundledProductsTapped())
            navigator?.navigate(to: .bundledProducts)
        case .components(_, let isActionable):
            guard isActionable else { return }
            analytics.track(event: .ProductDetail.componentsTapped())
            navigator?.navigate(to: .components)
        case .subscriptionFreeTrial(_, let isEditable):
            guard isEditable else { return }
            eventLogger.logSubscriptionsFreeTrialTapped()
            navigator?.navigate(to: .subscriptionFreeTrial)
        case .subscriptionExpiry(_, let isEditable):
            guard isEditable else { return }
            eventLogger.logSubscriptionsExpirationDateTapped()
            navigator?.navigate(to: .subscriptionExpiry)
        case .quantityRules:
            eventLogger.logQuantityRulesTapped()
            navigator?.navigate(to: .quantityRules)
        case .status, .noVariationsWarning:
            break
        }
    }
}
