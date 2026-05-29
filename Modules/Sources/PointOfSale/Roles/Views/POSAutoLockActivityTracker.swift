import SwiftUI

extension View {
    /// Tracks user activity for the POS auto-lock timer. When the iPad sits idle past the
    /// timeout while no payment is in-flight, calls `session.lock()`. Activity sources:
    /// touch (throttled), purchasable-item-count changes (to catch Bluetooth HID barcode
    /// scanners that deliver keyboard events rather than touches), and payment-state
    /// transitions that leave the in-flight set. Other cart mutations (coupons, custom
    /// amounts) are interactive and already covered by the gesture observer.
    func posAutoLockActivityTracking(
        session: any POSAccessSession,
        paymentModel: POSPaymentModel,
        aggregateModel: PointOfSaleAggregateModel,
        timeout: TimeInterval = POSAutoLockActivityController.defaultTimeout
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
    let session: any POSAccessSession
    let paymentModel: POSPaymentModel
    let aggregateModel: PointOfSaleAggregateModel
    let timeout: TimeInterval

    @State private var controller: POSAutoLockActivityController?

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in controller?.noteActivityThrottled() }
            )
            .onChange(of: paymentModel.paymentState) { _, newState in
                if !newState.isAutoLockSuppressing {
                    controller?.noteActivity()
                }
            }
            .onChange(of: aggregateModel.cart.purchasableItems.count) { _, _ in
                controller?.noteActivity()
            }
            .onChange(of: session.isLocked) { _, isLocked in
                // The tracker sits under the lock overlay, so PIN entry never reaches our
                // gesture or cart observers. Treat the locked -> unlocked transition as
                // activity so the timer re-arms after sign-in.
                if !isLocked {
                    controller?.noteActivity()
                }
            }
            .onAppear {
                if controller == nil {
                    controller = POSAutoLockActivityController(
                        session: session,
                        paymentStateProvider: { paymentModel.paymentState },
                        timeout: timeout
                    )
                }
                controller?.noteActivity()
            }
            .onDisappear { controller?.stop() }
    }
}
