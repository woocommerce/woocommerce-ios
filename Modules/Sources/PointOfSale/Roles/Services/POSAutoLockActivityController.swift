import Foundation

@MainActor
final class POSAutoLockActivityController {
    nonisolated private static let activityThrottle: TimeInterval = 1

    private let session: any POSAccessSession
    private let paymentStateProvider: () -> PointOfSalePaymentState
    private let isPaymentPending: () -> Bool
    private var timeout: TimeInterval?
    private let now: () -> Date

    private var lastActivityAt: Date
    private var timer: Timer?

    init(session: any POSAccessSession,
         paymentStateProvider: @escaping () -> PointOfSalePaymentState,
         timeout: TimeInterval?,
         now: @escaping () -> Date = Date.init,
         isPaymentPending: @escaping () -> Bool) {
        self.isPaymentPending = isPaymentPending
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

    func updateTimeout(_ timeout: TimeInterval?) {
        guard timeout != self.timeout else { return }
        self.timeout = timeout
        noteActivity()
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

    func handlePaymentStateChange(from oldState: PointOfSalePaymentState,
                                  to newState: PointOfSalePaymentState,
                                  locksAfterSale: Bool) {
        guard !newState.isAutoLockSuppressing, !isPaymentPending() else {
            stop()
            return
        }
        let leftCompletedSale = oldState.isSuccess && !newState.isSuccess
        if locksAfterSale, leftCompletedSale, hasUnlockedStaff {
            session.lock()
        } else {
            noteActivity()
        }
    }

    func handlePaymentSessionStateChange(_ state: CardPresentPaymentSessionState) {
        if state.isPending { stop() } else { noteActivity() }
    }

    func handleTimerFire() {
        guard let timeout, hasUnlockedStaff else {
            stop()
            return
        }
        if paymentStateProvider().isAutoLockSuppressing || isPaymentPending() {
            stop()
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
    var hasUnlockedStaff: Bool {
        session.isPINProtectionEnabled && session.currentStaff != nil
    }

    func restartTimer() {
        timer?.invalidate()
        guard let timeout, !isPaymentPending(), !paymentStateProvider().isAutoLockSuppressing else {
            timer = nil
            return
        }
        let scheduled = Timer(timeInterval: timeout, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.handleTimerFire() }
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }
}
