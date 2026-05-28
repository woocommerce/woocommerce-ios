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

    /// Woo Shipping Plugin V1.
    ///
    case wooShipping = "wcshipping/v1"

    /// WooCommerce Bookings Plugin V1.
    ///
    case wcBookings = "wc-bookings/v2"

    /// Prefix shared by the WooCommerce POS catalog-sync routes. The real registered namespace
    /// is `wc/pos/v1/catalog`; this enum value is the leading path segment that callers combine
    /// with `catalog/...` paths.
    ///
    case wcPosV1 = "wc/pos/v1"

    /// Top-level namespace for the POS staff endpoint and other POS routes added alongside it.
    /// Distinct from `wcPosV1` - the server registers `wc-pos/v1` separately from the older
    /// `wc/pos/v1/catalog` namespace. Routes here are gated by the `point_of_sale_staff`
    /// server-side feature flag.
    ///
    case pointOfSaleV1 = "wc-pos/v1"

    /// Returns the path for the current API Version
    ///
    var path: String {
        guard self != .none else {
            return "/"
        }

        return "/" + rawValue + "/"
    }
}
