import Testing
@testable import PointOfSale

struct RemotePOSPermissionProviderTests {
    @Test func test_autoLockTimeoutSeconds_when_no_session_then_uses_default_timeout() {
        let sut = makeSUT()

        #expect(sut.autoLockTimeoutSeconds == Int(RemotePOSPermissionProvider.defaultAutoLockTimeout))
    }

    // MARK: - authenticateRemotePIN

    @Test func test_authenticateRemotePIN_sets_operator_and_capabilities() async throws {
        // Given
        let response = makePINAuthResponse(
            capabilities: [
                "woocommerce_pos_access": true,
                "woocommerce_refund_orders": true,
                "woocommerce_void_orders": false
            ]
        )
        let sut = makeSUT(pinAuthResponse: response)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.userID == 100)
        #expect(op.displayName == "Test Cashier")
        #expect(op.role == "pos_cashier")
        #expect(op.capabilities == Set(["woocommerce_pos_access", "woocommerce_refund_orders"]))
        #expect(sut.currentOperator == op)
        #expect(sut.isLocked == false)
    }

    @Test func test_authenticateRemotePIN_filters_out_disabled_capabilities() async throws {
        // Given
        let response = makePINAuthResponse(
            capabilities: [
                "woocommerce_pos_access": true,
                "woocommerce_refund_orders": false,
                "woocommerce_void_orders": false,
                "woocommerce_apply_discounts": true
            ]
        )
        let sut = makeSUT(pinAuthResponse: response)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.capabilities == Set(["woocommerce_pos_access", "woocommerce_apply_discounts"]))
        #expect(op.capabilities.contains("woocommerce_refund_orders") == false)
        #expect(op.capabilities.contains("woocommerce_void_orders") == false)
    }

    @Test func test_authenticateRemotePIN_when_userID_matches_app_account_then_isAppAccountHolder_is_true() async throws {
        // Given
        let appAccountUserID: Int64 = 42
        let response = makePINAuthResponse(userID: appAccountUserID)
        let sut = makeSUT(pinAuthResponse: response, appAccountUserID: appAccountUserID)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.isAppAccountHolder == true)
    }

    @Test func test_authenticateRemotePIN_when_userID_differs_from_app_account_then_isAppAccountHolder_is_false() async throws {
        // Given
        let appAccountUserID: Int64 = 42
        let response = makePINAuthResponse(userID: 999)
        let sut = makeSUT(pinAuthResponse: response, appAccountUserID: appAccountUserID)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.isAppAccountHolder == false)
    }

    @Test func test_authenticateRemotePIN_stores_session_credential() async throws {
        // Given
        let response = makePINAuthResponse(
            applicationPassword: "app-pass-123",
            applicationPasswordUUID: "uuid-456",
            sessionExpires: "2026-04-10T00:00:00Z",
            idleTimeoutSeconds: 300
        )
        let sut = makeSUT(pinAuthResponse: response)

        // When
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        let credential = sut.sessionCredential
        #expect(credential != nil)
        #expect(credential?.applicationPassword == "app-pass-123")
        #expect(credential?.uuid == "uuid-456")
        #expect(credential?.sessionExpires == "2026-04-10T00:00:00Z")
        #expect(credential?.idleTimeoutSeconds == 300)
    }

    @Test func test_authenticateRemotePIN_updates_autoLockTimeoutSeconds_from_backend_response() async throws {
        let response = makePINAuthResponse(idleTimeoutSeconds: 1800)
        let sut = makeSUT(pinAuthResponse: response)

        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        #expect(sut.autoLockTimeoutSeconds == 1800)
    }

    @Test func test_authenticateRemotePIN_when_locked_and_valid_pin_then_unlocks() async throws {
        // Given
        let response = makePINAuthResponse()
        let sut = makeSUT(pinAuthResponse: response)
        sut.lock()
        #expect(sut.isLocked == true)
        #expect(sut.currentOperator == nil)

        // When
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(sut.isLocked == false)
        #expect(sut.currentOperator != nil)
    }

    @Test func test_authenticateRemotePIN_when_closure_throws_then_propagates_error() async {
        // Given
        let sut = makeSUT(pinAuthError: TestError.authFailed)

        // When / Then
        await #expect(throws: TestError.authFailed) {
            try await sut.authenticateRemotePIN("1234", registerID: "register-1")
        }
        #expect(sut.currentOperator == nil)
        #expect(sut.sessionCredential == nil)
    }

    @Test func test_authenticateRemotePIN_passes_pin_and_registerID_to_closure() async throws {
        // Given
        var capturedPIN: String?
        var capturedRegisterID: String?
        let response = makePINAuthResponse()
        let sut = RemotePOSPermissionProvider(
            approvalService: MockApprovalService(),
            authenticatePINRemote: { pin, registerID in
                capturedPIN = pin
                capturedRegisterID = registerID
                return response
            },
            verifyPINRemote: { _ in self.makeVerifyResponse() },
            appAccountUserID: 1
        )

        // When
        _ = try await sut.authenticateRemotePIN("9876", registerID: "register-42")

        // Then
        #expect(capturedPIN == "9876")
        #expect(capturedRegisterID == "register-42")
    }

    // MARK: - checkPermission

    @Test func test_checkPermission_when_operator_has_capability_then_returns_allowed() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["woocommerce_pos_access": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When
        let result = sut.checkPermission("woocommerce_pos_access")

        // Then
        #expect(result == .allowed)
    }

    @Test func test_checkPermission_when_operator_lacks_capability_then_returns_requiresOverride() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["woocommerce_pos_access": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When
        let result = sut.checkPermission("woocommerce_refund_orders")

        // Then
        #expect(result == .requiresOverride)
    }

    @Test func test_checkPermission_when_no_operator_then_returns_requiresOverride() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.checkPermission("woocommerce_pos_access")

        // Then
        #expect(result == .requiresOverride)
    }

    // MARK: - hasCapability

    @Test func test_hasCapability_when_operator_has_it_then_returns_true() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["woocommerce_pos_access": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When / Then
        #expect(sut.hasCapability("woocommerce_pos_access") == true)
    }

    @Test func test_hasCapability_when_operator_lacks_it_then_returns_false() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["woocommerce_pos_access": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When / Then
        #expect(sut.hasCapability("woocommerce_refund_orders") == false)
    }

    @Test func test_hasCapability_when_no_operator_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.hasCapability("woocommerce_pos_access") == false)
    }

    // MARK: - signIn

    @Test func test_signIn_sets_currentOperator_and_clears_isLocked() {
        // Given
        let sut = makeSUT()
        sut.lock()
        let op = makeOperator()

        // When
        sut.signIn(op)

        // Then
        #expect(sut.currentOperator == op)
        #expect(sut.isLocked == false)
    }

    // MARK: - lock

    @Test func test_lock_clears_operator_and_sets_isLocked() {
        // Given
        let sut = makeSUT()
        sut.signIn(makeOperator())

        // When
        sut.lock()

        // Then
        #expect(sut.currentOperator == nil)
        #expect(sut.isLocked == true)
    }

    @Test func test_lock_clears_session_credential() async throws {
        // Given
        let response = makePINAuthResponse()
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")
        #expect(sut.sessionCredential != nil)

        // When
        sut.lock()

        // Then
        #expect(sut.sessionCredential == nil)
    }

    @Test func test_lock_calls_onLock_callback() {
        // Given
        let sut = makeSUT()
        sut.signIn(makeOperator())
        var onLockCalled = false
        sut.onLock = { onLockCalled = true }

        // When
        sut.lock()

        // Then
        #expect(onLockCalled == true)
    }

    @Test func test_authenticateRemotePIN_calls_onAuthenticated_with_response() async throws {
        // Given
        let response = makePINAuthResponse(userLogin: "cashier_jane")
        let sut = makeSUT(pinAuthResponse: response)
        var capturedResponse: POSPINAuthResponse?
        sut.onAuthenticated = { capturedResponse = $0 }

        // When
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(capturedResponse?.userLogin == "cashier_jane")
    }

    // MARK: - requestApproval

    @Test func test_requestManagerApproval_when_backend_approvable_then_uses_approval_service() async throws {
        // Given
        let approvalService = MockApprovalService()
        approvalService.tokenToReturn = "approval-token-xyz"
        let sut = makeSUT(approvalService: approvalService)

        // When - refundOrders has supportsBackendApproval = true
        let token = try await sut.requestManagerApproval(
            managerPIN: "1234",
            for: "woocommerce_refund_orders",
            orderID: 99
        )

        // Then
        #expect(token == "approval-token-xyz")
        #expect(approvalService.spyCapturedPIN == "1234")
        #expect(approvalService.spyCapturedAction == "woocommerce_refund_orders")
        #expect(approvalService.spyCapturedContext == ["order_id": 99])
    }

    @Test func test_requestManagerApproval_when_backend_approvable_without_orderID_then_passes_empty_context() async throws {
        // Given
        let approvalService = MockApprovalService()
        approvalService.tokenToReturn = "token"
        let sut = makeSUT(approvalService: approvalService)

        // When
        _ = try await sut.requestManagerApproval(
            managerPIN: "1234",
            for: "woocommerce_refund_orders",
            orderID: nil
        )

        // Then
        #expect(approvalService.spyCapturedContext == [:])
    }

    @Test func test_requestManagerApproval_when_backend_approvable_and_service_throws_then_propagates_error() async {
        // Given
        let approvalService = MockApprovalService()
        approvalService.errorToThrow = TestError.approvalFailed
        let sut = makeSUT(approvalService: approvalService)

        // When / Then
        await #expect(throws: TestError.approvalFailed) {
            try await sut.requestManagerApproval(
                managerPIN: "1234",
                for: "woocommerce_refund_orders",
                orderID: nil
            )
        }
    }

    @Test func test_requestManagerApproval_when_not_backend_approvable_then_uses_verify_endpoint() async throws {
        // Given - posReadSettings has supportsBackendApproval = false
        let verifyResponse = makeVerifyResponse(capabilities: [
            "woocommerce_pos_read_settings": true
        ])
        let sut = makeSUT(verifyResponse: verifyResponse)

        // When
        let token = try await sut.requestManagerApproval(
            managerPIN: "1234",
            for: "woocommerce_pos_read_settings",
            orderID: nil
        )

        // Then - no approval token for verify-only path
        #expect(token == nil)
    }

    @Test func test_requestManagerApproval_when_not_backend_approvable_and_lacks_capability_then_throws() async {
        // Given - verify returns capabilities that don't include the required one
        let verifyResponse = makeVerifyResponse(capabilities: [
            "woocommerce_pos_access": true
        ])
        let sut = makeSUT(verifyResponse: verifyResponse)

        // When / Then
        await #expect(throws: Error.self) {
            try await sut.requestManagerApproval(
                managerPIN: "1234",
                for: "woocommerce_pos_write_settings",
                orderID: nil
            )
        }
    }

    // MARK: - Helpers

    private enum TestError: Error, Equatable {
        case authFailed
        case approvalFailed
    }

    private func makeSUT(pinAuthResponse: POSPINAuthResponse? = nil,
                         pinAuthError: Error? = nil,
                         verifyResponse: POSPINVerifyResponse? = nil,
                         verifyError: Error? = nil,
                         approvalService: MockApprovalService = MockApprovalService(),
                         appAccountUserID: Int64 = 1) -> RemotePOSPermissionProvider {
        let response = pinAuthResponse ?? makePINAuthResponse()
        let defaultVerify = verifyResponse ?? makeVerifyResponse()
        return RemotePOSPermissionProvider(
            approvalService: approvalService,
            authenticatePINRemote: { _, _ in
                if let error = pinAuthError {
                    throw error
                }
                return response
            },
            verifyPINRemote: { _ in
                if let error = verifyError {
                    throw error
                }
                return defaultVerify
            },
            appAccountUserID: appAccountUserID
        )
    }

    private func makeSUT(approvalService: MockApprovalService) -> RemotePOSPermissionProvider {
        RemotePOSPermissionProvider(
            approvalService: approvalService,
            authenticatePINRemote: { _, _ in
                self.makePINAuthResponse()
            },
            verifyPINRemote: { _ in
                self.makeVerifyResponse()
            },
            appAccountUserID: 1
        )
    }

    private func makePINAuthResponse(
        userID: Int64 = 100,
        userLogin: String = "test_cashier",
        displayName: String = "Test Cashier",
        role: String = "pos_cashier",
        capabilities: [String: Bool] = ["woocommerce_pos_access": true],
        applicationPassword: String = "app-pass",
        applicationPasswordUUID: String = "uuid-123",
        sessionExpires: String = "2026-04-10T00:00:00Z",
        idleTimeoutSeconds: Int = 600
    ) -> POSPINAuthResponse {
        POSPINAuthResponse(
            userID: userID,
            userLogin: userLogin,
            displayName: displayName,
            role: role,
            capabilities: capabilities,
            applicationPassword: applicationPassword,
            applicationPasswordUUID: applicationPasswordUUID,
            sessionExpires: sessionExpires,
            idleTimeoutSeconds: idleTimeoutSeconds
        )
    }

    private func makeVerifyResponse(
        userID: Int64 = 100,
        displayName: String = "Store Manager",
        role: String = "shop_manager",
        capabilities: [String: Bool] = [
            "woocommerce_pos_read_settings": true,
            "woocommerce_pos_write_settings": true
        ]
    ) -> POSPINVerifyResponse {
        POSPINVerifyResponse(
            userID: userID,
            displayName: displayName,
            role: role,
            capabilities: capabilities
        )
    }

    private func makeOperator() -> POSOperator {
        POSOperator(
            userID: 100,
            displayName: "Test Cashier",
            role: "pos_cashier",
            capabilities: Set(["woocommerce_pos_access"]),
            isAppAccountHolder: false
        )
    }
}

// MARK: - MockApprovalService

final class MockApprovalService: POSApprovalServiceProtocol, @unchecked Sendable {
    var tokenToReturn: String = ""
    var errorToThrow: Error?

    var spyCapturedPIN: String?
    var spyCapturedAction: String?
    var spyCapturedContext: [String: Int64]?

    func requestApproval(pin: String, action: String, context: [String: Int64]) async throws -> String {
        spyCapturedPIN = pin
        spyCapturedAction = action
        spyCapturedContext = context
        if let error = errorToThrow {
            throw error
        }
        return tokenToReturn
    }
}
