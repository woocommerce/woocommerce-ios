import UIKit
import Yosemite
import protocol WooFoundation.Analytics

enum ProductFormDestination {
    case privacySettings, productDescription, blaze
    case reloadLinkedProductsPromo, descriptionAI, productImages
    case aiLegalPage(URL)
    case productNameChanged(String), productStatusChanged(Bool)
    case imageUploadFailure(asset: ProductImageAssetType, error: Error)
    case price, customFields, reviews
    case downloadableFiles, linkedProducts
    case productType(sourceView: UIView?)
    case shipping, inventory, addOns
    case categories, tags, shortDescription
    case externalURL, simplifiedInventory, groupedProducts
    case variations, attributes
    case bundledProducts, components
    case subscriptionFreeTrial, subscriptionExpiry, quantityRules, addAttribute
}

@MainActor
protocol ProductFormNavigating: AnyObject { func navigate(to destination: ProductFormDestination) }

enum ProductFormInlineAction {
    case openLinkedProducts
    case reloadLinkedProductsPromo
    case descriptionAI
    case openAILegalPage(URL)
    case nameChanged(String)
    case statusChanged(Bool)
    case addImage
    case failedImageUpload(asset: ProductImageAssetType, error: Error)
}

@MainActor
final class ProductFormActionRoutingHandler {
    private weak var navigator: ProductFormNavigating?
    private let eventLogger: ProductFormEventLoggerProtocol
    private let analytics: Analytics

    init(navigator: ProductFormNavigating,
         eventLogger: ProductFormEventLoggerProtocol,
         analytics: Analytics = ServiceLocator.analytics) {
        self.navigator = navigator
        self.eventLogger = eventLogger
        self.analytics = analytics
    }

    func handle(_ row: ProductFormSection.PrimaryFieldRow, shouldShowBlazeIntroView: Bool) {
        switch row {
        case .images(_, let isStorePublic, _, _):
            guard !isStorePublic else { return }
            navigator?.navigate(to: .privacySettings)
        case .description(_, let isEditable, _):
            guard isEditable else { return }
            eventLogger.logDescriptionTapped()
            navigator?.navigate(to: .productDescription)
        case .promoteWithBlaze:
            if !shouldShowBlazeIntroView {
                analytics.track(event: .Blaze.blazeEntryPointTapped(source: .productDetailPromoteButton))
            }
            navigator?.navigate(to: .blaze)
        case .linkedProductsPromo, .name, .variationName, .descriptionAI, .learnMoreAboutAI, .separator:
            break
        }
    }

    func handle(_ action: ProductFormInlineAction) {
        switch action {
        case .openLinkedProducts: navigator?.navigate(to: .linkedProducts)
        case .reloadLinkedProductsPromo: navigator?.navigate(to: .reloadLinkedProductsPromo)
        case .descriptionAI: navigator?.navigate(to: .descriptionAI)
        case .openAILegalPage(let url): navigator?.navigate(to: .aiLegalPage(url))
        case .nameChanged(let name): navigator?.navigate(to: .productNameChanged(name))
        case .statusChanged(let isEnabled): navigator?.navigate(to: .productStatusChanged(isEnabled))
        case .addImage:
            eventLogger.logImageTapped()
            navigator?.navigate(to: .productImages)
        case .failedImageUpload(let asset, let error):
            navigator?.navigate(to: .imageUploadFailure(asset: asset, error: error))
        }
    }

    func handle(_ action: ProductFormBottomSheetAction, productID: Int64) {
        switch action {
        case .editInventorySettings:
            eventLogger.logInventorySettingsTapped()
            navigator?.navigate(to: .inventory)
        case .editShippingSettings:
            eventLogger.logShippingSettingsTapped()
            navigator?.navigate(to: .shipping)
        case .editCategories:
            analytics.track(.productDetailViewCategoriesTapped)
            navigator?.navigate(to: .categories)
        case .editTags:
            analytics.track(.productDetailViewTagsTapped)
            navigator?.navigate(to: .tags)
        case .editShortDescription:
            analytics.track(.productDetailViewShortDescriptionTapped)
            navigator?.navigate(to: .shortDescription)
        case .editSimplifiedInventory:
            analytics.track(.productDetailViewSKUTapped)
            navigator?.navigate(to: .simplifiedInventory)
        case .editLinkedProducts:
            analytics.track(.productDetailViewLinkedProductsTapped)
            navigator?.navigate(to: .linkedProducts)
        case .editReviews:
            analytics.track(.productDetailViewReviewsTapped)
            navigator?.navigate(to: .reviews)
        case .editDownloadableFiles:
            analytics.track(.productDetailViewDownloadableFilesTapped)
            navigator?.navigate(to: .downloadableFiles)
        case .editCustomFields:
            navigator?.navigate(to: .customFields)
        case .editAttributes:
            analytics.track(event: .Variations.addAttributeButtonTapped(productID: productID))
            navigator?.navigate(to: .addAttribute)
        }
    }
}
