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
            formattedSubtotal: booking.formattedSubtotal ?? booking.formattedAmount,
            formattedTax: booking.formattedTax ?? Localization.taxesZero,
            formattedTotal: booking.formattedAmount,
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

// MARK: - Localization

private extension POSBookingPaymentView {
    enum Localization {
        static let taxesZero = NSLocalizedString(
            "pointOfSale.bookingPayment.taxesZero",
            value: "$0.00",
            comment: "Placeholder for zero taxes in the booking payment screen"
        )
    }
}
