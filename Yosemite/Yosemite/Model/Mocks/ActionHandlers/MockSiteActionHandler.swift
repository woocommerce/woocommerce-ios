import Foundation
import Storage

struct MockSiteActionHandler: MockActionHandler {

    typealias ActionType = SiteAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .syncSite(let siteID, let completion):
            // Assuming Site is a type that exists
            completion(.failure(NSError(domain: "", code: -1)))

        default:
            unimplementedAction(action: action)
        }
    }
}
