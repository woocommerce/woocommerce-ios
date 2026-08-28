/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
public enum FeatureFlag: Int, CaseIterable {

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

    /// Enable optimistic updates for orders
    ///
    case updateOrderOptimistically

    /// Enables searching products by partial SKU for WC version 6.6+.
    ///
    case searchProductsBySKU

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

    /// Enables the custom login UI when user enters an existing email address during account creation.
    ///
    case customLoginUIForAccountCreation

    /// Enables the Scan to Update Inventory feature.
    ///
    case scanToUpdateInventory

    /// Displays the Products tab in a split view
    ///
    case splitViewInProductsTab

    /// Enables the Point Of Sale when remote feature flag is disabled.
    ///
    case pointOfSale

    /// Enables Google ads campaign creation on web view
    ///
    case googleAdsCampaignCreationOnWebView

    /// Supports evergreen campaigns for Blaze
    ///
    case blazeEvergreenCampaigns

    /// Enables revamped shipping label flow for Woo Shipping extension
    ///
    case revampedShippingLabelCreation

    /// Enables selecting objectives during Blaze campaign creation.
    ///
    case blazeCampaignObjective

    /// Supports hiding sites from the store picker
    ///
    case hideSitesInStorePicker

    /// Supports managing filer history on order and product lists
    ///
    case filterHistoryOnOrderAndProductLists

    /// Supports uploading product images in background
    ///
    case backgroundProductImageUpload

    /// Enables optimized handling of product images
    ///
    case productImageOptimizedHandling

    /// Enables the CTA to search for an address in the map in order details > shipping address.
    ///
    case orderAddressMapSearch

    /// Enables FTS (Full-Text Search) for Point of Sale local catalog search.
    ///
    case pointOfSaleFTSSearch

    /// Legacy Bookings tab flag.
    ///
    case ciabBookings

    /// Enables using the catalog API endpoint for Point of Sale catalog full sync
    ///
    case pointOfSaleCatalogAPI

    /// Enables POS staff roles and permissions (PIN access, lock screen, capability-based gating)
    ///
    case pointOfSaleRoles

    /// Enables adding custom amounts to the cart in Point of Sale
    ///
    case pointOfSaleCustomAmounts

    /// Enables Point of Sale on iPhone (prototype).
    /// When enabled, the iPad-only gate in `POSTabVisibilityChecker` is lifted and POS layouts
    /// adapt to compact horizontal size class. Mirrors the Android `POS_ON_PHONES` flag.
    ///
    case pointOfSalePhonePrototype

    /// Enables Scan to Pay as a secondary payment method in Point of Sale.
    /// When enabled, the merchant can have the customer pay by scanning a QR code that
    /// opens the order's gateway-hosted payment page on their phone.
    ///
    case pointOfSaleScanToPay

    /// Enables "Mark order as paid" as a secondary payment method in Point of Sale.
    /// Used when the merchant has collected payment out-of-band (external reader, gift card,
    /// account credit, etc.) and just needs the order marked as completed.
    ///
    case pointOfSaleMarkOrderAsPaid

    /// Enables Tap to Pay as a payment method in Point of Sale on phone.
    /// When enabled and the device + site support TTP, the totals view promotes "Tap to Pay"
    /// as the primary payment method. Mirrors the Android `WOO_POS_TAP_TO_PAY` flag.
    ///
    case pointOfSaleTapToPay

    /// Enables self driven push token registration
    ///
    case selfDrivenPushToken

    /// Enables client-side promotional banners for non-Jetpack stores on the dashboard
    ///
    case clientSideDashboardBanner

    /// Enables age range verification features
    /// https://developer.apple.com/news/?id=2ezb6jhj
    ///
    case ageRangeRequirementsCompliance

    /// Legacy booking reschedule entry point flag.
    ///
    case ciabBookingReschedule

    /// Enables the feature flag override panel in the Help screen during the login flow
    ///
    case loggedOutFFPanel

    /// Enables the WooAI Assistant.
    ///
    case wooAIAssistant

    /// Enables AR parcel fitting for shipping
    ///
    case arParcelFitting

    /// Enables smarter (AI-powered) push notifications.
    ///
    case smarterNotifications

    /// Enables Star Micronics receipt printer support in Point of Sale.
    /// Gates the feature's runtime behavior (printer setup and printing from the
    /// order-complete screen) while it lands across stacked PRs. The StarIO10 SDK is
    /// linked unconditionally; this flag only controls whether the feature is reachable.
    /// Off by default until the stack is ready to enable for internal builds.
    ///
    case starReceiptPrinterSupport

    /// Enables server-calculated POS refunds: the `/wc/v3` refund preview and `compute_totals`
    /// create endpoints (WC 11.1.0+).
    ///
    case posServerCalculatedRefunds
}
