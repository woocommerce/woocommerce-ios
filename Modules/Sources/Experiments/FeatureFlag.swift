/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
public enum FeatureFlag: Int, CaseIterable {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Enable optimistic updates for orders
    ///
    case updateOrderOptimistically

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


    /// Enables the custom login UI when user enters an existing email address during account creation.
    ///
    case customLoginUIForAccountCreation

    /// Enables the Point Of Sale when remote feature flag is disabled.
    ///
    case pointOfSale

    /// Supports uploading product images in background
    ///
    case backgroundProductImageUpload

    /// Enables optimized handling of product images
    ///
    case productImageOptimizedHandling

    /// Enables the CTA to search for an address in the map in order details > shipping address.
    ///
    case orderAddressMapSearch

    /// Legacy Bookings tab flag.
    ///
    case ciabBookings

    /// Enables POS staff roles and permissions (PIN access, lock screen, capability-based gating)
    ///
    case pointOfSaleRoles

    /// Enables adding custom amounts to the cart in Point of Sale
    ///
    case pointOfSaleCustomAmounts

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
}
