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

    /// Display the bar for displaying the filters in the Order List
    ///
    case orderListFilters

    /// Allows sites with plugins that include Jetpack Connection Package and without Jetpack-the-plugin to connect to the app
    ///
    case jetpackConnectionPackageSupport

    /// Allows new orders to be manually created
    ///
    case orderCreation

    /// Allows new orders to be created and synced as drafts
    ///
    case orderCreationRemoteSynchronizer

    /// Display the new tab "Menu" in the tab bar.
    ///
    case hubMenu

    /// Displays the System Status Report on Settings/Help screen
    ///
    case systemStatusReport

    /// Home Screen project milestone 2: design updates to the My Store tab
    ///
    case myStoreTabUpdates

    /// Displays the option to view coupons
    ///
    case couponView

    /// Barcode scanner for product SKU input
    ///
    case productSKUInputScanner

    /// Support for In-Person Payments in Canada
    ///
    case canadaInPersonPayments

    /// Displays the tax lines breakup in simple payments summary screen
    ///
    case taxLinesInSimplePayments

    /// Displays the Inbox option under the Hub Menu.
    ///
    case inbox
}
