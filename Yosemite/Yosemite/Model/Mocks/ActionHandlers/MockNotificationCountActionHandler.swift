import Foundation
import Storage

struct MockNotificationCountActionHandler: MockActionHandler {
    typealias ActionType = NotificationCountAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .load(let siteId, let type, let onCompletion):
                loadNotificationCount(siteId: siteId, type: type, onCompletion: onCompletion)
            case .reset(siteID: let siteId, let type, let onCompletion):
                reset(siteId: siteId, type: type, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func loadNotificationCount(siteId: Int64, type: SiteNotificationCountType, onCompletion: (Int) -> Void) {
        onCompletion(objectGraph.currentNotificationCount)
    }

    func reset(siteId: Int64, type: Note.Kind, onCompletion: () -> Void) {
        // Don't do anything when resetting
    }
}
