import Combine
import Foundation
import Testing
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce
@testable import Networking

@MainActor
class BookingListViewModelTests {

    private let sampleSiteID: Int64 = 322
    private let analyticsProvider = MockAnalyticsProvider()
    private lazy var analytics: WooAnalytics = WooAnalytics(analyticsProvider: self.analyticsProvider)
    private let stores = MockStoresManager(sessionManager: .testingInstance)

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    init() {
        storageManager = MockStorageManager()
    }

    // MARK: - State transitions

    @Test func state_is_empty_without_any_actions() {
        // Given
        var invocationCountOfLoadBookings = 0
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case .synchronizeBookings = action else {
                return
            }
            invocationCountOfLoadBookings += 1
        }
        let viewModel = givenViewModel()

        // Then
        #expect(viewModel.syncState == .empty)
        #expect(invocationCountOfLoadBookings == 0)
    }

    @Test func synchronize_bookings_is_dispatched_upon_load_bookings() {
        // Given
        var invocationCountOfLoadBookings = 0
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case .synchronizeBookings = action else {
                return
            }
            invocationCountOfLoadBookings += 1
        }
        let viewModel = givenViewModel()

        // When
        viewModel.loadBookings()

        // Then
        #expect(invocationCountOfLoadBookings == 1)
    }

    @Test func event_fires_when_load_bookings_fail() {
        // Given
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            onCompletion(.failure(MockError.anyError))
        }
        let viewModel = givenViewModel()

        // When
        viewModel.loadBookings()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_failed_to_fetch_bookings"))
    }

    @Test func state_is_syncing_first_page_upon_load_bookings_if_no_existing_booking_in_storage() {
        // Given
        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.syncState == .syncingFirstPage)
    }

    @Test func state_is_results_upon_load_bookings_if_existing_bookings_in_storage() {
        let existingBooking = createBooking(id: 123, startDate: Date())
        insertBookings([existingBooking])
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: MockStoresManager(sessionManager: .testingInstance),
                                             storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.syncState == .results)
    }

    @Test func state_is_results_after_load_bookings_with_nonempty_results() async {
        // Given
        let booking = createBooking(id: 1, startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            self.insertBookings([booking])
            onCompletion(.success(true))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        var states = [BookingListViewModel.SyncState]()
        await confirmation("State transitions") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadBookings()
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .results])
    }

    @Test func state_is_back_to_empty_after_load_bookings_with_empty_results() async {
        // Given
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            onCompletion(.success(true))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        var states = [BookingListViewModel.SyncState]()
        await confirmation("State transitions") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadBookings()
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .empty])
    }

    @Test func it_loads_next_page_after_load_bookings_and_on_load_next_page_action_until_has_next_page_is_false() async {
        // Given
        var invocationCountOfLoadBookings = 0
        let firstPageItems = (1...2).map { createBooking(id: Int64($0), startDate: Date()) }
        let secondPageItems = [createBooking(id: 3, startDate: Date())]
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, pageNumber, _, _, _, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadBookings += 1
            let bookings = pageNumber == 1 ? firstPageItems: secondPageItems
            self.insertBookings(bookings)
            onCompletion(.success(pageNumber == 1 ? true : false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        var states = [BookingListViewModel.SyncState]()
        await confirmation("State transitions") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadBookings() // Syncs first page of bookings.
            viewModel.onLoadNextPageAction() // Syncs next page of bookings.
            viewModel.onLoadNextPageAction() // No more data to be synced.
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .results])
        #expect(invocationCountOfLoadBookings == 2)
    }

    // MARK: - Row view models

    @Test func booking_models_match_loaded_bookings() {
        // Given
        let booking1 = createBooking(id: 9, startDate: Date())
        let booking2 = createBooking(id: 10, startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            self.insertBookings([booking1, booking2])
            onCompletion(.success(true))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then
        // ensure that the items are sorted correctly by dateCreated (descending)
        #expect(viewModel.bookings.count == 2)
        #expect(viewModel.bookings.contains { $0.bookingID == booking1.bookingID })
        #expect(viewModel.bookings.contains { $0.bookingID == booking2.bookingID })
    }

    @Test func booking_models_are_empty_when_loaded_bookings_are_empty() {
        // Given
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.bookings == [])
    }

    @Test func booking_models_are_sorted_by_date_created() {
        // Given
        let olderBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 1, dateCreated: Date(timeIntervalSince1970: 1000), startDate: Date())
        let newerBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 3, dateCreated: Date(timeIntervalSince1970: 2000), startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            let items = [olderBooking, newerBooking]
            self.insertBookings(items)
            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then bookings are sorted by descending dateCreated
        #expect(viewModel.bookings.count == 2)
        #expect(viewModel.bookings[0].bookingID == newerBooking.bookingID)
        #expect(viewModel.bookings[1].bookingID == olderBooking.bookingID)
    }

    // MARK: - `onRefreshAction`

    @Test func on_refresh_action_resyncs_the_first_page() async {
        // Given
        var invocationCountOfLoadBookings = 0
        var skip: Int?
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, pageNumber, pageSize, _, _, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadBookings += 1
            skip = pageNumber > 1 ? pageSize * (pageNumber - 1) : 0

            onCompletion(.success(false))
        }
        let viewModel = givenViewModel()

        // When
        await viewModel.reloadData()

        // Then
        #expect(skip == 0)
        #expect(invocationCountOfLoadBookings == 1)
    }

    // MARK: - Type-based filtering

    @Test func today_tab_passes_correct_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .today, stores: stores, currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z", "Today tab should filter after start of day")
        #expect(capturedFilters?.startDateBefore == "2021-01-02T00:00:00Z", "Today tab should filter before end of day")
    }

    @Test func upcoming_tab_passes_correct_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .upcoming,
                                             stores: stores,
                                             currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedFilters?.startDateBefore == nil, "Upcoming tab should not have startDateBefore filter")
        #expect(capturedFilters?.startDateAfter == "2021-01-01T23:59:59Z", "Upcoming tab should filter after end of day")
    }

    @Test func all_tab_passes_no_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores, currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedFilters?.startDateBefore == nil, "All tab should not have startDateBefore filter")
        #expect(capturedFilters?.startDateAfter == nil, "All tab should not have startDateAfter filter")
    }

    // MARK: - Cache clearing logic

    @Test func load_bookings_does_not_clear_cache() {
        // Given
        var capturedShouldClearCache: Bool?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, shouldClearCache, onCompletion) = action else {
                return
            }
            capturedShouldClearCache = shouldClearCache
            onCompletion(.success(false))
        }

        let viewModel = givenViewModel()

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedShouldClearCache == false, "Initial load should not clear cache")
    }

    @Test func on_load_next_page_action_does_not_clear_cache() {
        // Given
        var capturedShouldClearCache: Bool?
        var actionCallCount = 0

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, shouldClearCache, onCompletion) = action else {
                return
            }
            actionCallCount += 1
            capturedShouldClearCache = shouldClearCache
            onCompletion(.success(actionCallCount == 1)) // First call has next page, second doesn't
        }

        let viewModel = givenViewModel()

        // When
        viewModel.loadBookings() // First page
        viewModel.onLoadNextPageAction() // Next page

        // Then
        #expect(capturedShouldClearCache == false, "Load next page should not clear cache")
        #expect(actionCallCount == 2, "Should have made two API calls")
    }

    @Test func on_refresh_action_calls_refreshcoordiantor() async {
        // Given
        let mockRefresher = MockBookingListsRefreshCoordinating()
        let viewModel = givenViewModel()
        viewModel.refreshCoordinator = mockRefresher

        // When
        await viewModel.onRefreshAction()

        // Then
        #expect(mockRefresher.refreshAllListsCalled)
    }

    // MARK: - Local storage filtering

    @Test func today_tab_results_controller_filters_local_storage_correctly() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let todayStart = testDate.startOfDay(timezone: BookingListTab.utcTimeZone)
        let nextDayStart = testDate.endOfDay(timezone: BookingListTab.utcTimeZone).addingTimeInterval(1)

        // Create bookings with different start dates
        let atStartOfDayBooking = createBooking(id: 1, startDate: todayStart) // Exactly at start
        let withinTodayBooking = createBooking(id: 2, startDate: todayStart.addingTimeInterval(3600)) // 1 hour after start
        let beforeTodayBooking = createBooking(id: 3, startDate: todayStart.addingTimeInterval(-3600)) // 1 hour before start
        let afterTodayBooking = createBooking(id: 4, startDate: nextDayStart.addingTimeInterval(3600)) // 1 hour after end
        let startOfNextDayBooking = createBooking(id: 5, startDate: nextDayStart) // First second of next day

        insertBookings([withinTodayBooking, beforeTodayBooking, afterTodayBooking, atStartOfDayBooking, startOfNextDayBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .today,
                                             stores: MockStoresManager(sessionManager: .testingInstance),
                                             storage: storageManager,
                                             currentDate: testDate)

        // When/Then - should only show bookings within today (startDate >= start AND startDate <= end)
        #expect(viewModel.bookings.count == 3)
        let bookingIDs = viewModel.bookings.map({ $0.bookingID })
        #expect(bookingIDs.contains(withinTodayBooking.bookingID))
        #expect(bookingIDs.contains(atStartOfDayBooking.bookingID))
        #expect(bookingIDs.contains(startOfNextDayBooking.bookingID))
    }

    @Test func upcoming_tab_results_controller_filters_local_storage_correctly() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let todayEnd = testDate.endOfDay(timezone: BookingListTab.utcTimeZone)

        // Create bookings with different start dates
        let afterTodayBooking1 = createBooking(id: 1, startDate: todayEnd.addingTimeInterval(3600)) // 1 hour after end
        let afterTodayBooking2 = createBooking(id: 2, startDate: todayEnd.addingTimeInterval(86400)) // 1 day after end
        let withinTodayBooking = createBooking(id: 3, startDate: todayEnd.addingTimeInterval(-3600)) // 1 hour before end
        let beforeTodayBooking = createBooking(id: 4, startDate: testDate.addingTimeInterval(-86400)) // 1 day before
        let atEndOfDayBooking = createBooking(id: 5, startDate: todayEnd) // Exactly at end

        insertBookings([afterTodayBooking1, afterTodayBooking2, withinTodayBooking, beforeTodayBooking, atEndOfDayBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .upcoming,
                                             stores: MockStoresManager(sessionManager: .testingInstance),
                                             storage: storageManager,
                                             currentDate: testDate)

        // When/Then - should only show bookings after today (startDate >= end of today)
        #expect(viewModel.bookings.count == 3, "Upcoming tab should show bookings after today")
        let bookingIDs = Set(viewModel.bookings.map { $0.bookingID })
        #expect(bookingIDs.contains(afterTodayBooking1.bookingID), "Should contain booking after today")
        #expect(bookingIDs.contains(afterTodayBooking2.bookingID), "Should contain second booking after today")
        #expect(!bookingIDs.contains(withinTodayBooking.bookingID), "Should not contain booking within today")
        #expect(!bookingIDs.contains(beforeTodayBooking.bookingID), "Should not contain booking before today")
        #expect(bookingIDs.contains(atEndOfDayBooking.bookingID), "Should contain booking exactly at end of day")
    }

    @Test func all_tab_results_controller_shows_all_bookings_from_local_storage() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC

        // Create bookings for different times
        let todayBooking = createBooking(id: 1, startDate: testDate)
        let futureBooking = createBooking(id: 2, startDate: testDate.addingTimeInterval(86400)) // 1 day later
        let pastBooking = createBooking(id: 3, startDate: testDate.addingTimeInterval(-86400)) // 1 day earlier
        let farFutureBooking = createBooking(id: 4, startDate: testDate.addingTimeInterval(86400 * 30)) // 30 days later
        let farPastBooking = createBooking(id: 5, startDate: testDate.addingTimeInterval(-86400 * 30)) // 30 days earlier

        insertBookings([todayBooking, futureBooking, pastBooking, farFutureBooking, farPastBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: MockStoresManager(sessionManager: .testingInstance),
                                             storage: storageManager,
                                             currentDate: testDate)

        // When/Then - should show all bookings regardless of date
        #expect(viewModel.bookings.count == 5, "All tab should show all bookings")
        let bookingIDs = Set(viewModel.bookings.map { $0.bookingID })
        #expect(bookingIDs.contains(todayBooking.bookingID), "Should contain today's booking")
        #expect(bookingIDs.contains(futureBooking.bookingID), "Should contain future booking")
        #expect(bookingIDs.contains(pastBooking.bookingID), "Should contain past booking")
        #expect(bookingIDs.contains(farFutureBooking.bookingID), "Should contain far future booking")
        #expect(bookingIDs.contains(farPastBooking.bookingID), "Should contain far past booking")
    }

    @Test func results_controller_filters_by_site_id() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let otherSiteID: Int64 = 999

        // Create bookings for different sites
        let correctSiteBooking = createBooking(id: 1, startDate: testDate)
        let wrongSiteBooking = createBooking(id: 2, startDate: testDate, siteID: otherSiteID)

        insertBookings([correctSiteBooking, wrongSiteBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: MockStoresManager(sessionManager: .testingInstance),
                                             storage: storageManager,
                                             currentDate: testDate)

        // When/Then - should only show bookings for the correct site
        #expect(viewModel.bookings.count == 1, "Should only show bookings for the correct site")
        #expect(viewModel.bookings.first?.bookingID == correctSiteBooking.bookingID, "Should contain only the booking for the correct site")
        #expect(viewModel.bookings.first?.siteID == sampleSiteID, "Booking should have the correct site ID")
    }

    // MARK: - Filter merging

    @Test func today_tab_merges_user_date_filters_with_tab_constraints() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .today, stores: stores, storage: storageManager, currentDate: testDate)

        // User filter with a date range that overlaps today
        // User wants: after 2020-12-31T12:00:00Z, before 2021-01-01T18:00:00Z
        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatuses: [],
            customers: [],
            dateRange: BookingDateRangeFilter(
                startDate: Date(timeIntervalSince1970: 1609416000), // 2020-12-31T12:00:00Z
                endDate: Date(timeIntervalSince1970: 1609524000)    // 2021-01-01T18:00:00Z
            ),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        viewModel.loadBookings()

        // Then - startDateAfter should be max(tab, user) = tab's value (later)
        // Tab startDateAfter = "2020-12-31T23:59:59Z", user startDateAfter = "2020-12-31T12:00:00Z"
        // max = "2020-12-31T23:59:59Z"
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z",
                "Should use tab's startDateAfter since it's later (more restrictive)")

        // startDateBefore should be min(tab, user) = user's value (earlier)
        // Tab startDateBefore = "2021-01-02T00:00:00Z", user startDateBefore = "2021-01-01T18:00:00Z"
        // min = "2021-01-01T18:00:00Z"
        #expect(capturedFilters?.startDateBefore == "2021-01-01T18:00:00Z",
                "Should use user's startDateBefore since it's earlier (more restrictive)")
    }

    @Test func upcoming_tab_merges_user_date_filters_with_tab_constraints() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .upcoming, stores: stores, storage: storageManager, currentDate: testDate)

        // User filter with date range
        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatuses: [],
            customers: [],
            dateRange: BookingDateRangeFilter(
                startDate: Date(timeIntervalSince1970: 1609632000), // 2021-01-03T00:00:00Z
                endDate: Date(timeIntervalSince1970: 1609804800)    // 2021-01-05T00:00:00Z
            ),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        viewModel.loadBookings()

        // Then - startDateAfter = max(tab, user)
        // Tab startDateAfter = "2021-01-01T23:59:59Z", user startDateAfter = "2021-01-03T00:00:00Z"
        // max = "2021-01-03T00:00:00Z"
        #expect(capturedFilters?.startDateAfter == "2021-01-03T00:00:00Z",
                "Should use user's startDateAfter since it's later (more restrictive)")

        // startDateBefore = min(tab=nil, user) = user's value
        #expect(capturedFilters?.startDateBefore == "2021-01-05T00:00:00Z",
                "Should use user's startDateBefore since tab has no upper bound")
    }

    @Test func all_tab_passes_user_date_filters_through_unchanged() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores, storage: storageManager, currentDate: testDate)

        let userStartDate = Date(timeIntervalSince1970: 1609632000) // 2021-01-03T00:00:00Z
        let userEndDate = Date(timeIntervalSince1970: 1609804800)   // 2021-01-05T00:00:00Z
        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [],
            products: [],
            attendanceStatuses: [],
            customers: [],
            dateRange: BookingDateRangeFilter(startDate: userStartDate, endDate: userEndDate),
            numberOfActiveFilters: 1
        )

        // When
        viewModel.updateFilters(userFilters)
        viewModel.loadBookings()

        // Then - All tab has no tab constraints, so user dates pass through
        #expect(capturedFilters?.startDateAfter == userStartDate.ISO8601Format())
        #expect(capturedFilters?.startDateBefore == userEndDate.ISO8601Format())
    }

    @Test func non_date_filters_pass_through_on_today_tab() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .today, stores: stores, storage: storageManager, currentDate: testDate)

        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 42, name: "Alice")],
            products: [BookingProductFilter(productID: 100, name: "Massage")],
            attendanceStatuses: [.booked],
            customers: [BookingCustomerFilter(customerID: 7, name: "Bob")],
            dateRange: nil,
            numberOfActiveFilters: 4
        )

        // When
        viewModel.updateFilters(userFilters)
        viewModel.loadBookings()

        // Then - non-date filters should pass through
        #expect(capturedFilters?.resourceIDs == [42])
        #expect(capturedFilters?.productIDs == [100])
        #expect(capturedFilters?.attendanceStatuses == [BookingAttendanceStatus.booked.rawValue])
        #expect(capturedFilters?.customerIDs == [7])
        // Tab date constraints should still be applied
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z")
        #expect(capturedFilters?.startDateBefore == "2021-01-02T00:00:00Z")
    }

    @Test func clearing_filters_on_today_tab_resets_to_tab_date_constraints() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        var capturedFilters: BookingFilters?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, filters, _, _, onCompletion) = action else {
                return
            }
            capturedFilters = filters
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .today, stores: stores, storage: storageManager, currentDate: testDate)

        // Apply filters first
        let userFilters = BookingFiltersViewModel.Filters(
            teamMembers: [BookingTeamMemberFilter(resourceID: 42, name: "Alice")],
            products: [],
            attendanceStatuses: [],
            customers: [],
            dateRange: nil,
            numberOfActiveFilters: 1
        )
        viewModel.updateFilters(userFilters)

        // When - clear filters
        let emptyFilters = BookingFiltersViewModel.Filters()
        viewModel.updateFilters(emptyFilters)
        viewModel.loadBookings()

        // Then - should be back to tab-only constraints
        #expect(capturedFilters?.startDateAfter == "2020-12-31T23:59:59Z")
        #expect(capturedFilters?.startDateBefore == "2021-01-02T00:00:00Z")
        #expect(capturedFilters?.resourceIDs == [])
        #expect(capturedFilters?.productIDs == [])
        #expect(capturedFilters?.attendanceStatuses == [])
        #expect(capturedFilters?.customerIDs == [])
    }

    // MARK: - Sort order

    @Test func update_sort_order_sorts_bookings_from_oldest_to_newest() {
        // Given
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            onCompletion(.success(false))
        }

        let olderBooking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            dateCreated: Date(timeIntervalSince1970: 1000),
            startDate: Date(timeIntervalSince1970: 1000)
        )
        let newerBooking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 2,
            dateCreated: Date(timeIntervalSince1970: 2000),
            startDate: Date(timeIntervalSince1970: 2000)
        )
        insertBookings([olderBooking, newerBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        // Initial state - should be sorted newest to oldest (default)
        #expect(viewModel.bookings[0].bookingID == newerBooking.bookingID)
        #expect(viewModel.bookings[1].bookingID == olderBooking.bookingID)

        // When
        viewModel.updateSortOrder(.oldestToNewest)

        // Then - should be sorted oldest to newest
        #expect(viewModel.bookings[0].bookingID == olderBooking.bookingID)
        #expect(viewModel.bookings[1].bookingID == newerBooking.bookingID)
    }

    @Test func update_sort_order_sorts_bookings_from_newest_to_oldest() {
        // Given
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard let onCompletion = action.synchronizeBookingsCompletion  else { return }
            onCompletion(.success(false))
        }

        let olderBooking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            dateCreated: Date(timeIntervalSince1970: 1000),
            startDate: Date(timeIntervalSince1970: 1000)
        )
        let newerBooking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 2,
            dateCreated: Date(timeIntervalSince1970: 2000),
            startDate: Date(timeIntervalSince1970: 2000)
        )
        insertBookings([olderBooking, newerBooking])

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .all,
                                             stores: stores,
                                             storage: storageManager)

        // Change to oldest first
        viewModel.updateSortOrder(.oldestToNewest)
        #expect(viewModel.bookings[0].bookingID == olderBooking.bookingID)

        // When - change back to newest first
        viewModel.updateSortOrder(.newestToOldest)

        // Then - should be sorted newest to oldest
        #expect(viewModel.bookings[0].bookingID == newerBooking.bookingID)
        #expect(viewModel.bookings[1].bookingID == olderBooking.bookingID)
    }

    @Test func update_sort_order_triggers_resync_with_correct_order() {
        // Given
        var capturedOrder: BookingsRemote.Order?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, order, _, onCompletion) = action else {
                return
            }
            capturedOrder = order
            onCompletion(.success(false))
        }

        let viewModel = givenViewModel()

        // When
        viewModel.updateSortOrder(.oldestToNewest)

        // Then
        #expect(capturedOrder == .ascending, "Should dispatch action with ascending order")
    }

    @Test func update_sort_order_to_newest_first_triggers_resync_with_descending_order() {
        // Given
        var capturedOrder: BookingsRemote.Order?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, order, _, onCompletion) = action else {
                return
            }
            capturedOrder = order
            onCompletion(.success(false))
        }

        let viewModel = givenViewModel()

        // When
        viewModel.updateSortOrder(.newestToOldest)

        // Then
        #expect(capturedOrder == .descending, "Should dispatch action with descending order")
    }
}

private extension BookingListViewModelTests {

    func givenViewModel() -> BookingListViewModel {
        return BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores, analytics: analytics)
    }

    func insertBookings(_ readOnlyBookings: [Booking]) {
        storageManager.performAndSave({ storage in
            readOnlyBookings.forEach { booking in
                let newBooking = storage.insertNewObject(ofType: StorageBooking.self)
                newBooking.update(with: booking)
            }
        }, completion: {}, on: .main)
    }

    func createBooking(id: Int64, startDate: Date, siteID: Int64? = nil) -> Booking {
        return Booking.fake().copy(siteID: siteID ?? self.sampleSiteID, bookingID: id, startDate: startDate)
    }
}


class MockBookingListsRefreshCoordinating: BookingListsRefreshCoordinating {
    private(set) var refreshAllListsCalled = false

    func refreshAllLists() async {
        refreshAllListsCalled = true
    }
}

fileprivate extension BookingAction {
    var synchronizeBookingsCompletion: ((Result<Bool, Error>) -> Void)? {
        guard case let .synchronizeBookings(_, _, _, _, _, _, onCompletion) = self else {
            return nil
        }
        return onCompletion
    }
}
