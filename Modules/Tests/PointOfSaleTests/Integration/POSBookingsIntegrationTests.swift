// POSBookingsIntegrationTests.swift
import Testing
@testable import PointOfSale
@testable import Yosemite
import class WooFoundation.CurrencyFormatter

@MainActor
struct POSBookingsIntegrationTests {
    @Test func bookings_flow_from_list_to_payment() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100, statusKey: "unpaid")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProvider()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When - Load bookings
        await controller.loadBookings()

        // Then - Bookings loaded
        #expect(controller.state.bookings.count == 1)

        // When - Select booking
        let posBooking = controller.state.bookings.first!
        controller.selectBooking(posBooking)

        // Then - Booking selected and can collect payment
        #expect(controller.selectedBooking != nil)
        #expect(posBooking.canCollectPayment == true)
    }

    @Test func paid_booking_cannot_collect_payment() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100, statusKey: "paid")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProvider()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When
        await controller.loadBookings()

        // Then
        let posBooking = controller.state.bookings.first!
        #expect(posBooking.canCollectPayment == false)
        #expect(posBooking.status == .paid)
    }

    @Test func booking_without_order_shows_no_linked_order_status() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 0, statusKey: "unpaid")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProvider()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When
        await controller.loadBookings()

        // Then
        let posBooking = controller.state.bookings.first!
        #expect(posBooking.status == .noLinkedOrder)
        #expect(posBooking.canCollectPayment == false)
    }

    @Test func cancelled_booking_cannot_collect_payment() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100, statusKey: "cancelled")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProvider()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When
        await controller.loadBookings()

        // Then
        let posBooking = controller.state.bookings.first!
        #expect(posBooking.status == .cancelled)
        #expect(posBooking.canCollectPayment == false)
    }
}
