import Testing
import Foundation
@testable import Yosemite
import struct NetworkingCore.PagedItems
import enum NetworkingCore.OrderStatusEnum

@MainActor
struct POSDefaultBookingListFetchStrategyTests {

    private let siteID: Int64 = 123
    private let filters = BookingFilters(startDateBefore: "2026-03-15T23:59:59Z", startDateAfter: "2026-03-15T00:00:00Z")
    private let dateRange = POSBookingInMemoryStore.DateRange(
        startDateAfter: "2026-03-15T00:00:00Z",
        startDateBefore: "2026-03-15T23:59:59Z"
    )

    // MARK: - fetchBookings

    @Test func test_fetchBookings_page1_replaces_stored_bookings() async throws {
        // Given
        let store = POSBookingInMemoryStore()
        let mockService = MockBookingService()
        let strategy = makeStrategy(service: mockService, store: store)

        store.replaceBookings([makeBooking(id: 99)], for: dateRange)

        let newBookings = [makeBooking(id: 1), makeBooking(id: 2)]
        mockService.fetchBookingsResult = .success(PagedItems(items: newBookings, hasMorePages: false, totalItems: nil))

        // When
        let result = try await strategy.fetchBookings(pageNumber: 1)

        // Then
        #expect(result.items == newBookings)
        #expect(store.allBookings(for: dateRange) == newBookings)
    }

    @Test func test_fetchBookings_page2_appends_to_stored_bookings() async throws {
        // Given
        let store = POSBookingInMemoryStore()
        let mockService = MockBookingService()
        let strategy = makeStrategy(service: mockService, store: store)

        store.replaceBookings([makeBooking(id: 1)], for: dateRange)

        let page2 = [makeBooking(id: 2)]
        mockService.fetchBookingsResult = .success(PagedItems(items: page2, hasMorePages: false, totalItems: nil))

        // When
        let result = try await strategy.fetchBookings(pageNumber: 2)

        // Then
        #expect(result.items.map(\.id) == [1, 2])
        #expect(store.allBookings(for: dateRange).map(\.id) == [1, 2])
    }

