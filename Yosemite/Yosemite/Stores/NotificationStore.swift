import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class NotificationStore: Store {

    /// Thread Safety
    ///
    private static let lock = NSLock()

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
        case .registerDevice(let device, let applicationId, let applicationVersion, let defaultStoreID, let onCompletion):
            registerDevice(device: device,
                           applicationId: applicationId,
                           applicationVersion: applicationVersion,
                           defaultStoreID: defaultStoreID,
                           onCompletion: onCompletion)
        case .synchronizeNotifications(let onCompletion):
            synchronizeNotifications(onCompletion: onCompletion)
        case .synchronizeNotification(let noteID, let onCompletion):
            synchronizeNotification(with: noteID, onCompletion: onCompletion)
        case .unregisterDevice(let deviceId, let onCompletion):
            unregisterDevice(deviceId: deviceId, onCompletion: onCompletion)
        case .updateLastSeen(let timestamp, let onCompletion):
            updateLastSeen(timestamp: timestamp, onCompletion: onCompletion)
        case .updateReadStatus(let noteID, let read, let onCompletion):
            updateReadStatus(for: [noteID], read: read, onCompletion: onCompletion)
        case .updateMultipleReadStatus(let noteIDs, let read, let onCompletion):
            updateReadStatus(for: noteIDs, read: read, onCompletion: onCompletion)
        case .updateLocalDeletedStatus(let noteID, let deleteInProgress, let onCompletion):
            updateDeletedStatus(noteID: noteID, deleteInProgress: deleteInProgress, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension NotificationStore {

    /// Registers an APNS Device in the WordPress.com Delivery Subsystem.
    ///
    func registerDevice(device: APNSDevice,
                        applicationId: String,
                        applicationVersion: String,
                        defaultStoreID: Int64,
                        onCompletion: @escaping (DotcomDevice?, Error?) -> Void) {
        let remote = DevicesRemote(network: network)
        remote.registerDevice(device: device,
                              applicationId: applicationId,
                              applicationVersion: applicationVersion,
                              defaultStoreID: defaultStoreID,
                              completion: onCompletion)
    }

    /// Unregisters a Dotcom Device from the Push Notifications Delivery Subsystem.
    ///
    func unregisterDevice(deviceId: String, onCompletion: @escaping (Error?) -> Void) {
        let remote = DevicesRemote(network: network)
        remote.unregisterDevice(deviceId: deviceId, completion: onCompletion)
    }


    /// Retrieves the latest notifications (if any!).
    ///
    func synchronizeNotifications(onCompletion: @escaping (Error?) -> Void) {
        let remote = NotificationsRemote(network: network)

        remote.loadHashes(pageSize: Constants.maximumPageSize) { [weak self] (hashes, error) in
            guard let hashes = hashes else {
                onCompletion(error)
                return
            }

            self?.deleteLocalMissingNotes(from: hashes) { [weak self] in

                self?.determineUpdatedNotes(using: hashes) { outdatedIDs in

                    guard outdatedIDs.isEmpty == false else {
                        onCompletion(nil)
                        return
                    }

                    remote.loadNotes(noteIDs: outdatedIDs, pageSize: Constants.maximumPageSize) { [weak self] (notes, error) in

                        guard let notes = notes else {
                            onCompletion(error)
                            return
                        }

                        self?.updateLocalNotes(with: notes) {
                            onCompletion(nil)
                        }
                    }
                }
            }
        }
    }


    /// Synchronizes the Notification matching the specified ID, and updates the local entity.
    ///
    /// - Parameters:
    ///     - noteID: Notification ID of the note to be downloaded.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func synchronizeNotification(with noteID: Int64, onCompletion: @escaping (Note?, Error?) -> Void) {
        let remote = NotificationsRemote(network: network)

        remote.loadNotes(noteIDs: [noteID]) { notes, error in
            guard let notes = notes else {
                onCompletion(nil, error)
                return
            }

            self.updateLocalNotes(with: notes) {
                onCompletion(notes.first, nil)
            }
        }
    }


    /// Updates the last seen notification
    ///
    func updateLastSeen(timestamp: String, onCompletion: @escaping (Error?) -> Void) {
        let remote = NotificationsRemote(network: network)
        remote.updateLastSeen(timestamp) { (error) in
            onCompletion(error)
        }
    }


    /// Updates the read status for the given notification ID(s)
    ///
    func updateReadStatus(for noteIDs: [Int64], read: Bool, onCompletion: @escaping (Error?) -> Void) {
        /// Optimistically Update
        ///
        updateLocalNoteReadStatus(for: noteIDs, read: read)

        /// On error we'll just mark the Note for Refresh
        ///
        let remote = NotificationsRemote(network: network)
        remote.updateReadStatus(noteIDs: noteIDs, read: read) { error in
            guard let error = error else {

                /// What is this about:
                /// Notice that there are few conditions in which the Network Request's callback may run *before*
                /// the Optimisitc Update, such as in Unit Tests.
                /// This may cause the Callback to run before the Read Flag has been toggled, which isn't cool.
                /// *FORGIVE ME*, this is a workaround: the onCompletion closure must run after a No-OP in the derived
                /// storage.
                ///
                self.performSharedDerivedStorageNoOp {
                    onCompletion(nil)
                }
                return
            }

            self.invalidateCache(for: noteIDs) {
                onCompletion(error)
            }
        }
    }

    /// Marks the provided notification as "currently being deleted" — no network call is made. This is
    /// useful for filtering on the notifications list.
    ///
    func updateDeletedStatus(noteID: Int64, deleteInProgress: Bool, onCompletion: @escaping (Error?) -> Void) {
        markLocalNoteAsDeleted(for: noteID, isDeleted: deleteInProgress) {
            onCompletion(nil)
        }
    }
}


// MARK: - Persistence
//
extension NotificationStore {

    /// Deletes the collection of local notifications that cannot be found in a given collection of
    /// remote hashes.
    ///
    /// - Parameter remoteIds: Collection of remote Note IDs.
    ///
    func deleteLocalMissingNotes(from hashes: [NoteHash], completion: @escaping (() -> Void)) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            // The beauty of threadsafe Immutable Entities!!
            let remoteIDs = hashes.map { $0.noteID }
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
    func updateLocalNotes(with remoteNotes: [Note], onCompletion: (() -> Void)? = nil) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            for remoteNote in remoteNotes {
                let localNote = derivedStorage.loadNotification(noteID: remoteNote.noteID) ?? derivedStorage.insertNewObject(ofType: Storage.Note.self)
                localNote.update(with: remoteNote)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            guard let onCompletion = onCompletion else {
                return
            }

            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates the read status for the specified Notifications. The callback happens on the Main Thread.
    ///
    func updateLocalNoteReadStatus(for noteIDs: [Int64], read: Bool, onCompletion: (() -> Void)? = nil) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            let notifications = noteIDs.compactMap { derivedStorage.loadNotification(noteID: $0) }
            for note in notifications {
                note.read = read
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            guard let onCompletion = onCompletion else {
                return
            }

            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Given a collection of NoteHash Entities, this method will determine the `.noteID`'s of those entities that
    /// are either not locally found, or got their `.hash` field outdated.
    ///
    func determineUpdatedNotes(using hashes: [NoteHash], completion: @escaping ([Int64]) -> Void) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            let remoteIds = hashes.map { $0.noteID }
            let predicate = NSPredicate(format: "noteID IN %@", remoteIds)
            var localHashes = [Int64: Int64]()

            for note in derivedStorage.allObjects(ofType: StorageNote.self, matching: predicate, sortedBy: nil) {
                localHashes[note.noteID] = Int64(note.noteHash)
            }

            let outdated = hashes.filter { remote in
                let localHash = localHashes[remote.noteID]
                return localHash == nil || localHash != remote.hash
            }

            let outdatedIds = outdated.map { $0.noteID }

            DispatchQueue.main.async {
                completion(outdatedIds)
            }
        }
    }

    /// Invalidates the Hash for the specified Notifications.
    ///
    func invalidateCache(for noteIDs: [Int64], onCompletion: (() -> Void)? = nil) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            let notifications = noteIDs.compactMap { derivedStorage.loadNotification(noteID: $0) }
            for note in notifications {
                note.noteHash = Int64.min
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            guard let onCompletion = onCompletion else {
                return
            }

            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Runs a No-OP in the Shared Derived Storage. On completion, the callback will be executed on the main thread.
    ///
    func performSharedDerivedStorageNoOp(onCompletion: @escaping () -> Void) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates the deletion "status" for the specified Notification. The callback happens on the Main Thread.
    ///
    func markLocalNoteAsDeleted(for noteID: Int64, isDeleted: Bool, onCompletion: (() -> Void)? = nil) {
        let derivedStorage = type(of: self).sharedDerivedStorage(with: storageManager)

        derivedStorage.perform {
            let notification = derivedStorage.loadNotification(noteID: noteID)
            notification?.deleteInProgress = isDeleted
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            guard let onCompletion = onCompletion else {
                return
            }

            DispatchQueue.main.async(execute: onCompletion)
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
        lock.lock()
        if privateStorage == nil {
            privateStorage = manager.newDerivedStorage()
        }
        lock.unlock()

        return privateStorage
    }

    /// Nukes the private Shared Derived Storage instance.
    ///
    static func resetSharedDerivedStorage() {
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
