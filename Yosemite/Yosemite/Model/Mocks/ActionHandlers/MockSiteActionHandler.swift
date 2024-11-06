import Foundation
import Storage

struct MockSiteActionHandler: MockActionHandler {

    typealias ActionType = SiteAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .syncSite(_, let completion):
            let site = objectGraph.defaultSite
            completion(.success(site))

        default:
            unimplementedAction(action: action)
        }
    }
}
