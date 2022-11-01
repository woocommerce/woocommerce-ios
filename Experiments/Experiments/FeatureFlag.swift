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

    /// Barcode scanner for product SKU input
    ///
    case productSKUInputScanner

    /// Displays the Inbox option under the Hub Menu.
    ///
    case inbox

    /// Displays the Orders tab in a split view
    ///
    case splitViewInOrdersTab

    /// Enable optimistic updates for orders
    ///
    case updateOrderOptimistically

    /// Enable Shipping Labels Onboarding M1 (display the banner in Order Detail screen for installing the WCShip plugin)
    ///
    case shippingLabelsOnboardingM1

    /// Enable IPP reader manuals consolidation screen
    ///
    case consolidatedCardReaderManuals

    /// Showing a "New to WooCommerce" link in the login prologue screen
    ///
    case newToWooCommerceLinkInLoginPrologue

    /// Onboarding experiment on the login prologue screen
    ///
    case loginPrologueOnboarding

    /// Local notifications scheduled 24 hours after certain login errors
    ///
    case loginErrorNotifications

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

    /// Enables searching products by partial SKU for WC version 6.6+.
    ///
    case searchProductsBySKU

    /// Enables the Search Customers functionality in the Order Creation screen
    ///
    case orderCreationSearchCustomers

    /// Enables signing up for a WP.com account.
    ///
    case wpcomSignup

    /// Enables In-app purchases for buying Hosted WooCommerce plans
    ///
    case inAppPurchases

    /// Store creation MVP.
    ///
    case storeCreationMVP

    /// Just In Time Messages on Dashboard
    ///
    case justInTimeMessagesOnDashboard

    /// Hides products onboarding development.
    ///
    case productsOnboarding
}
