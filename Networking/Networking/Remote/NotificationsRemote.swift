import Foundation


/// Notifications: Remote Endpoints
///
public class NotificationsRemote: Remote {

    /// Retrieves latest Notifications (OR collection of specified Notifications, whenever the NoteIds is present).
    ///
    /// - Parameters:
    ///     - noteIDs: Identifiers of notifications to retrieve.
    ///     - pageSize: Number of hashes to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    public func loadNotes(noteIDs: [Int64]? = nil, pageSize: Int? = nil, completion: @escaping (Result<[Note], Error>) -> Void) {
        let request = requestForNotifications(fields: .all, noteIDs: noteIDs, pageSize: pageSize)
        let mapper = NoteListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Retrieves the top N Hashes (or the latest hashes for the specified NoteIds).
    ///
    /// - Parameters:
    ///     - noteIDs: Identifiers of notifications to retrieve.
    ///     - pageSize: Number of hashes to retrieve.
    ///     - completion: callback to be executed on completion.
    ///
    public func loadHashes(noteIDs: [Int64]? = nil, pageSize: Int? = nil, completion: @escaping ([NoteHash]?, Error?) -> Void) {
        let request = requestForNotifications(fields: .hashes, noteIDs: noteIDs, pageSize: pageSize)
        let mapper = NoteHashListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Updates a Notification's Read Status as specified.
    ///
    /// - Parameters:
    ///     - notificationID: The ID of the Notification to be updated.
    ///     - read: The new Read Status to be set.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    public func updateReadStatus(noteIDs: [Int64], read: Bool, completion: @escaping (Error?) -> Void) {
        // Note: Isn't the API wonderful?
        //
        let booleanFromPlanetMars = read ? Constants.readAsInteger : Constants.unreadAsInteger

        // Payload: [NoteID: ReadStatus]
        //
        var payload = [String: Int]()

        for noteID in noteIDs {
            let noteIDAsString = String(noteID)
            payload[noteIDAsString] = booleanFromPlanetMars
        }

        // Parameters: [.counts: [Payload]]
        //
        let parameters: [String: Any] = [
            ParameterKeys.counts: payload
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: Paths.read, parameters: parameters)
        let mapper = SuccessResultMapper()

        enqueue(request, mapper: mapper) { (success, error) in
            guard success == true else {
                completion(error ?? DotcomError.empty)
                return
            }

            completion(nil)
        }
    }


    /// Updates the Last Seen Notification's Timestamp.
    ///
    /// - Parameters:
    ///     - timestamp: Timestamp of the last seen notification.
    ///     - completion: Closure to be executed on completion, indicating whether the OP was successful or not.
    ///
    public func updateLastSeen(_ timestamp: String, completion: @escaping (Error?) -> Void) {
        let parameters = [
            ParameterKeys.time: timestamp
        ]

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: Paths.seen, parameters: parameters)
        let mapper = SuccessResultMapper()

        enqueue(request, mapper: mapper) { (success, error) in
            guard success == true else {
                completion(error ?? DotcomError.empty)
                return
            }

            completion(nil)
        }
    }
}


// MARK: - Private Methods
//
private extension NotificationsRemote {

    /// Retrieves the Notification for the specified pageSize (OR collection of NoteID's, when present).
    /// Note that only the specified fields will be retrieved.
    ///
    /// - Parameters:
    ///     - noteIDs: Identifier for the notifications that should be loaded.
    ///     - fields: List of comma separated fields, to be loaded.
    ///     - pageSize: Number of notifications to load.
    ///     - completion: Callback to be executed on completion.
    ///
    func requestForNotifications(fields: Fields? = nil, noteIDs: [Int64]? = nil, pageSize: Int?) -> DotcomRequest {
        var parameters = [ParameterKeys.locale: Locale.current.description]
        if let fields = fields {
            parameters[ParameterKeys.fields] = fields.rawValue
        }

        if let notificationIds = noteIDs {
            let identifiersAsStrings = notificationIds.map { String($0) }
            parameters[ParameterKeys.identifiers] = identifiersAsStrings.joined(separator: ",")
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

    enum Constants {
        static let readAsInteger = 9999
        static let unreadAsInteger = -9999
    }

    enum Fields: String {
        case all = "id,note_hash,type,unread,body,subject,timestamp,meta"
        case hashes = "id,note_hash"
    }

    enum Paths {
        static let notes = "notifications"
        static let read = "notifications/read"
        static let seen = "notifications/seen"
    }

    enum ParameterKeys {
        static let counts = "counts"
        static let fields = "fields"
        static let identifiers = "ids"
        static let number = "number"
        static let time = "time"
        static let locale = "locale"
    }
}
