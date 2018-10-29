import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class NotificationStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: NotificationAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? NotificationAction else {
            assertionFailure("NotificationStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeNotifications(let onCompletion):
            synchronizeNotifications(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension NotificationStore {

    /// Retrieves the latest notifications (if any!).
    ///
    func synchronizeNotifications(onCompletion: @escaping (Error?) -> Void) {
        let remote = NotificationsRemote(network: network)

        remote.loadHashes(pageSize: Constants.maximumPageSize) { (hashes, error) in
            guard let hashes = hashes else {
                onCompletion(error)
                return
            }

            // TODO: Step 1: Delete local missing notes            
            // TODO: Step 2: Determine what notes need updates
            // TODO: Step 3: Call the remote to fetch the notes that need updates (from step 2)
            // TODO: Step 4: Update the storage notes the the notes from step 3

            onCompletion(nil)
        }
    }
}


// MARK: - Persistence
//
extension OrderStore {

    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteHashes: Collection of NoteHash.
    ///
    func deleteLocalMissingNotes(from remoteHashes: [NoteHash], completion: @escaping (() -> Void)) {
        // TODO: Fill me in!
    }
}


// MARK: - Constants!
//
extension NotificationStore {

    enum Constants {
        static let maximumPageSize: Int = 100
    }
}

