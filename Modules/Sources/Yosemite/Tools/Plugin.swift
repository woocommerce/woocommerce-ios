import Foundation

public enum Plugin: Equatable, CaseIterable {
    case jetpack
    case googleListingsAndAds
    case stripe
    case wooCommerce
    case wooCompositeProducts
    case wooGiftCards
    case wooPayments
    case wooProductBundles
    case wooSubscriptions
    case wooShipmentTracking
    case wooSquare

    /// Creates a Plugin from a SystemPlugin by matching the plugin file name in the plugin path.
    /// Returns nil if the SystemPlugin doesn't match any known Plugin case.
    ///
    /// - Parameter systemPlugin: The SystemPlugin to convert.
    public init?(systemPlugin: SystemPlugin) {
        let pluginFileNameWithoutExtension = systemPlugin.fileNameWithoutExtension
        guard let plugin = Plugin.allCases.first(where: { $0.fileNameWithoutExtension == pluginFileNameWithoutExtension }) else {
            return nil
        }
        self = plugin
    }

    /// File name without extension in the plugin path.
    /// Full plugin path is like `woocommerce/woocommerce.php`.
    var fileNameWithoutExtension: String {
        switch self {
        case .jetpack:
            return "jetpack"
        case .googleListingsAndAds:
            return "google-listings-and-ads"
        case .stripe:
            return "woocommerce-gateway-stripe"
        case .wooCommerce:
            return "woocommerce"
        case .wooCompositeProducts:
            return "woocommerce-composite-products"
        case .wooGiftCards:
            return "woocommerce-gift-cards"
        case .wooPayments:
            return "woocommerce-payments"
        case .wooProductBundles:
            return "woocommerce-product-bundles"
        case .wooSubscriptions:
            return "woocommerce-subscriptions"
        case .wooShipmentTracking:
            return "woocommerce-shipment-tracking"
        case .wooSquare:
            return "woocommerce-square"
        }
    }
}

extension SystemPlugin {
    var fileNameWithoutExtension: String {
        ((plugin as NSString).lastPathComponent as NSString).deletingPathExtension
    }
}
