import Yosemite

/// Defines the names of the Site Plugins officially supported by the app.
///
extension SitePlugin {
    enum SupportedPlugin {
        public static let LegacyWCShip = "WooCommerce Shipping &amp; Tax"
        public static let WooShipping = ["Woo Shipping", "WooCommerce Shipping"]
        public static let WCTracking = "WooCommerce Shipment Tracking"
        public static let WCSubscriptions = ["WooCommerce Subscriptions", "Woo Subscriptions"]
        public static let WCProductBundles = ["WooCommerce Product Bundles", "Woo Product Bundles"]
        public static let WCCompositeProducts = "WooCommerce Composite Products"
        public static let square = "WooCommerce Square"
        public static let WCGiftCards = ["WooCommerce Gift Cards", "Woo Gift Cards"]
        public static let GoogleForWooCommerce = ["Google Listings and Ads", "Google for WooCommerce"]
    }
}
