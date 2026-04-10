// periphery:ignore:all
import Foundation
import Storage

extension PersistedSite {
    init(from posSite: POSSite) {
        self.init(
            id: posSite.siteID,
            lastCatalogIncrementalSyncDate: posSite.lastIncrementalSyncDate,
            lastCatalogFullSyncDate: posSite.lastFullSyncDate
        )
    }

    func toPOSSite() -> POSSite {
        POSSite(
            siteID: id,
            lastIncrementalSyncDate: lastCatalogIncrementalSyncDate,
            lastFullSyncDate: lastCatalogFullSyncDate
        )
    }
}
