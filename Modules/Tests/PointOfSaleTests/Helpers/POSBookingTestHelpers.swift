// POSBookingTestHelpers.swift
import Foundation
@testable import PointOfSale

/// Test helper functions for creating POSBooking instances
enum POSBookingTestHelpers {
    static func makeBooking(
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
