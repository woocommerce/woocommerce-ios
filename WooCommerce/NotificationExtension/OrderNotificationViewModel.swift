import Foundation
import KeychainAccess
import NetworkingCore
import UserNotifications

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
    func loadOrder(from notification: UNNotification) async throws -> (Order, String) {

        /// Only store order notifications are supported.
        ///
        guard notification.request.content.categoryIdentifier == Note.Kind.storeOrder.rawValue else {
            throw Error.unsupportedNotification
        }

        /// Error if there are no valid credentials.
        ///
        guard let credentials = Self.fetchCredentials() else {
            throw Error.noCredentials
        }

        let dataService = OrderNotificationDataService(credentials: credentials)
        if let notificationData = PushNotification.from(userInfo: notification.request.content.userInfo) {
            async let order = dataService.loadOrderFrom(notification: notificationData)
            async let storeName = dataService.loadStoreName(id: notificationData.siteID)
            return (try await order, try await storeName)
        } else {
            throw Error.unsupportedNotification
        }
    }

    /// Formats the information from the provided `Note` and `Order` to build a  `OrderNotificationView.Content` object.
    ///
    func formatContent(order: Order, storeName: String) -> OrderNotificationView.Content {
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
    private static func fetchCredentials() -> Credentials? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        guard let authToken = keychain[WooConstants.authToken] else {
            return nil
        }
        return Credentials(authToken: authToken)
    }
}
