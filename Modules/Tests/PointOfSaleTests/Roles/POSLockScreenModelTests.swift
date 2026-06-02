import Foundation
import Testing
import Observation
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLockScreenModelTests {
    @Test func test_init_when_session_is_locked_then_copies_session_state() {
        // Given
        let session = MockPOSAccessSession(isLocked: true)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_sessionState_when_session_locks_then_model_updates() async {
        // Given
        let session = MockPOSAccessSession(isLocked: false)
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
        let session = MockPOSAccessSession(isLocked: true)
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
        let signedInStaff = makeStaff()
        let session = MockPOSAccessSession(
            currentStaff: nil,
            isLocked: true,
            signInResult: .success(signedInStaff)
        )
        let sut = POSLockScreenModel(session: session)

        // When
        let succeeded = await sut.signIn(withPIN: "1234")

        // Then
        #expect(succeeded == true)
        #expect(sut.isLocked == false)
        #expect(sut.pinEntryState == .idle)
        #expect(session.currentStaff == signedInStaff)
    }

    @Test func test_signIn_when_pin_is_invalid_then_shows_invalid_pin_error() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, signInResult: .failure(.invalidPIN))
        let sut = POSLockScreenModel(session: session)

        // When
        let succeeded = await sut.signIn(withPIN: "9999")

        // Then
        #expect(succeeded == false)
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .error(kind: .invalidPIN))
    }

    @Test func test_signIn_when_error_is_unknown_then_shows_generic_error() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, signInResult: .failure(.unknown))
        let sut = POSLockScreenModel(session: session)

        // When
        let succeeded = await sut.signIn(withPIN: "1234")

        // Then
        #expect(succeeded == false)
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .error(kind: .generic))
    }

    @Test func test_signIn_when_rate_limited_then_shows_lockout_state() async {
        // Given
        let lockoutUntil = Date(timeIntervalSinceReferenceDate: 5000)
        let session = MockPOSAccessSession(
            isLocked: true,
            signInResult: .failure(.rateLimited(until: lockoutUntil))
        )
        let sut = POSLockScreenModel(session: session)

        // When
        let succeeded = await sut.signIn(withPIN: "9999")

        // Then
        #expect(succeeded == false)
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .lockout(until: lockoutUntil))
    }

    @Test func test_signIn_when_permanently_locked_then_shows_generic_error() async {
        // Given
        let session = MockPOSAccessSession(
            isLocked: true,
            signInResult: .failure(.permanentlyLocked)
        )
        let sut = POSLockScreenModel(session: session)

        // When
        let succeeded = await sut.signIn(withPIN: "9999")

        // Then
        #expect(succeeded == false)
        #expect(sut.isLocked == true)
        #expect(sut.pinEntryState == .error(kind: .generic))
    }

    @Test func test_lockoutExpired_when_in_lockout_state_then_resets_to_idle() async {
        // Given
        let session = MockPOSAccessSession(
            isLocked: true,
            signInResult: .failure(.rateLimited(until: Date().addingTimeInterval(60)))
        )
        let sut = POSLockScreenModel(session: session)
        await sut.signIn(withPIN: "9999")

        // When
        sut.lockoutExpired()

        // Then
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_lockoutExpired_when_in_idle_state_then_does_nothing() {
        // Given
        let session = MockPOSAccessSession(isLocked: true)
        let sut = POSLockScreenModel(session: session)

        // When
        sut.lockoutExpired()

        // Then
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_lockoutExpired_when_in_error_state_then_does_not_clear_error() {
        // Given
        let session = MockPOSAccessSession(isLocked: true)
        let sut = POSLockScreenModel(session: session, initialPinEntryState: .error(kind: .invalidPIN))

        // When
        sut.lockoutExpired()

        // Then
        #expect(sut.pinEntryState == .error(kind: .invalidPIN))
    }

    @Test func test_init_when_session_reports_rate_limited_then_sets_lockout_state() {
        // Given
        let lockoutEnd = Date(timeIntervalSinceReferenceDate: 5000)
        let session = MockPOSAccessSession(
            isLocked: true,
            checkLockoutResult: .failure(.rateLimited(until: lockoutEnd))
        )

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.pinEntryState == .lockout(until: lockoutEnd))
    }

    @Test func test_init_when_session_reports_permanently_locked_then_sets_generic_error() {
        // Given
        let session = MockPOSAccessSession(
            isLocked: true,
            checkLockoutResult: .failure(.permanentlyLocked)
        )

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.pinEntryState == .error(kind: .generic))
    }

    @Test func test_init_when_session_is_clean_then_pin_entry_state_is_idle() {
        // Given
        let session = MockPOSAccessSession(
            isLocked: true,
            checkLockoutResult: .success(())
        )

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.pinEntryState == .idle)
    }

    private func makeStaff() -> POSStaff {
        POSStaff(
            displayName: "Maya",
            role: "Manager",
            capabilities: Set(POSCapability.allCases.map(\.rawValue))
        )
    }
}
