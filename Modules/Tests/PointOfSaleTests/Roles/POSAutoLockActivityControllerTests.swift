import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAutoLockActivityControllerTests {
    @Test func test_handleTimerFire_when_isPINProtectionEnabled_is_false_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: false, isPINProtectionEnabled: false)
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

    @Test func test_handleTimerFire_when_timeout_is_never_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(session: session, paymentStateProvider: { .idle }, timeout: nil, now: clock.now)
        defer { sut.stop() }
        sut.noteActivity()
        clock.advance(by: 24 * 60 * 60)

        // When
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_updateTimeout_when_shorter_interval_is_selected_then_locks_after_new_interval_from_selection() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(session: session, paymentStateProvider: { .idle }, timeout: 300, now: clock.now)
        defer { sut.stop() }
        clock.advance(by: 200)

        // When
        sut.updateTimeout(60)
        clock.advance(by: 59)
        sut.handleTimerFire()
        let lockCountBeforeInterval = session.lockCallCount
        clock.advance(by: 1)
        sut.handleTimerFire()

        // Then
        #expect(lockCountBeforeInterval == 0)
        #expect(session.lockCallCount == 1)
    }

    @Test func test_updateTimeout_when_never_is_selected_then_stops_inactivity_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(session: session, paymentStateProvider: { .idle }, timeout: 60, now: clock.now)
        defer { sut.stop() }

        // When
        sut.updateTimeout(nil)
        clock.advance(by: 600)
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_updateTimeout_when_never_changes_back_to_interval_then_activity_restarts_it() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(session: session, paymentStateProvider: { .idle }, timeout: nil, now: clock.now)
        defer { sut.stop() }
        sut.updateTimeout(120)

        // When
        clock.advance(by: 100)
        sut.noteActivity()
        clock.advance(by: 100)
        sut.handleTimerFire()
        let lockCountAfterActivity = session.lockCallCount
        clock.advance(by: 20)
        sut.handleTimerFire()

        // Then
        #expect(lockCountAfterActivity == 0)
        #expect(session.lockCallCount == 1)
    }

    @Test(arguments: [PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle),
                      PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
                      PointOfSalePaymentState(card: .idle, cash: .idle, scanToPay: .paymentSuccess),
                      PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .paymentSuccess)])
    func test_handlePaymentStateChange_when_completed_sale_is_left_and_lock_after_sale_is_on_then_locks(completedSale: PointOfSalePaymentState) {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: completedSale, to: .idle, locksAfterSale: true)

        // Then
        #expect(session.lockCallCount == 1)
    }

    @Test func test_handlePaymentStateChange_when_completed_sale_is_left_and_lock_after_sale_is_off_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle), to: .idle, locksAfterSale: false)

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handlePaymentStateChange_when_sale_completes_then_does_not_lock_the_receipt() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .idle, cash: .collectingCash),
                                     to: PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
                                     locksAfterSale: true)

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handlePaymentStateChange_when_failed_payment_is_left_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .paymentError, cash: .idle), to: .idle, locksAfterSale: true)

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handlePaymentStateChange_when_completed_sale_is_left_for_payment_in_flight_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .idle, cash: .paymentSuccess),
                                     to: PointOfSalePaymentState(card: .processingPayment, cash: .idle),
                                     locksAfterSale: true)

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handlePaymentStateChange_when_isPINProtectionEnabled_is_false_then_does_not_lock() {
        // Given
        let session = MockPOSAccessSession(currentStaff: nil, isLocked: false, isPINProtectionEnabled: false)
        let sut = makeSUT(session: session)
        defer { sut.stop() }

        // When
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle), to: .idle, locksAfterSale: true)

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handlePaymentStateChange_when_it_does_not_lock_then_resets_the_idle_window() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff())
        let clock = ClockHandle()
        let sut = POSAutoLockActivityController(session: session, paymentStateProvider: { .idle }, timeout: 300, now: clock.now)
        defer { sut.stop() }

        // When
        clock.advance(by: 250)
        sut.handlePaymentStateChange(from: PointOfSalePaymentState(card: .idle, cash: .collectingCash), to: .idle, locksAfterSale: true)
        clock.advance(by: 250)
        sut.handleTimerFire()

        // Then
        #expect(session.lockCallCount == 0)
    }

    @Test func test_handleTimerFire_when_session_unlocked_then_relocked_via_noteActivity_then_relocks_after_timeout() {
        // Given
        let session = MockPOSAccessSession(currentStaff: makeStaff(), isLocked: true, isPINProtectionEnabled: true)
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
        POSLocalRole.admin.staff
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
