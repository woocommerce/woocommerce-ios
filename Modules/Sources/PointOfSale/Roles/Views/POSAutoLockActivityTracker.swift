import SwiftUI

extension View {
    /// Cart-count is observed in addition to gestures so Bluetooth HID barcode scanners
    /// (which don't emit UIKit touches) still count as activity.
    func posAutoLockActivityTracking(
        session: any POSAccessSession,
        paymentModel: POSPaymentModel,
        aggregateModel: PointOfSaleAggregateModel,
        settings: POSLockSettings
    ) -> some View {
        modifier(POSAutoLockActivityTracker(
            session: session,
            paymentModel: paymentModel,
            aggregateModel: aggregateModel,
            settings: settings
        ))
    }
}

struct POSAutoLockActivityTracker: ViewModifier {
    let session: any POSAccessSession
    let paymentModel: POSPaymentModel
    let aggregateModel: PointOfSaleAggregateModel
    let settings: POSLockSettings

    @State private var controller: POSAutoLockActivityController?

    func body(content: Content) -> some View {
        content
            .onReceive(paymentModel.paymentSessionStatePublisher) { state in
                controller?.handlePaymentSessionStateChange(state)
            }
            .onReceive(paymentModel.paymentStateChanges) { change in
                controller?.handlePaymentStateChange(from: change.oldState, to: change.newState,
                                                     locksAfterSale: settings.preferences.locksAfterSale)
            }
            .onChange(of: aggregateModel.cart.totalItemCount) { _, _ in
                controller?.noteActivity()
            }
            .onChange(of: settings.preferences.inactivityTimeout) { _, timeout in
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
                        timeout: settings.preferences.inactivityTimeout.interval,
                        isPaymentPending: { paymentModel.isCardPaymentPending }
                    )
                }
                controller?.noteActivity()
            }
            .onDisappear { controller?.stop() }
    }
}
