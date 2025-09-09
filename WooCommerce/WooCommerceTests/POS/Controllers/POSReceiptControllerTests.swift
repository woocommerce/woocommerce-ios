import Testing
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.SystemPlugin
import protocol WooFoundation.Analytics
import enum Networking.DotcomError

struct POSReceiptControllerTests {
    let mockOrderService = MockPOSOrderService()
    let mockReceiptService = MockReceiptService()
    let mockAnalyticsProvider = MockAnalyticsProvider()
    let mockFeatureFlagService = MockFeatureFlagService()
    let mockPluginsService = MockPluginsService()
    let sut: POSReceiptController

    init() {
        self.sut = POSReceiptController(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockAnalytics(),
                                       featureFlagService: mockFeatureFlagService,
                                       pluginsService: mockPluginsService)
    }

    @Test func sendReceipt_calls_both_updateOrder_and_sendReceipt() async throws {
        // Given
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
        let order = Order.fake()
        let recipientEmail = "test@fake.com"

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)

        // Then
        #expect(mockOrderService.updateOrderWasCalled)
        #expect(mockReceiptService.sendReceiptWasCalled == true)
    }

    @Test func sendReceipt_tracks_success_with_eligible_for_pos_receipt() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0-dev",
                                                                                active: true))
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
        let order = Order.fake()

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

        // Then
        #expect(mockReceiptService.sendReceiptWasCalled == true)
    }

    @Test func sendReceipt_tracks_failure_with_eligible_for_pos_receipt() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0-dev",
                                                                                active: true))
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
        mockReceiptService.sendReceiptResult = .failure(DotcomError.unknown(code: "test_error", message: "Test error"))
        let order = Order.fake()

        // When
        do {
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Then - error was thrown as expected
            #expect(mockOrderService.updateOrderWasCalled)
        }
    }

    @MainActor
    struct PluginEligibilityTests {
        private let mockOrderService = MockPOSOrderService()

        @Test("Eligible core plugin versions with feature flag enabled", arguments: Constants.eligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_eligible_plugin_version_sets_isEligibleForPOSReceipt_true(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptController(siteID: 123,
                                           orderService: mockOrderService,
                                           receiptService: mockReceiptService,
                                           analytics: MockAnalytics(),
                                           featureFlagService: mockFeatureFlagService,
                                           pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == true)
        }

        @Test(
            "All core plugin versions with feature flag disabled",
            arguments: Constants.eligibleWCPluginVersions + Constants.ineligibleWCPluginVersions
        )
        func sendReceipt_when_feature_flag_disabled_and_eligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = false
            // Plugin setup is irrelevant when feature flag is disabled
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptController(siteID: 123,
                                           orderService: mockOrderService,
                                           receiptService: mockReceiptService,
                                           analytics: MockAnalytics(),
                                           featureFlagService: mockFeatureFlagService,
                                           pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        @Test("Ineligible core plugin versions with feature flag enabled", arguments: Constants.ineligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_ineligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptController(siteID: 123,
                                           orderService: mockOrderService,
                                           receiptService: mockReceiptService,
                                           analytics: MockAnalytics(),
                                           featureFlagService: mockFeatureFlagService,
                                           pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        @Test("Unavailable core plugin with feature flag enabled",
              arguments: [
                SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", active: false),
                nil
              ])
        func sendReceipt_when_feature_flag_enabled_and_plugin_unavailable_sets_isEligibleForPOSReceipt_false(plugin: SystemPlugin?) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)
            let sut = POSReceiptController(siteID: 123,
                                           orderService: mockOrderService,
                                           receiptService: mockReceiptService,
                                           analytics: MockAnalytics(),
                                           featureFlagService: mockFeatureFlagService,
                                           pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        private enum Constants {
            static let eligibleWCPluginVersions = ["10.0.0", "10.0.0-dev", "10.0.0-beta", "10.0.1", "10.1"]
            static let ineligibleWCPluginVersions = ["9.9.0", "9.9.9", "9.9.9-beta.9", "9.9.9-dev"]
        }
    }
}
