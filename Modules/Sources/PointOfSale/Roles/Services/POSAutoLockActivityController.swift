import Foundation

/// Owns the POS auto-lock timer. Decoupled from the view modifier so the timer-fire
/// decision is unit-testable.
@MainActor
final class POSAutoLockActivityController {
    static let defaultTimeout: TimeInterval = 300

    private static let activityThrottle: TimeInterval = 1

    private let session: any POSAccessSession
    private let paymentStateProvider: () -> PointOfSalePaymentState
    private let timeout: TimeInterval
    private let now: () -> Date

    private var lastActivityAt: Date
    private var timer: Timer?

    init(session: any POSAccessSession,
         paymentStateProvider: @escaping () -> PointOfSalePaymentState,
         timeout: TimeInterval = POSAutoLockActivityController.defaultTimeout,
         now: @escaping () -> Date = Date.init) {
        self.session = session
        self.paymentStateProvider = paymentStateProvider
        self.timeout = timeout
        self.now = now
        self.lastActivityAt = now()
    }

    func noteActivity() {
        lastActivityAt = now()
        restartTimer()
    }

    func noteActivityThrottled() {
        guard now().timeIntervalSince(lastActivityAt) >= Self.activityThrottle else {
            return
        }
        noteActivity()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func handleTimerFire() {
        guard session.hasAnyPINs, session.currentStaff != nil else {
            stop()
            return
        }
        if paymentStateProvider().isAutoLockSuppressing {
            restartTimer()
            return
        }
        // Activity may have landed between Timer fire and the @MainActor hop.
        if now().timeIntervalSince(lastActivityAt) < timeout {
            restartTimer()
            return
        }
        session.lock()
    }
}

private extension POSAutoLockActivityController {
    func restartTimer() {
        timer?.invalidate()
        let scheduled = Timer(timeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.handleTimerFire() }
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }
}
