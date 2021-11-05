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

    /// Allows to create quick order orders
    ///
    case quickOrderPrototype

    /// Display the bar for displaying the filters in the Order List
    ///
    case orderListFilters

    /// Allows to filter products by a product category, persisting it so the filter can remain after restarting the app
    ///
    case filterProductsByCategory

    /// Allows sites with plugins that include Jetpack Connection Package and without Jetpack-the-plugin to connect to the app
    ///
    case jetpackConnectionPackageSupport
}
