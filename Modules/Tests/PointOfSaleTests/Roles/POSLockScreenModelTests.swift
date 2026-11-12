import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLockScreenModelTests {
    @Test func test_init_when_wait_has_not_been_read_then_disables_pin_entry() {
        // Given / When
        let model = POSLockScreenModel(session: MockPOSAccessSession(isLocked: true))

        // Then
        #expect(model.isLocked)
        #expect(POSPINEntryViewHelper().isInputEnabled(for: model.pinEntryState) == false)
    }

    @Test func test_refresh_when_shared_wait_exists_then_shows_countdown_before_first_input() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: .failure(.rateLimited(remainingSeconds: 17)))
        let model = POSLockScreenModel(session: session)

        // When
        await model.refreshLockoutState()

        // Then
        #expect(model.pinEntryState == .waiting(remainingSeconds: 17))
        #expect(session.signInPINs.isEmpty)
    }

    @Test func test_refresh_when_wait_expires_then_enables_entry_only_after_authoritative_check() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: .failure(.rateLimited(remainingSeconds: 1)))
        let model = POSLockScreenModel(session: session)
        await model.refreshLockoutState()

        // When
        await model.refreshLockoutState()
        #expect(model.pinEntryState == .waiting(remainingSeconds: 1))
        session.checkLockoutResult = .success(())
        await model.refreshLockoutState()

        // Then
        #expect(model.pinEntryState == .idle)
    }

    @Test func test_refresh_when_storage_fails_then_disables_entry_and_can_retry() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: .failure(.unknown))
        let model = POSLockScreenModel(session: session)

        // When
        await model.refreshLockoutState()

        // Then
        #expect(model.pinEntryState == .unavailable)
        #expect(POSPINEntryViewHelper().isInputEnabled(for: model.pinEntryState) == false)
        session.checkLockoutResult = .success(())
        await model.refreshLockoutState()
        #expect(model.pinEntryState == .idle)
    }

    @Test func test_signIn_when_started_then_shows_loading_and_unlocks_on_success() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true)
        let model = POSLockScreenModel(session: session)
        session.onSignIn = { #expect(model.pinEntryState == .loading) }

        // When
        let success = await model.signIn(withPIN: "1234")

        // Then
        #expect(success)
        #expect(model.isLocked == false)
        #expect(model.pinEntryState == .idle)
    }

    @Test func test_signIn_when_pin_is_wrong_then_shows_error_without_unlocking() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, signInResult: .failure(.invalidPIN))
        let model = POSLockScreenModel(session: session)

        // When
        let success = await model.signIn(withPIN: "0000")

        // Then
        #expect(success == false)
        #expect(model.isLocked)
        #expect(model.pinEntryState == .error(kind: .invalidPIN))
    }

    @Test func test_signIn_when_wait_starts_then_keeps_input_disabled() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, signInResult: .failure(.rateLimited(remainingSeconds: 30)))
        let model = POSLockScreenModel(session: session)

        // When
        await model.signIn(withPIN: "0000")

        // Then
        #expect(model.pinEntryState == .waiting(remainingSeconds: 30))
        #expect(model.isLocked)
    }

    @Test func test_forgotPIN_when_wait_is_active_then_preserves_lock_and_wait() async {
        // Given
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: .failure(.rateLimited(remainingSeconds: 30)))
        let model = POSLockScreenModel(session: session)
        await model.refreshLockoutState()

        // When
        await model.forgotPIN()

        // Then
        #expect(model.showsRecoveryUnavailable)
        #expect(model.isLocked)
        #expect(model.pinEntryState == .waiting(remainingSeconds: 30))
    }
}
