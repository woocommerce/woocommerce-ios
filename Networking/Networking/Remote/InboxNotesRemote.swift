import Foundation

/// Protocol for `InboxNotesRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol InboxNotesRemoteProtocol {
    func loadAllInboxNotes(for siteID: Int64,
                           pageNumber: Int,
                           pageSize: Int,
                           orderBy: InboxNotesRemote.OrderBy,
                           type: [InboxNotesRemote.NoteType]?,
                           status: [InboxNotesRemote.Status]?,
                           completion: @escaping (Result<[InboxNote], Error>) -> ())
}


/// Inbox Notes: Remote endpoints
///
public final class InboxNotesRemote: Remote, InboxNotesRemoteProtocol {

    // MARK: - Get Inbox Notes

    /// Retrieves all of the `InboxNote`s from the API.
    ///
    /// - Parameters:
    ///     - siteID: The site for which we'll fetch InboxNotes.
    ///     - pageNumber: The page number of the Inbox Notes list to be fetched.
    ///     - pageSize: The maximum number of Inbox Notes to be fetched for the current page.
    ///     - orderBy: The type of sorting that the Inbox Notes list will follow.
    ///     - type: The array of Inbox Notes Types.
    ///     - status: The array of Inbox Notes with a specific array of status that will be fetched.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllInboxNotes(for siteID: Int64,
                                  pageNumber: Int = Default.pageNumber,
                                  pageSize: Int = Default.pageSize,
                                  orderBy: InboxNotesRemote.OrderBy = .date,
                                  type: [InboxNotesRemote.NoteType]? = nil,
                                  status: [InboxNotesRemote.Status]? = nil,
                                  completion: @escaping (Result<[InboxNote], Error>) -> ()) {
        var parameters = [
            ParameterKey.orderBy: orderBy.rawValue,
            ParameterKey.page: pageNumber,
            ParameterKey.pageSize: pageSize
        ] as [String: Any]

        if let type = type {
            let stringOfTypes = type.map { $0.rawValue }
            parameters[ParameterKey.type] = stringOfTypes.joined(separator: ",")
        }
        if let status = status {
            let stringOfStatuses = status.map { $0.rawValue }
            parameters[ParameterKey.status] = stringOfStatuses.joined(separator: ",")
        }

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.notes,
                                     parameters: parameters)

        let mapper = InboxNoteListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: { result in
            switch result {
            case .success(let inboxNotes):
                completion(.success(inboxNotes))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

// MARK: - Constants
//
public extension InboxNotesRemote {

    enum Default {
        public static let pageSize = 25
        public static let pageNumber = 1
    }

    private enum Path {
        static let notes = "admin/notes"
        static let deleteNote = "admin/notes/delete"
    }

    private enum ParameterKey {
        static let orderBy = "order_by"
        static let page = "page"
        static let pageSize = "per_page"
        static let type = "type"
        static let status = "status"
    }

    /// Order By parameter
    ///
    enum OrderBy: String {
        case noteID = "note_id"
        case date = "date"
        case type = "type"
        case title = "title"
        case status = "status"
    }

    /// Type parameter
    ///
    enum NoteType: String {
        case info = "info"
        case marketing = "marketing"
        case survey = "survey"
        case update = "update"
        case error = "error"
        case warning = "warning"
        case email = "email"
    }

    /// Status parameter
    ///
    enum Status: String {
        case pending = "pending"
        case unactioned = "unactioned"
        case actioned = "actioned"
        case snoozed = "snoozed"
        case sent = "sent"
    }
}
