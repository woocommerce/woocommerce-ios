import Testing
@testable import Networking
@testable import Storage
@testable import Yosemite

@MainActor
struct BookingStoreTests {
    /// Mock network to inject responses
    ///
    private var network: MockNetwork

    /// Spy remote to check request parameter use
    ///
    private var remote: MockBookingsRemote
    private var ordersRemote: MockOrdersRemote

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager

    /// Storage
    ///
    private var storage: StorageType {
        storageManager.viewStorage
    }

    /// Convenience: returns the StorageType associated with the main thread
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience: returns the number of stored bookings
    ///
    private var storedBookingCount: Int {
        return viewStorage.countObjects(ofType: StorageBooking.self)
    }

    /// SiteID
    ///
    private let sampleSiteID: Int64 = 120934

    /// Default page number
    ///
    private let defaultPageNumber = 1

    /// Default page size
    ///
    private let defaultPageSize = 25

    init() {
        network = MockNetwork()
        storageManager = MockStorageManager()
        remote = MockBookingsRemote()
        ordersRemote = MockOrdersRemote()
    }

    // MARK: - synchronizeBookings

    @Test func synchronizeBookings_returns_false_for_hasNextPage_when_number_of_retrieved_results_is_zero() async throws {
        // Given
        remote.whenLoadingAllBookings(thenReturn: .success([]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let hasNextPage = try result.get()
        #expect(hasNextPage == false)
    }

    @Test func synchronizeBookings_returns_true_for_hasNextPage_when_number_of_retrieved_results_equals_pageSize() async throws {
        // Given
        let bookings = Array(repeating: Booking.fake(), count: defaultPageSize)
        remote.whenLoadingAllBookings(thenReturn: .success(bookings))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let hasNextPage = try result.get()
        #expect(hasNextPage == true)
    }

    @Test func synchronizeBookings_returns_error_on_failure() async throws {
        // Given
        remote.whenLoadingAllBookings(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                           pageNumber: defaultPageNumber,
                                                           pageSize: defaultPageSize,
                                                           onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isFailure)
        let error = result.failure as? NetworkError
        #expect(error == .timeout())
    }

    @Test func test_synchronizeBookings_when_invoked_fetches_orders_for_bookings() async throws {
        // Given
        let booking1 = Booking.fake().copy(orderID: 1)
        let booking2 = Booking.fake().copy(orderID: 2)
        remote.whenLoadingAllBookings(thenReturn: .success([booking1, booking2]))

        let order1 = Order.fake().copy(orderID: 1)
        let order2 = Order.fake().copy(orderID: 2)
        ordersRemote.whenLoadingOrders(thenReturn: .success([order1, order2]))

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(ordersRemote.invokedLoadOrders)
        #expect(ordersRemote.invokedLoadOrdersParameters?.orderIDs == [1, 2])
    }

    @Test func test_synchronizeBooking_when_invoked_fetches_order_for_booking() async throws {
        // Given
        let booking = Booking.fake().copy(bookingID: 1, orderID: 10)
        remote.whenLoadingBooking(thenReturn: .success(booking))
        ordersRemote.whenLoadingOrders(thenReturn: .success([]))

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.synchronizeBooking(
                    siteID: sampleSiteID,
                    bookingID: 1
                ) { result in
                    continuation.resume(returning: result)
                }
            )
        }

        // Then
        #expect(result.isSuccess)
        #expect(ordersRemote.invokedLoadOrders)
        #expect(ordersRemote.invokedLoadOrdersParameters?.orderIDs == [10])
    }

