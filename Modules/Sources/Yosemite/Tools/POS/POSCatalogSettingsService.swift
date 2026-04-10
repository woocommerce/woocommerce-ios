import Foundation
import GRDB
import protocol Storage.GRDBManagerProtocol

public protocol POSCatalogSettingsServiceProtocol {
    /// Gets catalog information for the specified site.
    /// - Parameter siteID: The site ID to get catalog information for.
    /// - Returns: Catalog information including statistics and sync dates.
    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo
}

public struct POSCatalogInfo {
    public let productCount: Int
    public let variationCount: Int
    public let lastFullSyncDate: Date?
    public let lastIncrementalSyncDate: Date?

    public init(productCount: Int, variationCount: Int, lastFullSyncDate: Date?, lastIncrementalSyncDate: Date?) {
        self.productCount = productCount
        self.variationCount = variationCount
        self.lastFullSyncDate = lastFullSyncDate
        self.lastIncrementalSyncDate = lastIncrementalSyncDate
    }
}

public class POSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    public init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    public func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            let site = try PersistedSite.filter(key: siteID).fetchOne(db)
            return POSCatalogInfo(
                productCount: productCount,
                variationCount: variationCount,
                lastFullSyncDate: site?.lastCatalogFullSyncDate,
                lastIncrementalSyncDate: site?.lastCatalogIncrementalSyncDate
            )
        }
    }
}
