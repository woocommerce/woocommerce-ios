import Foundation

#if canImport(Networking)
import struct Networking.Note
#elseif canImport(NetworkingWatchOS)
import struct NetworkingWatchOS.Note
#endif
#if DEBUG
import UserNotifications
#endif

/// Emitted by `PushNotificationsManager` when a remote notification is received while
/// the app is active.
///
struct PushNotification {
    /// The `note_id` value received from the Remote Notification's `userInfo`.
    ///
    let noteID: Int64
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
}

extension PushNotification {
    static func from(userInfo: [AnyHashable: Any]) -> PushNotification? {
        guard let aps = userInfo.dictionary(forKey: APNSKey.aps) else {
            return nil
        }

        let title: String? = {
            if let alert = aps.dictionary(forKey: APNSKey.alert) {
                return alert.string(forKey: APNSKey.alertTitle)
            } else {
                return aps.string(forKey: APNSKey.alert)
            }
        }()

        guard let noteID = userInfo.integer(forKey: APNSKey.identifier),
              let siteID = userInfo.integer(forKey: APNSKey.siteID),
              let title,
              let type = userInfo.string(forKey: APNSKey.type),
              let noteKind = Note.Kind(rawValue: type) else {
            return nil
        }

        let alert = aps.dictionary(forKey: APNSKey.alert)
        let subtitle = alert?.string(forKey: APNSKey.alertSubtitle)
        let message = alert?.string(forKey: APNSKey.alertMessage)
        let note: Note? = noteFromCompressedData(userInfo.string(forKey: APNSKey.noteFullData))
        return PushNotification(noteID: noteID, siteID: siteID, kind: noteKind, title: title, subtitle: subtitle, message: message, note: note)
    }

    /// Optional `String` passed parameter holds (base64 encoded and zlib compressed) data for the note.
    /// That data is used to create `Note` object which is returned
    static private func noteFromCompressedData(_ noteFulldata: String?) -> Note? {
        guard let noteFulldata, !noteFulldata.isEmpty, var data = Data(base64Encoded: noteFulldata) else {
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
        guard let note = try? Note.createdFrom(firstNote) else {
            return nil
        }
        return note
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

/// SwiftUI Identifiable conformance
///
extension PushNotification: Identifiable {
    var id: Int64 {
        noteID
    }
}

private extension Note {
    static func createdFrom(_ payload: [String: Any]) throws -> Note? {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(Note.self, from: data)
    }
}