    @Test func test_fetchBookings_page2_deduplicates_by_id() async throws {
        // Given
        let store = POSBookingInMemoryStore()
        let mockService = MockBookingService()
        let strategy = makeStrategy(service: mockService, store: store)

        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2)], for: dateRange)

        mockService.fetchBookingsResult = .success(
            PagedItems(items: [makeBooking(id: 2), makeBooking(id: 3)], hasMorePages: false, totalItems: nil)
        )

        // When
        let result = try await strategy.fetchBookings(pageNumber: 2)

        // Then
        #expect(result.items.map(\.id) == [1, 2, 3])
    }

    @Test func test_fetchBookings_when_filters_nil_then_returns_empty_without_calling_service() async throws {
        // Given
        let mockService = MockBookingService()
        let strategy = POSDefaultBookingListFetchStrategy(
            bookingService: mockService,
            store: POSBookingInMemoryStore(),
            siteID: siteID,
            filters: nil
        )

        // When
        let result = try await strategy.fetchBookings(pageNumber: 1)

        // Then
        #expect(result.items.isEmpty)
        #expect(mockService.fetchBookingsCallCount == 0)
    }

    @Test func test_fetchBookings_propagates_hasMorePages() async throws {
        // Given
        let mockService = MockBookingService()
        let strategy = makeStrategy(service: mockService)

        mockService.fetchBookingsResult = .success(PagedItems(items: [makeBooking(id: 1)], hasMorePages: true, totalItems: nil))

        // When
        let result = try await strategy.fetchBookings(pageNumber: 1)

        // Then
        #expect(result.hasMorePages == true)
    }

    @Test func test_fetchBookings_when_service_throws_then_propagates_error() async {
        // Given
        let mockService = MockBookingService()
        let strategy = makeStrategy(service: mockService)

        mockService.fetchBookingsResult = .failure(NSError(domain: "test", code: 42))

        // When/Then
        do {
            _ = try await strategy.fetchBookings(pageNumber: 1)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    @Test func test_fetchBookings_passes_correct_parameters_to_service() async throws {
        // Given
        let mockService = MockBookingService()
        let strategy = POSDefaultBookingListFetchStrategy(
            bookingService: mockService,
            store: POSBookingInMemoryStore(),
            siteID: siteID,
            filters: filters,
            pageSize: 15
        )
        mockService.fetchBookingsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))

        // When
        _ = try await strategy.fetchBookings(pageNumber: 3)

        // Then
        #expect(mockService.lastSiteID == siteID)
        #expect(mockService.lastPageNumber == 3)
        #expect(mockService.lastPageSize == 15)
        #expect(mockService.lastFilters?.startDateAfter == filters.startDateAfter)
        #expect(mockService.lastSearchQuery == nil)
    }

    // MARK: - fetchLocalBookings

    @Test func test_fetchLocalBookings_returns_stored_bookings_limited_by_pageSize() {
        // Given
        let store = POSBookingInMemoryStore()
        let strategy = POSDefaultBookingListFetchStrategy(
            bookingService: MockBookingService(),
            store: store,
            siteID: siteID,
            filters: filters,
            pageSize: 2
        )

        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2), makeBooking(id: 3)], for: dateRange)

        // When
        let result = strategy.fetchLocalBookings()

        // Then
        #expect(result.count == 2)
        #expect(result.map(\.id) == [1, 2])
    }

    @Test func test_fetchLocalBookings_returns_empty_when_no_stored_data() {
        // Given
        let strategy = makeStrategy()

        // When
        let result = strategy.fetchLocalBookings()

        // Then
        #expect(result.isEmpty)
    }

    @Test func test_fetchLocalBookings_when_filters_nil_then_returns_empty() {
        // Given
        let store = POSBookingInMemoryStore()
        let strategy = POSDefaultBookingListFetchStrategy(
            bookingService: MockBookingService(),
            store: store,
            siteID: siteID,
            filters: nil
        )
        store.replaceBookings([makeBooking(id: 1)], for: dateRange)

        // When
        let result = strategy.fetchLocalBookings()

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - Cross-date isolation

    @Test func test_different_dates_do_not_share_data() {
        // Given
        let store = POSBookingInMemoryStore()
        let filtersA = BookingFilters(startDateBefore: "2026-03-15T23:59:59Z", startDateAfter: "2026-03-15T00:00:00Z")
        let filtersB = BookingFilters(startDateBefore: "2026-03-16T23:59:59Z", startDateAfter: "2026-03-16T00:00:00Z")
        let dateRangeA = POSBookingInMemoryStore.DateRange(startDateAfter: "2026-03-15T00:00:00Z", startDateBefore: "2026-03-15T23:59:59Z")

        let strategyA = POSDefaultBookingListFetchStrategy(bookingService: MockBookingService(), store: store, siteID: siteID, filters: filtersA)
        let strategyB = POSDefaultBookingListFetchStrategy(bookingService: MockBookingService(), store: store, siteID: siteID, filters: filtersB)

        store.replaceBookings([makeBooking(id: 1)], for: dateRangeA)

        // When/Then
        #expect(strategyA.fetchLocalBookings().count == 1)
        #expect(strategyB.fetchLocalBookings().isEmpty)
    }

    // MARK: - Prefetch flow

    @Test func test_prefetch_stores_data_that_fetchLocal_returns() async throws {
        // Given
        let store = POSBookingInMemoryStore()
        let mockService = MockBookingService()
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]
        mockService.fetchBookingsResult = .success(PagedItems(items: bookings, hasMorePages: false, totalItems: nil))

        // Prefetch with one strategy instance
        let prefetchStrategy = POSDefaultBookingListFetchStrategy(
            bookingService: mockService, store: store, siteID: siteID, filters: filters
        )
        _ = try await prefetchStrategy.fetchBookings(pageNumber: 1)

        // When - a new strategy instance with same filters reads local data
        let readStrategy = POSDefaultBookingListFetchStrategy(
            bookingService: mockService, store: store, siteID: siteID, filters: filters
        )

        // Then
        #expect(readStrategy.fetchLocalBookings() == bookings)
    }

    // MARK: - Properties

    @Test func test_showsCachedDataWhileLoading_is_true() {
        #expect(makeStrategy().showsCachedDataWhileLoading == true)
    }

    @Test func test_id_includes_startDateAfter() {
        let strategy = makeStrategy()
        #expect(strategy.id == "POSDefaultBookingListFetchStrategy-2026-03-15T00:00:00Z")
    }

    @Test func test_id_when_no_filters_then_includes_none() {
        let strategy = POSDefaultBookingListFetchStrategy(
            bookingService: MockBookingService(),
            store: POSBookingInMemoryStore(),
            siteID: siteID,
            filters: nil
        )
        #expect(strategy.id == "POSDefaultBookingListFetchStrategy-none")
    }
}

// MARK: - Mock

private final class MockBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    var fetchBookingsResult: Result<PagedItems<POSBooking>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
    var fetchBookingsCallCount = 0
    var lastSiteID: Int64?
    var lastPageNumber: Int?
    var lastPageSize: Int?
    var lastFilters: BookingFilters?
    var lastSearchQuery: String?

    func fetchBookings(siteID: Int64,
                       pageNumber: Int,
                       pageSize: Int,
                       filters: BookingFilters?,
                       searchQuery: String?) async throws -> PagedItems<POSBooking> {
        fetchBookingsCallCount += 1
        lastSiteID = siteID
        lastPageNumber = pageNumber
        lastPageSize = pageSize
        lastFilters = filters
        lastSearchQuery = searchQuery
        return try fetchBookingsResult.get()
    }

    func fetchBooking(bookingID: Int64) async throws -> POSBooking {
        throw NSError(domain: "MockBookingService", code: 0)
    }

    func cancelBooking(bookingID: Int64) async throws -> BookingStatus {
        .cancelled
    }

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws -> BookingAttendanceStatus {
        status
    }

    func updateBookingNote(bookingID: Int64, note: String) async throws -> String {
        note
    }
}

// MARK: - Helpers

private extension POSDefaultBookingListFetchStrategyTests {
    func makeStrategy(service: MockBookingService = MockBookingService(),
                      store: POSBookingInMemoryStore? = nil) -> POSDefaultBookingListFetchStrategy {
        let resolvedStore = store ?? POSBookingInMemoryStore()
        return POSDefaultBookingListFetchStrategy(
            bookingService: service,
            store: resolvedStore,
            siteID: siteID,
            filters: filters
        )
    }

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
            order: POSOrder(
                id: id * 10,
                number: "\(id * 10)",
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
        )
    }
}
