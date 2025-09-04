import Foundation
import Storage

public protocol POSCatalogPersistenceServiceProtocol {
    /// Clears all catalog data for the specified site
    /// - Parameter siteID: The site ID to clear data for
    func clearSiteData(for siteID: Int64) async throws

    /// Persists catalog data to the database
    /// - Parameters:
    ///   - catalog: The catalog to persist
    ///   - siteID: The site ID to associate the catalog with
    func persistCatalog(_ catalog: POSCatalog, siteID: Int64) async throws

    /// Clears existing data and persists new catalog data
    /// - Parameters:
    ///   - catalog: The catalog to persist
    ///   - siteID: The site ID to associate the catalog with
    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws
}

public final class POSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    public init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    public func clearSiteData(for siteID: Int64) async throws {
        let db = grdbManager.databaseConnection
        try await db.write { db in
            DDLogInfo("🗑️ Clearing catalog data for site \(siteID)")
            try PersistedSite.deleteOne(db, key: siteID)
        }
    }

    public func persistCatalog(_ catalog: POSCatalog, siteID: Int64) async throws {
        let db = grdbManager.databaseConnection
        DDLogInfo("💾 Persisting catalog with \(catalog.products.count) products and \(catalog.variations.count) variations")

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Persist site first
            group.addTask {
                try db.write { db in
                    let site = PersistedSite(id: siteID)
                    try site.insert(db)
                }
            }

            // Wait for site to be persisted before continuing
            try await group.next()

            // Persist products
            for product in catalog.products {
                group.addTask {
                    try product.insertWithRelationships(in: db)
                }
            }

            // Persist variations
            for variation in catalog.variations {
                group.addTask {
                    try variation.insertWithRelationships(in: db)
                }
            }

            // Wait for all saves to complete
            for try await _ in group {}
        }

        DDLogInfo("✅ Catalog persistence complete")
    }

    public func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        try await clearSiteData(for: siteID)
        try await persistCatalog(catalog, siteID: siteID)
    }
}
