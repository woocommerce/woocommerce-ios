
import Foundation
import struct Yosemite.Note

/// Emitted by `PushNotificationsManager` when a remote notification is received while
/// the app is active.
///
struct ForegroundNotification {
    let noteID: Int
    let kind: Note.Kind
    let message: String
}
