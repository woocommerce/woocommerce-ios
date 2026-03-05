import Testing
import Foundation

@testable import PointOfSale
import struct Yosemite.Order
import struct Yosemite.SystemPlugin
import protocol WooFoundation.Analytics
import enum Networking.DotcomError

struct POSReceiptSenderTests {
    private let mockOrderService = MockPOSOrderService()
    private let mockReceiptService = MockReceiptService()
    private let mockFeatureFlagService = MockFeatureFlagService()
    private let mockPluginsService = MockPluginsService()
    private let sut: POSReceiptSender

    init() {
        self.sut = POSReceiptSender(siteID: 123,
                                    orderService: mockOrderService,
                                    receiptService: mockReceiptService,
                                    analytics: MockPOSAnalytics(),
                                    pluginsService: mockPluginsService)
    }

    @Test func sendReceipt_tracks_success_with_eligible_for_pos_receipt() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0-dev",
                                                                                active: true))
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
        mockReceiptService.sendReceiptResult = .failure(DotcomError.unknown(code: "test_error", message: "Test error", data: nil))
        let order = Order.fake()

        // When
        do {
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Then - error was thrown as expected
            #expect(!mockOrderService.updateOrderWasCalled) // Should not update order for POS receipts even on failure
        }
    }

    @MainActor
    struct PluginEligibilityTests {
        private let mockOrderService = MockPOSOrderService()

        @Test("Eligible core plugin versions with feature flag enabled", arguments: Constants.eligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_eligible_plugin_version_sets_isEligibleForPOSReceipt_true(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptSender(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockPOSAnalytics(),
                                       pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == true)
        }

        @Test("Ineligible core plugin versions with feature flag enabled", arguments: Constants.ineligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_ineligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptSender(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockPOSAnalytics(),
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
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)
            let sut = POSReceiptSender(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockPOSAnalytics(),
                                       pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        @Test("Auto-template versions omit templateID", arguments: Constants.autoTemplateVersions)
        func sendReceipt_when_auto_template_version_then_templateID_is_nil(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptSender(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockPOSAnalytics(),
                                       pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyTemplateID == nil)
        }

        @Test("Non-auto-template versions include templateID", arguments: Constants.nonAutoTemplateVersions)
        func sendReceipt_when_non_auto_template_version_then_templateID_is_set(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))
            let sut = POSReceiptSender(siteID: 123,
                                       orderService: mockOrderService,
                                       receiptService: mockReceiptService,
                                       analytics: MockPOSAnalytics(),
                                       pluginsService: mockPluginsService)
            let order = Order.fake()

            // When
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyTemplateID == "customer_pos_completed_order")
        }

        private enum Constants {
            static let eligibleWCPluginVersions = ["10.0.0", "10.0.0-dev", "10.0.0-beta", "10.0.1", "10.1"]
            static let ineligibleWCPluginVersions = ["9.9.0", "9.9.9", "9.9.9-beta.9", "9.9.9-dev"]
            static let autoTemplateVersions = ["10.7.0", "10.7.0-dev", "10.7.1", "11.0.0"]
            static let nonAutoTemplateVersions = ["10.0.0", "10.6.0", "10.6.9"]
        }
    }

    @Test func sendReceipt_calls_sendReceipt_but_not_updateOrder_for_POS_receipts() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0",
                                                                                active: true))
        let order = Order.fake()
        let recipientEmail = "test@fake.com"

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)

        // Then
        #expect(!mockOrderService.updateOrderWasCalled) // Should not update order for POS receipts
        #expect(mockReceiptService.sendReceiptWasCalled == true)
    }

    @Test func sendReceipt_calls_both_updateOrder_and_sendReceipt_for_legacy_POS_receipts() async throws {
        // Given - feature flag disabled or plugin not eligible
        let order = Order.fake()
        let recipientEmail = "test@fake.com"

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)

        // Then
        #expect(mockOrderService.updateOrderWasCalled) // Should update order for traditional receipts
        #expect(mockReceiptService.sendReceiptWasCalled == true)
    }
}
