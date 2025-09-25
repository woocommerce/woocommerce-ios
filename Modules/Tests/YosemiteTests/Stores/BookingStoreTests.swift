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
    }

    // MARK: - synchronizeBookings

    @Test func synchronizeBookings_returns_false_for_hasNextPage_when_number_of_retrieved_results_is_zero() async throws {
        // Given
        remote.whenLoadingAllBookings(thenReturn: .success([]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote)

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
                                 remote: remote)

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
                                 remote: remote)

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

    @Test func synchronizeBookings_stores_bookings_upon_success() async throws {
        // Given
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote)
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
                                 remote: remote)

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
                                 remote: remote)
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

    // MARK: - checkIfStoreHasBookings

    @Test func checkIfStoreHasBookings_returns_true_when_bookings_exist_locally() async throws {
        // Given
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123)
        storeBooking(booking)
        #expect(storedBookingCount == 1)

        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote)

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
                                 remote: remote)

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
                                 remote: remote)

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
                                 remote: remote)

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
}

private extension BookingStoreTests {
    @discardableResult
    func storeBooking(_ booking: Networking.Booking) -> Storage.Booking {
        let storedBooking = storage.insertNewObject(ofType: Storage.Booking.self)
        storedBooking.update(with: booking)
        return storedBooking
    }
}
