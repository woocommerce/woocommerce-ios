import SwiftUI
import struct Yosemite.POSBooking

/// Full-screen payment view for bookings.
/// Shows order items on the left and card/cash payment UI on the right,
/// mirroring the two-column layout used in the regular POS checkout flow.
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let paymentModel: POSPaymentModel
    let onDismiss: () -> Void

    @Environment(POSBookingsModel.self) private var bookingsModel

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: POSSpacing.none) {
                if !paymentModel.paymentState.shownFullScreen {
                    POSBookingOrderItemsView(
                        booking: booking,
                        orderItemBookings: bookingsModel.loadedBookingsByID
                    )
                    .frame(width: geometry.size.width * Constants.itemsWidth)
                }

                POSPaymentContentView(
                    formattedSubtotal: booking.order.formattedSubtotal,
                    formattedTax: booking.order.formattedTotalTax,
                    formattedTotal: booking.order.formattedTotal,
                    onDismiss: onDismiss)
            }
            .animation(.default, value: paymentModel.paymentState.shownFullScreen)
        }
        .environment(paymentModel)
        .background(Color.posSurface)
        .task {
            await paymentModel.startPayment()
        }
        .onDisappear {
            paymentModel.tearDown()
        }
    }

    private enum Constants {
        static let itemsWidth: CGFloat = 0.35
    }
}
