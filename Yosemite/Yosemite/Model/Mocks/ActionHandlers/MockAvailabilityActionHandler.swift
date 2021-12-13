import Foundation
import Storage

struct MockAvailabilityActionHandler: MockActionHandler {
    typealias ActionType = AvailabilityAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .checkStatsV4Availability(let siteID, let onCompletion):
                checkStatsV4Availability(siteId: siteID, onCompletion: onCompletion)
        }
    }

    func checkStatsV4Availability(siteId: Int64, onCompletion: (Bool) -> ()) {
        let result = objectGraph.statsV4ShouldBeAvailable(forSiteId: siteId)
        onCompletion(result)
    }
}
