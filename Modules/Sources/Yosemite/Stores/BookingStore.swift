import Foundation
import Networking
import Storage

// MARK: - BookingStore
//
public class BookingStore: Store {
    private let remote: BookingsRemoteProtocol
    private let ordersRemote: OrdersRemote

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = BookingsRemote(network: network)
        let ordersRemote = OrdersRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote, ordersRemote: ordersRemote)
    }

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: BookingsRemoteProtocol,
                ordersRemote: OrdersRemote) {
        self.remote = remote
        self.ordersRemote = ordersRemote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: BookingAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? BookingAction else {
            assertionFailure("BookingStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizeBookings(siteID, pageNumber, pageSize, startDateBefore, startDateAfter, shouldClearCache, onCompletion):
            synchronizeBookings(siteID: siteID,
                                pageNumber: pageNumber,
                                pageSize: pageSize,
                                startDateBefore: startDateBefore,
                                startDateAfter: startDateAfter,
                                shouldClearCache: shouldClearCache,
                                onCompletion: onCompletion)
        case let .checkIfStoreHasBookings(siteID, onCompletion):
            checkIfStoreHasBookings(siteID: siteID, onCompletion: onCompletion)
        case let .searchBookings(siteID, searchQuery, pageNumber, pageSize, startDateBefore, startDateAfter, onCompletion):
            searchBookings(siteID: siteID,
                           searchQuery: searchQuery,
                           pageNumber: pageNumber,
                           pageSize: pageSize,
                           startDateBefore: startDateBefore,
                           startDateAfter: startDateAfter,
                           onCompletion: onCompletion)
        }
    }
}


// MARK: - Services
//
private extension BookingStore {

    /// Synchronizes the bookings for the specified site.
    ///
    func synchronizeBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             startDateBefore: String?,
                             startDateAfter: String?,
                             shouldClearCache: Bool,
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize,
                                                                startDateBefore: startDateBefore,
                                                                startDateAfter: startDateAfter,
                                                                searchQuery: nil)

                let orders = try await ordersRemote.loadOrders(
                    for: siteID,
                    orderIDs: bookings.map { $0.orderID }
                )

                await upsertStoredBookingsInBackground(
                    readOnlyBookings: bookings,
                    readOnlyOrders: orders,
                    siteID: siteID,
                    shouldDeleteExistingBookings: shouldClearCache
                )
                let hasNextPage = bookings.count == pageSize
                onCompletion(.success(hasNextPage))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Checks if the store already has any bookings.
    /// Returns `false` if the store has no bookings.
    ///
    func checkIfStoreHasBookings(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        let derivedStorage = storageManager.viewStorage
        let hasLocalBookings = derivedStorage.countObjects(ofType: StorageBooking.self, matching: NSPredicate(format: "siteID == %lld", siteID)) > 0

        if hasLocalBookings {
            onCompletion(.success(true))
            return
        }

        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: 1,
                                                                pageSize: 1,
                                                                startDateBefore: nil,
                                                                startDateAfter: nil,
                                                                searchQuery: nil)
                let hasRemoteBookings = !bookings.isEmpty
                onCompletion(.success(hasRemoteBookings))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Searches for bookings matching the specified criteria and search query.
    /// Returns results immediately without saving to storage.
    ///
    func searchBookings(siteID: Int64,
                       searchQuery: String,
                       pageNumber: Int,
                       pageSize: Int,
                       startDateBefore: String?,
                       startDateAfter: String?,
                       onCompletion: @escaping (Result<[Booking], Error>) -> Void) {
        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize,
                                                                startDateBefore: startDateBefore,
                                                                startDateAfter: startDateAfter,
                                                                searchQuery: searchQuery)
                onCompletion(.success(bookings))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}


// MARK: - Storage: Booking
//
private extension BookingStore {

    /// Updates (OR Inserts) the specified ReadOnly Booking Entities *in a background thread* async.
    /// Also deletes existing bookings if requested.
    func upsertStoredBookingsInBackground(readOnlyBookings: [Yosemite.Booking],
                                          readOnlyOrders: [Yosemite.Order],
                                          siteID: Int64,
                                          shouldDeleteExistingBookings: Bool = false) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume()
            }

            upsertStoredBookingsInBackground(readOnlyBookings: readOnlyBookings,
                                             readOnlyOrders: readOnlyOrders,
                                             siteID: siteID,
                                             shouldDeleteExistingBookings: shouldDeleteExistingBookings) {
                continuation.resume()
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Booking Entities *in a background thread*.
    /// Also deletes existing bookings if requested.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertStoredBookingsInBackground(readOnlyBookings: [Yosemite.Booking],
                                          readOnlyOrders: [Yosemite.Order],
                                          siteID: Int64,
                                          shouldDeleteExistingBookings: Bool = false,
                                          onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else {
                return onCompletion()
            }
            if shouldDeleteExistingBookings {
                storage.deleteBookings(siteID: siteID)
            }
            upsertStoredBookings(readOnlyBookings: readOnlyBookings, readOnlyOrders: readOnlyOrders, in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly Booking Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyBookings: Remote Bookings to be persisted.
    ///     - readOnlyOrders: Remote Orders associated with bookings.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredBookings(readOnlyBookings: [Networking.Booking], readOnlyOrders: [Yosemite.Order], in storage: StorageType) {
        // Fetch all existing bookings for the site at once
        let bookingIDs = readOnlyBookings.map { $0.bookingID }
        let siteID = readOnlyBookings.first?.siteID ?? 0
        let storedBookings = storage.loadBookings(siteID: siteID, bookingIDs: bookingIDs)

        for readOnlyBooking in readOnlyBookings {
            // Filter to find existing booking by booking ID
            let storageBooking = storedBookings.first { $0.bookingID == readOnlyBooking.bookingID } ??
                storage.insertNewObject(ofType: StorageBooking.self)

            // TODO: - Apply new Booking specific models
            if let associatedOrder = readOnlyOrders.first(where: { $0.orderID == readOnlyBooking.orderID }) {
                /// 1. Convert `Order` into `Booking` specific order, product and customer
                /// 2. Obtain corresponding associated `Storage` models from `storageBooking` or create new ones.
                /// 3. Update the above models with values from `associatedOrder`
                print("The order for the booking \(readOnlyBooking.bookingID): \(associatedOrder)")
            }

            storageBooking.update(with: readOnlyBooking)
        }
    }
}
