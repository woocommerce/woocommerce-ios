import Foundation

/// Owns the POS auto-lock inactivity timer and decides when to call `session.lock()`.
/// Extracted from `POSAutoLockActivityTracker` so the timer-firing decision is unit-testable
/// without a SwiftUI hosting controller. The view modifier wires SwiftUI events into the
/// `noteActivity*` calls below; everything else lives here.
@MainActor
final class POSAutoLockActivityController {
    static let defaultTimeout: TimeInterval = 5

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

    /// Internal so tests can drive the timer-fire decision deterministically.
    func handleTimerFire() {
        guard session.hasAnyPINs, session.currentStaff != nil else {
            stop()
            return
        }
        if paymentStateProvider().isAutoLockSuppressing {
            restartTimer()
            return
        }
        // Catch the case where activity landed between the Timer firing and the
        // @MainActor hop. Without this guard a touch that arrived ~microseconds
        // before us would still see auto-lock fire on top of the user's hand.
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
