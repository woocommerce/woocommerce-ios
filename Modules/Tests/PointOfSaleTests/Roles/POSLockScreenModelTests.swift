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

    @Test func test_isShowingLockScreen_when_not_locked_then_false() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = false
        provider.currentOperator = nil

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == false)
    }

    @Test func test_isShowingLockScreen_when_locked_with_operator_then_false() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = true
        provider.currentOperator = makeOperator()

        // When
        let sut = makeSUT(provider: provider)

        // Then
        #expect(sut.isShowingLockScreen == false)
    }

    // MARK: - authenticatePIN

    @Test func test_authenticatePIN_when_valid_then_returns_true() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(authenticator: authenticator)

        // When
        let result = await sut.authenticatePIN("1234")

        // Then
        #expect(result == true)
    }

    @Test func test_authenticatePIN_when_invalid_then_returns_false() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = false
        let sut = makeSUT(authenticator: authenticator)

        // When
        let result = await sut.authenticatePIN("9999")

        // Then
        #expect(result == false)
    }

    @Test func test_authenticatePIN_when_valid_then_lock_screen_dismisses() async {
        // Given
        let provider = MockPOSPermissionProvider()
        provider.isLocked = true
        provider.currentOperator = nil
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(provider: provider, authenticator: authenticator)

        #expect(sut.isShowingLockScreen == true)

        // When - simulate what happens after auth: provider unlocks
        provider.isLocked = false
        provider.currentOperator = makeOperator()
        let result = await sut.authenticatePIN("1234")

        // Then
        #expect(result == true)
        #expect(sut.isShowingLockScreen == false)
    }

    @Test func test_authenticatePIN_passes_pin_to_authenticator() async {
        // Given
        let authenticator = MockPOSPINAuthenticator()
        authenticator.authenticateResult = true
        let sut = makeSUT(authenticator: authenticator)

        // When
        _ = await sut.authenticatePIN("5678")

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
    var verifyManagerPINResult: Bool = false
    var lastAuthenticatedPIN: String?
    var lastVerifiedManagerPIN: String?

    func authenticate(pin: String) async -> Bool {
        lastAuthenticatedPIN = pin
        return authenticateResult
    }

    func verifyManagerPIN(_ pin: String) -> Bool {
        lastVerifiedManagerPIN = pin
        return verifyManagerPINResult
    }
}
