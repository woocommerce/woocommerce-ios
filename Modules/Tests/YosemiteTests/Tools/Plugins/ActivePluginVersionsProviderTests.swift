import Testing
@testable import Yosemite

struct ActivePluginVersionsProviderTests {
    @Test func activePluginVersions_returns_woocommerce_version_when_active_woocommerce_plugin_has_non_empty_version() {
        // Given
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "10.9.2", active: true)

        // When
        let versions = WooCommerceActivePluginVersionsProvider.activePluginVersions(from: [plugin])

        // Then
        #expect(versions == ["woocommerce/woocommerce.php": "10.9.2"])
    }

    @Test func activePluginVersions_returns_empty_when_woocommerce_plugin_is_inactive() {
        // Given
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "10.9.2", active: false)

        // When
        let versions = WooCommerceActivePluginVersionsProvider.activePluginVersions(from: [plugin])

        // Then
        #expect(versions == [:])
    }

    @Test func activePluginVersions_returns_empty_when_woocommerce_plugin_is_missing() {
        // Given
        let plugin = SystemPlugin.fake().copy(plugin: "jetpack/jetpack.php", version: "14.0", active: true)

        // When
        let versions = WooCommerceActivePluginVersionsProvider.activePluginVersions(from: [plugin])

        // Then
        #expect(versions == [:])
    }

    @Test func activePluginVersions_returns_empty_when_woocommerce_plugin_version_is_blank() {
        // Given
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "", active: true)

        // When
        let versions = WooCommerceActivePluginVersionsProvider.activePluginVersions(from: [plugin])

        // Then
        #expect(versions == [:])
    }
}
