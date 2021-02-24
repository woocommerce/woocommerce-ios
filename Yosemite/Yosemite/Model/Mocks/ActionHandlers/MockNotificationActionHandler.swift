import Foundation
import Storage

struct MockNotificationActionHandler: MockActionHandler {
    typealias ActionType = NotificationAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            /// Not implemented yet
            case .synchronizeNotifications(let onCompletion):
                success(onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}
