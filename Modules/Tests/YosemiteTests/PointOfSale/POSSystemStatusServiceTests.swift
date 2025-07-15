import Foundation
import Testing
import TestKit
@testable import Networking
@testable import Yosemite

@MainActor
struct POSSystemStatusServiceTests {
    private let network = MockNetwork()
    private let sampleSiteID: Int64 = 134
    private let sut: POSSystemStatusService

    init() async throws {
        network.removeAllSimulatedResponses()
        sut = POSSystemStatusService(network: network)
    }

    // MARK: - loadWooCommercePluginAndPOSFeatureSwitch Tests

    @Test func loadWooCommercePluginAndPOSFeatureSwitch_returns_plugin_and_nil_feature_when_settings_response_does_not_include_enabled_featuers() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")

        // When
        let result = try await sut.loadWooCommercePluginAndPOSFeatureSwitch(siteID: sampleSiteID)

        // Then
        let plugin = try #require(result.wcPlugin)
        #expect(plugin.plugin == "woocommerce/woocommerce.php")
        #expect(plugin.name == "WooCommerce")
        #expect(plugin.version == "5.8.0")
        #expect(plugin.active == true)
        #expect(result.featureValue == nil)
    }

    @Test func loadWooCommercePluginAndPOSFeatureSwitch_returns_plugin_and_enabled_feature_when_feature_is_enabled() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "system-status-wc-plugin-and-pos-feature-enabled")

        // When
        let result = try await sut.loadWooCommercePluginAndPOSFeatureSwitch(siteID: sampleSiteID)

        // Then
        let plugin = try #require(result.wcPlugin)
        #expect(plugin.plugin == "woocommerce/woocommerce.php")
        #expect(plugin.name == "WooCommerce")
        #expect(plugin.version == "10.0.0-dev")
        #expect(plugin.active == true)
        #expect(result.featureValue == true)
    }

    @Test func loadWooCommercePluginAndPOSFeatureSwitch_returns_plugin_and_nil_feature_when_feature_is_disabled() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "system-status-wc-plugin-and-pos-feature-disabled")

        // When
        let result = try await sut.loadWooCommercePluginAndPOSFeatureSwitch(siteID: sampleSiteID)

        // Then
        let plugin = try #require(result.wcPlugin)
        #expect(plugin.plugin == "woocommerce/woocommerce.php")
        #expect(plugin.name == "WooCommerce")
        #expect(plugin.version == "10.0.0-dev")
        #expect(plugin.active == true)
        #expect(result.featureValue == nil)
    }

    @Test func loadWooCommercePluginAndPOSFeatureSwitch_returns_nil_plugin_and_nil_feature_when_woocommerce_plugin_not_found() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "system-status-wc-plugin-missing")

        // When
        let result = try await sut.loadWooCommercePluginAndPOSFeatureSwitch(siteID: sampleSiteID)

        // Then
        #expect(result.wcPlugin == nil)
        #expect(result.featureValue == nil)
    }

    @Test func loadWooCommercePluginAndPOSFeatureSwitch_throws_error_on_network_failure() async throws {
        // Given
        network.simulateError(requestUrlSuffix: "system_status", error: NetworkError.notFound())

        // When & Then
        await #expect(throws: NetworkError.self) {
            try await sut.loadWooCommercePluginAndPOSFeatureSwitch(siteID: sampleSiteID)
        }
    }
}
