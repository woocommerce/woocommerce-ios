import SwiftUI
import struct Yosemite.POSBooking

/// Full-screen payment view for bookings.
/// Shows card/cash payment UI via the shared `POSPaymentContentView`.
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let paymentModel: POSPaymentModel
    let onDismiss: () -> Void

    @State private var navigationPath: [POSNavigationDestination] = []

    private var navigationRouter: POSNavigationRouter {
        POSNavigationRouter(navigationPath: $navigationPath)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            POSPaymentContentView(
                formattedSubtotal: booking.order.formattedSubtotal,
                formattedTax: booking.order.formattedTotalTax,
                formattedTotal: booking.order.formattedTotal,
                onDismiss: onDismiss)
            .navigationDestination(for: POSNavigationDestination.self) { destination in
                switch destination {
                case .cashPayment(let orderTotal):
                    POSNavigationDestinationCashPaymentView(orderTotal: orderTotal)
                case .emailReceipt:
                    POSNavigationDestinationEmailReceiptView()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .environment(paymentModel)
        .environment(\.posNavigationRouter, navigationRouter)
        .background(Color.posSurface)
        .onChange(of: paymentModel.paymentState.cash) { _, newValue in
            if newValue == .collectingCash {
                navigationRouter.pushCash(orderTotal: booking.order.formattedTotal)
            }
        }
        .task {
            await paymentModel.startPayment()
        }
        .onDisappear {
            paymentModel.tearDown()
        }
    }
}
