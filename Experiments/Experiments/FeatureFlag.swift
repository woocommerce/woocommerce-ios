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

    /// Displays the Inbox option under the Hub Menu and the Dynamic Dashboard
    ///
    case inbox

    /// Displays the call to actions in the Inbox Notes under the Hub Menu and the Dynamic Dashboard
    ///
    case showInboxCTA

    /// Displays the OrderForm side by side with the Product Selector
    ///
    case sideBySideViewForOrderForm

    /// Enable optimistic updates for orders
    ///
    case updateOrderOptimistically

    /// Enable Shipping Labels Onboarding M1 (display the banner in Order Detail screen for installing the WCShip plugin)
    ///
    case shippingLabelsOnboardingM1

    /// Enables searching products by partial SKU for WC version 6.6+.
    ///
    case searchProductsBySKU

    /// Makes the Experimental Feature toggle for the Debug In-app purchases menu visible.
    /// This should not be turned on in production builds. This doesn't make any difference to the availabliity of plan purchases via IAP.
    ///
    case inAppPurchasesDebugMenu

    /// Enables Tap to Pay on iPhone flow in In-Person Payments, on eligible devices.
    /// This flag needs to be retained, as we cannot enable TTPoI on the Enterprise certificate,
    /// so `.alpha` builds must be excluded.
    ///
    case tapToPayOnIPhone

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

    /// Enables the ability to add products to orders by SKU scanning
    ///
    case addProductToOrderViaSKUScanner

    /// Enables manual error handling for site credential login.
    ///
    case manualErrorHandlingForSiteCredentialLogin

    /// Enables EU Bound notifications inside the Shipping Labels feature
    ///
    case euShippingNotification

    /// Enables the improvements in the customer selection logic when creating an order
    ///
    case betterCustomerSelectionInOrder

    /// Enables the hazmat shipping selection during the Shipping Labels package details
    ///
    case hazmatShipping

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

    /// Enables the custom login UI when user enters an existing email address during account creation.
    ///
    case customLoginUIForAccountCreation

    /// Enables the Scan to Update Inventory feature.
    ///
    case scanToUpdateInventory

    /// Enables backend receipt generation for all payment methods
    ///
    case backendReceipts

    /// Displays the Products tab in a split view
    ///
    case splitViewInProductsTab

    /// Enables visibility of Subscription product details when creating an order, within product selection, and order details.
    ///
    case subscriptionsInOrderCreationUI

    /// Enables a new customer creation flow in order creation for subscriptions support.
    ///
    case subscriptionsInOrderCreationCustomers

    /// Makes the Experimental Feature toggle "Point Of Sale" menu visible, under app settings.
    ///
    case displayPointOfSaleToggle

    /// Enables M1 updates of product creation AI version 2
    ///
    case productCreationAIv2M1

    /// Enables M3 updates of product creation AI version 2
    ///
    case productCreationAIv2M3

    /// Enables Google ads campaign creation on web view
    ///
    case googleAdsCampaignCreationOnWebView

    /// Code hidden while the background tasks feature is developed
    ///
    case backgroundTasks

    /// Enables view/editing of custom fields (metadata) in both Products and Orders
    ///
    case viewEditCustomFieldsInProductsAndOrders

    /// Supports evergreen campaigns for Blaze
    ///
    case blazeEvergreenCampaigns

    /// Enables revamped shipping label flow for Woo Shipping extension
    ///
    case revampedShippingLabelCreation
}
