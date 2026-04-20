import Foundation
import Testing
@testable import PointOfSale

/// `RemotePOSPermissionProvider` reads the persisted `isLocked` flag from
/// `UserDefaults.standard` during init, and the `refreshPINStatus` tests
/// below write to it. `.serialized` prevents parallel tests from reading
/// another test's write and flaking.
@Suite(.serialized)
struct RemotePOSPermissionProviderTests {
    init() {
        // Ensure each test starts from a known persisted state.
        UserDefaults.standard.removeObject(forKey: POSLockStateKey.isLocked)
        UserDefaults.standard.removeObject(forKey: "com.woocommerce.pos.hasAnyPINs")
    }

    @Test func test_autoLockTimeoutSeconds_when_no_session_then_uses_default_timeout() {
        let sut = makeSUT()

        #expect(sut.autoLockTimeoutSeconds == Int(RemotePOSPermissionProvider.defaultAutoLockTimeout))
    }

    // MARK: - authenticateRemotePIN

    @Test func test_authenticateRemotePIN_sets_operator_and_capabilities() async throws {
        // Given
        let response = makePINAuthResponse(
            capabilities: [
                "view_pos": true,
                "refund_shop_orders": true,
                "publish_shop_coupons": false
            ]
        )
        let sut = makeSUT(pinAuthResponse: response)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.userID == 100)
        #expect(op.displayName == "Test Cashier")
        #expect(op.role == "pos_cashier")
        #expect(op.capabilities == Set(["view_pos", "refund_shop_orders"]))
        #expect(sut.currentOperator == op)
        #expect(sut.isLocked == false)
    }

    @Test func test_authenticateRemotePIN_filters_out_disabled_capabilities() async throws {
        // Given
        let response = makePINAuthResponse(
            capabilities: [
                "view_pos": true,
                "refund_shop_orders": false,
                "publish_shop_coupons": false,
                "view_pos_settings": true
            ]
        )
        let sut = makeSUT(pinAuthResponse: response)

        // When
        let op = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // Then
        #expect(op.capabilities == Set(["view_pos", "view_pos_settings"]))
        #expect(op.capabilities.contains("refund_shop_orders") == false)
        #expect(op.capabilities.contains("publish_shop_coupons") == false)
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
            fetchStaffStatusRemote: { [] },
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
        let response = makePINAuthResponse(capabilities: ["view_pos": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When
        let result = sut.checkPermission("view_pos")

        // Then
        #expect(result == .allowed)
    }

    @Test func test_checkPermission_when_operator_lacks_capability_then_returns_requiresOverride() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["view_pos": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When
        let result = sut.checkPermission("refund_shop_orders")

        // Then
        #expect(result == .requiresOverride)
    }

    @Test func test_checkPermission_when_no_operator_then_returns_requiresOverride() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.checkPermission("view_pos")

        // Then
        #expect(result == .requiresOverride)
    }

    // MARK: - hasCapability

    @Test func test_hasCapability_when_operator_has_it_then_returns_true() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["view_pos": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When / Then
        #expect(sut.hasCapability("view_pos") == true)
    }

    @Test func test_hasCapability_when_operator_lacks_it_then_returns_false() async throws {
        // Given
        let response = makePINAuthResponse(capabilities: ["view_pos": true])
        let sut = makeSUT(pinAuthResponse: response)
        _ = try await sut.authenticateRemotePIN("1234", registerID: "register-1")

        // When / Then
        #expect(sut.hasCapability("refund_shop_orders") == false)
    }

    @Test func test_hasCapability_when_no_operator_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.hasCapability("view_pos") == false)
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
            for: "refund_shop_orders",
            orderID: 99
        )

        // Then
        #expect(token == "approval-token-xyz")
        #expect(approvalService.spyCapturedPIN == "1234")
        #expect(approvalService.spyCapturedAction == "refund_shop_orders")
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
            for: "refund_shop_orders",
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
                for: "refund_shop_orders",
                orderID: nil
            )
        }
    }

    @Test func test_requestManagerApproval_when_not_backend_approvable_then_uses_verify_endpoint() async throws {
        // Given - posReadSettings has supportsBackendApproval = false
        let verifyResponse = makeVerifyResponse(capabilities: [
            "view_pos_settings": true
        ])
        let sut = makeSUT(verifyResponse: verifyResponse)

        // When
        let token = try await sut.requestManagerApproval(
            managerPIN: "1234",
            for: "view_pos_settings",
            orderID: nil
        )

        // Then - no approval token for verify-only path
        #expect(token == nil)
    }

    @Test func test_requestManagerApproval_when_not_backend_approvable_and_lacks_capability_then_throws() async {
        // Given - verify returns capabilities that don't include the required one
        let verifyResponse = makeVerifyResponse(capabilities: [
            "view_pos": true
        ])
        let sut = makeSUT(verifyResponse: verifyResponse)

        // When / Then
        await #expect(throws: Error.self) {
            try await sut.requestManagerApproval(
                managerPIN: "1234",
                for: "edit_pos_settings",
                orderID: nil
            )
        }
    }

    // MARK: - refreshPINStatus

    @Test func test_refreshPINStatus_when_no_staff_have_pin_then_clears_hasAnyPINs() async {
        // Given - backend returns staff but none has a PIN (admin removed all PINs)
        let sut = makeSUT(staffStatus: [
            makeStaffStatus(userID: 1, hasPIN: false),
            makeStaffStatus(userID: 2, hasPIN: false)
        ])
        #expect(sut.hasAnyPINs == true) // default

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(sut.hasAnyPINs == false)
    }

    @Test func test_refreshPINStatus_when_empty_staff_then_clears_hasAnyPINs() async {
        // Given - backend returns no staff at all (admin deleted all POS users)
        let sut = makeSUT(staffStatus: [])

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(sut.hasAnyPINs == false)
    }

    @Test func test_refreshPINStatus_when_some_staff_have_pin_then_hasAnyPINs_stays_true() async {
        // Given
        let sut = makeSUT(staffStatus: [
            makeStaffStatus(userID: 1, hasPIN: false),
            makeStaffStatus(userID: 2, hasPIN: true)
        ])

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(sut.hasAnyPINs == true)
    }

    @Test func test_refreshPINStatus_when_no_pins_and_previously_locked_then_clears_isLocked() async {
        // Given - a POS session was locked before the admin removed all PINs
        UserDefaults.standard.set(true, forKey: POSLockStateKey.isLocked)
        defer { UserDefaults.standard.removeObject(forKey: POSLockStateKey.isLocked) }
        let sut = makeSUT(staffStatus: [makeStaffStatus(hasPIN: false)])
        #expect(sut.isLocked == true)

        // When
        await sut.refreshPINStatus()

        // Then - lock is cleared so the lock screen doesn't trap the user at an unreachable PIN prompt
        #expect(sut.isLocked == false)
        #expect(UserDefaults.standard.bool(forKey: POSLockStateKey.isLocked) == false)
    }

    @Test func test_refreshPINStatus_when_some_pins_exist_then_preserves_isLocked() async {
        // Given
        UserDefaults.standard.set(true, forKey: POSLockStateKey.isLocked)
        defer { UserDefaults.standard.removeObject(forKey: POSLockStateKey.isLocked) }
        let sut = makeSUT(staffStatus: [makeStaffStatus(hasPIN: true)])

        // When
        await sut.refreshPINStatus()

        // Then - lock stays because someone can still unlock via PIN
        #expect(sut.isLocked == true)
    }

    @Test func test_refreshPINStatus_when_fetch_fails_then_preserves_default_hasAnyPINs() async {
        // Given
        let sut = makeSUT(staffStatusError: TestError.authFailed)

        // When
        await sut.refreshPINStatus()

        // Then - default `true` is kept so the lock screen stays up on network failure
        #expect(sut.hasAnyPINs == true)
    }

    // MARK: - Helpers

    private enum TestError: Error, Equatable {
        case authFailed
        case approvalFailed
    }

    private func makeStaffStatus(userID: Int64 = 1,
                                 displayName: String = "Staff",
                                 role: String = "pos_cashier",
                                 hasPIN: Bool = false) -> POSStaffMemberStatus {
        POSStaffMemberStatus(userID: userID, displayName: displayName, role: role, hasPIN: hasPIN)
    }

    private func makeSUT(pinAuthResponse: POSPINAuthResponse? = nil,
                         pinAuthError: Error? = nil,
                         verifyResponse: POSPINVerifyResponse? = nil,
                         verifyError: Error? = nil,
                         staffStatus: [POSStaffMemberStatus] = [],
                         staffStatusError: Error? = nil,
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
            fetchStaffStatusRemote: {
                if let error = staffStatusError {
                    throw error
                }
                return staffStatus
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
            fetchStaffStatusRemote: { [] },
            appAccountUserID: 1
        )
    }

    private func makePINAuthResponse(
        userID: Int64 = 100,
        userLogin: String = "test_cashier",
        displayName: String = "Test Cashier",
        role: String = "pos_cashier",
        capabilities: [String: Bool] = ["view_pos": true],
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
            "view_pos_settings": true,
            "edit_pos_settings": true
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
            capabilities: Set(["view_pos"]),
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
