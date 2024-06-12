import Foundation


/// Defines the supported Woo API Versions.
///
public enum WooAPIVersion: String {

    /// No version
    ///
    case none = ""

    /// Woo Endpoint Mark 1
    ///
    case mark1 = "wc/v1"

    /// Woo Endpoint Mark 2
    ///
    case mark2 = "wc/v2"

    /// Woo Endpoint Mark 3
    ///
    case mark3 = "wc/v3"

    /// Woo Endpoint Mark 4
    ///
    case mark4 = "wc/v4"

    /// WooCommerce Analytics.
    ///
    case wcAnalytics = "wc-analytics"

    /// WooCommerce Connect Server API v1 from WooCommerce Shipping plugin.
    ///
    case wcConnectV1 = "wc/v1/connect"

    /// WooCommerce Product Add-ons plugin.
    ///
    case addOnsV1 = "wc-product-add-ons/v1"

    /// WooCommerce Telemetry.
    /// Only works on WC 5.9.0 and up.
    ///
    case wcTelemetry = "wc-telemetry"

    /// WooCommerce Admin.
    ///
    case wcAdmin = "wc-admin"

    /// Returns the path for the current API Version
    ///
    var path: String {
        guard self != .none else {
            return "/"
        }

        return "/" + rawValue + "/"
    }
}
