import Combine
import Foundation
import Testing
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce

@MainActor
struct BookingListViewModelTests {

    private let sampleSiteID: Int64 = 322

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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadBookings = 0
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case .synchronizeBookings = action else {
                return
            }
            invocationCountOfLoadBookings += 1
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // Then
        #expect(viewModel.syncState == .empty)
        #expect(invocationCountOfLoadBookings == 0)
    }

    @Test func synchronize_bookings_is_dispatched_upon_load_bookings() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadBookings = 0
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case .synchronizeBookings = action else {
                return
            }
            invocationCountOfLoadBookings += 1
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // When
        viewModel.loadBookings()

        // Then
        #expect(invocationCountOfLoadBookings == 1)
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let booking = createBooking(id: 1, startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadBookings = 0
        let firstPageItems = (1...2).map { createBooking(id: Int64($0), startDate: Date()) }
        let secondPageItems = [createBooking(id: 3, startDate: Date())]
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, pageNumber, _, _, _, _, _, onCompletion) = action else {
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let booking1 = createBooking(id: 9, startDate: Date())
        let booking2 = createBooking(id: 10, startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let olderBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 1, dateCreated: Date(timeIntervalSince1970: 1000), startDate: Date())
        let newerBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 3, dateCreated: Date(timeIntervalSince1970: 2000), startDate: Date())
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
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
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfLoadBookings = 0
        var skip: Int?
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, pageNumber, pageSize, _, _, _, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadBookings += 1
            skip = pageNumber > 1 ? pageSize * (pageNumber - 1) : 0

            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // When
        await viewModel.onRefreshAction()

        // Then
        #expect(skip == 0)
        #expect(invocationCountOfLoadBookings == 1)
    }

    // MARK: - Type-based filtering

    @Test func today_tab_passes_correct_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedStartDateBefore: String?
        var capturedStartDateAfter: String?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, startDateBefore, startDateAfter, _, _, onCompletion) = action else {
                return
            }
            capturedStartDateBefore = startDateBefore
            capturedStartDateAfter = startDateAfter
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .today, stores: stores, currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedStartDateAfter == "2020-12-31T23:59:59Z", "Today tab should filter after start of day")
        #expect(capturedStartDateBefore == "2021-01-02T00:00:00Z", "Today tab should filter before end of day")
    }

    @Test func upcoming_tab_passes_correct_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedStartDateBefore: String?
        var capturedStartDateAfter: String?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, startDateBefore, startDateAfter, _, _, onCompletion) = action else {
                return
            }
            capturedStartDateBefore = startDateBefore
            capturedStartDateAfter = startDateAfter
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID,
                                             type: .upcoming,
                                             stores: stores,
                                             currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedStartDateBefore == nil, "Upcoming tab should not have startDateBefore filter")
        #expect(capturedStartDateAfter == "2021-01-01T23:59:59Z", "Upcoming tab should filter after end of day")
    }

    @Test func all_tab_passes_no_date_filters_to_booking_action() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedStartDateBefore: String?
        var capturedStartDateAfter: String?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, startDateBefore, startDateAfter, _, _, onCompletion) = action else {
                return
            }
            capturedStartDateBefore = startDateBefore
            capturedStartDateAfter = startDateAfter
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores, currentDate: testDate)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedStartDateBefore == nil, "All tab should not have startDateBefore filter")
        #expect(capturedStartDateAfter == nil, "All tab should not have startDateAfter filter")
    }

    // MARK: - Cache clearing logic

    @Test func load_bookings_does_not_clear_cache() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedShouldClearCache: Bool?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, shouldClearCache, onCompletion) = action else {
                return
            }
            capturedShouldClearCache = shouldClearCache
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // When
        viewModel.loadBookings()

        // Then
        #expect(capturedShouldClearCache == false, "Initial load should not clear cache")
    }

    @Test func on_load_next_page_action_does_not_clear_cache() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedShouldClearCache: Bool?
        var actionCallCount = 0

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, shouldClearCache, onCompletion) = action else {
                return
            }
            actionCallCount += 1
            capturedShouldClearCache = shouldClearCache
            onCompletion(.success(actionCallCount == 1)) // First call has next page, second doesn't
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // When
        viewModel.loadBookings() // First page
        viewModel.onLoadNextPageAction() // Next page

        // Then
        #expect(capturedShouldClearCache == false, "Load next page should not clear cache")
        #expect(actionCallCount == 2, "Should have made two API calls")
    }

    @Test func on_refresh_action_clears_cache() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var capturedShouldClearCache: Bool?

        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, _, _, _, shouldClearCache, onCompletion) = action else {
                return
            }
            capturedShouldClearCache = shouldClearCache
            onCompletion(.success(false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, type: .all, stores: stores)

        // When
        await viewModel.onRefreshAction()

        // Then
        #expect(capturedShouldClearCache == true, "Refresh action should clear cache")
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

        // When/Then - should only show bookings within today (startDate > start AND startDate < end)
        #expect(viewModel.bookings.count == 2)
        #expect(viewModel.bookings.first?.bookingID == withinTodayBooking.bookingID)
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

        // When/Then - should only show bookings after today (startDate > end of today)
        #expect(viewModel.bookings.count == 2, "Upcoming tab should show bookings after today")
        let bookingIDs = Set(viewModel.bookings.map { $0.bookingID })
        #expect(bookingIDs.contains(afterTodayBooking1.bookingID), "Should contain booking after today")
        #expect(bookingIDs.contains(afterTodayBooking2.bookingID), "Should contain second booking after today")
        #expect(!bookingIDs.contains(withinTodayBooking.bookingID), "Should not contain booking within today")
        #expect(!bookingIDs.contains(beforeTodayBooking.bookingID), "Should not contain booking before today")
        #expect(!bookingIDs.contains(atEndOfDayBooking.bookingID), "Should not contain booking exactly at end of day")
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
}

private extension BookingListViewModelTests {
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
