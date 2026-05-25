import Foundation
import struct NetworkingCore.AnyCodable
import struct NetworkingCore.Note
import struct NetworkingCore.MetaContainer

#if DEBUG
import UserNotifications
#endif

/// Emitted by `PushNotificationsManager` when a remote notification is received while
/// the app is active.
///
struct PushNotification {
    /// The `note_id` value received from the Remote Notification's `userInfo`.
    ///
    let noteID: Int64?
    /// The `blog` value received from the Remote Notification's `userInfo`.
    ///
    let siteID: Int64
    /// The `type` value received from the Remote Notification's `userInfo`.
    ///
    let kind: Note.Kind
    /// The `alert.title` value received from the Remote Notification's `userInfo`.
    ///
    let title: String
    /// The `alert.subtitle` value received from the Remote Notification's `userInfo`.
    ///
    let subtitle: String?
    /// The `alert.message` value received from the Remote Notification's `userInfo`.
    ///
    let message: String?
    /// The `note` value received from the Remote Notification's `userInfo` and parsed from `note_full_data`.
    ///
    let note: Note?

    /// The meta value parsed from `note_full_data` in `userInfo`
    let meta: MetaContainer?
}

extension PushNotification {
    static func from(userInfo: [AnyHashable: Any]) -> PushNotification? {
        guard let aps = userInfo.dictionary(forKey: APNSKey.aps) else {
            return nil
        }

        let alert = aps.dictionary(forKey: APNSKey.alert)

        let title: String? = {
            if let alert {
                return alert.string(forKey: APNSKey.alertTitle)
            } else {
                return aps.string(forKey: APNSKey.alert)
            }
        }()

        guard let siteID = userInfo.integer(forKey: APNSKey.siteID),
              let title,
              let type = userInfo.string(forKey: APNSKey.type),
              let noteKind = Note.Kind(rawValue: type) else {
            return nil
        }

        let noteID = userInfo.integer(forKey: APNSKey.identifier)
        let subtitle = alert?.string(forKey: APNSKey.alertSubtitle)
        let message = alert?.string(forKey: APNSKey.alertMessage)

        let noteFullData = userInfo.string(forKey: APNSKey.noteFullData)
        let note: Note? = noteFromCompressedData(noteFullData)
        let meta = metaDataFromCompressedData(noteFullData)
        return PushNotification(noteID: noteID,
                                siteID: siteID,
                                kind: noteKind,
                                title: title,
                                subtitle: subtitle,
                                message: message,
                                note: note,
                                meta: meta)
    }

    /// Optional `String` passed parameter holds (base64 encoded and zlib compressed) data for the note.
    /// That data is used to create `Note` object which is returned
    private static func noteFromCompressedData(_ noteFulldata: String?) -> Note? {
        guard let content = noteContent(from: noteFulldata),
              let note = try? Note.createdFrom(content) else {
            return nil
        }
        return note
    }

    private static func metaDataFromCompressedData(_ noteFullData: String?) -> MetaContainer? {
        guard let content = noteContent(from: noteFullData),
                let metaDict = content["meta"] as? [String: Any] else {
            return nil
        }
        let anyCodableDict = metaDict.mapValues { AnyCodable($0) }
        return MetaContainer(payload: anyCodableDict)
    }

    private static func noteContent(from noteFullData: String?) -> [String: Any]? {
        guard let noteFullData,
                !noteFullData.isEmpty,
                var data = Data(base64Encoded: noteFullData) else {
            return nil
        }
        if data.count > 1 {
            data.removeFirst(2) // https://stackoverflow.com/a/76510182
        }
        guard let zlib = try? (data as NSData).decompressed(using: .zlib) else {
            return nil
        }
        let zlibData = Data(referencing: zlib)
        guard let dataDictionary = try? JSONSerialization.jsonObject(with: zlibData) as? [String: Any],
              let notes = dataDictionary[APNSKey.notes] as? [[String: Any]],
              let firstNote = notes.first else {
            return nil
        }
        return firstNote
    }
}

enum APNSKey {
    static let aps = "aps"
    static let alert = "alert"
    static let alertTitle = "title"
    static let alertSubtitle = "subtitle"
    static let alertMessage = "body"
    static let identifier = "note_id"
    static let type = "type"
    static let siteID = "blog"
    static let postID = "post_id"
    static let noteFullData = "note_full_data"
    static let notes = "notes"
    static let meta = "meta"
    static let ids = "ids"
    static let order = "order"
}

private extension Note {
    static func createdFrom(_ payload: [String: Any]) throws -> Note? {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(Note.self, from: data)
    }
}
