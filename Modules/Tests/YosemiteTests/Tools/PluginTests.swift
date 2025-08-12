import Foundation
import Testing
import Networking

@testable import Yosemite

struct PluginTests {
    @Test(arguments: [
        ("blaze-ads/blaze-ads.php", Plugin.blaze),
        ("jetpack/jetpack.php", Plugin.jetpack),
        ("google-listings-and-ads/google-listings-and-ads.php", Plugin.googleListingsAndAds),
        ("woocommerce-gateway-stripe/woocommerce-gateway-stripe.php", Plugin.stripe),
        ("woocommerce/woocommerce.php", Plugin.wooCommerce),
        ("woocommerce-composite-products/woocommerce-composite-products.php", Plugin.wooCompositeProducts),
        ("woocommerce-gift-cards/woocommerce-gift-cards.php", Plugin.wooGiftCards),
        ("woocommerce-payments/woocommerce-payments.php", Plugin.wooPayments),
        ("woocommerce-paypal-payments/woocommerce-paypal-payments.php", Plugin.wooPayPal),
        ("woocommerce-product-bundles/woocommerce-product-bundles.php", Plugin.wooProductBundles),
        ("woocommerce-subscriptions/woocommerce-subscriptions.php", Plugin.wooSubscriptions),
        ("woocommerce-shipment-tracking/woocommerce-shipment-tracking.php", Plugin.wooShipmentTracking),
        ("woocommerce-square/woocommerce-square.php", Plugin.wooSquare),
        // Altered paths
        ("_woocommerce-subscriptions/woocommerce-subscriptions.php", .wooSubscriptions),
        ("woocommerce-subscriptions.php", .wooSubscriptions),
        ("test/woocommerce-dev.php", nil)
    ])
    func init_with_systemPlugin_returns_correct_plugin(pluginPath: String, expectedPlugin: Plugin?) {
        // Given
        let systemPlugin = SystemPlugin.fake().copy(
            siteID: 134,
            plugin: pluginPath,
            active: true
        )

        // When
        let plugin = Plugin(systemPlugin: systemPlugin)

        // Then
        #expect(plugin == expectedPlugin)
    }

    @Test func init_with_systemPlugin_returns_nil_for_unknown_plugin() {
        // Given
        let systemPlugin = SystemPlugin.fake().copy(
            siteID: 134,
            plugin: "unknown-plugin/unknown-plugin.php"
        )

        // When
        let plugin = Plugin(systemPlugin: systemPlugin)

        // Then
        #expect(plugin == nil)
    }

    @Test func init_with_systemPlugin_returns_nil_for_empty_plugin_path() {
        // Given
        let systemPlugin = SystemPlugin.fake().copy(
            plugin: ""
        )

        // When
        let plugin = Plugin(systemPlugin: systemPlugin)

        // Then
        #expect(plugin == nil)
    }

    // MARK: - `init(fileNameWithoutExtension:)`

    @Test(arguments: [
        ("blaze-ads", Plugin.blaze),
        ("jetpack", Plugin.jetpack),
        ("google-listings-and-ads", Plugin.googleListingsAndAds),
        ("woocommerce-gateway-stripe", Plugin.stripe),
        ("woocommerce", Plugin.wooCommerce),
        ("woocommerce-composite-products", Plugin.wooCompositeProducts),
        ("woocommerce-gift-cards", Plugin.wooGiftCards),
        ("woocommerce-payments", Plugin.wooPayments),
        ("woocommerce-paypal-payments", Plugin.wooPayPal),
        ("woocommerce-product-bundles", Plugin.wooProductBundles),
        ("woocommerce-subscriptions", Plugin.wooSubscriptions),
        ("woocommerce-shipment-tracking", Plugin.wooShipmentTracking),
        ("woocommerce-square", Plugin.wooSquare)
    ])
    func init_with_fileNameWithoutExtension_returns_correct_plugin(fileName: String, expectedPlugin: Plugin) {
        // When
        let plugin = Plugin(fileNameWithoutExtension: fileName)

        // Then
        #expect(plugin == expectedPlugin)
    }

    @Test func init_with_fileNameWithoutExtension_returns_nil_for_unknown_filename() {
        // When
        let plugin = Plugin(fileNameWithoutExtension: "wooooocommerce")

        // Then
        #expect(plugin == nil)
    }

    @Test func init_with_fileNameWithoutExtension_returns_nil_for_empty_filename() {
        // When
        let plugin = Plugin(fileNameWithoutExtension: "")

        // Then
        #expect(plugin == nil)
    }
}
