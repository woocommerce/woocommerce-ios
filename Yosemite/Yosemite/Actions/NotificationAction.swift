import Foundation
import Networking



// MARK: - NotificationAction: Defines all of the Actions supported by the NotificationStore.
//
public enum NotificationAction: Action {
    case synchronizeNotifications(onCompletion: (Error?) -> Void)
    case synchronizeNotification(noteId: Int64, onCompletion: (Error?) -> Void)
    case updateLastSeen(timestamp: String, onCompletion: (Error?) -> Void)
    case updateReadStatus(noteID: Int64, read: Bool, onCompletion: (Error?) -> Void)
}
