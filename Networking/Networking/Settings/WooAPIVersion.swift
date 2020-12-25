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

    /// WooCommerce Analytics from the WooCommerce Admin plugin.
    /// Only works for WC Admin v0.22 and up.
    ///
    case wcAnalytics = "wc-analytics"

    /// WooCommerce Connect Server API v1 from WooCommerce Shipping plugin.
    ///
    case wcConnectV1 = "wc/v1/connect"

    /// Returns the path for the current API Version
    ///
    var path: String {
        guard self != .none else {
            return "/"
        }

        return "/" + rawValue + "/"
    }
}
