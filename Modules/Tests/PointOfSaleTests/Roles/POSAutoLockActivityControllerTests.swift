import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAutoLockActivityControllerTests {
    @Test func test_handleTimerFire_when_hasAnyPINs_is_false_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: false, hasAnyPINs: false)
        let sut = makeSUT(session: session, secondsSinceLastActivity: 600)
        defer { sut.stop() }

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_no_currentStaff_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: nil)
        let sut = makeSUT(session: session, secondsSinceLastActivity: 600)
        defer { sut.stop() }

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_payment_is_in_flight_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(
            session: session,
            paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle),
            secondsSinceLastActivity: 600
        )
        defer { sut.stop() }

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_activity_landed_within_timeout_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session, timeout: 300, secondsSinceLastActivity: 290)
        defer { sut.stop() }

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_idle_past_timeout_then_locks() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session, timeout: 300, secondsSinceLastActivity: 500)
        defer { sut.stop() }

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 1)
    }

    @Test func test_handleTimerFire_when_payment_succeeds_and_then_idle_past_timeout_then_locks() {
        // Given - card payment ended, dashboard idle 5 minutes
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        var paymentState = PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle)
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { paymentState },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }

        // Payment ends - simulates the .onChange handler firing noteActivity().
        paymentState = .idle
        sut.noteActivity()
        clock.advance(by: 600)

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 1)
    }

    @Test func test_noteActivity_then_resets_the_idle_window() {
        // Given - controller created at t=0, lastActivityAt = 0
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { .idle },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }

        // When - 250s pass with no activity, then user taps
        clock.advance(by: 250)
        sut.noteActivity()
        // 250s more pass (total 500s since creation but only 250s since the tap)
        clock.advance(by: 250)

        // Then - the activity reset the window, so handleTimerFire should restart not lock
        sut.handleTimerFire()
        #expect(session.lockCallCount == 0)
    }

    @Test func test_noteActivityThrottled_when_called_within_throttle_window_then_does_not_reset() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { .idle },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }

        // First throttled call resets - lastActivityAt = 0
        sut.noteActivityThrottled()

        // When - same second, a second throttled call should be ignored
        clock.advance(by: 0.5)
        sut.noteActivityThrottled()

        // Then - 300s after the original (not the suppressed second) call, lock should fire
        clock.advance(by: 300)
        sut.handleTimerFire()
        #expect(session.lockCallCount == 1)
    }

    @Test func test_noteActivityThrottled_when_called_past_throttle_window_then_resets() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { .idle },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }
        sut.noteActivityThrottled()

        // When - 2s later (well past 1s throttle), another touch
        clock.advance(by: 2)
        sut.noteActivityThrottled()
        // Then - 290s after the second activity, no lock yet (timeout 300)
        clock.advance(by: 290)
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_session_unlocked_then_relocked_via_noteActivity_then_relocks_after_timeout() {
        // Given - simulates the Codex P1 path: session locked, user signs in (calls
        // noteActivity via the isLocked .onChange), then walks away.
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: true, hasAnyPINs: true)
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { .idle },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }

        // Simulate the unlocked transition triggering noteActivity
        session.isLocked = false
        sut.noteActivity()
        clock.advance(by: 500)

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 1)
    }
}

private extension POSAutoLockActivityControllerTests {
    func makeSUT(session: MockPOSAccessSession,
                 paymentState: PointOfSalePaymentState = .idle,
                 timeout: TimeInterval = 300,
                 secondsSinceLastActivity: TimeInterval = 0) -> POSAutoLockActivityController {
        let clock = ClockHandle()
        let controller = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { paymentState },
            timeout: timeout,
            now: clock.now
        )
        clock.advance(by: secondsSinceLastActivity)
        return controller
    }

    func makeStaff() -> POSStaff {
        POSStaff(displayName: "Maya", role: "shop_manager", capabilities: [])
    }
}

@MainActor
private final class ClockHandle {
    private var current = Date(timeIntervalSinceReferenceDate: 0)

    lazy var now: () -> Date = { self.current }

    func advance(by seconds: TimeInterval) {
        current = current.addingTimeInterval(seconds)
    }
}
