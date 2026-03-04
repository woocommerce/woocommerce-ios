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
