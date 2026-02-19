import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.POSOrder
import enum NetworkingCore.OrderStatusEnum
import struct Yosemite.PagedItems
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus
import struct Yosemite.BookingFilters

@MainActor
final class POSBookingListControllerTests {

    private let siteTimezone = TimeZone(identifier: "America/New_York")!
    private let mockStrategy = MockPOSBookingListFetchStrategy()
    private lazy var mockFactory: MockPOSBookingListFetchStrategyFactory = {
        let factory = MockPOSBookingListFetchStrategyFactory()
        factory.defaultStrategyResult = mockStrategy
        return factory
    }()
    private lazy var sut = POSBookingListController(bookingListFetchStrategyFactory: mockFactory,
                                                     siteTimezone: siteTimezone)

    // MARK: - loadBookings

    @Test func test_loadBookings_results_in_loaded_state() async {
        // Given
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()

        // Then
        #expect(sut.bookingsViewState == .loaded(bookings, hasMoreItems: false))
    }

    @Test func test_loadBookings_when_empty_results_in_empty_state() async {
        // Given
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()

        // Then
        #expect(sut.bookingsViewState == .empty)
    }

    @Test func test_loadBookings_when_error_results_in_error_state() async {
        // Given
        mockStrategy.fetchBookingsResult = .failure(NSError(domain: "test", code: 1))

        // When
        await sut.loadBookings()

        // Then
        guard case .error = sut.bookingsViewState else {
            Issue.record("Expected error state, got \(sut.bookingsViewState)")
            return
        }
    }

    // MARK: - loadNextBookings

