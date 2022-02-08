import Foundation
import Storage
import Networking

// MARK: - InboxNotesStore
//
public class InboxNotesStore: Store {
    private let remote: InboxNotesRemote

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
        remote.loadAllInboxNotes(for: siteID, pageNumber: pageNumber, pageSize: pageSize, orderBy: orderBy, type: type, status: status, completion: completion)
    }

    /// Dismiss one `InboxNote`.
    /// This internally marks a notification’s is_deleted field to true and such notifications do not show in the results anymore.
    ///
    func dismissInboxNote(for siteID: Int64,
                          noteID: Int64,
                          completion: @escaping (Result<InboxNote, Error>) -> ()) {
        remote.dismissInboxNote(for: siteID, noteID: noteID, completion: completion)
    }

    /// Set an `InboxNote` as `actioned`.
    /// This internally marks a notification’s status as `actioned`.
    ///
    func markInboxNoteAsActioned(for siteID: Int64,
                                 noteID: Int64,
                                 actionID: Int64,
                                 completion: @escaping (Result<InboxNote, Error>) -> ()) {
        remote.markInboxNoteAsActioned(for: siteID, noteID: noteID, actionID: actionID, completion: completion)
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
