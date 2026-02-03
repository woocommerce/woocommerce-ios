import Foundation
import NetworkingCore

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

    private let siteRemote: SiteRemote

    /// Notifications remote
    ///
    private let notesRemote: NotificationsRemote

    /// Network helper.
    ///
    private let network: AlamofireNetwork

    init(credentials: Credentials) {
        network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        ordersRemote = OrdersRemote(network: network)
        notesRemote = NotificationsRemote(network: network)
        siteRemote = SiteRemote(network: network, dotcomClientID: "", dotcomClientSecret: "")
    }

    ///  Marks a notification as read when the given `orderID` matches `orderID` of the provided notification.
    ///
    @MainActor
    func markOrderNoteAsReadIfNeeded(noteID: Int64, orderID: Int) async -> Result<Int64, MarkOrderAsReadUseCase.Error> {
        return await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network, noteID: noteID, orderID: orderID)
    }

    @MainActor
    func loadOrderFrom(notification: PushNotification) async throws -> Order {
        guard let orderID = notification.meta?.identifier(forKey: .order) else {
            throw Error.unsupportedNotification
        }
        return try await loadOrder(siteID: Int(notification.siteID), orderID: orderID)
    }

    @MainActor
    func loadStoreName(id: Int64) async throws -> String {
        try await siteRemote.loadSite(siteID: id).name
    }

    @MainActor
    private func loadOrder(siteID: Int, orderID: Int) async throws -> Order {
        try await withCheckedThrowingContinuation { continuation in
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
