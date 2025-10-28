// periphery:ignore:all
import Foundation
import Storage
import GRDB

public protocol POSCatalogSyncCoordinatorProtocol {
    /// Performs a full catalog sync if applicable for the specified site
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws

    /// Performs an incremental sync if applicable based on sync conditions
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    //periphery:ignore - remove ignore comment when incremental sync is integrated with POS
    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws

    /// Performs a smart sync that decides between full and incremental sync based on the last full sync date
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - fullSyncMaxAge: Maximum age before a full sync is triggered. If the last full sync is older than this,
    ///                     performs full sync; otherwise, performs incremental sync
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval) async throws
}

public extension POSCatalogSyncCoordinatorProtocol {
    func performFullSync(for siteID: Int64) async throws {
        try await performFullSyncIfApplicable(for: siteID, maxAge: .zero)
    }

    func performIncrementalSync(for siteID: Int64) async throws {
        try await performIncrementalSyncIfApplicable(for: siteID, maxAge: .zero)
    }

    /// Performs a smart sync with a default 24-hour threshold for full sync
    func performSmartSync(for siteID: Int64) async throws {
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        try await performSmartSync(for: siteID, fullSyncMaxAge: twentyFourHours)
    }
}

public enum POSCatalogSyncError: Error, Equatable {
    case syncAlreadyInProgress(siteID: Int64)
    case negativeMaxAge
}

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol
    private let grdbManager: GRDBManagerProtocol
    private let catalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol

    /// Tracks ongoing full syncs by site ID to prevent duplicates
    private var ongoingSyncs: Set<Int64> = []
    /// Tracks ongoing incremental syncs by site ID to prevent duplicates
    private var ongoingIncrementalSyncs: Set<Int64> = []

    public init(fullSyncService: POSCatalogFullSyncServiceProtocol,
                incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol,
                grdbManager: GRDBManagerProtocol,
                catalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol,
                siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.fullSyncService = fullSyncService
        self.incrementalSyncService = incrementalSyncService
        self.grdbManager = grdbManager
        self.catalogEligibilityChecker = catalogEligibilityChecker
        self.siteSettings = siteSettings ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
    }

    public func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        // Check sync eligibility before proceeding
        guard await checkSyncEligibility(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Full sync skipped - site \(siteID) is not eligible")
            return
        }

        guard await shouldPerformFullSync(for: siteID, maxAge: maxAge) else {
            return
        }

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

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    public func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval) async throws {
        // Check sync eligibility before proceeding
        guard await checkSyncEligibility(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Sync skipped - site \(siteID) is not eligible")
            return
        }

        let lastFullSync = await lastFullSyncDate(for: siteID) ?? Date(timeIntervalSince1970: 0)
        let lastFullSyncUTC = ISO8601DateFormatter().string(from: lastFullSync)

        if Date().timeIntervalSince(lastFullSync) >= fullSyncMaxAge {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing full sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performFullSync(for: siteID)
        } else {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing incremental sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performIncrementalSync(for: siteID)
        }

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    /// Determines if a full sync should be performed based on the age of the last sync
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Returns: True if a sync should be performed
    private func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
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
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago " +
                      "(max: \(Int(maxAge))s), sync needed")
        } else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago " +
                      "(max: \(Int(maxAge))s), sync not needed")
        }

        return shouldSync
    }

    /// Performs an incremental sync if applicable based on sync conditions
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    public func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        // Check sync eligibility before proceeding
        guard await checkSyncEligibility(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Incremental sync skipped - site \(siteID) is not eligible")
            return
        }

        guard await shouldPerformIncrementalSync(for: siteID, maxAge: maxAge) else {
            return
        }

        if ongoingIncrementalSyncs.contains(siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Incremental sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        guard let lastFullSyncDate = await lastFullSyncDate(for: siteID) else {
            return
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

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    private func shouldPerformIncrementalSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
        guard await lastFullSyncDate(for: siteID) != nil else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: No full sync performed yet for site \(siteID), skipping incremental sync")
            return false
        }

        if maxAge > 0, let lastIncrementalSyncDate = await lastIncrementalSyncDate(for: siteID) {
            let age = Date().timeIntervalSince(lastIncrementalSyncDate)

            if age <= maxAge {
                DDLogInfo("📋 POSCatalogSyncCoordinator: Last incremental sync for site \(siteID) was \(Int(age))s ago, sync not needed")
                return false
            }
        }

        return true
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

private extension POSCatalogSyncCoordinator {
    enum Constants {
        static let defaultSizeLimitForPOSCatalog = 1000
        static let maxDaysSinceLastOpened = 30
    }

    // MARK: - Sync Eligibility

    /// Checks if sync is eligible for the given site based on catalog eligibility and temporal criteria
    func checkSyncEligibility(for siteID: Int64) async -> Bool {guard await catalogEligibilityChecker.catalogEligibility(for: siteID) == .eligible else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) - Catalog ineligible")
            return false
        }

        // Then check temporal eligibility (30-day criteria)
        let firstSyncDate = siteSettings.getFirstPOSCatalogSyncDate(siteID: siteID)
        let lastOpenedDate = siteSettings.getPOSLastOpenedDate(siteID: siteID)

        // Case 1: No first sync date yet - eligible (will be set on first sync)
        guard let firstSync = firstSyncDate else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (no first sync date recorded)")
            return true
        }

        // Case 2: Has synced before. Check if within 30-day window from first sync
        let daysSinceFirstSync = Calendar.current.dateComponents([.day], from: firstSync, to: Date()).day ?? 0

        if daysSinceFirstSync > Constants.maxDaysSinceLastOpened {
            // More than 30 days since first sync - must have opened POS recently to remain eligible
            guard let lastOpened = lastOpenedDate else {
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) ineligible (past 30-day grace period, no recent POS open)")
                return false
            }

            let daysSinceLastOpened = Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day ?? 0

            if daysSinceLastOpened <= Constants.maxDaysSinceLastOpened {
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (last opened \(daysSinceLastOpened) days ago)")
                return true
            } else {
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) ineligible (POS last opened \(daysSinceLastOpened) days ago)")
                return false
            }
        } else {
            // Within 30 days of first sync - always eligible (new user grace period)
            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (within grace period: \(daysSinceFirstSync) days since first sync)")
            return true
        }
    }

    /// Records the first sync date if not already set
    func recordFirstSyncIfNeeded(for siteID: Int64) {
        // Only set if not already set (preserves original first sync date)
        if siteSettings.getFirstPOSCatalogSyncDate(siteID: siteID) == nil {
            siteSettings.setFirstPOSCatalogSyncDate(siteID: siteID, date: Date())
            DDLogInfo("📋 POSCatalogSyncCoordinator: Recorded first sync date for site \(siteID)")
        }
    }
}
