/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
public enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

    /// Large titles on the main tabs
    ///
    case largeTitles

    /// Product Reviews
    ///
    case reviews

    /// Shipping labels - Milestones 2 & 3
    ///
    case shippingLabelsM2M3

    /// Shipping labels - International Shipping
    ///
    case shippingLabelsInternational

    /// Shipping labels - Add payment methods
    ///
    case shippingLabelsAddPaymentMethods

    /// Shipping labels - Add custom packages
    ///
    case shippingLabelsAddCustomPackages

    /// Shipping labels - Multi-package support
    ///
    case shippingLabelsMultiPackage

    /// Push notifications for all stores
    ///
    case pushNotificationsForAllStores

    /// Display the bar for displaying the filters in the Order List
    ///
    case orderListFilters

    /// Allows sites with plugins that include Jetpack Connection Package and without Jetpack-the-plugin to connect to the app
    ///
    case jetpackConnectionPackageSupport

    /// Allows new orders to be manually created
    ///
    case orderCreation

    /// Display the new tab "Menu" in the tab bar.
    ///
    case hubMenu

    /// Displays the System Status Report on Settings/Help screen
    ///
    case systemStatusReport

    /// Allows sites using the WooCommerce Stripe Payment Gateway extension to accept In-Person Payments
    ///
    case stripeExtensionInPersonPayments

    /// Home Screen project milestone 2: design updates to the My Store tab
    ///
    case myStoreTabUpdates

    /// Allow merchants to share a payment link when creating a simple payments order.
    ///
    case simplePaymentsLink

    /// Displays the option to manage coupons
    ///
    case couponManagement

    /// Barcode scanner for product SKU input
    ///
    case productSKUInputScanner
}
