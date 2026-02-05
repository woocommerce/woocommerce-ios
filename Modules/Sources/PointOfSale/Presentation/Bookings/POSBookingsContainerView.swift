// POSBookingsContainerView.swift
import SwiftUI
import Yosemite

struct POSBookingsContainerView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var isPresented: Bool
    @State private var showingCashPayment: Bool = false
    @State private var showingEmailReceipt: Bool = false
    @State private var cardPaymentController: POSBookingPaymentController?

    private var bookingListController: POSBookingListController {
        bookingsModel.bookingListController
    }

    var body: some View {
        contentView
            .task {
                await bookingListController.loadBookings()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch bookingListController.state {
        case .error(let error):
            errorView(error)
        case .empty:
            emptyView
        default:
            splitView
        }
    }

    @ViewBuilder
    private var splitView: some View {
        POSCustomNavigationSplitView(
            selection: Binding(
                get: { bookingListController.selectedBooking },
                set: { bookingListController.selectBooking($0) }
            )
        ) { _ in
            POSBookingListView(onClose: { isPresented = false })
                .environment(bookingListController)
        } detail: { booking in
            POSBookingDetailView(
                booking: booking,
                isRefreshing: bookingListController.isRefreshing,
                onBack: { bookingListController.selectBooking(nil) },
                onPayByCard: { startCardPayment(for: booking) },
                onPayByCash: { startCashPayment(for: booking) }
            )
            .id(booking.bookingID)
        } detailPlaceholderView: {
            if bookingListController.state.isLoading {
                POSBookingDetailsLoadingView()
            } else {
                POSBookingDetailsEmptyView()
            }
        } setDefaultValue: {
            if bookingListController.selectedBooking == nil,
               let firstBooking = bookingListController.state.bookings.first {
                bookingListController.selectBooking(firstBooking)
            }
        }
        .onChange(of: bookingListController.state.bookings) { _, newBookings in
            guard horizontalSizeClass == .regular else { return }

            guard let firstBooking = newBookings.first else { return }

            if let selectedBooking = bookingListController.selectedBooking,
               newBookings.map(\.bookingID).contains(selectedBooking.bookingID) {
                return
            }

            bookingListController.selectBooking(firstBooking)
        }
        .animation(.default, value: bookingListController.state.bookings.isEmpty)
        .onDisappear {
            bookingListController.selectBooking(nil)
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
                if let booking = bookingListController.selectedBooking,
                   let orderID = booking.orderID {
                    POSSendReceiptView(
                        isShowingSendReceiptView: $showingEmailReceipt
                    ) { email in
                        try await bookingsModel.sendReceipt(orderID: orderID, email: email)
                    }
                }
            }
        }
        .posFullScreenCover(isPresented: $showingCashPayment) {
            if let booking = bookingListController.selectedBooking {
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
    }

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: .init(state: .enabled, action: { isPresented = false }, buttonIcon: "xmark")
            )
            POSListEmptyView(viewModel: POSBookingListEmptyViewModel())
        }
        .background(Color.posSurfaceBright)
    }

    @ViewBuilder
    private func errorView(_ error: PointOfSaleErrorState) -> some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: .init(state: .enabled, action: { isPresented = false }, buttonIcon: "xmark")
            )
            POSListErrorView(error: error) {
                Task {
                    await bookingListController.loadBookings()
                }
            }
        }
        .background(Color.posSurfaceBright)
    }

    private func startCardPayment(for booking: POSBooking) {
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
            await bookingListController.refreshBookings()
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "posBookingsContainer.title",
            value: "Today's Bookings",
            comment: "Title for bookings screen"
        )
    }
}
