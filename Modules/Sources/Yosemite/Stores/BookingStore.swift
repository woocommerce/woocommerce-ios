import Foundation
import Networking
import Storage

// MARK: - BookingStore
//
public class BookingStore: Store {
    private let remote: BookingsRemoteProtocol
    private let ordersRemote: OrdersRemoteProtocol

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = BookingsRemote(network: network)
        let ordersRemote = OrdersRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote, ordersRemote: ordersRemote)
    }

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: BookingsRemoteProtocol,
                ordersRemote: OrdersRemoteProtocol) {
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
        case let .synchronizeBookings(siteID, pageNumber, pageSize, filters, order, shouldClearCache, onCompletion):
            synchronizeBookings(siteID: siteID,
                                pageNumber: pageNumber,
                                pageSize: pageSize,
                                filters: filters,
                                order: order,
                                shouldClearCache: shouldClearCache,
                                onCompletion: onCompletion)
        case .synchronizeBooking(siteID: let siteID, bookingID: let bookingID, onCompletion: let onCompletion):
            synchronizeBooking(siteID: siteID, bookingID: bookingID, onCompletion: onCompletion)
        case let .checkIfStoreHasBookings(siteID, onCompletion):
            checkIfStoreHasBookings(siteID: siteID, onCompletion: onCompletion)
        case let .searchBookings(siteID, searchQuery, pageNumber, pageSize, filters, order, onCompletion):
            searchBookings(siteID: siteID,
                           searchQuery: searchQuery,
                           pageNumber: pageNumber,
                           pageSize: pageSize,
                           filters: filters,
                           order: order,
                           onCompletion: onCompletion)
        case let .fetchResource(siteID, resourceID, onCompletion):
            fetchResource(siteID: siteID, resourceID: resourceID, onCompletion: onCompletion)
        case let .synchronizeResources(siteID, pageNumber, pageSize, onCompletion):
            synchronizeResources(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .updateBookingAttendanceStatus(let siteID, let bookingID, let status, let onCompletion):
            performUpdateBookingAttendanceStatus(
                siteID: siteID,
                bookingID: bookingID,
                status: status,
                onCompletion: onCompletion
            )
        case .cancelBooking(let siteID, let bookingID, let onCompletion):
            cancelBooking(
                siteID: siteID,
                bookingID: bookingID,
                onCompletion: onCompletion
            )
        case .markBookingAsPaid(let siteID, let bookingID, let onCompletion):
            markBookingAsPaid(
                siteID: siteID,
                bookingID: bookingID,
                onCompletion: onCompletion
            )
        case .updateBookingNote(let siteID, let bookingID, let note, let onCompletion):
            updateBookingNote(
                siteID: siteID,
                bookingID: bookingID,
                note: note,
                onCompletion: onCompletion
            )
        case .clearBookingsCache(siteID: let siteID, onCompletion: let onCompletion):
            clearBookingsCache(siteID: siteID, onCompletion: onCompletion)
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
                             filters: BookingFilters?,
                             order: BookingsRemote.Order,
                             shouldClearCache: Bool,
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize,
                                                                filters: filters,
                                                                searchQuery: nil,
                                                                order: order)

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

    func synchronizeBooking(
        siteID: Int64,
        bookingID: Int64,
        onCompletion: @escaping (Result<Void, Error>) -> Void
    ) {
        enum SynchronizeBookingError: Error {
            case bookingIsMissing
        }

        Task { @MainActor in
            do {
                let booking = try await remote.loadBooking(
                    bookingID: bookingID,
                    siteID: siteID
                )

                guard let booking else {
                    onCompletion(.failure(SynchronizeBookingError.bookingIsMissing))
                    return
                }

                let orders = try await ordersRemote.loadOrders(
                    for: siteID,
                    orderIDs: [booking.orderID]
                )

                await upsertStoredBookingsInBackground(
                    readOnlyBookings: [booking],
                    readOnlyOrders: orders,
                    siteID: siteID
                )

                onCompletion(.success(()))
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
                                                                filters: nil,
                                                                searchQuery: nil,
                                                                order: .descending)
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
                        filters: BookingFilters?,
                        order: BookingsRemote.Order,
                        onCompletion: @escaping (Result<[Booking], Error>) -> Void) {
        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize,
                                                                filters: filters,
                                                                searchQuery: searchQuery,
                                                                order: order)
                let orders = try await ordersRemote.loadOrders(
                    for: siteID,
                    orderIDs: bookings.map { $0.orderID }
                )
                let updatedBookings = bookings.map { booking in
                    guard let order = orders.first(where: { booking.orderID == $0.orderID }) else {
                        return booking
                    }
                    let orderInfo = BookingOrderInfo(booking: booking, order: order)
                    return booking.copy(orderInfo: orderInfo)
                }
                onCompletion(.success(updatedBookings))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Fetches a booking resource by resource ID and saves it to storage.
    ///
    func fetchResource(siteID: Int64,
                       resourceID: Int64,
                       onCompletion: @escaping (Result<BookingResource, Error>) -> Void) {
        enum FetchResourceError: Error {
            case resourceIsMissing
        }

        Task { @MainActor in
            do {
                let resource = try await remote.fetchResource(
                    resourceID: resourceID,
                    siteID: siteID
                )

                guard let resource else {
                    onCompletion(.failure(FetchResourceError.resourceIsMissing))
                    return
                }

                await upsertBookingResourcesInBackground(siteID: resource.siteID,
                                                         readOnlyBookingResources: [resource])

                onCompletion(.success(resource))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Synchronizes booking resources for the specified site.
    ///
    func synchronizeResources(siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let resources = try await remote.fetchResources(
                    for: siteID,
                    pageNumber: pageNumber,
                    pageSize: pageSize
                )

                await upsertBookingResourcesInBackground(siteID: siteID,
                                                         readOnlyBookingResources: resources)

                let hasNextPage = resources.count == pageSize
                onCompletion(.success(hasNextPage))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func performUpdateBookingAttendanceStatus(
        siteID: Int64,
        bookingID: Int64,
        status: BookingAttendanceStatus,
        onCompletion: @escaping (Error?) -> Void
    ) {
        updateBookingAttendanceStatusLocally(
            siteID: siteID,
            bookingID: bookingID,
            statusKey: status
        ) { [weak self] previousStatusKey in
            guard let self else {
                return onCompletion(UpdateBookingStatusError.undefinedState)
            }

            Task { @MainActor in
                do {
                    if let remoteBooking = try await self.remote.updateBooking(
                        from: siteID,
                        bookingID: bookingID,
                        attendanceStatus: status,
                        bookingStatus: nil,
                        note: nil,
                    ) {
                        await self.upsertStoredBookingsInBackground(
                            readOnlyBookings: [remoteBooking],
                            readOnlyOrders: [],
                            siteID: siteID
                        )

                        onCompletion(nil)
                    } else {
                        return onCompletion(UpdateBookingStatusError.missingRemoteBooking)
                    }
                } catch {
                    /// Revert Optimistic Update
                    self.updateBookingAttendanceStatusLocally(
                        siteID: siteID,
                        bookingID: bookingID,
                        statusKey: previousStatusKey
                    ) { _ in
                        onCompletion(error)
                    }
                }
            }
        }
    }

    func updateBookingNote(
        siteID: Int64,
        bookingID: Int64,
        note: String,
        onCompletion: @escaping (Error?) -> Void
    ) {
        Task { @MainActor in
            do {
                if let remoteBooking = try await self.remote.updateBooking(
                    from: siteID,
                    bookingID: bookingID,
                    attendanceStatus: nil,
                    bookingStatus: nil,
                    note: note,
                ) {
                    await self.upsertStoredBookingsInBackground(
                        readOnlyBookings: [remoteBooking],
                        readOnlyOrders: [],
                        siteID: siteID
                    )

                    onCompletion(nil)
                } else {
                    return onCompletion(UpdateBookingStatusError.missingRemoteBooking)
                }
            } catch {
                return onCompletion(error)
            }
        }
    }

    /// Updates local (Storage) Booking attendance status
    func updateBookingAttendanceStatusLocally(
        siteID: Int64,
        bookingID: Int64,
        statusKey: BookingAttendanceStatus,
        onCompletion: @escaping (BookingAttendanceStatus) -> Void
    ) {
        storageManager.performAndSave({ storage -> BookingAttendanceStatus in
            guard let booking = storage.loadBooking(
                siteID: siteID,
                bookingID: bookingID
            ) else {
                return statusKey
            }

            let oldStatus = booking.attendanceStatusKey
            booking.attendanceStatusKey = statusKey.rawValue
            return BookingAttendanceStatus(rawValue: oldStatus ?? "") ?? .unknown
        }, completion: { result in
            switch result {
            case .success(let status):
                onCompletion(status)
            case .failure:
                onCompletion(statusKey)
            }
        }, on: .main)
    }

    /// Cancels a booking by updating its status to cancelled.
    func cancelBooking(
        siteID: Int64,
        bookingID: Int64,
        onCompletion: @escaping (Error?) -> Void
    ) {
        Task { @MainActor in
            do {
                if let remoteBooking = try await remote.updateBooking(
                    from: siteID,
                    bookingID: bookingID,
                    attendanceStatus: nil,
                    bookingStatus: .cancelled,
                    note: nil,
                ) {
                    await upsertStoredBookingsInBackground(
                        readOnlyBookings: [remoteBooking],
                        readOnlyOrders: [],
                        siteID: siteID
                    )

                    onCompletion(nil)
                } else {
                    return onCompletion(UpdateBookingStatusError.missingRemoteBooking)
                }
            } catch {
                onCompletion(error)
            }
        }
    }

    /// Marks a booking as paid by updating its status to paid.
    func markBookingAsPaid(
        siteID: Int64,
        bookingID: Int64,
        onCompletion: @escaping (Error?) -> Void
    ) {
        Task { @MainActor in
            do {
                if let remoteBooking = try await remote.updateBooking(
                    from: siteID,
                    bookingID: bookingID,
                    attendanceStatus: nil,
                    bookingStatus: .paid,
                    note: nil,
                ) {
                    await upsertStoredBookingsInBackground(
                        readOnlyBookings: [remoteBooking],
                        readOnlyOrders: [],
                        siteID: siteID
                    )

                    onCompletion(nil)
                } else {
                    return onCompletion(UpdateBookingStatusError.missingRemoteBooking)
                }
            } catch {
                onCompletion(error)
            }
        }
    }

    func clearBookingsCache(siteID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteBookings(siteID: siteID)
        }, completion: onCompletion, on: .main)
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
    func upsertStoredBookings(readOnlyBookings: [Yosemite.Booking], readOnlyOrders: [Yosemite.Order], in storage: StorageType) {
        // Fetch all existing bookings for the site at once
        let bookingIDs = readOnlyBookings.map { $0.bookingID }
        let siteID = readOnlyBookings.first?.siteID ?? 0
        let storedBookings = storage.loadBookings(siteID: siteID, bookingIDs: bookingIDs)

        for readOnlyBooking in readOnlyBookings {
            // Filter to find existing booking by booking ID
            let storageBooking = storedBookings.first { $0.bookingID == readOnlyBooking.bookingID } ??
                storage.insertNewObject(ofType: StorageBooking.self)

            if let associatedOrder = readOnlyOrders.first(where: { $0.orderID == readOnlyBooking.orderID }) {
                let readOnlyOrderInfo = BookingOrderInfo(booking: readOnlyBooking, order: associatedOrder)

                let orderInfo = storageBooking.orderInfo ?? storage.insertNewObject(ofType: Storage.BookingOrderInfo.self)

                let productInfo = orderInfo.productInfo ?? storage.insertNewObject(ofType: Storage.BookingProductInfo.self)
                if let readOnlyProductInfo = readOnlyOrderInfo.productInfo {
                    productInfo.update(with: readOnlyProductInfo)
                }
                orderInfo.productInfo = productInfo

                let customerInfo = orderInfo.customerInfo ?? storage.insertNewObject(ofType: Storage.BookingCustomerInfo.self)
                if let readOnlyCustomerInfo = readOnlyOrderInfo.customerInfo {
                    customerInfo.update(with: readOnlyCustomerInfo)
                }
                orderInfo.customerInfo = customerInfo

                let paymentInfo = orderInfo.paymentInfo ?? storage.insertNewObject(ofType: Storage.BookingPaymentInfo.self)
                if let readOnlyPaymentInfo = readOnlyOrderInfo.paymentInfo {
                    paymentInfo.update(with: readOnlyPaymentInfo)
                }
                orderInfo.paymentInfo = paymentInfo

                orderInfo.statusKey = associatedOrder.status.rawValue
                orderInfo.datePaid = associatedOrder.datePaid
                orderInfo.total = NSDecimalNumber(string: associatedOrder.total)
                orderInfo.refundTotal = {
                    let sum = associatedOrder.refunds
                        .compactMap { Decimal(string: $0.total) }
                        .map { abs($0) }
                        .reduce(0, +)
                    return sum as NSDecimalNumber
                }()
                storageBooking.orderInfo = orderInfo
            }

            storageBooking.update(with: readOnlyBooking)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly BookingResource Entities *in a background thread* async.
    func upsertBookingResourcesInBackground(siteID: Int64, readOnlyBookingResources: [BookingResource]) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume()
            }

            storageManager.performAndSave({ storage in
                let storedItems = storage.loadBookingResources(
                    siteID: siteID,
                    resourceIDs: readOnlyBookingResources.map { $0.resourceID }
                )
                for item in readOnlyBookingResources {
                    let storageResource = storedItems.first(where: { $0.resourceID == item.resourceID }) ??
                    storage.insertNewObject(ofType: Storage.BookingResource.self)
                    storageResource.update(with: item)
                }
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }
}


// MARK: - Errors
//
private enum UpdateBookingStatusError: Error {
    case undefinedState
    case missingRemoteBooking
}
