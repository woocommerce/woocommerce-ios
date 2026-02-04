// POSBookingsContainerView.swift
import SwiftUI
import Yosemite

struct POSBookingsContainerView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @Binding var isPresented: Bool
    @State private var selectedBooking: POSBooking?
    @State private var showingCardPayment: Bool = false
    @State private var showingCashPayment: Bool = false
    @State private var showingEmailReceipt: Bool = false
    @State private var paymentController: POSBookingPaymentController?

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
        .posFullScreenCover(isPresented: $showingCardPayment) {
            if let controller = paymentController {
                POSBookingPaymentView(
                    onDismiss: {
                        showingCardPayment = false
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
        paymentController = POSBookingPaymentController(
            siteID: bookingsModel.siteID,
            booking: booking,
            bookingService: bookingsModel.bookingService,
            cardPaymentFacade: bookingsModel.cardPaymentFacade,
            orderProvider: DefaultPOSOrderProvider()
        )
        showingCardPayment = true
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

/// Default order provider that fetches orders from the network
private struct DefaultPOSOrderProvider: POSOrderProviding {
    func fetchOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        // This would normally fetch from the network via stores
        // For now, return a placeholder as booking payment uses the order ID
        // The actual implementation would use StoresManager
        throw POSOrderProviderError.notImplemented
    }

    enum POSOrderProviderError: Error {
        case notImplemented
    }
}
