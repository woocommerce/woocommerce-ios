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

    /// Enables the ability to add products to orders by SKU scanning
    ///
    case addProductToOrderViaSKUScanner

    /// Whether to enable product bundle settings in product details
    ///
    case productBundles

    /// Enables manual error handling for site credential login.
    ///
    case manualErrorHandlingForSiteCredentialLogin

    /// Enables composite product settings in product details
    ///
    case compositeProducts

    /// Enables read-only support for the Subscriptions extension in product and order details
    ///
    case readOnlySubscriptions

    /// Enables generating product description using AI from product description editor.
    ///
    case productDescriptionAI

    /// Enables generating product description using AI from store onboarding.
    ///
    case productDescriptionAIFromStoreOnboarding

    /// Enables read-only support for the Gift Cards extension
    ///
    case readOnlyGiftCards

    /// Ability to hide store onboarding task list
    ///
    case hideStoreOnboardingTaskList

    /// Enables read-only support for the Min/Max Quantities extension
    ///
    case readOnlyMinMaxQuantities

    /// Local notifications for store creation
    ///
    case storeCreationNotifications

    /// Enables EU Bound notifications inside the Shipping Labels feature
    ///
    case euShippingNotification

    /// Do not use the Google SDK when authenticating through a Google account.
    ///
    case sdkLessGoogleSignIn

    /// Enables generating share product content using AI
    ///
    case shareProductAI

    /// Enables the Milestone 4 of the Orders with Coupons project: Adding discounts to products
    case ordersWithCouponsM4

    /// Enables the Milestone 6 of the Orders with Coupons project: UX improvements
    ///
    case ordersWithCouponsM6

    /// Enables the improvements in the customer selection logic when creating an order
    /// 
    case betterCustomerSelectionInOrder

    /// Enables the improvements related to taxes in the order flows (Milestone 2)
    ///
    case manualTaxesInOrderM2

    /// Enables storing the selected tax rate locally and applying to future orders (Manual Taxes Milestone 3)
    ///
    case manualTaxesInOrderM3

    /// Enables the hazmat shipping selection during the Shipping Labels package details
    ///
    case hazmatShipping

    /// Enables the reuse of Payment Intents when retrying a failed payment
    /// 
    case reusePaymentIntentOnRetryInPersonPayment

    /// Enables a required refresh of the order before each IPP payment (or retry)
    ///
    case refreshOrderBeforeInPersonPayment

    /// Enables product creation with AI.
    ///
    case productCreationAI

    /// Enables gift card support in order creation/editing
    ///
    case giftCardInOrderForm

    /// Enables the Woo Payments Deposits item in the Payments menu
    ///
    case wooPaymentsDepositsOverviewInPaymentsMenu

    /// Enables Tap to Pay for UK Woo Payments stores
    /// 
    case tapToPayOnIPhoneInUK

    /// Enables bundle product configuration support in order creation/editing.
    ///
    case productBundlesInOrderForm
}
