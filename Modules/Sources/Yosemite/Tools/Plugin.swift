import Foundation

public enum Plugin: Equatable, CaseIterable {
    case wooCommerce
    case wooSubscriptions
    
    /// File name without extension in the plugin path.
    /// Full plugin path is like `woocommerce/woocommerce.php`.
    var fileNameWithoutExtension: String {
        switch self {
        case .wooCommerce:
            return "woocommerce"
        case .wooSubscriptions:
            return "woocommerce-subscriptions"
        }
    }
}
