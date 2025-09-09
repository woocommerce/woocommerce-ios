import Foundation
import Storage

extension PersistedSite {
    init(from posSite: POSSite) {
        self.init(
            id: posSite.siteID,
            posLastIncrementalSyncDate: posSite.lastIncrementalSyncDate
        )
    }

    func toPOSSite() -> POSSite {
        POSSite(
            siteID: id,
            lastIncrementalSyncDate: posLastIncrementalSyncDate
        )
    }
}
