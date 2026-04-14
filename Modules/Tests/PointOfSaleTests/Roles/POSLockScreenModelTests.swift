import Testing
import Combine
@testable import PointOfSale

@MainActor
struct POSLockScreenModelTests {

    // MARK: - isShowingLockScreen

    @Test func test_isShowingLockScreen_when_locked_and_no_operator_then_true() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = true
        provider.currentOperator = nil

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == true)
    }

    @Test func test_isShowingLockScreen_when_not_locked_and_no_pins_then_false() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = false
        provider.hasAnyPINs = false
        provider.currentOperator = nil

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == false)
    }

    @Test func test_isShowingLockScreen_when_not_locked_but_has_pins_and_no_operator_then_true() async {
        // Given - first POS open with PINs configured
        let provider = MockPOSPermissionProvider()
        provider.isLocked = false
        provider.hasAnyPINs = true
        provider.currentOperator = nil

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == true)
    }

    @Test func test_isShowingLockScreen_when_locked_with_operator_then_false() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = true
        provider.hasAnyPINs = true
        provider.currentOperator = makeOperator()

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == false)
    }

    @Test func test_isShowingLockScreen_when_has_pins_and_signed_in_then_false() async {
        // Given - operator authenticated
        let provider = MockPOSPermissionProvider()
        provider.isLocked = false
        provider.hasAnyPINs = true
        provider.currentOperator = makeOperator()

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == false)
    }

    // MARK: - authenticatePIN

    @Test func test_authenticatePIN_when_valid_then_returns_true() async throws {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(authenticator: authenticator)

        // When
        let result = try await sut.authenticatePIN("1234")

        // Then
        #expect(result == true)
    }

    @Test func test_authenticatePIN_when_invalid_then_returns_false() async throws {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = false
        let sut = makeSUT(authenticator: authenticator)

        // When
        let result = try await sut.authenticatePIN("9999")

        // Then
        #expect(result == false)
    }

    @Test func test_authenticatePIN_when_valid_then_lock_screen_dismisses() async throws {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = true
        provider.hasAnyPINs = true
        provider.currentOperator = nil
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(provider: provider, authenticator: authenticator)

        #expect(sut.isShowingLockScreen == true)

        // When - simulate what happens after auth: provider unlocks
        provider.isLocked = false
        provider.currentOperator = makeOperator()
        let result = try await sut.authenticatePIN("1234")

        // Then
        #expect(result == true)
        #expect(sut.isShowingLockScreen == false)
    }

    @Test func test_authenticatePIN_passes_pin_to_authenticator() async throws {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(authenticator: authenticator)

        // When
        _ = try await sut.authenticatePIN("5678")

        // Then
        #expect(authenticator.lastAuthenticatedPIN == "5678")
    }

    // MARK: - Helpers

    private func makeSUT(
        provider: MockPOSPermissionProvider = MockPOSPermissionProvider(),
        authenticator: MockPOSPINAuthenticator = MockPOSPINAuthenticator()
    ) -> POSLockScreenModel {
        POSLockScreenModel(provider: provider, authenticator: authenticator)
    }

    private func makeOperator() -> POSOperator {
        POSOperator(
            userID: 42,
            displayName: "Store Owner",
            role: "pos_manager",
            capabilities: ["woocommerce_pos_access"],
            isAppAccountHolder: true
        )
    }
}

// MARK: - MockPOSPINAuthenticator

final class MockPOSPINAuthenticator: POSPINAuthenticating {
    var authenticateResult: Bool = false
    var errorToThrow: Error?
    var lastAuthenticatedPIN: String?

    func authenticate(pin: String) async throws -> Bool {
        lastAuthenticatedPIN = pin
        if let errorToThrow {
            throw errorToThrow
        }
        return authenticateResult
    }
}
