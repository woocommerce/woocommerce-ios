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

    /// Enables In-app purchases for buying Hosted WooCommerce plans
    ///
    case inAppPurchases

    /// Store creation MVP.
    ///
    case storeCreationMVP

    /// Store creation milestone 2. https://wp.me/pe5sF9-I3
    ///
    case storeCreationM2

    /// Whether in-app purchases are enabled for store creation milestone 2 behind `storeCreationM2` feature flag.
    /// If disabled, mock in-app purchases are provided by `MockInAppPurchases`.
    ///
    case storeCreationM2WithInAppPurchasesEnabled

    /// Just In Time Messages on Dashboard
    ///
    case justInTimeMessagesOnDashboard

    /// Adds the System Status Report to support requests
    ///
    case systemStatusReportInSupportRequest

    // MARK: - Performance Monitoring
    //
    // These flags are not transient. That is, they are not here to help us rollout a feature,
    // but to serve a safety switches to granularly turn off performance monitoring if it looks
    // like we are consuming too many events.

    /// Whether to enable performance monitoring.
    ///
    case performanceMonitoring

    /// Whether to enable performance monitoring for Core Data operations.
    ///
    /// - Note: The app will ignore this if `performanceMonitoring` is `false`
    case performanceMonitoringCoreData

    /// Whether to enable performance monitoring for file IO operations.
    ///
    /// - Note: The app will ignore this if `performanceMonitoring` is `false`
    case performanceMonitoringFileIO

    /// Whether to enable performance monitoring for networking operations.
    ///
    /// - Note: The app will ignore this if `performanceMonitoring` is `false`
    case performanceMonitoringNetworking

    /// Whether to enable performance monitoring for user interaction events.
    ///
    /// - Note: The app will ignore this if `performanceMonitoring` is `false`
    case performanceMonitoringUserInteraction

    /// Whether to enable performance monitoring for `UIViewController` life-cycle events.
    ///
    /// - Note: The app will ignore this if `performanceMonitoring` is `false`.
    case performanceMonitoringViewController

    /// Temporary feature flag for the native Jetpack setup flow.
    /// TODO-8075: replace this with A/B test.
    ///
    case nativeJetpackSetupFlow

    /// Temporary feature flag for the native Jetpack setup flow.
    ///
    case analyticsHub
}
