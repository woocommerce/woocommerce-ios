import Foundation
import KeychainAccess
import Networking

/// View Model for the `OrderNotificationViewController`type.
///
final class OrderNotificationViewModel {

    // Define possible error states.
    enum Error: Swift.Error {
        case noCredentials
        case unavailableNote
        case unsupportedNotification
    }

    /// Loads a Note object from a given push notification object.
    ///
    @MainActor
    func loadOrder(from notification: UNNotification) async throws -> (Note, Order) {

        /// Only store order notifications are supported.
        ///
        guard notification.request.content.categoryIdentifier == Note.Kind.storeOrder.rawValue else {
            throw Error.unsupportedNotification
        }

        /// Error of we can't find `note_id` in the user info object
        ///
        guard let noteID = notification.request.content.userInfo["note_id"] as? Int64 else {
            throw Error.unavailableNote
        }

        /// Error if there are no valid credentials.
        ///
        guard let credentials = Self.fetchCredentials() else {
            throw Error.noCredentials
        }

        let dataService = OrderNotificationDataService(credentials: credentials)
        return try await dataService.loadOrderFrom(noteID: noteID)
    }

    /// Formats the information from the provided `Note` and `Order` to build a  `OrderNotificationView.Content` object.
    ///
    func formatContent(note: Note, order: Order) -> OrderNotificationView.Content {

        // Extract the store name from the notification subject using the provided store name indices
        let storeName: String = {
            guard let subtitle = note.subject.last?.text,
                  let indices = note.subject.last?.ranges.first?.range else {
                return AppLocalizedString("My Store", comment: "Placeholder store name on a notification")
            }

            let storeIndex = subtitle.index(subtitle.startIndex, offsetBy: indices.lowerBound)
            return String(subtitle.suffix(from: storeIndex))
        }()

        // Format order paid or order created date
        let date: String = {
            let date = order.datePaid ?? order.dateCreated

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none

            return formatter.string(from: date)
        }()

        // Map order line items into view products.
        let items = order.items.map { OrderNotificationView.Content.Product(count: "\($0.quantity)", name: $0.name) }

        return OrderNotificationView.Content(storeName: storeName,
                                             date: date,
                                             orderNumber: "#\(order.orderID)",
                                             amount: "\(order.currencySymbol)\(order.total)",
                                             paymentMethod: order.paymentMethodTitle.lowercased(),
                                             shippingMethod: order.shippingLines.first?.methodTitle,
                                             products: items)
    }

    /// Fetches WPCom credentials if possible.
    /// We only care `WPCom` because other forms of auth do not support notifications.
    ///
    static private func fetchCredentials() -> Credentials? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        guard let authToken = keychain[WooConstants.authToken] else {
            return nil
        }
        return Credentials(authToken: authToken)
    }
}