    @Test func test_loadNextBookings_appends_to_existing() async {
        // Given
        let firstPage = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: firstPage, hasMorePages: true, totalItems: nil))
        await sut.loadBookings()

        let secondPage = [makeBooking(id: 2)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: secondPage, hasMorePages: false, totalItems: nil))

        // When
        await sut.loadNextBookings()

        // Then
        let allBookings = firstPage + secondPage
        #expect(sut.bookingsViewState == .loaded(allBookings, hasMoreItems: false))
    }

    // MARK: - Duplicate prevention

    @Test func test_loadBookings_when_called_multiple_times_then_bookings_are_not_duplicated() async {
        // Given
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()
        await sut.loadBookings()

        // Then
        #expect(sut.bookingsViewState.bookings.count == 1)
    }

    // MARK: - selectBooking

    @Test func test_selectBooking_updates_selectedBooking() {
        // Given
        let booking = makeBooking(id: 1)

        // When
        sut.selectBooking(booking)

        // Then
        #expect(sut.selectedBooking == booking)
    }

    @Test func test_selectBooking_nil_clears_selectedBooking() {
        // Given
        sut.selectBooking(makeBooking(id: 1))

        // When
        sut.selectBooking(nil)

        // Then
        #expect(sut.selectedBooking == nil)
    }

    // MARK: - searchBookings

    @Test func test_searchBookings_switches_strategy_and_loads() async {
        // Given
        let searchBookings = [makeBooking(id: 10)]
        let searchStrategy = MockPOSBookingListFetchStrategy()
        searchStrategy.fetchBookingsResult = .success(PagedItems(items: searchBookings, hasMorePages: false, totalItems: nil))
        searchStrategy.supportsCaching = false
        searchStrategy.id = "SearchStrategy"
        mockFactory.searchStrategyResult = searchStrategy

        // When
        await sut.searchBookings(searchTerm: "test")

        // Then
        #expect(sut.bookingsViewState == .loaded(searchBookings, hasMoreItems: false))
    }

    // MARK: - clearSearchBookings

    @Test func test_clearSearchBookings_restores_cached_bookings() async {
        // Given - load initial bookings (cached)
        let initialBookings = [makeBooking(id: 1), makeBooking(id: 2)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: initialBookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        // Switch to search
        let searchStrategy = MockPOSBookingListFetchStrategy()
        searchStrategy.fetchBookingsResult = .success(PagedItems(items: [makeBooking(id: 10)], hasMorePages: false, totalItems: nil))
        searchStrategy.supportsCaching = false
        searchStrategy.id = "SearchStrategy"
        mockFactory.searchStrategyResult = searchStrategy
        await sut.searchBookings(searchTerm: "test")

        // When
        sut.clearSearchBookings()

        // Then - should restore cached bookings
        #expect(sut.bookingsViewState == .loaded(initialBookings, hasMoreItems: true))
    }

    // MARK: - updateAttendanceStatus

    @Test func test_updateAttendanceStatus_calls_service_and_refreshes_bookings() async throws {
        // Given
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        let mockService = mockFactory.bookingService as! MockPOSBookingService

        // When
        try await sut.updateAttendanceStatus(bookingID: 1, status: .attended)

        // Then
        #expect(mockService.updateAttendanceCallCount == 1)
        #expect(mockService.lastUpdatedAttendanceBookingID == 1)
        #expect(mockService.lastUpdatedAttendanceStatus == .attended)
        // Verify bookings were refreshed (loadBookings was called)
        #expect(sut.bookingsViewState == .loaded(bookings, hasMoreItems: false))
    }

    @Test func test_updateAttendanceStatus_when_service_throws_then_throws_error() async {
        // Given
        let mockService = mockFactory.bookingService as! MockPOSBookingService
        mockService.updateAttendanceError = NSError(domain: "test", code: 1)

        // When/Then
        do {
            try await sut.updateAttendanceStatus(bookingID: 1, status: .attended)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(mockService.updateAttendanceCallCount == 1)
        }
    }

    // MARK: - Caching

    @Test func test_loadBookings_uses_cached_data_on_reload() async {
        // Given - load initial bookings
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        // When - reload
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        // Then - should still have the bookings
        #expect(sut.bookingsViewState.bookings == bookings)
    }

    // MARK: - Date Navigation

    @Test func test_selectedDate_defaults_to_today_in_site_timezone() {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        let expectedStartOfDay = calendar.startOfDay(for: Date())

        // Then
        #expect(sut.selectedDate == expectedStartOfDay)
    }

    @Test func test_selectDate_updates_selectedDate_and_reloads() async {
        // Given
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // When
        await sut.selectDate(tomorrow)

        // Then
        #expect(sut.selectedDate == tomorrow)
    }

    @Test func test_goToNextDay_advances_date_by_one_day() async {
        // Given
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
        await sut.loadBookings()
        let initialDate = sut.selectedDate

        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: initialDate)!

        // When
        await sut.goToNextDay()

        // Then
        #expect(sut.selectedDate == expectedNextDay)
    }

    @Test func test_goToPreviousDay_goes_back_one_day() async {
        // Given
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
        await sut.loadBookings()
        let initialDate = sut.selectedDate

        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: initialDate)!

        // When
        await sut.goToPreviousDay()

        // Then
        #expect(sut.selectedDate == expectedPreviousDay)
    }

    @Test func test_dateFilters_generates_correct_day_boundaries() {
        // Given
        let utcTimezone = TimeZone(identifier: "UTC")!
        let controller = POSBookingListController(bookingListFetchStrategyFactory: mockFactory,
                                                   siteTimezone: utcTimezone)

        var calendar = Calendar.current
        calendar.timeZone = utcTimezone
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!

        // When
        let filters = controller.dateFilters(for: date)

        // Then
        #expect(filters.startDateAfter == "2026-03-15T00:00:00Z")
        #expect(filters.startDateBefore == "2026-03-15T23:59:59Z")
    }

    @Test func test_dateFilters_with_positive_offset_timezone() {
        // Given - Tokyo is UTC+9
        let tokyoTimezone = TimeZone(identifier: "Asia/Tokyo")!
        let controller = POSBookingListController(bookingListFetchStrategyFactory: mockFactory,
                                                   siteTimezone: tokyoTimezone)

        var calendar = Calendar.current
        calendar.timeZone = tokyoTimezone
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20))!

        // When
        let filters = controller.dateFilters(for: date)

        // Then
        #expect(filters.startDateAfter == "2026-06-20T00:00:00+09:00")
        #expect(filters.startDateBefore == "2026-06-20T23:59:59+09:00")
    }

    @Test func test_selectDate_clears_cache_and_shows_loading() async {
        // Given - load bookings for initial date
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // When
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
        await sut.selectDate(tomorrow)

        // Then - cache was cleared, new date shows empty
        #expect(sut.bookingsViewState == .empty)
    }
}

// MARK: - Helpers

private extension POSBookingListControllerTests {
    func makeBooking(id: Int64) -> POSBooking {
        POSBooking(
            id: id,
            customerName: "Customer \(id)",
            serviceName: "Service \(id)",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            formattedAmount: "$50.00",
            status: .confirmed,
            attendanceStatus: .unattended,
            orderID: id * 10,
            resourceName: nil,
            order: makeOrder(id: id * 10)
        )
    }

    func makeOrder(id: Int64) -> POSOrder {
        POSOrder(
            id: id,
            number: "\(id)",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$50.00",
            formattedSubtotal: "$50.00",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$50.00",
            datePaid: Date()
        )
    }
}
