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

    /// Enables bundle product configuration support in order creation/editing.
    ///
    case productBundlesInOrderForm

    /// Enables the custom login UI when user enters an existing email address during account creation.
    ///
    case customLoginUIForAccountCreation

    /// Enables the Scan to Update Inventory feature.
    ///
    case scanToUpdateInventory

    /// Displays the Products tab in a split view
    ///
    case splitViewInProductsTab

    /// Enables visibility of Subscription product details when creating an order, within product selection, and order details.
    ///
    case subscriptionsInOrderCreationUI

    /// Enables a new customer creation flow in order creation for subscriptions support.
    ///
    case subscriptionsInOrderCreationCustomers

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

    /// Shows inventory levels and inventory status in POS item cards
    ///
    case inventoryProductLabelsInPOS

    /// Enables displaying Point Of Sale details in order list and order details
    ///
    case pointOfSaleOrdersi1

    /// Enables displaying Point Of Sale as a filter in order list
    ///
    case pointOfSaleOrdersi2

    /// Enables the CTA to search for an address in the map in order details > shipping address.
    ///
    case orderAddressMapSearch

    /// Enables the entry point for Point of Sale Orders
    ///
    case pointOfSaleHistoricalOrdersi1

    /// Enables Local Catalog i1 in Point of Sale.
    /// It syncs products and variations to local storage and display them in POS for quick access.
    ///
    case pointOfSaleLocalCatalogi1

    /// Enables FTS (Full-Text Search) for Point of Sale local catalog search.
    /// Only has effect when pointOfSaleLocalCatalogi1 is also enabled.
    ///
    case pointOfSaleFTSSearch

    /// Enables a new Bookings tab for CIAB sites
    ///
    case ciabBookings

    /// Enables using the catalog API endpoint for Point of Sale catalog full sync
    ///
    case pointOfSaleCatalogAPI

    /// Enables the refunds functionality within POS
    ///
    case pointOfSaleRefundsi1

    /// Enables the bookings functionality within POS
    ///
    case pointOfSaleBookings

    /// Enables self driven push token registration for users authenticated with WPCom
    ///
    case selfDrivenPushTokenWPCom

    /// Enables self driven push token registration for users authenticated with app passwords
    ///
    case selfDrivenPushTokenAppPasswords

    /// Enables POS-only products filtering
    ///
    case pointOfSaleOnlyProducts

    /// Enables client-side promotional banners for non-Jetpack stores on the dashboard
    ///
    case clientSideDashboardBanner

    /// Enables age range verification features
    /// https://developer.apple.com/news/?id=2ezb6jhj
    ///
    case ageRangeRequirementsCompliance
}
