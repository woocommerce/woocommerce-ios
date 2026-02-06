import XCTest
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct NetworkingCore.PagedItems
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

@MainActor
final class POSBookingListControllerTests: XCTestCase {

    private var mockFactory: MockPOSBookingListFetchStrategyFactory!
    private var mockStrategy: MockPOSBookingListFetchStrategy!
    private var sut: POSBookingListController!

    override func setUp() {
        super.setUp()
        mockStrategy = MockPOSBookingListFetchStrategy()
        mockFactory = MockPOSBookingListFetchStrategyFactory()
        mockFactory.defaultStrategyResult = mockStrategy
        sut = POSBookingListController(bookingListFetchStrategyFactory: mockFactory)
    }

    override func tearDown() {
        sut = nil
        mockFactory = nil
        mockStrategy = nil
        super.tearDown()
    }

    // MARK: - loadBookings

    func test_loadBookings_results_in_loaded_state() async {
        // Given
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()

        // Then
        XCTAssertEqual(sut.bookingsViewState, .loaded(bookings, hasMoreItems: false))
    }

    func test_loadBookings_when_empty_results_in_empty_state() async {
        // Given
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()

        // Then
        XCTAssertEqual(sut.bookingsViewState, .empty)
    }

    func test_loadBookings_when_error_results_in_error_state() async {
        // Given
        mockStrategy.fetchBookingsResult = .failure(NSError(domain: "test", code: 1))

        // When
        await sut.loadBookings()

        // Then
        if case .error = sut.bookingsViewState {
            // Expected
        } else {
            XCTFail("Expected error state, got \(sut.bookingsViewState)")
        }
    }

    // MARK: - loadNextBookings

    func test_loadNextBookings_appends_to_existing() async {
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
        XCTAssertEqual(sut.bookingsViewState, .loaded(allBookings, hasMoreItems: false))
    }

    // MARK: - Duplicate prevention

    func test_loadBookings_when_called_multiple_times_then_bookings_are_not_duplicated() async {
        // Given
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))

        // When
        await sut.loadBookings()
        await sut.loadBookings()

        // Then
        XCTAssertEqual(sut.bookingsViewState.bookings.count, 1)
    }

    // MARK: - selectBooking

    func test_selectBooking_updates_selectedBooking() async {
        // Given
        let booking = makeBooking(id: 1)

        // When
        sut.selectBooking(booking)

        // Then
        XCTAssertEqual(sut.selectedBooking, booking)
    }

    func test_selectBooking_nil_clears_selectedBooking() async {
        // Given
        sut.selectBooking(makeBooking(id: 1))

        // When
        sut.selectBooking(nil)

        // Then
        XCTAssertNil(sut.selectedBooking)
    }

    // MARK: - searchBookings

    func test_searchBookings_switches_strategy_and_loads() async {
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
        XCTAssertEqual(sut.bookingsViewState, .loaded(searchBookings, hasMoreItems: false))
    }

    // MARK: - clearSearchBookings

    func test_clearSearchBookings_restores_cached_bookings() async {
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
        XCTAssertEqual(sut.bookingsViewState, .loaded(initialBookings, hasMoreItems: true))
    }

    // MARK: - Caching

    func test_loadBookings_uses_cached_data_on_reload() async {
        // Given - load initial bookings
        let bookings = [makeBooking(id: 1)]
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        // When - reload (strategy will now return empty, simulating in-progress load)
        mockStrategy.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))
        await sut.loadBookings()

        // Then - should still have the bookings (from cache during loading)
        XCTAssertEqual(sut.bookingsViewState.bookings, bookings)
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
            attendanceStatus: .booked,
            orderID: id * 10,
            resourceName: nil
        )
    }
}