    @Test func synchronizeBookings_stores_bookings_upon_success() async throws {
        // Given
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)
        #expect(storedBookingCount == 0)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 1)
    }

    @Test func synchronizeBookings_updates_existing_booking_when_booking_already_exists() async throws {
        // Given
        let originalBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, statusKey: "pending")
        storeBooking(originalBooking)
        #expect(storedBookingCount == 1)

        let updatedBooking = originalBooking.copy(statusKey: "confirmed")
        remote.whenLoadingAllBookings(thenReturn: .success([updatedBooking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 1)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 123))
        #expect(storedBooking.statusKey == "confirmed")
    }

    @Test func synchronizeBookings_stores_multiple_bookings_upon_success() async throws {
        // Given
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 456)
        remote.whenLoadingAllBookings(thenReturn: .success([booking1, booking2]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)
        #expect(storedBookingCount == 0)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 2)
    }

    @Test func synchronizeBookings_clears_existing_bookings_when_shouldClearCache_is_true() async throws {
        // Given
        let existingBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 999)
        storeBooking(existingBooking)
        #expect(storedBookingCount == 1)

        let newBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        remote.whenLoadingAllBookings(thenReturn: .success([newBooking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             shouldClearCache: true,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 1)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 123))
        #expect(storedBooking.bookingID == 123)

        // Verify the existing booking was cleared
        let existingStoredBooking = viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 999)
        #expect(existingStoredBooking == nil)
    }

    @Test func synchronizeBookings_preserves_existing_bookings_when_shouldClearCache_is_false() async throws {
        // Given
        let existingBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 999)
        storeBooking(existingBooking)
        #expect(storedBookingCount == 1)

        let newBooking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        remote.whenLoadingAllBookings(thenReturn: .success([newBooking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeBookings(siteID: sampleSiteID,
                                                             pageNumber: defaultPageNumber,
                                                             pageSize: defaultPageSize,
                                                             shouldClearCache: false,
                                                             onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 2)

        // Verify both bookings exist
        let newStoredBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 123))
        #expect(newStoredBooking.bookingID == 123)

        let existingStoredBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 999))
        #expect(existingStoredBooking.bookingID == 999)
    }

    // MARK: - checkIfStoreHasBookings

    @Test func checkIfStoreHasBookings_returns_true_when_bookings_exist_locally() async throws {
        // Given
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        storeBooking(booking)
        #expect(storedBookingCount == 1)

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.checkIfStoreHasBookings(siteID: sampleSiteID,
                                                                onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let hasBookings = try result.get()
        #expect(hasBookings == true)
    }

    @Test func checkIfStoreHasBookings_returns_true_when_no_local_bookings_but_remote_has_bookings() async throws {
        // Given
        #expect(storedBookingCount == 0)
        let remoteBooking = Booking.fake()
        remote.whenLoadingAllBookings(thenReturn: .success([remoteBooking]))

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.checkIfStoreHasBookings(siteID: sampleSiteID,
                                                                onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let hasBookings = try result.get()
        #expect(hasBookings == true)
    }

    @Test func checkIfStoreHasBookings_returns_false_when_no_bookings_exist_locally_or_remotely() async throws {
        // Given
        #expect(storedBookingCount == 0)
        remote.whenLoadingAllBookings(thenReturn: .success([]))

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.checkIfStoreHasBookings(siteID: sampleSiteID,
                                                                onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let hasBookings = try result.get()
        #expect(hasBookings == false)
    }

    @Test func checkIfStoreHasBookings_returns_error_on_remote_failure() async throws {
        // Given
        #expect(storedBookingCount == 0)
        remote.whenLoadingAllBookings(thenReturn: .failure(NetworkError.timeout()))

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.checkIfStoreHasBookings(siteID: sampleSiteID,
                                                                onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isFailure)
        let error = result.failure as? NetworkError
        #expect(error == .timeout())
    }

    // MARK: - searchBookings

    @Test func searchBookings_returns_bookings_on_success() async throws {
        // Given
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 456)
        remote.whenLoadingAllBookings(thenReturn: .success([booking1, booking2]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.searchBookings(siteID: sampleSiteID,
                                                        searchQuery: "test",
                                                        pageNumber: defaultPageNumber,
                                                        pageSize: defaultPageSize,
                                                        onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let bookings = try result.get()
        #expect(bookings.count == 2)
        #expect(bookings[0].bookingID == 123)
        #expect(bookings[1].bookingID == 456)
    }

    @Test func searchBookings_returns_error_on_failure() async throws {
        // Given
        remote.whenLoadingAllBookings(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.searchBookings(siteID: sampleSiteID,
                                                        searchQuery: "test",
                                                        pageNumber: defaultPageNumber,
                                                        pageSize: defaultPageSize,
                                                        onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isFailure)
        let error = result.failure as? NetworkError
        #expect(error == .timeout())
    }

    @Test func searchBookings_does_not_save_results_to_storage() async throws {
        // Given
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)
        #expect(storedBookingCount == 0)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.searchBookings(siteID: sampleSiteID,
                                                        searchQuery: "test",
                                                        pageNumber: defaultPageNumber,
                                                        pageSize: defaultPageSize,
                                                        onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingCount == 0)
    }
}

private extension BookingStoreTests {
    @discardableResult
    func storeBooking(_ booking: Networking.Booking) -> Storage.Booking {
        let storedBooking = storage.insertNewObject(ofType: Storage.Booking.self)
        storedBooking.update(with: booking)
        return storedBooking
    }
}

private class MockOrdersRemote: OrdersRemoteProtocol {
    var invokedLoadOrders = false
    var invokedLoadOrdersParameters: (siteID: Int64, orderIDs: [Int64])?
    private var loadOrdersResult: Result<[Yosemite.Order], Error> = .success([])

    func whenLoadingOrders(thenReturn result: Result<[Yosemite.Order], Error>) {
        loadOrdersResult = result
    }

    func loadOrders(for siteID: Int64, orderIDs: [Int64]) async throws -> [Yosemite.Order] {
        invokedLoadOrders = true
        invokedLoadOrdersParameters = (siteID, orderIDs)
        switch loadOrdersResult {
        case .success(let orders):
            return orders
        case .failure(let error):
            throw error
        }
    }

    func loadOrder(for siteID: Int64, orderID: Int64, completion: @escaping (NetworkingCore.Order?, (any Error)?) -> Void) {
        return
    }
}
