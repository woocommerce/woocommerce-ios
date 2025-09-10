// periphery:ignore:all
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

    /// Performs an incremental sync if applicable based on sync conditions
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - forceSync: Whether to bypass age checks and always sync
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    //periphery:ignore - remove ignore comment when incremental sync is integrated with POS
    func performIncrementalSyncIfApplicable(for siteID: Int64, forceSync: Bool) async throws
}

public enum POSCatalogSyncError: Error, Equatable {
    case syncAlreadyInProgress(siteID: Int64)
}

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol
    private let grdbManager: GRDBManagerProtocol
    private let maxIncrementalSyncAge: TimeInterval
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol

    /// Tracks ongoing full syncs by site ID to prevent duplicates
    private var ongoingSyncs: Set<Int64> = []
    /// Tracks ongoing incremental syncs by site ID to prevent duplicates
    private var ongoingIncrementalSyncs: Set<Int64> = []

    public init(fullSyncService: POSCatalogFullSyncServiceProtocol,
                incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol,
                grdbManager: GRDBManagerProtocol,
                maxIncrementalSyncAge: TimeInterval = 300,
                catalogSizeChecker: POSCatalogSizeCheckerProtocol) {
        self.fullSyncService = fullSyncService
        self.incrementalSyncService = incrementalSyncService
        self.grdbManager = grdbManager
        self.maxIncrementalSyncAge = maxIncrementalSyncAge
        self.catalogSizeChecker = catalogSizeChecker
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

        _ = try await fullSyncService.startFullSync(for: siteID)

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")
    }

    public func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
        guard let catalogSize = try? await catalogSizeChecker.checkCatalogSize(for: siteID) else {
            DDLogError("📋 POSCatalogSyncCoordinator: Could not get catalog size for site \(siteID)")
            return false
        }

        guard catalogSize.totalCount <= 1000 else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) has catalog size \(catalogSize.totalCount), greater than 1000, should not sync.")
            return false
        }

        DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) has catalog size \(catalogSize.totalCount), with \(catalogSize.productCount) products and \(catalogSize.variationCount) variations")

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

    public func performIncrementalSyncIfApplicable(for siteID: Int64, forceSync: Bool) async throws {
        if ongoingIncrementalSyncs.contains(siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Incremental sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        guard let lastFullSyncDate = await lastFullSyncDate(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: No full sync performed yet for site \(siteID), skipping incremental sync")
            return
        }

        if !forceSync, let lastIncrementalSyncDate = await lastIncrementalSyncDate(for: siteID) {
            let age = Date().timeIntervalSince(lastIncrementalSyncDate)

            if age <= maxIncrementalSyncAge {
                return DDLogInfo("📋 POSCatalogSyncCoordinator: Last incremental sync for site \(siteID) was \(Int(age))s ago, sync not needed")
            }
        }

        ongoingIncrementalSyncs.insert(siteID)

        defer {
            ongoingIncrementalSyncs.remove(siteID)
        }

        DDLogInfo("🔄 POSCatalogSyncCoordinator starting incremental sync for site \(siteID)")

        try await incrementalSyncService.startIncrementalSync(for: siteID,
                                                              lastFullSyncDate: lastFullSyncDate,
                                                              lastIncrementalSyncDate: lastIncrementalSyncDate(for: siteID))

        DDLogInfo("✅ POSCatalogSyncCoordinator completed incremental sync for site \(siteID)")
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

    private func lastIncrementalSyncDate(for siteID: Int64) async -> Date? {
        do {
            return try await grdbManager.databaseConnection.read { db in
                return try PersistedSite.filter(key: siteID).fetchOne(db)?.lastCatalogIncrementalSyncDate
            }
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Error loading site \(siteID) for incremental sync date: \(error)")
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
