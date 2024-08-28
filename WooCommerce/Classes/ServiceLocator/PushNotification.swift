import Foundation

#if canImport(Yosemite)
import struct Yosemite.Note
#elseif canImport(NetworkingWatchOS)
import struct NetworkingWatchOS.Note
#elseif canImport(Networking)
import struct Networking.Note
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
        let note: Note? = noteFromNoteData(userInfo.string(forKey: APNSKey.noteFullData))
        return PushNotification(noteID: noteID, siteID: siteID, kind: noteKind, title: title, subtitle: subtitle, message: message, note: note)
    }

    static func noteFromNoteData(_ noteFulldata: String?) -> Note? {
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
        guard let note = try? Note(payload: firstNote) else {
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

#if DEBUG
extension PushNotification {
    static func scheduleTestingOrderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "[Testing] You have a new order! 🎉"
        content.body = "New order for $3.00 on Indie Melon"
        content.sound = UNNotificationSound.default
        content.userInfo = [
            "blog": "205617935",
            // swiftlint:disable line_length
            "note_full_data": "eNqVkc1O6zAQhV/FjNiRH+enTZqHgA0bdI0qN522hsSx4jEFobz7nYRSwZJN7MjnfDpn5hPsQOih+fcJZg9NXUgpiyyrygjowyE04GkYcTuMexwhgmBH1Cy0oesi8NY4h/T92yNpaGaSnw9viAG5XK2zalOsIviCNIVcTxF0xr7+kMGJyPlGpSp1YdeZNtbOJGe2uBG9T9qhVynfSKVvmUpnk1fpFQ5X+h9Bi4tJHAomjuVJU/DXgmH3gi0t8yF85ws8DUGc9BsKLSyexeK/ESrs66Ll76HewBRd1fffEnEYRnGbJ1KKwQo6oVgGC9MzT9r0nEf3jg25zMtYVnG+fswkj6opizspGylh1lGHF+jDZSGmHeyv0j45u6+SZxfzI6Hlqn2IXReOxnLVZeUqNb0+zmdwe00YO/3RszTO3xNnj0xm2QWuwqEsqyVqpz1tPaLdzqH5Lavysi7qzaqYLaHfzTvIpv+sG8QM",
            "aps": [
                "category": "store_order",
                "badge": 1,
                "sound": "o.caf",
                "content-available": 1,
                "mutable-content": 1,
                "thread-id": "205617935 - store_order",
                "alert": [
                    "body": "New order for $2.00 on the store",
                    "title": "You have a new order! 🎉"
                    ]
            ],
            "type": "store_order",
            "blog_id": "205617935",
            "note_id": "8326526386",
            "user": "212589093",
            "title": "You have a new order! 🎉",
        ]
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "FiveSecondNewOrdeTestingNotification", content: content, trigger: trigger) // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request)
    }
}
#endif
