// POSBookingsContainerView.swift
import SwiftUI
import Yosemite

struct POSBookingsContainerView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @Binding var isPresented: Bool
    @State private var selectedBooking: POSBooking?
    @State private var showingCashPayment: Bool = false
    @State private var showingEmailReceipt: Bool = false
    @State private var cardPaymentController: POSBookingPaymentController?

    var body: some View {
        NavigationSplitView {
            POSBookingListView(
                onClose: { isPresented = false },
                onBookingSelected: { booking in
                    selectedBooking = booking
                }
            )
            .environment(bookingsModel.bookingListController)
        } detail: {
            if let booking = selectedBooking {
                POSBookingDetailView(
                    booking: booking,
                    onBack: { selectedBooking = nil },
                    onPayByCard: { startCardPayment(for: booking) },
                    onPayByCash: { startCashPayment(for: booking) }
                )
            } else {
                emptyDetailView
            }
        }
        .posFullScreenCover(item: $cardPaymentController) { controller in
            POSBookingPaymentView(
                onDismiss: {
                    cardPaymentController = nil
                    refreshAfterPayment()
                },
                onEmailReceipt: {
                    showingEmailReceipt = true
                }
            )
            .environment(controller)
            .task {
                try? await controller.collectCardPayment()
            }
            .posSheet(isPresented: $showingEmailReceipt) {
                if let booking = selectedBooking, let orderID = booking.orderID {
                    POSSendReceiptView(
                        isShowingSendReceiptView: $showingEmailReceipt
                    ) { email in
                        try await bookingsModel.sendReceipt(orderID: orderID, email: email)
                    }
                }
            }
        }
        .posFullScreenCover(isPresented: $showingCashPayment) {
            if let booking = selectedBooking {
                POSBookingCashPaymentView(
                    booking: booking,
                    onPaymentComplete: {
                        showingCashPayment = false
                        refreshAfterPayment()
                    },
                    onDismiss: {
                        showingCashPayment = false
                    },
                    onEmailReceipt: {
                        showingEmailReceipt = true
                    }
                )
                .posSheet(isPresented: $showingEmailReceipt) {
                    if let orderID = booking.orderID {
                        POSSendReceiptView(
                            isShowingSendReceiptView: $showingEmailReceipt
                        ) { email in
                            try await bookingsModel.sendReceipt(orderID: orderID, email: email)
                        }
                    }
                }
            }
        }
        .task {
            await bookingsModel.bookingListController.loadBookings()
        }
    }

    @ViewBuilder
    private var emptyDetailView: some View {
        VStack(spacing: POSSpacing.medium) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(Localization.selectBooking)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    private func startCardPayment(for booking: POSBooking) {
        // Setting the controller triggers the full screen cover (item-based presentation)
        cardPaymentController = POSBookingPaymentController(
            siteID: bookingsModel.siteID,
            booking: booking,
            bookingService: bookingsModel.bookingService,
            cardPaymentFacade: bookingsModel.cardPaymentFacade,
            orderProvider: bookingsModel.orderProvider
        )
    }

    private func startCashPayment(for booking: POSBooking) {
        showingCashPayment = true
    }

    private func refreshAfterPayment() {
        Task {
            await bookingsModel.bookingListController.refreshBookings()
            // Update selected booking if it was paid
            if let currentID = selectedBooking?.bookingID,
               let updated = bookingsModel.bookingListController.state.bookings.first(where: { $0.bookingID == currentID }) {
                selectedBooking = updated
            }
        }
    }

    private enum Localization {
        static let selectBooking = NSLocalizedString(
            "posBookingsContainer.selectBooking",
            value: "Select a booking to view details",
            comment: "Placeholder when no booking is selected"
        )
    }
}
