import Foundation
import Networking



// MARK: - NotificationAction: Defines all of the Actions supported by the NotificationStore.
//
public enum NotificationAction: Action {
    /// Synchronizes the full Notifications collection.
    ///
    case synchronizeNotifications(onCompletion: (Error?) -> Void)

    /// Synchronizes a specified Notification.
    ///
    case synchronizeNotification(noteId: Int64, onCompletion: (Error?) -> Void)

    /// Updates the WordPress.com Last Seen field.
    ///
    case updateLastSeen(timestamp: String, onCompletion: (Error?) -> Void)

    /// Updates a given Notification's read flag.
    ///
    case updateReadStatus(noteId: Int64, read: Bool, onCompletion: (Error?) -> Void)

    /// Updates, in batch, the Notification's read flag.
    ///
    case updateMultipleReadStatus(noteIds: [Int64], read: Bool, onCompletion: (Error?) -> Void)
}
