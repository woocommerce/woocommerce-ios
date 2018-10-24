import Foundation
import Alamofire


/// Notifications: Remote Endpoints
///
public class NotificationsRemote: Remote {

    /// Retrieves latest Notifications (OR collection of specified Notifications, whenever the NoteIds is present).
    ///
    /// - Parameters:
    ///     - noteIds: Identifiers of notifications to retrieve.
    ///     - pageSize: Number of hashes to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    public func loadNotes(noteIds: [String]? = nil, pageSize: Int? = nil, completion: @escaping ([Note]?, Error?) -> Void) {
        let request = requestForNotifications(fields: .all, noteIds: noteIds, pageSize: pageSize)
        let mapper = NoteListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Retrieves the top N Hashes (or the latest hashes for the specified NoteIds).
    ///
    /// - Parameters:
    ///     - noteIds: Identifiers of notifications to retrieve.
    ///     - pageSize: Number of hashes to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    public func loadHashes(noteIds: [String]? = nil, pageSize: Int? = nil, completion: @escaping ([NoteHash]?, Error?) -> Void) {
        let request = requestForNotifications(fields: .hashes, noteIds: noteIds, pageSize: pageSize)
        let mapper = NoteHashListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Private Methods
//
private extension NotificationsRemote {

    /// Retrieves the Notification for the specified pageSize (OR collection of NoteID's, when present).
    /// Note that only the specified fields will be retrieved.
    ///
    /// - Parameters:
    ///     - noteIds: Identifier for the notifications that should be loaded.
    ///     - fields: List of comma separated fields, to be loaded.
    ///     - pageSize: Number of notifications to load.
    ///     - completion: Callback to be executed on completion.
    ///
    func requestForNotifications(fields: Fields? = nil, noteIds: [String]? = nil, pageSize: Int?) -> DotcomRequest {
        var parameters = [String: String]()
        if let fields = fields {
            parameters[ParameterKeys.fields] = fields.rawValue
        }

        if let notificationIds = noteIds {
            parameters[ParameterKeys.identifiers] = notificationIds.joined(separator: ",")
        }

        if let pageSize = pageSize {
            parameters[ParameterKeys.number] = String(pageSize)
        }

        return DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: Paths.notes, parameters: parameters)
    }
}


// MARK: - Constants!
//
private extension NotificationsRemote {

    enum Fields: String {
        case all = "id,note_hash,type,unread,body,subject,timestamp,meta"
        case hashes = "id,note_hash"
    }

    enum Paths {
        static let notes = "notifications"
    }

    enum ParameterKeys {
        static let number = "number"
        static let identifiers = "ids"
        static let fields = "fields"
    }
}
