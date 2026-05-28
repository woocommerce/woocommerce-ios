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

    @Test func test_pinStatus_when_session_has_pins_then_present() {
        // Given
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .present)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then - the overlay shows the lock screen with the numpad active.
        #expect(sut.pinStatus == .present)
    }

    @Test func test_pinStatus_when_session_has_no_pins_then_absent() {
        // Given
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .absent)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then - .absent tells the overlay to skip the lock screen entirely.
        #expect(sut.pinStatus == .absent)
        #expect(sut.isLocked == true)
    }

    @Test func test_pinStatus_when_session_status_is_unknown_then_unknown() {
        // Given - cold cache before any refresh resolves
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .unknown)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then - the overlay still presents (gating until a fetch confirms).
        #expect(sut.pinStatus == .unknown)
        #expect(sut.isLocked == true)
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

    // MARK: - Content state (drives lock-screen body)

    @Test func test_content_when_pinStatus_is_present_then_pinEntry() {
        // Given
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .present)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then
        #expect(sut.content == .pinEntry)
    }

    @Test func test_content_when_pinStatus_is_unknown_and_refreshing_then_loading() {
        // Given - cold start; init assumes the lock screen will trigger a refresh
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .unknown)

        // When
        let sut = POSLockScreenModel(session: session)

        // Then - no flash of the unavailable state on first appear
        #expect(sut.isRefreshing == true)
        #expect(sut.content == .loading)
    }

    @Test func test_content_when_pinStatus_is_unknown_and_not_refreshing_then_unavailable() {
        // Given - refresh has completed but the session is still uncertain
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .unknown)
        let sut = POSLockScreenModel(session: session, isRefreshing: false)

        // When / Then
        #expect(sut.content == .unavailable)
    }

    @Test func test_refreshPINStatus_when_called_then_toggles_isRefreshing_and_calls_session() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .unknown)
        let sut = POSLockScreenModel(session: session, isRefreshing: false)
        #expect(sut.isRefreshing == false)

        // When
        await sut.refreshPINStatus()

        // Then - isRefreshing flips back to false after the call; session received exactly one call.
        #expect(sut.isRefreshing == false)
        #expect(session.refreshPINStatusCalls == 1)
    }

    @Test func test_refreshPINStatus_while_running_then_isRefreshing_is_true() async {
        // Given - capture isRefreshing mid-call via the mock's hook
        let session = MockPOSAccessSession(isLocked: true, pinStatus: .unknown)
        let sut = POSLockScreenModel(session: session, isRefreshing: false)
        var refreshingDuringCall = false
        session.onRefreshPINStatus = {
            refreshingDuringCall = sut.isRefreshing
        }

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(refreshingDuringCall == true)
    }

    private func makeStaff() -> POSStaff {
        POSStaff(
            userID: 1,
            userLogin: "maya",
            displayName: "Maya",
            role: "Manager",
            capabilities: Set(POSCapability.allCases.map(\.rawValue))
        )
    }
}
