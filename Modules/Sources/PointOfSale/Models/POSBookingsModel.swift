// POSBookingsModel.swift
import Foundation
import Observation
import Yosemite
import class WooFoundation.CurrencyFormatter

@Observable final class POSBookingsModel {
    let bookingListController: POSBookingListController
    let siteID: Int64
    let bookingService: POSBookingServiceProtocol
    let cardPaymentFacade: CardPresentPaymentFacade
    let receiptSender: POSReceiptSending
    let orderProvider: POSOrderProviding
    let refundsService: POSRefundsServiceProtocol
    let currencyFormatter: CurrencyFormatter

    init(bookingListController: POSBookingListController,
         siteID: Int64,
         bookingService: POSBookingServiceProtocol,
         cardPaymentFacade: CardPresentPaymentFacade,
         receiptSender: POSReceiptSending,
         orderProvider: POSOrderProviding,
         refundsService: POSRefundsServiceProtocol,
         currencyFormatter: CurrencyFormatter) {
        self.bookingListController = bookingListController
        self.siteID = siteID
        self.bookingService = bookingService
        self.cardPaymentFacade = cardPaymentFacade
        self.receiptSender = receiptSender
        self.orderProvider = orderProvider
        self.refundsService = refundsService
        self.currencyFormatter = currencyFormatter
    }

    func sendReceipt(orderID: Int64, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: orderID, recipientEmail: email)
    }

    @MainActor func makeRefundController() -> POSBookingRefundController {
        POSBookingRefundController(
            siteID: siteID,
            orderProvider: orderProvider,
            refundsService: refundsService,
            currencyFormatter: currencyFormatter
        )
    }
}
