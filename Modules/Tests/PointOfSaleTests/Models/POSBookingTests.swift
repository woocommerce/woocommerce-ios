// POSBookingTests.swift
import Foundation
import Testing
@testable import PointOfSale

struct POSBookingTests {
    @Test func status_unpaid_when_booking_has_linked_order_and_not_paid() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: false
        )

        #expect(booking.status == .unpaid)
    }

    @Test func status_paid_when_booking_is_paid() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: true,
            isCancelled: false
        )

        #expect(booking.status == .paid)
    }

    @Test func status_cancelled_when_booking_is_cancelled() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: true
        )

        #expect(booking.status == .cancelled)
    }

    @Test func status_noLinkedOrder_when_orderID_is_nil() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: nil,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: false
        )

        #expect(booking.status == .noLinkedOrder)
    }

    @Test func canCollectPayment_true_only_when_unpaid() {
        let unpaid = POSBooking(bookingID: 1, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: false)
        let paid = POSBooking(bookingID: 2, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: true, isCancelled: false)
        let cancelled = POSBooking(bookingID: 3, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: true)
        let noOrder = POSBooking(bookingID: 4, orderID: nil, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: false)

        #expect(unpaid.canCollectPayment == true)
        #expect(paid.canCollectPayment == false)
        #expect(cancelled.canCollectPayment == false)
        #expect(noOrder.canCollectPayment == false)
    }
}

// Test helper extension
extension POSBookingTests {
    static func makeBooking(
        bookingID: Int64 = 1,
        orderID: Int64? = 100,
        customerName: String = "Jane Smith",
        serviceName: String = "Haircut",
        startTime: Date = Date(),
        amount: String = "$50.00",
        isPaid: Bool = false,
        isCancelled: Bool = false
    ) -> POSBooking {
        POSBooking(
            bookingID: bookingID,
            orderID: orderID,
            customerName: customerName,
            serviceName: serviceName,
            startTime: startTime,
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled
        )
    }
}
