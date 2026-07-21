import Foundation
import GRDB
import Storage

/// Checks whether a full POS catalog sync has completed for a site.
public protocol POSCatalogSyncStatusCheckerProtocol {
    /// Whether a full catalog sync completed for the site at some point,
    /// meaning the local catalog holds a complete data set that can serve POS.
    func hasCompletedFullSync(for siteID: Int64) async -> Bool
}

/// Default implementation backed by the persisted full sync date in the local catalog database.
public struct POSCatalogSyncStatusChecker: POSCatalogSyncStatusCheckerProtocol {
    private let grdbManager: GRDBManagerProtocol

    public init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    public func hasCompletedFullSync(for siteID: Int64) async -> Bool {
        let lastFullSyncDate = try? await grdbManager.databaseConnection.read { db in
            try PersistedSite.filter(key: siteID).fetchOne(db)?.lastCatalogFullSyncDate
        }
        return lastFullSyncDate != nil
    }
}
