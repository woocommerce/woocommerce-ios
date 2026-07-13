import UIKit

/// Navigation performed in response to interactions with the Product form's content (rows,
/// inline cell actions, and the "Add more details" bottom sheet).
///
/// This is the seam that decouples *what the user interacted with* (routed by
/// `ProductFormRowActionHandler`) from *how the screen navigates* (implemented today by
/// `ProductFormViewController`). Only content-reachable navigation lives here; navigation-bar,
/// more-options action sheet, and save/publish/delete flows stay owned by the view controller.
protocol ProductFormNavigating: AnyObject {
    /// Opens the WP.com privacy settings, shown when the images row is tapped on a private store.
    func openPrivacySettings()

    func editProductDescription()

    func showProductDescriptionAI()

    /// Opens the legal page linked from the AI-generated content disclaimer.
    func openAILegalPage(url: URL)

    func displayBlaze()

    func showProductImages()

    func editPriceSettings()

    func showCustomFields()

    func showReviews()

    func showDownloadableFiles()

    func editLinkedProducts()

    /// Opens the product type selector. `sourceView` anchors the bottom sheet popover on iPad.
    func editProductType(sourceView: UIView?)

    func editShippingSettings()

    func editInventorySettings()

    func navigateToAddOns()

    func editCategories()

    func editTags()

    func editShortDescription()

    func editExternalLink()

    func editSimplifiedInventory()

    func editGroupedProducts()

    func showVariations()

    func editAttributes()

    func showBundledProducts()

    func showCompositeComponents()

    func showSubscriptionFreeTrialSettings()

    func showSubscriptionExpirySettings()

    func showQuantityRules()
}
