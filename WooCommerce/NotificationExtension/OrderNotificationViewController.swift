import UIKit
import UserNotifications
import UserNotificationsUI
import KeychainAccess
import Networking
import SwiftUI

class OrderNotificationViewController: UIViewController, UNNotificationContentExtension {

    @MainActor @IBOutlet var label: UILabel?
    @MainActor @IBOutlet var loadingIndicator: UIActivityIndicatorView?

    let viewModel = OrderNotificationViewModel()
    var hostingView: UIHostingController<OrderNotificationView>!

    func didReceive(_ notification: UNNotification) {

        // Show loading Indicator
        self.loadingIndicator?.isHidden = false

        Task {
            do {
                // Hide loading indicator after do block is finished.
                defer {
                    self.loadingIndicator?.isHidden = true
                }

                // Load notification, order and render order view.
                let note = try await viewModel.loadNotification(notification)
                let order = try await viewModel.loadOrder(for: note)
                let content = viewModel.formatContent(note: note, order: order)
                addOrderNotificationView(with: content)

            } catch {
                self.label?.text = AppLocalizedString("Unable to load notification",
                                                      comment: "Text when failing to load a notification after long pressing on it.")
            }
        }
    }

    @MainActor
    private func addOrderNotificationView(with content: OrderNotificationView.Content) {
        let orderView = OrderNotificationView(content: content)
        hostingView = UIHostingController(rootView: orderView)

        self.view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}


final class OrderNotificationViewModel {

    // Define possible error states.
    enum Error: Swift.Error {
        case noCredentials
        case network(Swift.Error)
        case unavailableNote
        case unsupportedNotification
        case unknown
    }

    private let notesRemote: NotificationsRemote?
    private let orderRemote: OrdersRemote?

    init() {
        if let credentials = Self.fetchCredentials() {
            let network = AlamofireNetwork(credentials: credentials)
            self.notesRemote = NotificationsRemote(network: network)
            self.orderRemote = OrdersRemote(network: network)
        } else {
            self.notesRemote = nil
            self.orderRemote = nil
        }
    }

    /// Loads a Note object from a given push notification object.
    ///
    @MainActor
    func loadNotification(_ notification: UNNotification) async throws -> Note {

        /// Only store order notifications are supported.
        ///
        guard notification.request.content.categoryIdentifier == "store_order" else {
            throw Error.unsupportedNotification
        }

        /// Error of we can't find `note_id` in the user info object
        ///
        guard let noteID = notification.request.content.userInfo["note_id"] as? Int64 else {
            throw Error.unavailableNote
        }

        /// Error if we couldn't create a remote object. This can happen if there are no valid credentials.
        ///
        guard let notesRemote else {
            throw Error.noCredentials
        }

        /// Load notification from a remote source.
        ///
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
    func loadOrder(for notification: Note) async throws -> Order {

        /// Notification must contain order and site ID.
        ///
        guard let siteID = notification.meta.identifier(forKey: .site),
              let orderID = notification.meta.identifier(forKey: .order) else {
            throw Error.unsupportedNotification
        }

        /// Error if we couldn't create a remote object. This can happen if there are no valid credentials.
        ///
        guard let orderRemote else {
            throw Error.noCredentials
        }

        /// Load notification from a remote source.
        ///
        return try await withCheckedThrowingContinuation { continuation in
            orderRemote.loadOrder(for: Int64(siteID), orderID: Int64(orderID)) { order, error in
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
                                             paymentMethod: order.paymentMethodTitle,
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
