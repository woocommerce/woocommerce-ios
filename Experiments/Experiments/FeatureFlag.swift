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

    /// Enables Tap to Pay on iPhone flow in In-Person Payments, on eligible devices.
    /// This flag needs to be retained, as we cannot enable TTPoI on the Enterprise certificate,
    /// so `.alpha` builds must be excluded.
    ///
    case tapToPayOnIPhone

    /// Enables Tap to Pay on iPhone Milestone 2 (Tap to Pay deeplinks, JITM deeplink handling, JITM customisation) on eligible devices.
    ///
    case tapToPayOnIPhoneMilestone2

    /// Store creation MVP.
    ///
    case storeCreationMVP

    /// Store creation milestone 2. https://wp.me/pe5sF9-I3
    ///
    case storeCreationM2

    /// Whether in-app purchases are enabled for store creation milestone 2 behind `storeCreationM2` feature flag.
    /// If disabled, purchases are backed by `WebPurchasesForWPComPlans` for checkout in a webview.
    ///
    case storeCreationM2WithInAppPurchasesEnabled

    /// Store creation milestone 3 - profiler questions
    ///
    case storeCreationM3Profiler

    /// Just In Time Messages on Dashboard
    ///
    case justInTimeMessagesOnDashboard

    /// IPP in-app feedback banner
    ///
    case IPPInAppFeedbackBanner

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

    /// Whether to enable domain updates from the settings for a WPCOM site.
    ///
    case domainSettings

    /// Whether to enable the new support request form.
    ///
    case supportRequests

    /// Whether to enable Jetpack setup for users authenticated with application passwords.
    ///
    case jetpackSetupWithApplicationPassword

    /// Whether to enable the onboarding checklist in the dashboard for WPCOM stores.
    ///
    case dashboardOnboarding

    ///Ability to add coupon to order
    ///
    case addCouponToOrder

    /// Whether to enable product bundle settings in product details
    ///
    case productBundles

    /// Enables conditional behaviour when a site has a free trial plan.
    ///
    case freeTrial

    /// Enables manual error handling for site credential login.
    ///
    case manualErrorHandlingForSiteCredentialLogin

    /// Enables composite product settings in product details
    ///
    case compositeProducts

    /// Enables UK-based stores taking In-Person Payments
    ///
    case IPPUKExpansion

    /// Enables read-only support for the Subscriptions extension in product and order details
    ///
    case readOnlySubscriptions

    /// Enables generating product description using AI.
    ///
    case productDescriptionAI

    /// Enables read-only support for the Gift Cards extension
    ///
    case readOnlyGiftCards

    /// Ability to hide store onboarding task list
    ///
    case hideStoreOnboardingTaskList

    /// Enables read-only support for the Min/Max Quantities extension
    ///
    case readOnlyMinMaxQuantities

    /// Enables updates of the Privacy Choices project.
    ///
    case privacyChoices
}
