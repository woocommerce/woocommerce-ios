
import Foundation
import struct Yosemite.Note

/// Emitted by `PushNotificationsManager` when a remote notification is received while
/// the app is active.
///
struct ForegroundNotification {
    /// The `note_id` value received from the Remote Notification's `userInfo`.
    ///
    let noteID: Int
    /// The `type` value received from the Remote Notification's `userInfo`.
    ///
    let kind: Note.Kind
    /// The `alert` value received from the Remote Notification's `userInfo`.
    ///
    let message: String
}
