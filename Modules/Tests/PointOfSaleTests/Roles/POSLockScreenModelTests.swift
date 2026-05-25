import Testing
import Observation
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLockScreenModelTests {
    @Test func test_init_when_session_is_locked_then_copies_session_state() {
        // Given
        let session = MockPOSAccessSession(isLocked: true, hasAnyPINs: true)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.isLocked == true)
        #expect(sut.hasAnyPINs == true)
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_refreshPINStatus_when_session_status_changes_then_updates_pin_availability() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, hasAnyPINs: true, refreshedPINStatus: false)
        let sut = POSLockScreenModel(session: session)

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(sut.hasAnyPINs == false)
        #expect(sut.isLocked == true)
    }

    @Test func test_sessionState_when_session_locks_then_model_updates() async {
        // Given
        let session = MockPOSAccessSession(isLocked: false, hasAnyPINs: true)
        let sut = POSLockScreenModel(session: session)

        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = sut.isLocked
            } onChange: {
                Task { @MainActor in
                    if sut.isLocked {
                        continuation.resume()
                    }
                }
            }

            // When
            session.lock()
        }

        // Then
        #expect(sut.isLocked == true)
    }

    @Test func test_signIn_when_started_then_sets_loading_state() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, hasAnyPINs: true)
        let sut = POSLockScreenModel(session: session)
        session.onSignIn = {
            #expect(sut.pinEntryState == .loading)
        }

        // When
        await sut.signIn(withPIN: "1234")

        // Then
        #expect(session.signInPINs == ["1234"])
    }

    @Test func test_signIn_when_pin_is_valid_then_unlocks_and_resets_pin_state() async {
        // Given
        let signedInOperator = makeOperator()
        let session = MockPOSAccessSession(
            currentOperator: nil,
            isLocked: true,
            hasAnyPINs: true,
            signInResult: .success(signedInOperator)
        )
        let sut = POSLockScreenModel(session: session)

        // When
        await sut.signIn(withPIN: "1234")

        // Then
        #expect(sut.isLocked == false)
        #expect(sut.pinEntryState == .idle)
        #expect(session.currentOperator == signedInOperator)
    }

    @Test func test_signIn_when_pin_is_invalid_then_shows_invalid_pin_error() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, hasAnyPINs: true, signInResult: .failure(.invalidPIN))
        let sut = POSLockScreenModel(session: session)

        // When
        await sut.signIn(withPIN: "9999")

        // Then
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .error(message: "Incorrect PIN. Try again."))
    }

    @Test func test_signIn_when_error_is_unknown_then_shows_generic_error() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, hasAnyPINs: true, signInResult: .failure(.unknown))
        let sut = POSLockScreenModel(session: session)

        // When
        await sut.signIn(withPIN: "1234")

        // Then
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .error(message: "Something went wrong. Try again."))
    }

    private func makeOperator() -> POSOperator {
        POSOperator(
            displayName: "Maya",
            role: "Manager",
            capabilities: Set(POSCapability.allCases.map(\.rawValue))
        )
    }
}
