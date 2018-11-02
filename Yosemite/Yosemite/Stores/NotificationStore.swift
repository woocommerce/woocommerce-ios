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

        remote.loadNotes(pageSize: Constants.maximumPageSize) { [weak self] (remoteNotes, error) in
            guard let `self` = self, let remoteNotes = remoteNotes else {
                onCompletion(error)
                return
            }

            // Step 1: Delete local missing notes
            let remoteIDs = remoteNotes.map({ $0.noteId })
            self.deleteLocalMissingNotes(from: remoteIDs) {

                // Step 2: Update the storage notes from the fetched notes
                self.updateLocalNotes(with: remoteNotes) {
                    onCompletion(nil)
                }
            }
        }
    }
}


// MARK: - Persistence
//
private extension NotificationStore {

    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteIds: Collection of remote Note IDs.
    ///
    func deleteLocalMissingNotes(from remoteIDs: [Int64], completion: @escaping (() -> Void)) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            let predicate = NSPredicate(format: "NOT (noteID IN %@)", remoteIDs)

            for orphan in derivedStorage.allObjects(ofType: Storage.Note.self, matching: predicate, sortedBy: nil) {
                derivedStorage.deleteObject(orphan)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Given a collection of Notes, this method will insert missing local ones, and update the others that can be found.
    ///
    /// - Parameters:
    ///     - remoteNotes: Collection of Notes
    ///     - completion: Callback to be executed on completion
    ///
    func updateLocalNotes(with remoteNotes: [Note], completion: (() -> Void)? = nil) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            for remoteNote in remoteNotes {
                let predicate = NSPredicate(format: "(noteID == %ld)", remoteNote.noteId)
                let localNote = derivedStorage.firstObject(ofType: Storage.Note.self, matching: predicate) ?? derivedStorage.insertNewObject(ofType: Storage.Note.self)

                localNote.update(with: remoteNote)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async {
                completion?()
            }
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
}


// MARK: - Constants!
//
extension NotificationStore {

    enum Constants {
        static let maximumPageSize: Int = 100
    }
}
