import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class NotificationStore: Store {

    /// Shared private StorageType for use during then entire notification sync process
    ///
    private static var privateStorage: StorageType!

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

        remote.loadHashes(pageSize: Constants.maximumPageSize) { [weak self] (hashes, error) in
            guard let hashes = hashes else {
                onCompletion(error)
                return
            }

            // Step 1: Delete local missing notes
            self?.deleteLocalMissingNotes(from: hashes) {

                // TODO: Step 2: Determine what notes need updates
                // TODO: Step 3: Call the remote to fetch the notes that need updates (from step 2)
                // TODO: Step 4: Update the storage notes the the notes from step 3
                onCompletion(nil)
            }
        }
    }
}


// MARK: - Private Helpers
//
private extension NotificationStore {

    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteHashes: Collection of NoteHash.
    ///
    func deleteLocalMissingNotes(from remoteHashes: [NoteHash], completion: @escaping (() -> Void)) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)
        let remoteIds = remoteHashes.map { $0.noteID }
        let predicate = NSPredicate(format: "NOT (noteID IN %@)", remoteIds)

        for orphan in derivedStorage.allObjects(ofType: Storage.Note.self, matching: predicate, sortedBy: nil) {
            derivedStorage.deleteObject(orphan)
        }

        derivedStorage.saveIfNeeded()
        DispatchQueue.main.async {
            completion()
        }
    }
}


// MARK: - Thread Safety Helpers
//
extension NotificationStore {
    /// Returns the current shared derived StorageType, if any. Otherwise proceeds to create a new
    /// derived StorageType, given a specified StorageManagerType.
    ///
    static func sharedDerivedStorage(with manager: StorageManagerType) -> StorageType {
        if privateStorage == nil {
            privateStorage = manager.newDerivedStorage()
        }
        return privateStorage
    }

    /// Nukes the private Shared Derived Context instance. For unit testing purposes.
    ///
    static func resetSharedDerivedContext() {
        privateStorage = nil
    }
}


// MARK: - Constants!
//
extension NotificationStore {

    enum Constants {
        static let maximumPageSize: Int = 100
    }
}
