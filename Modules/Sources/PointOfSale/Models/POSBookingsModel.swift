import Foundation
import Observation
import struct Yosemite.POSBooking
import enum Yosemite.BookingStatus
import enum Yosemite.OrderStatusEnum
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.PaymentCaptureCelebrationProtocol
import class Yosemite.PaymentCaptureCelebration

@Observable final class POSBookingsModel {
    let bookingsController: POSSearchingBookingListControllerProtocol
    let cardPresentPaymentService: CardPresentPaymentFacade
    /// Bookings resolved from order line item `_booking_id` meta_data, keyed by booking ID.
    /// Populated when payment collection starts; views read this reactively.
    @MainActor private(set) var orderItemBookings: [Int64: POSBooking] = [:]
    private let orderService: POSOrderServiceProtocol
    private let receiptSender: POSReceiptSending
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking

    init(bookingsController: POSSearchingBookingListControllerProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         receiptSender: POSReceiptSending,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking) {
        self.bookingsController = bookingsController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderService = orderService
        self.receiptSender = receiptSender
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
    }

    @MainActor
    func updateAfterSuccessfulPayment(bookingID: Int64) async {
        await bookingsController.updateBookingOptimistically(bookingID: bookingID) {
            $0.copy(status: .paid, order: $0.order.copy(datePaid: Date()))
        }
    }

    @MainActor
    func updateAfterRefund(bookingID: Int64) async {
        await bookingsController.updateBookingOptimistically(bookingID: bookingID) {
            $0.copy(order: $0.order.copy(status: .refunded))
        }
    }

    /// Resolves bookings referenced by the order's line items.
    /// Immediately populates from already-loaded bookings, then fetches
    /// any missing ones in the background so dates appear without blocking.
    @MainActor
    func prepareOrderItemBookings(for booking: POSBooking) {
        let bookingIDs = booking.order.lineItems.compactMap(\.bookingID)
        guard bookingIDs.isNotEmpty else {
            orderItemBookings = [:]
            return
        }

        // Populate immediately from loaded bookings
        let loadedBookings = bookingsController.bookingsViewState.bookings
        var resolved: [Int64: POSBooking] = [:]
        for loaded in loadedBookings where bookingIDs.contains(loaded.id) {
            resolved[loaded.id] = loaded
        }
        orderItemBookings = resolved

        // Fetch any missing bookings in the background
        let missingIDs = bookingIDs.filter { resolved[$0] == nil }
        if missingIDs.isNotEmpty {
            Task { [weak self] in
                guard let self else { return }
                let fetched = await bookingsController.fetchBookingsByIDs(missingIDs)
                orderItemBookings.merge(fetched) { _, new in new }
            }
        }
    }

    @MainActor
    func makePaymentModel(for booking: POSBooking,
                           onDismiss: @escaping () -> Void,
                           analytics: POSAnalyticsProviding) -> POSPaymentModel {
        let orderProvider = POSBookingPaymentOrderProvider(
            orderID: booking.orderID ?? 0,
            formattedTotal: booking.order.formattedTotal,
            orderService: orderService)

        return POSPaymentModel(
            cardPresentPaymentService: cardPresentPaymentService,
            orderProvider: orderProvider,
            cashPaymentHandler: POSBookingCashPaymentHandler(orderService: orderService),
            receiptSender: receiptSender,
            configuration: .bookings(onDismiss: onDismiss),
            analytics: analytics,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            celebration: PaymentCaptureCelebration())
    }
}
