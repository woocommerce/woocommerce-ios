import SwiftUI

extension View {
    /// Tracks user activity for the POS auto-lock timer. When the iPad sits idle past the
    /// timeout while no payment is in-flight, calls `session.lock()`. Activity sources:
    /// touch (throttled), cart count changes, and payment-state transitions that leave the
    /// in-flight set. Bluetooth HID barcode scanners deliver keyboard events rather than
    /// touches, which is why the cart count is observed in addition to gestures.
    func posAutoLockActivityTracking(
        session: any POSAccessSession,
        paymentModel: POSPaymentModel,
        aggregateModel: PointOfSaleAggregateModel,
        timeout: TimeInterval = POSAutoLockActivityTracker.defaultTimeout
    ) -> some View {
        modifier(POSAutoLockActivityTracker(
            session: session,
            paymentModel: paymentModel,
            aggregateModel: aggregateModel,
            timeout: timeout
        ))
    }
}

struct POSAutoLockActivityTracker: ViewModifier {
    static let defaultTimeout: TimeInterval = 300

    private static let activityThrottle: TimeInterval = 1

    let session: any POSAccessSession
    let paymentModel: POSPaymentModel
    let aggregateModel: PointOfSaleAggregateModel
    let timeout: TimeInterval

    @State private var lastActivityAt = Date()
    @State private var timer: Timer?

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in noteActivityThrottled() }
            )
            .onChange(of: paymentModel.paymentState) { _, newState in
                if !newState.isAutoLockSuppressing {
                    noteActivity()
                }
            }
            .onChange(of: aggregateModel.cart.purchasableItems.count) { _, _ in
                noteActivity()
            }
            .onChange(of: session.isLocked) { _, isLocked in
                // The tracker sits under the lock overlay, so PIN entry never reaches our
                // gesture or cart observers. Treat the locked -> unlocked transition as
                // activity so the timer re-arms after sign-in.
                if !isLocked {
                    noteActivity()
                }
            }
            .onAppear { noteActivity() }
            .onDisappear { stopTimer() }
    }
}

private extension POSAutoLockActivityTracker {
    func noteActivityThrottled() {
        let now = Date()
        guard now.timeIntervalSince(lastActivityAt) >= Self.activityThrottle else {
            return
        }
        noteActivity()
    }

    func noteActivity() {
        lastActivityAt = Date()
        restartTimer()
    }

    func restartTimer() {
        timer?.invalidate()
        let scheduled = Timer(timeInterval: timeout, repeats: false) { _ in
            Task { @MainActor in handleTimerFire() }
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func handleTimerFire() {
        guard session.hasAnyPINs, session.currentStaff != nil else {
            stopTimer()
            return
        }
        if paymentModel.paymentState.isAutoLockSuppressing {
            restartTimer()
            return
        }
        session.lock()
    }
}
