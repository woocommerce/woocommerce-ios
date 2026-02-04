// POSBookingsModel.swift
import Foundation
import Observation
import Yosemite

@Observable final class POSBookingsModel {
    let bookingListController: POSBookingListController
    let siteID: Int64
    let bookingService: POSBookingServiceProtocol
    let cardPaymentFacade: CardPresentPaymentFacade
    let receiptSender: POSReceiptSending

    init(bookingListController: POSBookingListController,
         siteID: Int64,
         bookingService: POSBookingServiceProtocol,
         cardPaymentFacade: CardPresentPaymentFacade,
         receiptSender: POSReceiptSending) {
        self.bookingListController = bookingListController
        self.siteID = siteID
        self.bookingService = bookingService
        self.cardPaymentFacade = cardPaymentFacade
        self.receiptSender = receiptSender
    }

    func sendReceipt(orderID: Int64, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: orderID, recipientEmail: email)
    }
}
