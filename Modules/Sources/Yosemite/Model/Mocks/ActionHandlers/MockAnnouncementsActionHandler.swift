import Foundation
import Storage

struct MockAnnouncementsActionHandler: MockActionHandler {
    typealias ActionType = AnnouncementsAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .synchronizeAnnouncements(let onCompletion):
            onCompletion(.failure(AnnouncementsError.announcementNotFound))
        case .loadSavedAnnouncement(let onCompletion):
            onCompletion(.failure(AnnouncementsError.announcementNotFound))
        default: unimplementedAction(action: action)
        }
    }
}
