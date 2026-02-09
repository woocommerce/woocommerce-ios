// POSBookingsContainerView.swift
import CocoaLumberjackSwift
import SwiftUI
import Yosemite

struct POSBookingsContainerView: View {
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posExternalNavigation) private var externalNavigation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var isPresented: Bool
    var onNavigateToPOSOrder: ((Int64) -> Void)?
    @State private var showingCashPayment: Bool = false
    @State private var showingEmailReceipt: Bool = false
    @State private var cardPaymentController: POSBookingPaymentController?
    @State private var refundModalState: BookingRefundModalState?
    @State private var bookingRefundController: POSBookingRefundController?

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
                .environment(bookingsModel)
        } detail: { booking in
            POSBookingDetailView(
                booking: booking,
                isRefreshing: bookingListController.isRefreshing,
                onBack: { bookingListController.selectBooking(nil) },
                onPayByCard: { startCardPayment(for: booking) },
                onPayByCash: { startCashPayment(for: booking) },
                onIssueRefund: booking.status == .paid ? { startRefundFlow(for: booking) } : nil,
                onViewOrder: booking.orderID != nil ? {
                    externalNavigation.navigateToOrderDetails(orderID: booking.orderID!, siteID: bookingsModel.siteID)
                } : nil,
                onViewOrderInPOS: booking.orderID != nil ? {
                    onNavigateToPOSOrder?(booking.orderID!)
                } : nil
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
        .posModal(item: $refundModalState, onDismiss: {
            bookingRefundController?.clearRefundSelection()
        }) { state in
            bookingRefundModalContent(for: state)
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

    // MARK: - Payment Actions

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

    // MARK: - Refund Flow

    private func startRefundFlow(for booking: POSBooking) {
        let controller = bookingsModel.makeRefundController()
        bookingRefundController = controller

        Task {
            await controller.loadOrderForRefund(booking: booking)

            if controller.isFullyRefunded {
                // Order is already fully refunded, don't show item selection
                bookingRefundController = nil
                return
            }

            if controller.orderLoadError != nil {
                // Failed to load order, don't show refund flow
                bookingRefundController = nil
                return
            }

            refundModalState = .itemSelection
        }
    }

    @ViewBuilder
    private func bookingRefundModalContent(for state: BookingRefundModalState) -> some View {
        switch state {
        case .itemSelection:
            if let controller = bookingRefundController {
                POSBookingRefundItemsSelectionView(
                    refundController: controller,
                    onClose: { refundModalState = nil },
                    onContinue: { navigateToRefundReview() }
                )
            }
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: { refundModalState = nil },
                itemsCount: reviewData.itemsCount,
                formattedItemsSubtotal: reviewData.formattedItemsSubtotal,
                formattedTax: reviewData.formattedTax,
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                refundReason: reviewData.refundReason,
                onAddReason: {
                    refundModalState = .reasonInput(reviewData)
                },
                onContinue: {
                    refundModalState = .confirmation(reviewData)
                },
                onEditRefund: {
                    refundModalState = .itemSelection
                }
            )
        case .reasonInput(let reviewData):
            POSRefundReasonView(
                initialReason: reviewData.refundReason,
                onSave: { reason in
                    var updatedReviewData = reviewData
                    updatedReviewData.refundReason = reason
                    refundModalState = .review(updatedReviewData)
                },
                onBack: {
                    refundModalState = .review(reviewData)
                },
                onClose: {
                    refundModalState = nil
                }
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: {
                    refundModalState = nil
                },
                onConfirm: {
                    refundModalState = .processing(reviewData)
                    Task { @MainActor in
                        await processBookingRefund(reviewData: reviewData)
                    }
                },
                onBack: {
                    refundModalState = .review(reviewData)
                }
            )
        case .processing(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success(let reviewData):
            POSRefundSuccessView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                onDone: {
                    refundModalState = nil
                    refreshAfterPayment()
                },
                onEmailReceipt: {
                    if let booking = bookingListController.selectedBooking,
                       let orderID = booking.orderID {
                        showingEmailReceipt = true
                        // Email receipt is handled by the sheet already attached to the view
                        _ = orderID
                    }
                },
                onClose: {
                    refundModalState = nil
                    refreshAfterPayment()
                }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                onRetry: {
                    refundModalState = .confirmation(reviewData)
                },
                onCancel: {
                    refundModalState = nil
                },
                onClose: {
                    refundModalState = nil
                }
            )
        }
    }

    private func navigateToRefundReview() {
        guard let reviewData = bookingRefundController?.preparePOSRefundReviewData() else { return }
        refundModalState = .review(reviewData)
    }

    @MainActor
    private func processBookingRefund(reviewData: POSRefundReviewData) async {
        do {
            try await bookingRefundController?.processRefund(reason: reviewData.refundReason)
            refundModalState = .success(reviewData)
        } catch {
            DDLogError("⛔️ Failed to process booking refund: \(error)")
            refundModalState = .error(reviewData)
        }
    }

    // MARK: - Localization

    private enum Localization {
        static let title = NSLocalizedString(
            "posBookingsContainer.title",
            value: "Today's Bookings",
            comment: "Title for bookings screen"
        )
    }
}

// MARK: - Booking Refund Modal State

/// State machine for the booking refund modal flow.
/// Mirrors `RefundModalState` from `POSOrderDetailsView` but scoped to bookings.
enum BookingRefundModalState: Identifiable, Equatable {
    case itemSelection
    case review(POSRefundReviewData)
    case reasonInput(POSRefundReviewData)
    case confirmation(POSRefundReviewData)
    case processing(POSRefundReviewData)
    case success(POSRefundReviewData)
    case error(POSRefundReviewData)

    var id: String {
        switch self {
        case .itemSelection: return "itemSelection"
        case .review: return "review"
        case .reasonInput: return "reasonInput"
        case .confirmation: return "confirmation"
        case .processing: return "processing"
        case .success: return "success"
        case .error: return "error"
        }
    }
}
