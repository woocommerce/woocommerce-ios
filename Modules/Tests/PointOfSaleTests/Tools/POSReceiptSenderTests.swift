import Testing
import Foundation

@testable import PointOfSale
import struct Yosemite.Order
import struct Yosemite.SystemPlugin
import protocol WooFoundation.Analytics
import enum Networking.DotcomError

@MainActor
struct POSReceiptSenderTests {
    private let mockOrderService = MockPOSOrderService()
    private let mockReceiptService = MockReceiptService()
    private let analytics = MockPOSAnalytics()
    private let mockPluginsService = MockPluginsService()
    private let sut: POSReceiptSender

    init() {
        self.sut = POSReceiptSender(siteID: 123,
                                    orderService: mockOrderService,
                                    receiptService: mockReceiptService,
                                    analytics: analytics,
                                    pluginsService: mockPluginsService)
    }

    @Test func test_sendReceipt_when_eligible_then_tracks_success() async throws {
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
        #expect(analytics.events.map(\.eventName) == ["receipt_email_success"])
        #expect(analytics.events.first?.properties["eligible_for_pos_receipt"] as? Bool == true)
    }

    @Test func test_sendReceipt_when_eligible_request_fails_then_tracks_and_rethrows_error() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0-dev",
                                                                                active: true))
        let expectedError = DotcomError.unknown(code: "test_error", message: "Test error", data: nil)
        mockReceiptService.sendReceiptResult = .failure(expectedError)
        let order = Order.fake()

        // When
        do {
            try await sut.sendReceipt(orderID: order.orderID, recipientEmail: "test@example.com")
            Issue.record("Expected the receipt request error")
        } catch {
            // Then
            #expect(error as? DotcomError == expectedError)
            #expect(analytics.events.map(\.eventName) == ["receipt_email_failed"])
            #expect(analytics.events.first?.properties["eligible_for_pos_receipt"] as? Bool == true)
            #expect(analytics.events.first?.error as? DotcomError == expectedError)
            #expect(!mockOrderService.updateOrderWasCalled) // Should not update order for POS receipts even on failure
        }
    }

    @MainActor
    struct PluginEligibilityTests {
        private let mockOrderService = MockPOSOrderService()

        @Test("Eligible core plugin versions with active plugin", arguments: Constants.eligibleWCPluginVersions)
        func sendReceipt_when_eligible_plugin_version_sets_isEligibleForPOSReceipt_true(wcPluginVersion: String) async throws {
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

        @Test("Ineligible core plugin versions with active plugin", arguments: Constants.ineligibleWCPluginVersions)
        func sendReceipt_when_ineligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
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

        @Test("Unavailable core plugin with active plugin",
              arguments: [
                SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", active: false),
                nil
              ])
        func sendReceipt_when_plugin_unavailable_sets_isEligibleForPOSReceipt_false(plugin: SystemPlugin?) async throws {
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
        func test_sendReceipt_when_auto_template_version_then_templateID_is_nil(wcPluginVersion: String) async throws {
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
        func test_sendReceipt_when_non_auto_template_version_then_templateID_is_set(wcPluginVersion: String) async throws {
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
            static let nonAutoTemplateVersions = ["10.0.0", "10.6.0", "10.6.9", "10.6.99"]
        }
    }

    @Test func test_sendReceipt_when_pos_receipts_supported_then_sends_to_requested_order_and_recipient() async throws {
        // Given
        mockPluginsService.setMockPlugin(.wooCommerce,
                                         systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                version: "10.0.0",
                                                                                active: true))
        let order = Order.fake().copy(orderID: 42)
        let recipientEmail = "test@fake.com"

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)

        // Then
        #expect(!mockOrderService.updateOrderWasCalled) // Should not update order for POS receipts
        #expect(mockReceiptService.sendReceiptWasCalled == true)
        #expect(mockReceiptService.spyOrderID == 42)
        #expect(mockReceiptService.spyRecipientEmail == "test@fake.com")
    }

    @Test func test_sendReceipt_when_legacy_receipts_required_then_updates_order_and_sends_to_requested_recipient() async throws {
        // Given - plugin is unavailable
        let order = Order.fake().copy(orderID: 42)
        let recipientEmail = "test@fake.com"

        // When
        try await sut.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)

        // Then
        #expect(mockOrderService.updateOrderWasCalled) // Should update order for traditional receipts
        #expect(mockReceiptService.sendReceiptWasCalled == true)
        #expect(mockReceiptService.spyOrderID == 42)
        #expect(mockReceiptService.spyRecipientEmail == "test@fake.com")
    }
}
