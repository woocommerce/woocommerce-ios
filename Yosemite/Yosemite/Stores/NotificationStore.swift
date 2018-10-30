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

        remote.loadHashes(pageSize: Constants.maximumPageSize) { [weak self] (remoteHashes, error) in
            guard let `self` = self, let remoteHashes = remoteHashes else {
                onCompletion(error)
                return
            }

            // Step 1: Delete local missing notes
            self.deleteLocalMissingNotes(from: remoteHashes) {

                // Step 2: Determine what noteIDs need updates
                self.determineUpdatedNotes(with: remoteHashes) { outdatedNoteIds in
                    guard outdatedNoteIds.isEmpty == false else {
                        onCompletion(nil)
                        return
                    }

                    // Step 3: Call the remote to fetch the notes that need updates (from Step 2's noteIDs)
                    remote.loadNotes(noteIds: outdatedNoteIds) { (remoteNotes, error) in
                        guard let remoteNotes = remoteNotes else {
                            onCompletion(error)
                            return
                        }

                        // Step 4: Update the storage notes from the fetched notes
                        self.updateLocalNotes(with: remoteNotes) {
                            onCompletion(nil)
                            self.storageManager.viewStorage.saveIfNeeded()
                        }
                    }
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
    /// - Parameter remoteHashes: Collection of NoteHash.
    ///
    func deleteLocalMissingNotes(from remoteHashes: [NoteHash], completion: @escaping (() -> Void)) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)
        let remoteIds = remoteHashes.map { $0.noteID }
        let predicate = NSPredicate(format: "NOT (noteID IN %@)", remoteIds)

        for orphan in derivedStorage.allObjects(ofType: Storage.Note.self, matching: predicate, sortedBy: nil) {
            derivedStorage.deleteObject(orphan)
        }

        storageManager.saveDerivedType(derivedStorageType: derivedStorage) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Given a collection of NoteHashes, this method will determine the NotificationID's
    /// that are either missing in our database, or have been remotely updated.
    ///
    /// - Parameters:
    ///     - remoteHashes: Collection of NoteHash
    ///     - completion: Callback to be executed on completion (returns an array of noteIDs that need updating)
    ///
    func determineUpdatedNotes(with remoteHashes: [NoteHash], completion: @escaping (([String]) -> Void)) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)
        let remoteIds = remoteHashes.map { $0.noteID }
        let predicate = NSPredicate(format: "(noteID IN %@)", remoteIds)
        var localHashes = [String: String]()

        for note in derivedStorage.allObjects(ofType: Storage.Note.self, matching: predicate, sortedBy: nil) {
            localHashes[String(note.noteID)] = String(note.noteHash)
        }

        let filtered = remoteHashes.filter { remote in
            let localHash = localHashes[String(remote.noteID)]
            return localHash == nil || localHash != String(remote.noteID)
        }

        // TODO: Do we need a reset here? e.g. derivedStorage.reset()

        let outdatedIds = filtered.map { String($0.noteID) }
        DispatchQueue.main.async {
            completion(outdatedIds)
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

        for remoteNote in remoteNotes {
            let predicate = NSPredicate(format: "(noteID == %ld)", remoteNote.noteId)
            let localNote = derivedStorage.firstObject(ofType: Storage.Note.self, matching: predicate) ?? derivedStorage.insertNewObject(ofType: Storage.Note.self)

            localNote.update(with: remoteNote)
        }

        storageManager.saveDerivedType(derivedStorageType: derivedStorage) {
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
