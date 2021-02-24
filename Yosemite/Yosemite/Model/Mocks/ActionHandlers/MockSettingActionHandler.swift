import Foundation
import Storage

struct MockSettingActionHandler: MockActionHandler {
    typealias ActionType = SettingAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveSiteAPI(let siteID, let onCompletion):
                retreiveSiteAPI(siteId: siteID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func retreiveSiteAPI(siteId: Int64, onCompletion: (SiteAPI?, Error?) -> Void) {
        onCompletion(objectGraph.defaultSiteAPI, nil)
    }
}
