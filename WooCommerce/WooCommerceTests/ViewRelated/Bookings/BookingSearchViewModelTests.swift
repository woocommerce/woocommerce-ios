import Combine
import Foundation
import Testing
import Yosemite
@testable import WooCommerce
@testable import Networking

@MainActor
struct BookingSearchViewModelTests {

    private let sampleSiteID: Int64 = 322

    // MARK: - Search query subscription

    @Test func search_query_updates_from_publisher() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher()
        )

        // When
        searchQuerySubject.send("test query")

        // Wait for the publisher to propagate (no debounce on assignment)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        #expect(viewModel.currentSearchQuery == "test query")
    }

    // MARK: - Search action

    @Test func search_bookings_is_dispatched_when_query_is_not_empty() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCount = 0
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, _, onCompletion) = action else {
                return
            }
            invocationCount += 1
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When
        searchQuerySubject.send("test query")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(invocationCount == 1)
    }

    @Test func search_bookings_passes_correct_search_query() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedSearchQuery: String?
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, searchQuery, _, _, _, _, onCompletion) = action else {
                return
            }
            capturedSearchQuery = searchQuery
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When
        searchQuerySubject.send("my test query")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedSearchQuery == "my test query")
    }

    @Test func search_results_are_updated_on_successful_search() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 1, startDate: Date())
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 2, startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success([booking1, booking2]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(viewModel.searchResults.count == 2)
        #expect(viewModel.searchResults.contains { $0.bookingID == booking1.bookingID })
        #expect(viewModel.searchResults.contains { $0.bookingID == booking2.bookingID })
    }

    @Test func error_fetching_is_true_on_search_failure() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.failure(NSError(domain: "test", code: 1)))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(viewModel.errorFetching == true)
    }

    // MARK: - Pagination

    @Test func on_load_next_page_action_loads_next_page() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedPageNumbers: [Int] = []

        // First page returns exactly pageSize (25) items to indicate there's a next page
        let firstPageBookings = (1...25).map { Booking.fake().copy(siteID: sampleSiteID, bookingID: Int64($0), startDate: Date()) }
        let secondPageBookings = [Booking.fake().copy(siteID: sampleSiteID, bookingID: 26, startDate: Date())]

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, pageNumber, _, _, _, onCompletion) = action else {
                return
            }
            capturedPageNumbers.append(pageNumber)
            let bookings = pageNumber == 1 ? firstPageBookings : secondPageBookings
            onCompletion(.success(bookings))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.searchResults.count == 25, "First page should have 25 results")

        viewModel.onLoadNextPageAction()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(capturedPageNumbers == [1, 2])
        #expect(viewModel.searchResults.count == 26, "Should have 26 results total (25 from page 1 + 1 from page 2)")
    }

    @Test func search_results_are_cleared_on_new_search() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let firstSearchBookings = [Booking.fake().copy(siteID: sampleSiteID, bookingID: 1, startDate: Date())]
        let secondSearchBookings = [Booking.fake().copy(siteID: sampleSiteID, bookingID: 2, startDate: Date())]
        var searchCount = 0

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, _, onCompletion) = action else {
                return
            }
            searchCount += 1
            let bookings = searchCount == 1 ? firstSearchBookings : secondSearchBookings
            onCompletion(.success(bookings))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When - first search
        searchQuerySubject.send("test1")
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.searchResults.first?.bookingID == 1)

        // Second search
        searchQuerySubject.send("test2")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then - results should be replaced, not appended
        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.searchResults.first?.bookingID == 2)
    }

    // MARK: - Type-based filtering

    @Test func today_tab_passes_correct_date_filters_to_search_action() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .today,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z", "Today tab should filter after start of day")
        #expect(capturedFilters?.startDateBefore == "2021-01-02T00:00:00Z", "Today tab should filter before end of day")
    }

    @Test func upcoming_tab_passes_correct_date_filters_to_search_action() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .upcoming,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateBefore == nil, "Upcoming tab should not have startDateBefore filter")
        #expect(capturedFilters?.startDateAfter == "2021-01-01T23:59:59Z", "Upcoming tab should filter after end of day")
    }

    @Test func all_tab_passes_no_date_filters_to_search_action() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        // When
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateBefore == nil, "All tab should not have startDateBefore filter")
        #expect(capturedFilters?.startDateAfter == nil, "All tab should not have startDateAfter filter")
    }

    // MARK: - Filter merging

    @Test func today_tab_merges_user_date_filters_with_tab_constraints() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .today,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatus: nil,
            customers: [],
            dateRange: BookingDateRangeFilter(
                startDate: Date(timeIntervalSince1970: 1609416000), // 2020-12-31T12:00:00Z
                endDate: Date(timeIntervalSince1970: 1609524000)    // 2021-01-01T18:00:00Z
            ),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z",
                "Should use tab's startDateAfter since it's later")
        #expect(capturedFilters?.startDateBefore == "2021-01-01T18:00:00Z",
                "Should use user's startDateBefore since it's earlier")
    }

    @Test func upcoming_tab_merges_user_date_filters_with_tab_constraints() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .upcoming,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatus: nil,
            customers: [],
            dateRange: BookingDateRangeFilter(
                startDate: Date(timeIntervalSince1970: 1609632000), // 2021-01-03T00:00:00Z
                endDate: Date(timeIntervalSince1970: 1609804800)    // 2021-01-05T00:00:00Z
            ),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateAfter == "2021-01-03T00:00:00Z",
                "Should use user's startDateAfter since it's later")
        #expect(capturedFilters?.startDateBefore == "2021-01-05T00:00:00Z",
                "Should use user's startDateBefore since tab has no upper bound")
    }

    @Test func all_tab_passes_user_date_filters_through_unchanged() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        let userStartDate = Date(timeIntervalSince1970: 1609632000)
        let userEndDate = Date(timeIntervalSince1970: 1609804800)
        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatus: nil,
            customers: [],
            dateRange: BookingDateRangeFilter(startDate: userStartDate, endDate: userEndDate),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.startDateAfter == userStartDate.ISO8601Format())
        #expect(capturedFilters?.startDateBefore == userEndDate.ISO8601Format())
    }

    @Test func non_date_filters_pass_through_on_today_tab() async throws {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, filters, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .today,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores,
            currentDate: testDate
        )

        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 42, name: "Alice")],
            products: [BookingProductFilter(productID: 100, name: "Massage")],
            attendanceStatus: .attended,
            customers: [BookingCustomerFilter(customerID: 7, name: "Bob")],
            dateRange: nil,
            numberOfActiveFilters: 4
        )

        // When
        viewModel.updateFilters(userFilters)
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedFilters?.resourceIDs == [42])
        #expect(capturedFilters?.productIDs == [100])
        #expect(capturedFilters?.attendanceStatus == BookingAttendanceStatus.attended.rawValue)
        #expect(capturedFilters?.customerIDs == [7])
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z")
        #expect(capturedFilters?.startDateBefore == "2021-01-02T00:00:00Z")
    }

    // MARK: - Refresh action

    @Test func on_refresh_action_resyncs_search_results() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var searchCount = 0

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, _, onCompletion) = action else {
                return
            }
            searchCount += 1
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When - initial search
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(searchCount == 1)

        // Refresh
        await viewModel.onRefreshAction()

        // Then
        #expect(searchCount == 2, "Should have searched twice")
    }

    // MARK: - Sort order

    @Test func update_sort_order_triggers_new_search_with_ascending_order() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedOrder: BookingsRemote.Order?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, order, onCompletion) = action else {
                return
            }
            capturedOrder = order
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // Setup initial search
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // When
        viewModel.updateSortOrder(.oldestToNewest)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(capturedOrder == .ascending, "Should search with ascending order")
    }

    @Test func update_sort_order_triggers_new_search_with_descending_order() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedOrder: BookingsRemote.Order?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, order, onCompletion) = action else {
                return
            }
            capturedOrder = order
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // Setup initial search
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // When
        viewModel.updateSortOrder(.newestToOldest)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(capturedOrder == .descending, "Should search with descending order")
    }

    @Test func update_sort_order_does_not_trigger_search_when_query_is_empty() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var searchCount = 0

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case .searchBookings = action else {
                return
            }
            searchCount += 1
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When - update sort order without any search query
        viewModel.updateSortOrder(.oldestToNewest)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(searchCount == 0, "Should not trigger search when query is empty")
    }

    @Test func update_sort_order_uses_current_sort_for_subsequent_searches() async throws {
        // Given
        let searchQuerySubject = PassthroughSubject<String, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedOrders: [BookingsRemote.Order] = []

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .searchBookings(_, _, _, _, _, order, onCompletion) = action else {
                return
            }
            capturedOrders.append(order)
            onCompletion(.success([]))
        }

        let viewModel = BookingSearchViewModel(
            siteID: sampleSiteID,
            type: .all,
            searchQueryPublisher: searchQuerySubject.eraseToAnyPublisher(),
            stores: stores
        )

        // When - first search with default order
        searchQuerySubject.send("test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Update sort order
        viewModel.updateSortOrder(.oldestToNewest)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Second search should use updated sort order
        searchQuerySubject.send("another test")
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then
        #expect(capturedOrders.count == 3, "Should have three searches")
        #expect(capturedOrders[0] == .descending, "First search uses default descending order")
        #expect(capturedOrders[1] == .ascending, "Second search from updateSortOrder uses ascending")
        #expect(capturedOrders[2] == .ascending, "Third search should maintain ascending order")
    }
}
