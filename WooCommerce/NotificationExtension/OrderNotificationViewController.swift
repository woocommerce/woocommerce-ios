import UIKit
import UserNotifications
import UserNotificationsUI
import KeychainAccess
import Networking

class OrderNotificationViewController: UIViewController, UNNotificationContentExtension {

    @MainActor @IBOutlet var label: UILabel?

    let viewModel = OrderNotificationViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }

    func didReceive(_ notification: UNNotification) {
        self.label?.text = "Loading..."
        Task {
            do {
                let note = try await viewModel.loadNotification(notification)
                self.label?.text = viewModel.formatContent(note)
            } catch {
                self.label?.text = error.localizedDescription
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
        case unknownNotification
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
