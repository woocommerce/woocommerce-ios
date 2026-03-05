import Foundation
import Testing
import YosemiteTestHelpers
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

    /// Convenience: returns the number of stored booking resources
    ///
    private var storedBookingResourceCount: Int {
        return viewStorage.countObjects(ofType: Storage.BookingResource.self)
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
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, orderID: 1)
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 456, orderID: 2)
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
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, orderID: 1)
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))

        let order = Order.fake().copy(orderID: 1)
        ordersRemote.whenLoadingOrders(thenReturn: .success([order]))

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

    @Test func searchBookings_fetches_orders_for_bookings() async throws {
        // Given
        let booking1 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, orderID: 10)
        let booking2 = Booking.fake().copy(siteID: sampleSiteID, bookingID: 456, orderID: 20)
        remote.whenLoadingAllBookings(thenReturn: .success([booking1, booking2]))

        let order1 = Order.fake().copy(orderID: 10)
        let order2 = Order.fake().copy(orderID: 20)
        ordersRemote.whenLoadingOrders(thenReturn: .success([order1, order2]))

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
        #expect(result.isSuccess)
        #expect(ordersRemote.invokedLoadOrders)
        #expect(ordersRemote.invokedLoadOrdersParameters?.orderIDs == [10, 20])
    }

    @Test func searchBookings_returns_bookings_with_orderInfo_when_orders_are_available() async throws {
        // Given
        let productID: Int64 = 100
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 123,
            orderID: 1,
            productID: productID
        )
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))

        let orderItem = OrderItem.fake().copy(itemID: 1, name: "Test Product", productID: productID)
        let order = Order.fake().copy(orderID: 1, status: .processing, items: [orderItem])
        ordersRemote.whenLoadingOrders(thenReturn: .success([order]))

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
        #expect(bookings.count == 1)
        let returnedBooking = try #require(bookings.first)
        let orderInfo = try #require(returnedBooking.orderInfo)
        #expect(orderInfo.productInfo?.name == "Test Product")
        #expect(orderInfo.statusKey == "processing")
    }

    // MARK: - performUpdateBookingAttendanceStatus

    @Test func performUpdateBookingAttendanceStatus_updates_localBooking() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            attendanceStatusKey: BookingAttendanceStatus.unattended.rawValue
        )
        storeBooking(booking)

        let remoteBooking = booking.copy(attendanceStatusKey: BookingAttendanceStatus.attended.rawValue)
        remote.whenUpdatingBooking(thenReturn: .success(remoteBooking))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.updateBookingAttendanceStatus(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    status: .attended,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error == nil)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 1))
        #expect(storedBooking.attendanceStatusKey == BookingAttendanceStatus.attended.rawValue)
    }

    @Test func performUpdateBookingAttendanceStatus_keeps_existing_create_and_update_dates() async throws {
        // Given
        let date = Date(timeIntervalSince1970: 0)
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            dateCreated: date,
            dateModified: date
        )
        storeBooking(booking)

        let remoteBooking = booking.copy(
            dateCreated: nil,
            dateModified: nil
        )
        remote.whenUpdatingBooking(thenReturn: .success(remoteBooking))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.updateBookingAttendanceStatus(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    status: .attended,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error == nil)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 1))
        #expect(storedBooking.dateCreated == date)
        #expect(storedBooking.dateModified == date)
    }

    @Test func performUpdateBookingAttendanceStatus_reverts_old_status_on_error() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            attendanceStatusKey: BookingAttendanceStatus.unattended.rawValue
        )
        storeBooking(booking)

        remote.whenUpdatingBooking(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.updateBookingAttendanceStatus(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    status: .attended,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error != nil)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 1))
        #expect(storedBooking.attendanceStatusKey == BookingAttendanceStatus.unattended.rawValue)
    }

    // MARK: - cancelBooking

    @Test func cancelBooking_updates_local_booking_to_cancelled_status() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "confirmed"
        )
        storeBooking(booking)

        let cancelledBooking = booking.copy(statusKey: "cancelled")
        remote.whenUpdatingBooking(thenReturn: .success(cancelledBooking))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.cancelBooking(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error == nil)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 1))
        #expect(storedBooking.statusKey == "cancelled")
    }

    @Test func cancelBooking_returns_error_on_remote_failure() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "confirmed"
        )
        storeBooking(booking)

        remote.whenUpdatingBooking(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.cancelBooking(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error != nil)
        let networkError = error as? NetworkError
        #expect(networkError == .timeout())
    }

    @Test func cancelBooking_returns_error_when_remote_booking_is_missing() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "confirmed"
        )
        storeBooking(booking)

        remote.whenUpdatingBooking(thenReturn: .success(nil))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.cancelBooking(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error != nil)
    }

    // MARK: - markBookingAsPaid

    @Test func markBookingAsPaid_updates_local_booking_to_paid_status() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "unpaid"
        )
        storeBooking(booking)

        let paidBooking = booking.copy(statusKey: "paid")
        remote.whenUpdatingBooking(thenReturn: .success(paidBooking))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.markBookingAsPaid(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error == nil)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 1))
        #expect(storedBooking.statusKey == "paid")
    }

    @Test func markBookingAsPaid_returns_error_on_remote_failure() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "unpaid"
        )
        storeBooking(booking)

        remote.whenUpdatingBooking(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.markBookingAsPaid(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error != nil)
        let networkError = error as? NetworkError
        #expect(networkError == .timeout())
    }

    @Test func markBookingAsPaid_returns_error_when_remote_booking_is_missing() async throws {
        // Given
        let booking = Booking.fake().copy(
            siteID: sampleSiteID,
            bookingID: 1,
            statusKey: "unpaid"
        )
        storeBooking(booking)

        remote.whenUpdatingBooking(thenReturn: .success(nil))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(
                BookingAction.markBookingAsPaid(
                    siteID: sampleSiteID,
                    bookingID: 1,
                    onCompletion: { error in
                        continuation.resume(returning: error)
                    }
                )
            )
        }

        // Then
        #expect(error != nil)
    }

    // MARK: - synchronizeResources

    @Test func synchronizeResources_returns_false_for_hasNextPage_when_number_of_retrieved_results_is_zero() async throws {
        // Given
        remote.whenFetchingResources(thenReturn: .success([]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
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

    @Test func synchronizeResources_returns_true_for_hasNextPage_when_number_of_retrieved_results_equals_pageSize() async throws {
        // Given
        let resources = Array(repeating: BookingResource.fake(), count: defaultPageSize)
        remote.whenFetchingResources(thenReturn: .success(resources))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
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

    @Test func synchronizeResources_stores_resources_upon_success() async throws {
        // Given
        let resource = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 123)
        remote.whenFetchingResources(thenReturn: .success([resource]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)
        #expect(storedBookingResourceCount == 0)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
                                                              pageNumber: defaultPageNumber,
                                                              pageSize: defaultPageSize,
                                                              onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingResourceCount == 1)
    }

    @Test func synchronizeResources_updates_existing_resource_when_resource_already_exists() async throws {
        // Given
        let originalResource = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 123, name: "Original Name")
        storeBookingResource(originalResource)
        #expect(storedBookingResourceCount == 1)

        let updatedResource = originalResource.copy(name: "Updated Name")
        remote.whenFetchingResources(thenReturn: .success([updatedResource]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
                                                              pageNumber: defaultPageNumber,
                                                              pageSize: defaultPageSize,
                                                              onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingResourceCount == 1)
        let storedResource = try #require(viewStorage.loadBookingResource(siteID: sampleSiteID, resourceID: 123))
        #expect(storedResource.name == "Updated Name")
    }

    @Test func synchronizeResources_stores_multiple_resources_upon_success() async throws {
        // Given
        let resource1 = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 123)
        let resource2 = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 456)
        remote.whenFetchingResources(thenReturn: .success([resource1, resource2]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)
        #expect(storedBookingResourceCount == 0)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
                                                              pageNumber: defaultPageNumber,
                                                              pageSize: defaultPageSize,
                                                              onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingResourceCount == 2)
    }

    @Test func synchronizeResources_returns_error_on_failure() async throws {
        // Given
        remote.whenFetchingResources(thenReturn: .failure(NetworkError.timeout()))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
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

    @Test func synchronizeResources_preserves_existing_resources_from_previous_pages() async throws {
        // Given
        let existingResource = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 999)
        storeBookingResource(existingResource)
        #expect(storedBookingResourceCount == 1)

        let newResource = BookingResource.fake().copy(siteID: sampleSiteID, resourceID: 123)
        remote.whenFetchingResources(thenReturn: .success([newResource]))
        let store = BookingStore(dispatcher: Dispatcher(),
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 ordersRemote: ordersRemote)

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(BookingAction.synchronizeResources(siteID: sampleSiteID,
                                                              pageNumber: defaultPageNumber,
                                                              pageSize: defaultPageSize,
                                                              onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(result.isSuccess)
        #expect(storedBookingResourceCount == 2)

        // Verify both resources exist
        let newStoredResource = try #require(viewStorage.loadBookingResource(siteID: sampleSiteID, resourceID: 123))
        #expect(newStoredResource.resourceID == 123)

        let existingStoredResource = try #require(viewStorage.loadBookingResource(siteID: sampleSiteID, resourceID: 999))
        #expect(existingStoredResource.resourceID == 999)
    }

    // MARK: - orderInfo Storage Tests

    @Test func synchronizeBookings_stores_complete_orderInfo_with_all_nested_properties() async throws {
        // Given
        let productID: Int64 = 100
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, orderID: 1, productID: productID)
        remote.whenLoadingAllBookings(thenReturn: .success([booking]))

        let billingAddress = Address.fake().copy(
            firstName: "Jane",
            lastName: "Smith",
            address1: "456 Oak Ave",
            city: "Los Angeles",
            postcode: "90001",
            country: "US"
        )
        let orderItem = OrderItem.fake().copy(
            itemID: 1,
            name: "Premium Booking",
            productID: productID,
            subtotal: "200.00",
            subtotalTax: "20.00"
        )
        let order = Order.fake().copy(
            orderID: 1,
            status: .processing,
            total: "220.00",
            totalTax: "20.00",
            paymentMethodID: "paypal",
            paymentMethodTitle: "PayPal",
            items: [orderItem],
            billingAddress: billingAddress
        )
        ordersRemote.whenLoadingOrders(thenReturn: .success([order]))

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
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 123))
        let orderInfo = try #require(storedBooking.orderInfo)

        // Verify order status
        #expect(orderInfo.statusKey == "processing")

        // Verify product info
        let productInfo = try #require(orderInfo.productInfo)
        #expect(productInfo.name == "Premium Booking")

        // Verify customer info
        let customerInfo = try #require(orderInfo.customerInfo)
        #expect(customerInfo.billingFirstName == "Jane")
        #expect(customerInfo.billingLastName == "Smith")
        #expect(customerInfo.billingAddress1 == "456 Oak Ave")
        #expect(customerInfo.billingCity == "Los Angeles")

        // Verify payment info
        let paymentInfo = try #require(orderInfo.paymentInfo)
        #expect(paymentInfo.paymentMethodID == "paypal")
        #expect(paymentInfo.paymentMethodTitle == "PayPal")
        #expect(paymentInfo.subtotal == "200.0")
        #expect(paymentInfo.subtotalTax == "20.0")
        #expect(paymentInfo.total == "220.00")
        #expect(paymentInfo.totalTax == "20.00")
    }

    @Test func synchronizeBooking_stores_orderInfo_correctly() async throws {
        // Given
        let productID: Int64 = 100
        let booking = Booking.fake().copy(siteID: sampleSiteID, bookingID: 123, orderID: 1, productID: productID)
        remote.whenLoadingBooking(thenReturn: .success(booking))

        let billingAddress = Address.fake().copy(firstName: "Test", lastName: "User")
        let orderItem = OrderItem.fake().copy(itemID: 1, name: "Test Product", productID: productID)
        let order = Order.fake().copy(
            orderID: 1,
            status: .onHold,
            paymentMethodID: "cod",
            items: [orderItem],
            billingAddress: billingAddress
        )
        ordersRemote.whenLoadingOrders(thenReturn: .success([order]))

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
                    bookingID: 123
                ) { result in
                    continuation.resume(returning: result)
                }
            )
        }

        // Then
        #expect(result.isSuccess)
        let storedBooking = try #require(viewStorage.loadBooking(siteID: sampleSiteID, bookingID: 123))
        let orderInfo = try #require(storedBooking.orderInfo)
        #expect(orderInfo.statusKey == "on-hold")

        let productInfo = try #require(orderInfo.productInfo)
        #expect(productInfo.name == "Test Product")

        let customerInfo = try #require(orderInfo.customerInfo)
        #expect(customerInfo.billingFirstName == "Test")
        #expect(customerInfo.billingLastName == "User")
    }
}

private extension BookingStoreTests {
    @discardableResult
    func storeBooking(_ booking: Networking.Booking) -> Storage.Booking {
        let storedBooking = storage.insertNewObject(ofType: Storage.Booking.self)
        storedBooking.update(with: booking)
        return storedBooking
    }

    @discardableResult
    func storeProduct(_ product: Networking.Product) -> Storage.Product {
        let storedProduct = storage.insertNewObject(ofType: Storage.Product.self)
        storedProduct.update(with: product)
        return storedProduct
    }

    @discardableResult
    func storeBookingResource(_ resource: Networking.BookingResource) -> Storage.BookingResource {
        let storedResource = storage.insertNewObject(ofType: Storage.BookingResource.self)
        storedResource.update(with: resource)
        return storedResource
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
