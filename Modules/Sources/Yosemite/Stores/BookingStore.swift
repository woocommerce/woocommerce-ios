import Foundation
import Networking
import Storage

// MARK: - BookingStore
//
public class BookingStore: Store {
    private let remote: BookingsRemoteProtocol

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = BookingsRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: BookingsRemoteProtocol) {
        self.remote = remote
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
        case let .synchronizeBookings(siteID, pageNumber, pageSize, onCompletion):
            synchronizeBookings(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
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
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let bookings = try await remote.loadAllBookings(for: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize)
                await upsertStoredBookingsInBackground(readOnlyBookings: bookings, siteID: siteID)
                let hasNextPage = bookings.count == pageSize
                onCompletion(.success(hasNextPage))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}


// MARK: - Storage: Booking
//
extension BookingStore {

    /// Updates (OR Inserts) the specified ReadOnly Booking Entities *in a background thread* async.
    /// Also deletes existing bookings if requested.
    func upsertStoredBookingsInBackground(readOnlyBookings: [Yosemite.Booking],
                                          siteID: Int64,
                                          shouldDeleteExistingBookings: Bool = false) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume()
            }
            upsertStoredBookingsInBackground(readOnlyBookings: readOnlyBookings,
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
            upsertStoredBookings(readOnlyBookings: readOnlyBookings, in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly Booking Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyBookings: Remote Bookings to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredBookings(readOnlyBookings: [Networking.Booking], in storage: StorageType) {
        // Fetch all existing bookings for the site at once
        let bookingIDs = readOnlyBookings.map { $0.bookingID }
        let siteID = readOnlyBookings.first?.siteID ?? 0
        let storedBookings = storage.loadBookings(siteID: siteID, bookingIDs: bookingIDs)

        for readOnlyBooking in readOnlyBookings {
            // Filter to find existing booking by booking ID
            let storageBooking = storedBookings.first { $0.bookingID == readOnlyBooking.bookingID } ??
                storage.insertNewObject(ofType: StorageBooking.self)

            storageBooking.update(with: readOnlyBooking)
        }
    }
}
