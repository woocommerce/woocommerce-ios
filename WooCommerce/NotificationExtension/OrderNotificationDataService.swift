import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif

/// This wrapper to fetch orders from a notification.
///
final class OrderNotificationDataService {
    /// Possible error states.
    ///
    enum Error: Swift.Error {
        case network(Swift.Error)
        case unavailableNote
        case unsupportedNotification
        case unknown
    }

    /// Orders remote
    ///
    private let ordersRemote: OrdersRemote

    /// Notifications remote
    ///
    private let notesRemote: NotificationsRemote

    /// Network helper.
    ///
    private let network: AlamofireNetwork

    init(credentials: Credentials) {
        network = AlamofireNetwork(credentials: credentials)
        ordersRemote = OrdersRemote(network: network)
        notesRemote = NotificationsRemote(network: network)
    }

    /// Loads the order associated with the given note id if possible.
    ///
    @MainActor
    func loadOrderFrom(noteID: Int64) async throws -> (Note, Order) {
        let note = try await loadNotification(noteID: noteID)
        let order = try await loadOrder(from: note)
        return (note, order)
    }

    /// Loads a Note object from a remote source.
    ///
    @MainActor
    private func loadNotification(noteID: Int64) async throws -> Note {
        return try await withCheckedThrowingContinuation { continuation in
            notesRemote.loadNotes(noteIDs: [noteID]) { result in
                switch result {
                case .success(let notes):
                    if let note = notes.first {
                        continuation.resume(returning: note)
                    } else {
                        continuation.resume(throwing: Error.unavailableNote)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Loads an Order object from a given Note object.
    ///
    @MainActor
    private func loadOrder(from notification: Note) async throws -> Order {

        /// Notification must contain order and site ID.
        ///
        guard let siteID = notification.meta.identifier(forKey: .site),
              let orderID = notification.meta.identifier(forKey: .order) else {
            throw Error.unsupportedNotification
        }

        /// Load notification from a remote source.
        ///
        return try await withCheckedThrowingContinuation { continuation in
            ordersRemote.loadOrder(for: Int64(siteID), orderID: Int64(orderID)) { order, error in
                switch (order, error) {
                case (let order?, nil):
                    continuation.resume(returning: order)
                case (_, let error?):
                    continuation.resume(throwing: Error.network(error))
                default:
                    continuation.resume(throwing: Error.unknown)
                }
            }
        }
    }
}
