// MockPOSBookingService.swift
import Foundation
@testable import Yosemite
import Networking

final class MockPOSBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    var bookingsToReturn: [Booking] = []
    var fetchTodaysBookingsCallCount = 0
    var markBookingAsPaidCallCount = 0
    var markBookingAsPaidBookingID: Int64?
    var shouldThrowOnFetch = false
    var shouldThrowOnMarkAsPaid = false
    var errorToThrow: Error = NSError(domain: "test", code: 1)

    func fetchTodaysBookings(siteID: Int64) async throws -> [Booking] {
        fetchTodaysBookingsCallCount += 1
        if shouldThrowOnFetch {
            throw errorToThrow
        }
        return bookingsToReturn
    }

    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws {
        markBookingAsPaidCallCount += 1
        markBookingAsPaidBookingID = bookingID
        if shouldThrowOnMarkAsPaid {
            throw errorToThrow
        }
    }

    // MARK: - Test Helpers

    static func makeBooking(
        siteID: Int64 = 123,
        bookingID: Int64 = 1,
        orderID: Int64 = 100,
        productID: Int64 = 10,
        customerID: Int64 = 5,
        startDate: Date = Date(),
        endDate: Date? = nil,
        cost: String = "50.00",
        statusKey: String = "unpaid",
        customerFirstName: String = "Jane",
        productName: String = "Haircut"
    ) -> Booking {
        let computedEndDate = endDate ?? startDate.addingTimeInterval(3600)

        return Booking(
            siteID: siteID,
            bookingID: bookingID,
            orderID: orderID,
            orderItemID: 1,
            productID: productID,
            resourceID: nil,
            parentID: nil,
            customerID: customerID,
            statusKey: statusKey,
            attendanceStatusKey: "booked",
            startDate: startDate,
            endDate: computedEndDate,
            allDay: false,
            dateCreated: Date(),
            dateModified: Date(),
            cost: cost,
            googleCalendarEventID: nil,
            note: nil,
            localTimezone: nil,
            currency: "USD",
            orderInfo: BookingOrderInfo(
                customerInfo: BookingCustomerInfo(
                    billingAddress: Address(
                        firstName: customerFirstName,
                        lastName: "Smith",
                        company: nil,
                        address1: "",
                        address2: nil,
                        city: "",
                        state: "",
                        postcode: "",
                        country: "",
                        phone: nil,
                        email: nil
                    ),
                    shippingAddress: nil
                ),
                paymentInfo: nil,
                productInfo: BookingProductInfo(
                    productID: productID,
                    name: productName,
                    shortDescription: nil
                )
            )
        )
    }
}
