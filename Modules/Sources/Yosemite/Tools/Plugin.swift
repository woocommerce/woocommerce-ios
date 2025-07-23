import Foundation

public enum Plugin: Equatable, CaseIterable {
    case wooCommerce
    case wooSubscriptions
    case wooShipmentTracking
    case wooSquare

    /// File name without extension in the plugin path.
    /// Full plugin path is like `woocommerce/woocommerce.php`.
    var fileNameWithoutExtension: String {
        switch self {
        case .wooCommerce:
            return "woocommerce"
        case .wooSubscriptions:
            return "woocommerce-subscriptions"
        case .wooShipmentTracking:
            return "woocommerce-shipment-tracking"
        case .wooSquare:
            return "woocommerce-square"
        }
    }
}
