import SwiftUI
import struct Yosemite.POSBooking

/// Full-screen payment view for bookings.
/// Shows card/cash payment UI via the shared `POSPaymentContentView`.
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let paymentModel: POSPaymentModel
    let onDismiss: () -> Void

    var body: some View {
        POSPaymentContentView(
            formattedSubtotal: booking.order.formattedSubtotal,
            formattedTax: booking.order.formattedTotalTax,
            formattedTotal: booking.order.formattedTotal,
            onDismiss: onDismiss)
            .environment(paymentModel)
            .background(Color.posSurface)
            .task {
                await paymentModel.startPayment()
            }
            .onDisappear {
                paymentModel.tearDown()
            }
    }
}
