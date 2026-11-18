import SwiftUI

extension View {
    /// Cart-count is observed in addition to gestures so Bluetooth HID barcode scanners
    /// (which don't emit UIKit touches) still count as activity.
    func posAutoLockActivityTracking(
        session: any POSAccessSession,
        paymentModel: POSPaymentModel,
        aggregateModel: PointOfSaleAggregateModel,
        preferences: POSLockPreferences
    ) -> some View {
        modifier(POSAutoLockActivityTracker(
            session: session,
            paymentModel: paymentModel,
            aggregateModel: aggregateModel,
            preferences: preferences
        ))
    }
}

struct POSAutoLockActivityTracker: ViewModifier {
    let session: any POSAccessSession
    let paymentModel: POSPaymentModel
    let aggregateModel: PointOfSaleAggregateModel
    let preferences: POSLockPreferences

    @State private var controller: POSAutoLockActivityController?

    func body(content: Content) -> some View {
        content
            .onChange(of: paymentModel.paymentState) { oldState, newState in
                controller?.handlePaymentStateChange(from: oldState, to: newState, locksAfterSale: preferences.locksAfterSale)
            }
            .onChange(of: aggregateModel.cart.totalItemCount) { _, _ in
                controller?.noteActivity()
            }
            .onChange(of: preferences.inactivityTimeout) { _, timeout in
                controller?.updateTimeout(timeout.interval)
            }
            .onChange(of: session.isLocked) { _, isLocked in
                // PIN entry happens in the overlay above us; re-arm on unlock.
                if !isLocked {
                    controller?.noteActivity()
                }
            }
            .background(
                POSAutoLockWindowAttacher(controller: controller)
                    .allowsHitTesting(false)
            )
            .onAppear {
                if controller == nil {
                    controller = POSAutoLockActivityController(
                        session: session,
                        paymentStateProvider: { paymentModel.paymentState },
                        timeout: preferences.inactivityTimeout.interval
                    )
                }
                controller?.noteActivity()
            }
            .onDisappear { controller?.stop() }
    }
}
