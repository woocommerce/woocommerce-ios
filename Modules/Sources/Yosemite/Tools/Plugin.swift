import Foundation

public enum Plugin: Equatable, CaseIterable {
    case stripe
    case wooCommerce
    case wooPayments
    case wooSubscriptions
    case wooShipmentTracking
    case wooSquare

    /// File name without extension in the plugin path.
    /// Full plugin path is like `woocommerce/woocommerce.php`.
    var fileNameWithoutExtension: String {
        switch self {
        case .stripe:
            return "woocommerce-gateway-stripe"
        case .wooCommerce:
            return "woocommerce"
        case .wooPayments:
            return "woocommerce-payments"
        case .wooSubscriptions:
            return "woocommerce-subscriptions"
        case .wooShipmentTracking:
            return "woocommerce-shipment-tracking"
        case .wooSquare:
            return "woocommerce-square"
        }
    }
}
