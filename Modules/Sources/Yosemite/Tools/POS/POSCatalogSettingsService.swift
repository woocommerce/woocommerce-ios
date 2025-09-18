import Foundation
import GRDB
import protocol Storage.GRDBManagerProtocol

public protocol POSCatalogSettingsServiceProtocol {
    /// Gets catalog statistics for the specified site.
    /// - Parameter siteID: The site ID to get catalog statistics for.
    /// - Returns: Catalog statistics including product/variation counts.
    func loadCatalogStatistics(for siteID: Int64) async throws -> POSCatalogStatistics

    /// Gets the last sync dates for the specified site.
    /// - Parameter siteID: The site ID to get sync dates for.
    /// - Returns: Sync dates information.
    func loadSyncDates(for siteID: Int64) async throws -> POSSyncDates
}

public struct POSCatalogStatistics {
    public let productCount: Int
    public let variationCount: Int

    public init(productCount: Int, variationCount: Int) {
        self.productCount = productCount
        self.variationCount = variationCount
    }
}

public struct POSSyncDates {
    public let lastFullSyncDate: Date?
    public let lastIncrementalSyncDate: Date?

    public init(lastFullSyncDate: Date?, lastIncrementalSyncDate: Date?) {
        self.lastFullSyncDate = lastFullSyncDate
        self.lastIncrementalSyncDate = lastIncrementalSyncDate
    }
}

public class POSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    public init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    public func loadCatalogStatistics(for siteID: Int64) async throws -> POSCatalogStatistics {
        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            return POSCatalogStatistics(productCount: productCount, variationCount: variationCount)
        }
    }

    public func loadSyncDates(for siteID: Int64) async throws -> POSSyncDates {
        try await grdbManager.databaseConnection.read { db in
            let site = try PersistedSite.filter(key: siteID).fetchOne(db)
            return POSSyncDates(
                lastFullSyncDate: site?.lastCatalogFullSyncDate,
                lastIncrementalSyncDate: site?.lastCatalogIncrementalSyncDate
            )
        }
    }
}
