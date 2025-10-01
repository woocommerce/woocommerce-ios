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
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores)

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
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.loadBookings()

        // Then
        #expect(invocationCountOfLoadBookings == 1)
    }

    @Test func state_is_syncing_first_page_upon_load_bookings_if_no_existing_booking_in_storage() {
        // Given
        let viewModel = BookingListViewModel(siteID: sampleSiteID)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.syncState == .syncingFirstPage)
    }

    @Test func state_is_results_upon_load_bookings_if_existing_bookings_in_storage() {
        let existingBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        insertBookings([existingBooking])
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: MockStoresManager(sessionManager: .testingInstance), storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.syncState == .results)
    }

    @Test func state_is_results_after_load_bookings_with_nonempty_results() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let booking = Booking.fake().copy(siteID: sampleSiteID)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, onCompletion) = action else {
                return
            }
            self.insertBookings([booking])
            onCompletion(.success(true))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

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
            guard case let .synchronizeBookings(_, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

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
        let firstPageItems = [Booking](repeating: .fake().copy(siteID: sampleSiteID), count: 2)
        let secondPageItems = [Booking](repeating: .fake().copy(siteID: sampleSiteID), count: 1)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, pageNumber, _, onCompletion) = action else {
                return
            }
            invocationCountOfLoadBookings += 1
            let bookings = pageNumber == 1 ? firstPageItems: secondPageItems
            self.insertBookings(bookings)
            onCompletion(.success(pageNumber == 1 ? true : false))
        }

        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

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
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 9)
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 10)
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, onCompletion) = action else {
                return
            }
            self.insertBookings([booking1, booking2])
            onCompletion(.success(true))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

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
            guard case let .synchronizeBookings(_, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

        // When
        viewModel.loadBookings()

        // Then
        #expect(viewModel.bookings == [])
    }

    @Test func booking_models_are_sorted_by_date_created() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let olderBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 1, dateCreated: Date(timeIntervalSince1970: 1000))
        let newerBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 3, dateCreated: Date(timeIntervalSince1970: 2000))
        stores.whenReceivingAction(ofType: BookingAction.self) { action in
            guard case let .synchronizeBookings(_, _, _, onCompletion) = action else {
                return
            }
            let items = [olderBooking, newerBooking]
            self.insertBookings(items)
            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores, storage: storageManager)

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
            guard case let .synchronizeBookings(_, pageNumber, pageSize, onCompletion) = action else {
                return
            }
            invocationCountOfLoadBookings += 1
            skip = pageNumber > 1 ? pageSize * (pageNumber - 1) : 0

            onCompletion(.success(false))
        }
        let viewModel = BookingListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        await viewModel.onRefreshAction()

        // Then
        #expect(skip == 0)
        #expect(invocationCountOfLoadBookings == 1)
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
}
