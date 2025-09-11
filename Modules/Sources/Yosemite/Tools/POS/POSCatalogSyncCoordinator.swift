import Foundation
import Storage
import GRDB

public protocol POSCatalogSyncCoordinatorProtocol {
    /// Performs a full catalog sync for the specified site
    /// - Parameter siteID: The site ID to sync catalog for
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    func performFullSync(for siteID: Int64) async throws

    /// Determines if a full sync should be performed based on the age of the last sync
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Returns: True if a sync should be performed
    func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool
}

public enum POSCatalogSyncError: Error, Equatable {
    case syncAlreadyInProgress(siteID: Int64)
}

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let persistenceService: POSCatalogPersistenceServiceProtocol
    private let grdbManager: GRDBManagerProtocol

    /// Tracks ongoing syncs by site ID to prevent duplicates
    private var ongoingSyncs: Set<Int64> = []

    public init(fullSyncService: POSCatalogFullSyncServiceProtocol,
                grdbManager: GRDBManagerProtocol) {
        self.fullSyncService = fullSyncService
        self.persistenceService = POSCatalogPersistenceService(grdbManager: grdbManager)
        self.grdbManager = grdbManager
    }

    //periphery:ignore - used for tests to inject persistence service
    init(fullSyncService: POSCatalogFullSyncServiceProtocol,
         persistenceService: POSCatalogPersistenceServiceProtocol,
         grdbManager: GRDBManagerProtocol) {
        self.fullSyncService = fullSyncService
        self.persistenceService = persistenceService
        self.grdbManager = grdbManager
    }

    public func performFullSync(for siteID: Int64) async throws {
        if ongoingSyncs.contains(siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        // Mark sync as in progress
        ongoingSyncs.insert(siteID)

        // Ensure cleanup happens regardless of success or failure
        defer {
            ongoingSyncs.remove(siteID)
        }

        DDLogInfo("🔄 POSCatalogSyncCoordinator starting full sync for site \(siteID)")

        let catalog = try await fullSyncService.startFullSync(for: siteID)

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")
    }

    public func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
        if !siteExistsInDatabase(siteID: siteID) {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) not found in database, sync needed")
            return true
        }

        guard let lastSyncDate = await lastFullSyncDate(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: No previous sync found for site \(siteID), sync needed")
            return true
        }

        let age = Date().timeIntervalSince(lastSyncDate)
        let shouldSync = age > maxAge

        if shouldSync {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago (max: \(Int(maxAge))s), sync needed")
        } else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago (max: \(Int(maxAge))s), sync not needed")
        }

        return shouldSync
    }

    // MARK: - Private

    private func lastFullSyncDate(for siteID: Int64) async -> Date? {
        do {
            return try await grdbManager.databaseConnection.read { db in
                return try PersistedSite.filter(key: siteID).fetchOne(db)?.lastCatalogFullSyncDate
            }
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Error loading site \(siteID) for full sync date: \(error)")
            return nil
        }
    }

    private func siteExistsInDatabase(siteID: Int64) -> Bool {
        do {
            return try grdbManager.databaseConnection.read { db in
                return try PersistedSite.filter(key: siteID).fetchCount(db) > 0
            }
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Error checking if site \(siteID) exists in database: \(error)")
            // On error, assume site exists to avoid unnecessary syncs
            return true
        }
    }
}
