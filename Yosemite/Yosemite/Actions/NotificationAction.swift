import Foundation
import Networking



// MARK: - NotificationAction: Defines all of the Actions supported by the NotificationStore.
//
public enum NotificationAction: Action {
    case synchronizeNotifications(onCompletion: (Error?) -> Void)
    case synchronizeNotification(noteId: Int64, onCompletion: (Error?) -> Void)
    case updateLastSeen(timestamp: String, onCompletion: (Error?) -> Void)
    case updateReadStatus(noteId: Int64, read: Bool, onCompletion: (Error?) -> Void)
    case updateMultipleReadStatus(noteIds: [Int64], read: Bool, onCompletion: (Error?) -> Void)
    case updateLocalDeletedStatus(noteId: Int64, deleteInProgress: Bool, onCompletion: (Error?) -> Void)
}
