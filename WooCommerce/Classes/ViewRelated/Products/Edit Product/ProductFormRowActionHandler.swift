import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// Routes interactions with the Product form's content to navigation, applying the same
/// editability/actionability guards and analytics as the legacy `didSelectRowAt` implementation.
///
/// Extracted from `ProductFormViewController` so the routing is unit-testable (guard → log →
/// navigate) and consumable by a renderer that is not a `UIViewController`. The behavior here is a
/// faithful, behavior-preserving move of the previous inline logic.
final class ProductFormRowActionHandler {
    private let analytics: Analytics
    private let eventLogger: ProductFormEventLoggerProtocol
    private weak var navigator: ProductFormNavigating?

    init(analytics: Analytics,
         eventLogger: ProductFormEventLoggerProtocol,
         navigator: ProductFormNavigating?) {
        self.analytics = analytics
        self.eventLogger = eventLogger
        self.navigator = navigator
    }

    /// Handles selection of a row in the primary fields section.
    /// - Parameter shouldShowBlazeIntroView: current value of the view model's Blaze intro flag,
    ///   used to decide whether the Blaze entry-point-tapped event is tracked.
    func handlePrimaryFieldRowSelection(_ row: ProductFormSection.PrimaryFieldRow,
                                        shouldShowBlazeIntroView: Bool) {
        switch row {
        case .images(_, let isStorePublic, _, _):
            guard isStorePublic else {
                navigator?.openPrivacySettings()
                return
            }
        case .description(_, let isEditable, _):
            guard isEditable else {
                return
            }
            eventLogger.logDescriptionTapped()
            navigator?.editProductDescription()
        case .promoteWithBlaze:
            if !shouldShowBlazeIntroView {
                analytics.track(event: .Blaze.blazeEntryPointTapped(source: .productDetailPromoteButton))
            }
            navigator?.displayBlaze()
        default:
            break
        }
    }

    /// Handles selection of a row in the settings section.
    /// - Parameters:
    ///   - productID: current product ID, used for the add-ons tapped event.
    ///   - sourceView: the tapped cell, used to anchor the product type selector popover on iPad.
    func handleSettingsRowSelection(_ row: ProductFormSection.SettingsRow,
                                    productID: Int64,
                                    sourceView: UIView?) {
        switch row {
        case .price(_, let isEditable):
            guard isEditable else {
                return
            }
            eventLogger.logPriceSettingsTapped()
            navigator?.editPriceSettings()
        case .customFields:
            analytics.track(.productDetailCustomFieldsTapped)
            navigator?.showCustomFields()
        case .reviews:
            analytics.track(.productDetailViewReviewsTapped)
            navigator?.showReviews()
        case .downloadableFiles(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewDownloadableFilesTapped)
            navigator?.showDownloadableFiles()
        case .linkedProducts(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewLinkedProductsTapped)
            navigator?.editLinkedProducts()
        case .productType(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewProductTypeTapped)
            navigator?.editProductType(sourceView: sourceView)
        case .shipping(_, let isEditable):
            guard isEditable else {
                return
            }
            eventLogger.logShippingSettingsTapped()
            navigator?.editShippingSettings()
        case .inventory(_, let isEditable):
            guard isEditable else {
                return
            }
            eventLogger.logInventorySettingsTapped()
            navigator?.editInventorySettings()
        case .addOns(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(event: .ProductDetailAddOns.productAddOnsButtonTapped(productID: productID))
            navigator?.navigateToAddOns()
        case .categories(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewCategoriesTapped)
            navigator?.editCategories()
        case .tags(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewTagsTapped)
            navigator?.editTags()
        case .shortDescription(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewShortDescriptionTapped)
            navigator?.editShortDescription()
        case .externalURL(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewExternalProductLinkTapped)
            navigator?.editExternalLink()
        case .simplifiedInventory(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewSKUTapped)
            navigator?.editSimplifiedInventory()
        case .groupedProducts(_, let isEditable):
            guard isEditable else {
                return
            }
            analytics.track(.productDetailViewGroupedProductsTapped)
            navigator?.editGroupedProducts()
        case .variations(let viewModel):
            guard viewModel.isActionable else {
                return
            }
            analytics.track(.productDetailViewVariationsTapped)
            navigator?.showVariations()
        case .noPriceWarning(let viewModel):
            guard viewModel.isActionable else {
                return
            }
            analytics.track(.productDetailViewVariationsTapped)
            navigator?.showVariations()
        case .attributes(_, let isEditable):
            guard isEditable else {
                return
            }
            navigator?.editAttributes()
        case .status:
            break
        case .bundledProducts(_, let isActionable):
            guard isActionable else {
                return
            }
            analytics.track(event: .ProductDetail.bundledProductsTapped())
            navigator?.showBundledProducts()
        case .components(_, let isActionable):
            guard isActionable else {
                return
            }
            analytics.track(event: .ProductDetail.componentsTapped())
            navigator?.showCompositeComponents()
        case .subscriptionFreeTrial(_, let isEditable):
            guard isEditable else {
                return
            }
            eventLogger.logSubscriptionsFreeTrialTapped()
            navigator?.showSubscriptionFreeTrialSettings()
        case .subscriptionExpiry(_, let isEditable):
            guard isEditable else {
                return
            }
            eventLogger.logSubscriptionsExpirationDateTapped()
            navigator?.showSubscriptionExpirySettings()
        case .noVariationsWarning:
            return // This warning is not actionable.
        case .quantityRules:
            eventLogger.logQuantityRulesTapped()
            navigator?.showQuantityRules()
        }
    }

    /// Handles selection of an action in the "Add more details" bottom sheet.
    func handleMoreDetailsAction(_ action: ProductFormBottomSheetAction) {
        switch action {
        case .editInventorySettings:
            eventLogger.logInventorySettingsTapped()
            navigator?.editInventorySettings()
        case .editShippingSettings:
            eventLogger.logShippingSettingsTapped()
            navigator?.editShippingSettings()
        case .editCategories:
            analytics.track(.productDetailViewCategoriesTapped)
            navigator?.editCategories()
        case .editTags:
            analytics.track(.productDetailViewTagsTapped)
            navigator?.editTags()
        case .editShortDescription:
            analytics.track(.productDetailViewShortDescriptionTapped)
            navigator?.editShortDescription()
        case .editSimplifiedInventory:
            analytics.track(.productDetailViewSKUTapped)
            navigator?.editSimplifiedInventory()
        case .editLinkedProducts:
            analytics.track(.productDetailViewLinkedProductsTapped)
            navigator?.editLinkedProducts()
        case .editReviews:
            analytics.track(.productDetailViewReviewsTapped)
            navigator?.showReviews()
        case .editDownloadableFiles:
            analytics.track(.productDetailViewDownloadableFilesTapped)
            navigator?.showDownloadableFiles()
        case .editCustomFields:
            navigator?.showCustomFields()
        }
    }

    /// Handles the "Add image" CTA in the images cell.
    func handleAddImageTapped() {
        eventLogger.logImageTapped()
        navigator?.showProductImages()
    }
}
