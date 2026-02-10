import SwiftUI
import struct Yosemite.POSBooking

/// Full-screen payment view for bookings.
/// Creates a `POSPaymentModel` with bookings-specific configuration
/// and shows card/cash payment UI via the shared `POSPaymentContentView`.
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let onDismiss: () -> Void

    @State private var paymentModel: POSPaymentModel?

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        Group {
            if let paymentModel {
                POSPaymentContentView(
                    formattedSubtotal: booking.formattedSubtotal ?? booking.formattedAmount,
                    formattedTax: booking.formattedTax ?? Localization.taxesZero,
                    formattedTotal: booking.formattedAmount,
                    onDismiss: onDismiss)
                    .environment(paymentModel)
            } else {
                POSPaymentLoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.posSurface)
        .task {
            guard paymentModel == nil, booking.orderID != nil else { return }

            // Cancel any in-progress cart payment to free the reader before starting
            // a bookings payment. Without this, the reader may still be live from a
            // cart checkout, which would conflict with the bookings payment.
            try? await bookingsModel.cardPresentPaymentService.cancelPayment()

            let model = bookingsModel.makePaymentModel(
                for: booking, onDismiss: onDismiss, analytics: analytics)
            paymentModel = model
            await model.startPayment()
        }
        .onDisappear {
            paymentModel?.tearDown()
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
