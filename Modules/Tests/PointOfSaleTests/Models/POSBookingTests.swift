// POSBookingTests.swift
import Foundation
import Testing
@testable import PointOfSale

struct POSBookingTests {
    @Test func status_unpaid_when_booking_has_linked_order_and_not_paid() {
        let booking = makeBooking(orderID: 100, isPaid: false, isCancelled: false)

        #expect(booking.status == .unpaid)
    }

    @Test func status_paid_when_booking_is_paid() {
        let booking = makeBooking(orderID: 100, isPaid: true, isCancelled: false)

        #expect(booking.status == .paid)
    }

    @Test func status_cancelled_when_booking_is_cancelled_via_flag() {
        let booking = makeBooking(orderID: 100, isPaid: false, isCancelled: true)

        #expect(booking.status == .cancelled)
    }

    @Test func status_cancelled_when_attendance_status_is_cancelled() {
        let booking = makeBooking(
            orderID: 100,
            isPaid: false,
            isCancelled: false,
            attendanceStatus: .cancelled
        )

        #expect(booking.status == .cancelled)
    }

    @Test func status_noLinkedOrder_when_orderID_is_nil() {
        let booking = makeBooking(orderID: nil, isPaid: false, isCancelled: false)

        #expect(booking.status == .noLinkedOrder)
    }

    @Test func canCollectPayment_true_only_when_unpaid() {
        let unpaid = makeBooking(orderID: 100, isPaid: false, isCancelled: false)
        let paid = makeBooking(orderID: 100, isPaid: true, isCancelled: false)
        let cancelled = makeBooking(orderID: 100, isPaid: false, isCancelled: true)
        let noOrder = makeBooking(orderID: nil, isPaid: false, isCancelled: false)

        #expect(unpaid.canCollectPayment == true)
        #expect(paid.canCollectPayment == false)
        #expect(cancelled.canCollectPayment == false)
        #expect(noOrder.canCollectPayment == false)
    }

    @Test func durationMinutes_calculates_correctly() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(90 * 60) // 90 minutes

        let booking = makeBooking(startTime: startTime, endTime: endTime)

        #expect(booking.durationMinutes == 90)
    }

    // MARK: - Helper

    private func makeBooking(
        bookingID: Int64 = 1,
        orderID: Int64? = 100,
        customerName: String = "Jane Smith",
        serviceName: String = "Haircut",
        startTime: Date = Date(),
        endTime: Date? = nil,
        amount: String = "$50.00",
        isPaid: Bool = false,
        isCancelled: Bool = false,
        resourceName: String? = nil,
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        subtotal: String? = nil,
        tax: String? = nil,
        attendanceStatus: POSBookingAttendanceStatus = .booked
    ) -> POSBooking {
        POSBooking(
            bookingID: bookingID,
            orderID: orderID,
            customerName: customerName,
            serviceName: serviceName,
            startTime: startTime,
            endTime: endTime ?? startTime.addingTimeInterval(3600),
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled,
            resourceName: resourceName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            subtotal: subtotal,
            tax: tax,
            attendanceStatus: attendanceStatus
        )
    }
}
