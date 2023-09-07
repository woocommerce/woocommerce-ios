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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }

    func didReceive(_ notification: UNNotification) {
        self.loadingIndicator?.isHidden = false

        Task {
            do {
                defer {
                    self.loadingIndicator?.isHidden = true
                }

                let note = try await viewModel.loadNotification(notification)

                _ = viewModel.formatContent2(note)

                let content = OrderNotificationView.Content(
                    storeName: "Cool Hats Store",
                    date: "September 5, 2023",
                    orderNumber: "#2322",
                    amount: "$99.01",
                    paymentMethod: nil,
                    shippingMethod: nil,
                    products: [
                        .init(count: "1", name: "Album"),
                        .init(count: "105", name: "Baked beans"),
                        .init(count: "10", name: "Pins"),
                        .init(count: "3", name: "Product with a really really long long name")

                    ])

                let orderView = OrderNotificationView(content: content)
                hostingView = UIHostingController(rootView: orderView)

                self.view.addSubview(hostingView.view)
                hostingView.view.translatesAutoresizingMaskIntoConstraints = false
                hostingView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

            } catch {
                self.label?.text = AppLocalizedString("Unable to load notification",
                                                      comment: "Text when failing to load a notification after long pressing on it.")
            }
        }
    }
}


final class OrderNotificationViewModel {

    // Define possible error states.
    enum Error: Swift.Error {
        case noCredentials
        case network(Swift.Error)
        case unavailableNote
        case unsupportedNotification
    }

    private let remote: NotificationsRemote?

    init() {
        if let credentials = Self.fetchCredentials() {
            let network = AlamofireNetwork(credentials: credentials)
            self.remote = NotificationsRemote(network: network)
        } else {
            self.remote = nil
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
        guard let remote else {
            throw Error.noCredentials
        }

        /// Load notification from a remote source.
        ///
        return try await withCheckedThrowingContinuation { continuation in
            remote.loadNotes(noteIDs: [noteID]) { result in
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

    func formatContent(_ notification: Note) -> String {
        notification.body.compactMap { $0.text }.joined(separator: "\n")
    }

    func formatContent2(_ notification: Note) -> OrderNotificationView.Content {

        let subtitle = notification.subject.last?.text
        let storeName = subtitle?.components(separatedBy: "on").last ?? ""


        let rawContent = notification.body.flatMap { $0.text?.components(separatedBy: "\n") ?? [] }
        let rawDictionary = rawContent.reduce(into: [String: String]()) { dict, row in
            let components = row.components(separatedBy: ":")
            if components.count == 2 {
                dict[components[0]] = components[1]
            }
        }


        let content = OrderNotificationView.Content(
            storeName: storeName,
            date: rawDictionary["Date"] ?? "",
            orderNumber: rawDictionary["Order Number"] ?? "",
            amount: rawDictionary["Total"] ?? "",
            paymentMethod: rawDictionary["Payment Method"],
            shippingMethod: rawDictionary["Shipping Method"],
            products: [
                .init(count: "1", name: "Album"),
                .init(count: "105", name: "Baked beans"),
                .init(count: "10", name: "Pins"),
                .init(count: "3", name: "Product with a really really long long name")

            ])
        return content
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
