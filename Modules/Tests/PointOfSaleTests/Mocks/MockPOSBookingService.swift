// MockPOSBookingService.swift
import Foundation
@testable import Yosemite
import Networking

final class MockPOSBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    var bookingsToReturn: [Booking] = []
    var resourcesToReturn: [Int64: BookingResource] = [:]
    var fetchTodaysBookingsCallCount = 0
    var markBookingAsPaidCallCount = 0
    var markBookingAsPaidBookingID: Int64?
    var shouldThrowOnFetch = false
    var shouldThrowOnMarkAsPaid = false
    var errorToThrow: Error = NSError(domain: "test", code: 1)

    func fetchTodaysBookings(siteID: Int64) async throws -> POSBookingFetchResult {
        fetchTodaysBookingsCallCount += 1
        if shouldThrowOnFetch {
            throw errorToThrow
        }
        return POSBookingFetchResult(bookings: bookingsToReturn, resources: resourcesToReturn)
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
            allDay: false,
            cost: cost,
            customerID: customerID,
            dateCreated: Date(),
            dateModified: Date(),
            endDate: computedEndDate,
            googleCalendarEventID: nil,
            orderID: orderID,
            orderItemID: 1,
            parentID: 0,
            productID: productID,
            resourceID: 0,
            startDate: startDate,
            statusKey: statusKey,
            attendanceStatusKey: "booked",
            localTimezone: "UTC",
            currency: "USD",
            orderInfo: BookingOrderInfo(
                statusKey: statusKey,
                paymentInfo: nil,
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
                    )
                ),
                productInfo: BookingProductInfo(name: productName)
            ),
            note: ""
        )
    }
}
