import Foundation

#if canImport(Yosemite)
import struct Yosemite.Note
#elseif canImport(NetworkingWatchOS)
import struct NetworkingWatchOS.Note
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
    /// The orderID value received from the Remote Notification's `userInfo`, extracted from note_full_data.
    ///
    let orderID: Int64?
}

extension PushNotification {
    static func from(userInfo: [AnyHashable: Any]) -> PushNotification? {
        guard let noteID = userInfo.integer(forKey: APNSKey.identifier),
              let siteID = userInfo.integer(forKey: APNSKey.siteID),
              let alert = userInfo.dictionary(forKey: APNSKey.aps)?.dictionary(forKey: APNSKey.alert),
              let title = alert.string(forKey: APNSKey.alertTitle),
              let type = userInfo.string(forKey: APNSKey.type),
              let noteKind = Note.Kind(rawValue: type) else {
                  return nil
              }
        let subtitle = alert.string(forKey: APNSKey.alertSubtitle)
        let message = alert.string(forKey: APNSKey.alertMessage)
        let orderID: Int64? = orderIdFromNoteData(userInfo.string(forKey: APNSKey.noteFullData))
        return PushNotification(noteID: noteID, siteID: siteID, kind: noteKind, title: title, subtitle: subtitle, message: message, orderID: orderID)
    }

    static func orderIdFromNoteData(_ noteFulldata: String?) -> Int64? {
        guard let noteFulldata, var data = Data(base64Encoded: noteFulldata) else {
            return nil
        }
        data.removeFirst(2)
        guard let zlib = try? (data as NSData).decompressed(using: .zlib) else {
            return nil
        }
        let zlibData = Data(referencing: zlib)
        guard let dataDictionary = try? JSONSerialization.jsonObject(with: zlibData) as? [String: Any],
              let notes = dataDictionary[APNSKey.notes] as? [[String: Any]],
              let firstNote = notes.first, let meta = firstNote[APNSKey.meta] as? [String: Any],
              let ids = meta[APNSKey.ids] as? [String: Any],
              let orderID = ids[APNSKey.order] as? Int64
        else {
            return nil
        }
        return orderID
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
