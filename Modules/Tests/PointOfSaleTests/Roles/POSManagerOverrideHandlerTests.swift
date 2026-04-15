import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSManagerOverrideHandlerTests {

    // MARK: - requestPermission - Allowed

    @Test func test_requestPermission_when_allowed_then_calls_onApproved_immediately() {
        // Given
        let mock = makeMock()
        mock.currentOperator = makeManagerOperator()
        let handler = POSManagerOverrideHandler()

        // When
        var approved = false
        let wasImmediate = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { _ in
            approved = true
        }

        // Then
        #expect(wasImmediate == true)
        #expect(approved == true)
        #expect(handler.isShowingOverride == false)
    }

    @Test func test_requestPermission_when_allowed_then_passes_nil_token() {
        // Given
        let mock = makeMock()
        mock.currentOperator = makeManagerOperator()
        let handler = POSManagerOverrideHandler()

        // When
        var receivedToken: String? = "should-be-nil"
        handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { token in
            receivedToken = token
        }

        // Then
        #expect(receivedToken == nil)
    }

    // MARK: - requestPermission - Requires Override

    @Test func test_requestPermission_when_requiresOverride_then_shows_modal() {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        // When
        var approved = false
        let wasImmediate = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { _ in
            approved = true
        }

        // Then
        #expect(wasImmediate == false)
        #expect(approved == false)
        #expect(handler.isShowingOverride == true)
        #expect(handler.overrideState == .awaitingPIN)
    }

    @Test func test_requestPermission_when_requiresOverride_then_stores_action_description() {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        // When
        _ = handler.requestPermission(
            for: .refundShopOrders,
            actionDescription: "Issue a refund for Order #42",
            permissions: mock
        ) { _ in }

        // Then
        #expect(handler.actionDescription == "Issue a refund for Order #42")
        #expect(handler.activeCapability == "refund_shop_orders")
    }

    @Test func test_requestPermission_when_no_operator_then_shows_modal() {
        // Given
        let mock = makeMock()
        let handler = POSManagerOverrideHandler()

        // When
        let wasImmediate = handler.requestPermission(for: .viewPOSSettings, actionDescription: "Test", permissions: mock) { _ in }

        // Then
        #expect(wasImmediate == false)
        #expect(handler.isShowingOverride == true)
    }

    // MARK: - handlePINEntered - Success

    @Test func test_handlePINEntered_when_valid_then_sets_approved_and_calls_onApproved() async {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        mock.approvalTokenToReturn = "approval-token"
        let handler = POSManagerOverrideHandler()

        var receivedToken: String?
        _ = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { token in
            receivedToken = token
        }

        // When
        await handler.handlePINEntered("1234", permissions: mock)

        // Then
        #expect(receivedToken == "approval-token")
        #expect(handler.isShowingOverride == false)
        #expect(mock.requestedManagerPIN == "1234")
        #expect(mock.requestedCapability == "refund_shop_orders")
    }

    @Test func test_handlePINEntered_when_valid_then_passes_orderID_to_permissions() async {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        _ = handler.requestPermission(
            for: .refundShopOrders,
            actionDescription: "Test",
            permissions: mock,
            orderID: 42
        ) { _ in }

        // When
        await handler.handlePINEntered("1234", permissions: mock)

        // Then
        #expect(mock.requestedOrderID == 42)
    }

    // MARK: - handlePINEntered - Error

    @Test func test_handlePINEntered_when_invalid_then_sets_error_state() async {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        mock.approvalErrorToThrow = TestError.invalidPIN
        let handler = POSManagerOverrideHandler()

        var approved = false
        _ = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { _ in
            approved = true
        }

        // When
        await handler.handlePINEntered("wrong", permissions: mock)

        // Then
        #expect(approved == false)
        #expect(handler.isShowingOverride == true)
        if case .error = handler.overrideState {
            // Expected error state
        } else {
            Issue.record("Expected error state, got \(handler.overrideState)")
        }
    }

    // MARK: - cancel

    @Test func test_cancel_when_override_showing_then_hides_modal() {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        _ = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { _ in }
        #expect(handler.isShowingOverride == true)

        // When
        handler.cancel()

        // Then
        #expect(handler.isShowingOverride == false)
    }

    @Test func test_cancel_when_override_showing_then_clears_callback() async {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["refund_shop_orders"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        var approved = false
        _ = handler.requestPermission(for: .refundShopOrders, actionDescription: "Test", permissions: mock) { _ in
            approved = true
        }

        // When
        handler.cancel()
        await handler.handlePINEntered("1234", permissions: mock)

        // Then
        #expect(approved == false)
    }

    // MARK: - Multiple Capabilities

    @Test func test_requestPermission_when_different_capabilities_then_tracks_correct_capability() async {
        // Given
        let mock = makeMock()
        mock.capabilityOverrides["publish_shop_coupons"] = .requiresOverride
        let handler = POSManagerOverrideHandler()

        _ = handler.requestPermission(for: .publishCoupons, actionDescription: "Test", permissions: mock) { _ in }

        // When
        await handler.handlePINEntered("1234", permissions: mock)

        // Then
        #expect(mock.requestedCapability == "publish_shop_coupons")
    }

    // MARK: - Helpers

    private enum TestError: Error, LocalizedError {
        case invalidPIN

        var errorDescription: String? {
            "Invalid PIN"
        }
    }

    private func makeMock() -> MockPOSPermissionProvider {
        let mock = makeMock()
        mock.hasAnyPINs = true
        return mock
    }

    private func makeManagerOperator() -> POSOperator {
        POSOperator(
            userID: 42,
            displayName: "Store Owner",
            role: "pos_manager",
            capabilities: LocalPOSPermissionProvider.adminCapabilities,
            isAppAccountHolder: true
        )
    }
}
