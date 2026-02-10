import Foundation
import Observation
import struct Yosemite.POSBooking
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

    func makePaymentModel(for booking: POSBooking,
                           onDismiss: @escaping () -> Void,
                           analytics: POSAnalyticsProviding) -> POSPaymentModel {
        let orderProvider = POSBookingPaymentOrderProvider(
            orderID: booking.orderID ?? 0,
            formattedTotal: booking.formattedAmount,
            orderService: orderService)

        let cashHandler = POSBookingCashPaymentHandler(
            orderService: orderService)

        return POSPaymentModel(
            cardPresentPaymentService: cardPresentPaymentService,
            orderProvider: orderProvider,
            cashPaymentHandler: cashHandler,
            receiptSender: receiptSender,
            configuration: .bookings(onDismiss: onDismiss),
            analytics: analytics,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            celebration: PaymentCaptureCelebration())
    }
}
