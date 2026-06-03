import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAutoLockActivityControllerTests {
    @Test func test_handleTimerFire_when_hasAnyPINs_is_false_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: false, pinStatus: .absent)
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
        // Given
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
        paymentState = .idle
        sut.noteActivity()
        clock.advance(by: 600)

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 1)
    }

    @Test func test_noteActivity_then_resets_the_idle_window() {
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

        // When
        clock.advance(by: 250)
        sut.noteActivity()
        clock.advance(by: 250)
        sut.handleTimerFire()

        // Then
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
        sut.noteActivityThrottled()

        // When
        clock.advance(by: 0.5)
        sut.noteActivityThrottled()
        clock.advance(by: 300)
        sut.handleTimerFire()

        // Then
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

        // When
        clock.advance(by: 2)
        sut.noteActivityThrottled()
        clock.advance(by: 290)
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_session_unlocked_then_relocked_via_noteActivity_then_relocks_after_timeout() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: true, pinStatus: .present)
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(
            session: session,
            paymentStateProvider: { .idle },
            timeout: 300,
            now: clock.now
        )
        defer { sut.stop() }
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
        POSStaff(userID: 1, displayName: "Maya", preset: "pos_manager", capabilities: [])
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
