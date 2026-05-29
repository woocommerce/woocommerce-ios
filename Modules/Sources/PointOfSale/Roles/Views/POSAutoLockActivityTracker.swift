import SwiftUI

extension View {
    /// Cart-count is observed in addition to gestures so Bluetooth HID barcode scanners
    /// (which don't emit UIKit touches) still count as activity.
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
            .onChange(of: aggregateModel.cart.totalItemCount) { _, _ in
                controller?.noteActivity()
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
                        timeout: timeout
                    )
                }
                controller?.noteActivity()
            }
            .onDisappear { controller?.stop() }
    }
}
