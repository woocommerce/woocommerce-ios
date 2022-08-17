/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
public enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

    /// Product Reviews
    ///
    case reviews

    /// Display the bar for displaying the filters in the Order List
    ///
    case orderListFilters

    /// Allows sites with plugins that include Jetpack Connection Package and without Jetpack-the-plugin to connect to the app
    ///
    case jetpackConnectionPackageSupport

    /// Display the new tab "Menu" in the tab bar.
    ///
    case hubMenu

    /// Displays the System Status Report on Settings/Help screen
    ///
    case systemStatusReport

    /// Displays the option to view coupons
    ///
    case couponView

    /// Barcode scanner for product SKU input
    ///
    case productSKUInputScanner

    /// Displays the Inbox option under the Hub Menu.
    ///
    case inbox

    /// Displays the bulk update option in product variations
    ///
    case bulkEditProductVariations

    /// Displays the Orders tab in a split view
    ///
    case splitViewInOrdersTab

    /// Displays the option to delete coupons
    ///
    case couponDeletion

    /// Displays the option to edit a coupon
    ///
    case couponEditing

    /// Displays the option to create a coupon
    ///
    case couponCreation

    /// Enable optimistic updates for orders
    ///
    case updateOrderOptimistically

    /// Enable Shipping Labels Onboarding M1 (display the banner in Order Detail screen for installing the WCShip plugin)
    ///
    case shippingLabelsOnboardingM1

    /// Enable selection of payment gateway to use for In-Person Payments when there is more than one available
    ///
    case inPersonPaymentGatewaySelection

    /// Enable order editing from the order detailed screen.
    ///
    case unifiedOrderEditing

    /// Enable image upload after leaving the product form
    ///
    case backgroundProductImageUpload

    /// Enable IPP reader manuals consolidation screen
    ///
    case consolidatedCardReaderManuals

    /// Apple ID account deletion
    ///
    case appleIDAccountDeletion

    /// Showing a "New to WooCommerce" link in the login prologue screen
    ///
    case newToWooCommerceLinkInLoginPrologue

    /// Onboarding experiment on the login prologue screen
    ///
    case loginPrologueOnboarding

    /// Local notifications scheduled 24 hours after certain login errors
    ///
    case loginErrorNotifications

    /// Payments Section in the Hub Menu
    ///
    case paymentsHubMenuSection

    /// Whether to show a survey at the end of the login onboarding screen after feature carousel
    ///
    case loginPrologueOnboardingSurvey

    /// Whether to prefer magic link to password in the login flow
    ///
    case loginMagicLinkEmphasis

    /// Whether to show the magic link as a secondary button instead of a table view cell on the password screen
    ///
    case loginMagicLinkEmphasisM2
    
    /// Whether to include the Cash on Delivery enable step in In-Person Payment onboarding
    ///
    case promptToEnableCodInIppOnboarding
}
