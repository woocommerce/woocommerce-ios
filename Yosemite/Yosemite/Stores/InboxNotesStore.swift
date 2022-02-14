import Foundation
import Storage
import Networking

// MARK: - InboxNotesStore
//
public class InboxNotesStore: Store {
    private let remote: InboxNotesRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = InboxNotesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: InboxNotesAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? InboxNotesAction else {
            assertionFailure("InboxNotesStore received an unsupported action")
            return
        }


        switch action {
        case .loadAllInboxNotes(let siteID, let pageNumber, let pageSize, let orderBy, let type, let status, let completion):
            loadAllInboxNotes(for: siteID, pageNumber: pageNumber, pageSize: pageSize, orderBy: orderBy, type: type, status: status, completion: completion)
        case .dismissInboxNote(let siteID, let noteID, let completion):
            dismissInboxNote(for: siteID, noteID: noteID, completion: completion)
        case .markInboxNoteAsActioned(let siteID, let noteID, let actionID, let completion):
            markInboxNoteAsActioned(for: siteID, noteID: noteID, actionID: actionID, completion: completion)
        }
    }
}


// MARK: - Services
//
private extension InboxNotesStore {

    /// Retrieves all of the `InboxNote`s from the API.
    ///
    func loadAllInboxNotes(for siteID: Int64,
                           pageNumber: Int = Default.pageNumber,
                           pageSize: Int = Default.pageSize,
                           orderBy: InboxNotesRemote.OrderBy = .date,
                           type: [InboxNotesRemote.NoteType]? = nil,
                           status: [InboxNotesRemote.Status]? = nil,
                           completion: @escaping (Result<[InboxNote], Error>) -> ()) {
        remote.loadAllInboxNotes(for: siteID, pageNumber: pageNumber, pageSize: pageSize, orderBy: orderBy, type: type, status: status) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let inboxNotes):
                if pageNumber == Default.pageNumber {
                    self.deleteStoredInboxNotes(siteID: siteID)
                }

                self.upsertStoredInboxNotesInBackground(readOnlyInboxNotes: inboxNotes, siteID: siteID) {
                    completion(.success(inboxNotes))
                }
            }
        }
    }

    /// Dismiss one `InboxNote`.
    /// This internally marks a notification’s is_deleted field to true and such notifications do not show in the results anymore.
    ///
    func dismissInboxNote(for siteID: Int64,
                          noteID: Int64,
                          completion: @escaping (Result<InboxNote, Error>) -> ()) {
        remote.dismissInboxNote(for: siteID, noteID: noteID) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let inboxNote):
                self?.upsertStoredInboxNotesInBackground(readOnlyInboxNotes: [inboxNote], siteID: siteID, onCompletion: {
                    completion(.success(inboxNote))
                })
            }
        }
    }

    /// Set an `InboxNote` as `actioned`.
    /// This internally marks a notification’s status as `actioned`.
    ///
    func markInboxNoteAsActioned(for siteID: Int64,
                                 noteID: Int64,
                                 actionID: Int64,
                                 completion: @escaping (Result<InboxNote, Error>) -> ()) {
        remote.markInboxNoteAsActioned(for: siteID, noteID: noteID, actionID: actionID) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let inboxNote):
                self?.upsertStoredInboxNotesInBackground(readOnlyInboxNotes: [inboxNote], siteID: siteID, onCompletion: {
                    completion(.success(inboxNote))
                })
            }
        }
    }
}

// MARK: - Storage: InboxNote
//
private extension InboxNotesStore {

    /// Updates or Inserts specified Inbox Notes Entities in a background thread
    /// `onCompletion` will be called on the main thread.
    ///
    func upsertStoredInboxNotesInBackground(readOnlyInboxNotes: [Networking.InboxNote],
                                            siteID: Int64,
                                            onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredInboxNotes(readOnlyInboxNotes: readOnlyInboxNotes,
                                         in: derivedStorage,
                                         siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates or Inserts the specified Inbox Note entities
    ///
    func upsertStoredInboxNotes(readOnlyInboxNotes: [Networking.InboxNote],
                                in storage: StorageType,
                                siteID: Int64) {
        for inboxNote in readOnlyInboxNotes {
            let storageInboxNote = storage.loadInboxNote(siteID: siteID, id: inboxNote.id) ?? storage.insertNewObject(ofType: Storage.InboxNote.self)
            storageInboxNote.update(with: inboxNote)
            handleInboxActions(inboxNote, storageInboxNote, storage)
        }
    }

    /// Updates, inserts, or prunes the provided stored inboxnote actions using the provided read-only Inbox's actions
    ///
    func handleInboxActions(_ readOnlyInboxNote: Networking.InboxNote, _ storageInboxNote: Storage.InboxNote, _ storage: StorageType) {

        // Removes all the inbox action first.
        storageInboxNote.actions?.forEach { existingStorageAction in
            storage.deleteObject(existingStorageAction)
        }

        // Inserts the actions from the read-only inbox note.
        var storageInboxActions = [StorageInboxAction]()
        for readOnlyInboxAction in readOnlyInboxNote.actions {
            let newStorageInboxAction = storage.insertNewObject(ofType: Storage.InboxAction.self)
            newStorageInboxAction.update(with: readOnlyInboxAction)
            storageInboxActions.append(newStorageInboxAction)
        }
        storageInboxNote.actions = Set(storageInboxActions)
    }

    /// Deletes all Storage.InboxNote with the specified `siteID`
    ///
    func deleteStoredInboxNotes(siteID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteInboxNotes(siteID: siteID)
        storage.saveIfNeeded()
    }
}

// MARK: - Constants
//
public extension InboxNotesStore {
    enum Default {
        public static let pageSize = 25
        public static let pageNumber = 1
    }
}
