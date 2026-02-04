// POSBookingListControllerTests.swift
import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite
import class WooFoundation.CurrencyFormatter

@MainActor
struct POSBookingListControllerTests {
    private let bookingService = MockPOSBookingService()
    private let currencySettings = MockPOSCurrencySettingsProvider()

    private func makeSUT() -> POSBookingListController {
        POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )
    }

    @Test func initial_state_is_loading() {
        let sut = makeSUT()
        #expect(sut.state.isLoading)
    }

    @Test func loadBookings_updates_state_to_loaded_with_bookings() async {
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100)
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()

        await sut.loadBookings()

        #expect(sut.state.bookings.count == 1)
        #expect(sut.state.bookings.first?.bookingID == 1)
    }

    @Test func loadBookings_updates_state_to_empty_when_no_bookings() async {
        bookingService.bookingsToReturn = []
        let sut = makeSUT()

        await sut.loadBookings()

        #expect(sut.state == .empty)
    }

    @Test func loadBookings_updates_state_to_error_on_failure() async {
        bookingService.shouldThrowOnFetch = true
        let sut = makeSUT()

        await sut.loadBookings()

        if case .error = sut.state {
            // Expected
        } else {
            Issue.record("Expected error state but got \(sut.state)")
        }
    }

    @Test func selectBooking_updates_selectedBooking() async {
        let booking = MockPOSBookingService.makeBooking()
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()
        await sut.loadBookings()

        sut.selectBooking(sut.state.bookings.first)

        #expect(sut.selectedBooking?.bookingID == booking.bookingID)
    }

    @Test func clearSelection_sets_selectedBooking_to_nil() async {
        let booking = MockPOSBookingService.makeBooking()
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()
        await sut.loadBookings()
        sut.selectBooking(sut.state.bookings.first)

        sut.clearSelection()

        #expect(sut.selectedBooking == nil)
    }
}
