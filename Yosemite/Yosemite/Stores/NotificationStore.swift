import Foundation
import Networking
import Storage


// MARK: - OrderStore
//
public class NotificationStore: Store {
    private let remote: NotificationsRemote
    private let devicesRemote: DevicesRemote

    /// Shared private StorageType for use during then entire notification sync process
    ///
    private static var privateStorage: StorageType!

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = NotificationsRemote(network: network)
        self.devicesRemote = DevicesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case .registerDevice(let device,
                             let applicationId,
                             let applicationVersion,
                             let defaultStoreID,
                             let onCompletion):
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
        devicesRemote.registerDevice(device: device,
                              applicationId: applicationId,
                              applicationVersion: applicationVersion,
                              defaultStoreID: defaultStoreID,
                              completion: onCompletion)
    }

    /// Unregisters a Dotcom Device from the Push Notifications Delivery Subsystem.
    ///
    func unregisterDevice(deviceId: String, onCompletion: @escaping (Error?) -> Void) {
        devicesRemote.unregisterDevice(deviceId: deviceId, completion: onCompletion)
    }


    /// Retrieves the latest notifications (if any!).
    ///
    func synchronizeNotifications(onCompletion: @escaping (Error?) -> Void) {
        remote.loadHashes(pageSize: Constants.maximumPageSize) { [weak self] (hashes, error) in
            guard let hashes = hashes else {
                onCompletion(error)
                return
            }

            self?.deleteLocalMissingNotes(from: hashes) { [weak self] outdatedIDs in

                guard outdatedIDs.isEmpty == false else {
                    onCompletion(nil)
                    return
                }

                self?.remote.loadNotes(noteIDs: outdatedIDs, pageSize: Constants.maximumPageSize) { result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .failure(let error):
                        onCompletion(error)
                    case .success(let notes):
                        self.updateLocalNotes(with: notes) {
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
        remote.loadNotes(noteIDs: [noteID]) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                onCompletion(nil, error)
            case .success(let notes):
                self.updateLocalNotes(with: notes) {
                    onCompletion(notes.first, nil)
                }
            }
        }
    }


    /// Updates the last seen notification
    ///
    func updateLastSeen(timestamp: String, onCompletion: @escaping (Error?) -> Void) {
        remote.updateLastSeen(timestamp) { (error) in
            onCompletion(error)
        }
    }


    /// Updates the read status for the given notification ID(s)
    ///
    func updateReadStatus(for noteIDs: [Int64], read: Bool, onCompletion: @escaping (Error?) -> Void) {
        /// Optimistically Update
        ///
        updateLocalNoteReadStatus(for: noteIDs, read: read) { [weak self] in

            /// On error we'll just mark the Note for Refresh
            ///
            self?.remote.updateReadStatus(noteIDs: noteIDs, read: read) { [weak self] error in
                guard let self else {
                    return onCompletion(error)
                }

                if let error {
                    invalidateCache(for: noteIDs) {
                        onCompletion(error)
                    }
                } else {
                    onCompletion(nil)
                }
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

    /// Deletes the collection of local notifications that cannot be found in a given collection of remote hashes.
    ///
    /// - Parameters:
    ///    - hashes: Collection of remote hashes to compare local notifications with.
    ///    - completion: Callback closure returning outdated note IDs.
    ///
    func deleteLocalMissingNotes(from hashes: [NoteHash], completion: @escaping (([Int64]) -> Void)) {
        storageManager.performAndSave({ [weak self] storage -> [Int64] in
            guard let self else { return [] }
            // The beauty of threadsafe Immutable Entities!!
            let remoteIDs = hashes.map { $0.noteID }
            let predicate = NSPredicate(format: "NOT (noteID IN %@)", remoteIDs)

            let allObjects = storage.allObjects(ofType: Storage.Note.self, matching: predicate, sortedBy: nil)
            for orphan in allObjects {
                storage.deleteObject(orphan)
            }
            return determineOutdatedNotes(using: hashes, in: storage)
        }, completion: { result in
            switch result {
            case .success(let outdatedNoteIDs):
                completion(outdatedNoteIDs)
            case .failure:
                completion([])
            }
        }, on: .main)
    }

    /// Given a collection of Notes, this method will insert missing local ones, and update the others that can be found.
    ///
    /// - Parameters:
    ///     - remoteNotes: Collection of Notes
    ///     - completion: Callback to be executed on completion
    ///
    func updateLocalNotes(with remoteNotes: [Note], onCompletion: (() -> Void)? = nil) {
        storageManager.performAndSave({ storage in
            for remoteNote in remoteNotes {
                let localNote = storage.loadNotification(noteID: remoteNote.noteID) ?? storage.insertNewObject(ofType: Storage.Note.self)
                localNote.update(with: remoteNote)
            }
        }, completion: onCompletion, on: .main)
    }

    /// Updates the read status for the specified Notifications. The callback happens on the Main Thread.
    ///
    func updateLocalNoteReadStatus(for noteIDs: [Int64], read: Bool, onCompletion: @escaping (() -> Void)) {
        storageManager.performAndSave({ storage in
            let notifications = noteIDs.compactMap { storage.loadNotification(noteID: $0) }
            for note in notifications {
                note.read = read
            }
        }, completion: onCompletion, on: .main)
    }

    /// Given a collection of NoteHash Entities, this method will determine the `.noteID`'s of those entities that
    /// are either not locally found, or got their `.hash` field outdated.
    ///
    func determineOutdatedNotes(using hashes: [NoteHash], in storage: StorageType) -> [Int64] {

        let remoteIds = hashes.map { $0.noteID }
        let predicate = NSPredicate(format: "noteID IN %@", remoteIds)
        var localHashes = [Int64: Int64]()

        for note in storage.allObjects(ofType: StorageNote.self, matching: predicate, sortedBy: nil) {
            localHashes[note.noteID] = Int64(note.noteHash)
        }

        let outdated = hashes.filter { remote in
            let localHash = localHashes[remote.noteID]
            return localHash == nil || localHash != remote.hash
        }

        let outdatedIds = outdated.map { $0.noteID }
        return outdatedIds
    }

    /// Invalidates the Hash for the specified Notifications.
    ///
    func invalidateCache(for noteIDs: [Int64], onCompletion: (() -> Void)? = nil) {
        storageManager.performAndSave({ storage in
            let notifications = noteIDs.compactMap { storage.loadNotification(noteID: $0) }
            for note in notifications {
                note.noteHash = Int64.min
            }
        }, completion: onCompletion, on: .main)
    }

    /// Updates the deletion "status" for the specified Notification. The callback happens on the Main Thread.
    ///
    func markLocalNoteAsDeleted(for noteID: Int64, isDeleted: Bool, onCompletion: (() -> Void)? = nil) {
        storageManager.performAndSave({ storage in
            let notification = storage.loadNotification(noteID: noteID)
            notification?.deleteInProgress = isDeleted
        }, completion: onCompletion, on: .main)
    }
}

// MARK: - Constants!
//
extension NotificationStore {

    enum Constants {
        static let maximumPageSize: Int = 100
    }
}
