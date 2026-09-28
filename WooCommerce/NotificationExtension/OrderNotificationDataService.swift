import Foundation
import NetworkingCore

/// This wrapper to fetch orders from a notification.
///
@MainActor
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

    private let credentials: Credentials

    /// Notifications remote
    ///
    private let notesRemote: NotificationsRemote

    /// Network helper.
    ///
    private let network: AlamofireNetwork

    init(credentials: Credentials) {
        self.credentials = credentials
        network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        ordersRemote = OrdersRemote(network: network)
        notesRemote = NotificationsRemote(network: network)
    }

    ///  Marks a notification as read when the given `orderID` matches `orderID` of the provided notification.
    ///
    func markOrderNoteAsReadIfNeeded(noteID: Int64, orderID: Int) async -> Result<Int64, MarkOrderAsReadUseCase.Error> {
        return await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network, noteID: noteID, orderID: orderID)
    }

    func loadOrderFrom(notification: PushNotification) async throws -> Order {
        guard let orderID = notification.meta?.identifier(forKey: .order) else {
            throw Error.unsupportedNotification
        }
        return try await loadOrder(siteID: notification.siteID, orderID: orderID)
    }

    func loadStoreName(id: Int64) async throws -> String {
        // The async remote owns a separate network so it cannot race with order and notification requests.
        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil)
        let siteRemote = SiteRemote(network: network, dotcomClientID: "", dotcomClientSecret: "")
        return try await siteRemote.loadSite(siteID: id).name
    }

    func loadOrder(siteID: Int64, orderID: Int) async throws -> Order {
        try await withCheckedThrowingContinuation { continuation in
            ordersRemote.loadOrder(for: siteID, orderID: Int64(orderID)) { order, error in
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
