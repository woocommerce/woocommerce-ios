// periphery:ignore:all
import Foundation
import Storage
import GRDB
import Alamofire
import protocol WooFoundation.Analytics
import protocol WooFoundation.ConnectivityObserver
import enum WooFoundation.ConnectionType
import struct WooFoundationCore.WooAnalyticsEvent

public protocol POSCatalogSyncCoordinatorProtocol {
    /// Performs a full catalog sync if applicable for the specified site
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    ///   - regenerateCatalog: Whether to always generate a new catalog. If false, a cached catalog will be used if available.
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool, isBackgroundSync: Bool) async throws

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
    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval, isBackgroundSync: Bool) async throws

    /// Stream that emits full sync state updates
    var fullSyncStateModel: POSCatalogSyncStateModel { get }

    /// Returns the last known full sync state for a site
    /// If no state is cached, determines state from lastSyncDate
    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState

    /// Checks if the last sync is older than the specified number of days
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxDays: Maximum number of days before a sync is considered stale
    /// - Returns: True if the last sync is older than the specified days or if there has been no sync
    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool

    /// Returns the number of hours since the last catalog sync
    /// - Parameter siteID: The site ID to check
    /// - Returns: Hours since last sync, or nil if no sync date is available
    func hoursSinceLastSync(for siteID: Int64) async -> Int?

    /// Stops all ongoing sync tasks for the specified site
    /// - Parameter siteID: The site ID to stop syncs for
    func stopOngoingSyncs(for siteID: Int64) async

    /// Processes a completed background catalog download.
    /// Called when the app is woken by iOS for a background URLSession completion.
    /// Parses and persists the catalog, then updates sync state.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog
    ///   - siteID: Site ID for this catalog
    func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws

    /// Deletes specific products and/or variations from the local catalog
    /// - Parameters:
    ///   - productIDs: Product IDs to delete
    ///   - variationIDs: Variation IDs to delete
    ///   - siteID: The site ID
    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws

    /// Starts background FTS rebuild if needed (products exist but index empty)
    func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async
}

public extension POSCatalogSyncCoordinatorProtocol {
    func performFullSync(for siteID: Int64, regenerateCatalog: Bool = false) async throws {
        try await performFullSyncIfApplicable(for: siteID, maxAge: .zero, regenerateCatalog: regenerateCatalog, isBackgroundSync: false)
    }

    func performIncrementalSync(for siteID: Int64) async throws {
        try await performIncrementalSyncIfApplicable(for: siteID, maxAge: .zero)
    }

    /// Performs a smart sync with a default 24-hour threshold for full sync
    func performSmartSync(for siteID: Int64, isBackgroundSync: Bool) async throws {
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        let oneHour: TimeInterval = 60 * 60
        try await performSmartSync(for: siteID, fullSyncMaxAge: twentyFourHours, incrementalSyncMaxAge: oneHour, isBackgroundSync: isBackgroundSync)
    }
}

public enum POSCatalogSyncError: Error, Equatable {
    case syncAlreadyInProgress(siteID: Int64)
    case negativeMaxAge
    case invalidData
    case timeout
    case generationFailed
    case requestCancelled
    case shouldNotSync
}

/// Type of catalog sync operation for analytics tracking
public enum POSCatalogSyncType: String {
    case full
    case incremental
}

/// Strategy used for catalog sync, for analytics tracking
public enum POSCatalogSyncStrategy: String {
    /// Paginated API sync
    case localCatalog = "local_catalog"
    /// File-based catalog API sync
    case localCatalogFile = "local_catalog_file"
}

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol
    private let grdbManager: GRDBManagerProtocol
    private let catalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol
    private let analytics: Analytics?
    private let connectivityObserver: ConnectivityObserver?
    private let syncStrategy: POSCatalogSyncStrategy

    /// Tracks ongoing incremental syncs by site ID to prevent duplicates
    private var ongoingIncrementalSyncs: Set<Int64> = []

    /// Tracks ongoing full sync tasks by site ID for cancellation
    private var ongoingFullSyncTasks: [Int64: Task<POSCatalog, Error>] = [:]

    /// Tracks ongoing incremental sync tasks by site ID for cancellation
    private var ongoingIncrementalSyncTasks: [Int64: Task<POSCatalog, Error>] = [:]

    /// Tracks background FTS rebuild tasks by site ID
    private var backgroundFTSRebuildTasks: [Int64: Task<Void, Never>] = [:]

    /// Observable model for full sync state updates
    public nonisolated let fullSyncStateModel: POSCatalogSyncStateModel = .init()

    public init(fullSyncService: POSCatalogFullSyncServiceProtocol,
                incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol,
                grdbManager: GRDBManagerProtocol,
                catalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol,
                siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol? = nil,
                analytics: Analytics? = nil,
                connectivityObserver: ConnectivityObserver? = nil,
                usesCatalogAPI: Bool = false) {
        self.fullSyncService = fullSyncService
        self.incrementalSyncService = incrementalSyncService
        self.grdbManager = grdbManager
        self.catalogEligibilityChecker = catalogEligibilityChecker
        self.siteSettings = siteSettings ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
        self.analytics = analytics
        self.connectivityObserver = connectivityObserver
        self.syncStrategy = usesCatalogAPI ? .localCatalogFile : .localCatalog
    }

    public func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool, isBackgroundSync: Bool) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        guard try await shouldPerformFullSync(for: siteID, maxAge: maxAge) else {
            let reason = await getSyncSkipReason(for: siteID, maxAge: maxAge)
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncSkipped(reason: reason,
                                                                      syncType: POSCatalogSyncType.full.rawValue,
                                                                      syncStrategy: syncStrategy.rawValue))
            throw POSCatalogSyncError.shouldNotSync
        }

        if await fullSyncInProgress(for: siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        let isFirstSync = await lastFullSyncDate(for: siteID) == nil

        await emitSyncState(isFirstSync ? .initialSyncStarted(siteID: siteID) : .syncStarted(siteID: siteID))

        // Track sync started analytics
        let connectionType = getConnectionType()
        trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncStarted(syncType: POSCatalogSyncType.full.rawValue,
                                                                  syncStrategy: syncStrategy.rawValue,
                                                                  connectionType: connectionType))

        let allowCellular = isFirstSync || siteSettings.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)
        DDLogInfo("🔄 POSCatalogSyncCoordinator starting full sync for site \(siteID)")

        let syncStartTime = Date()

        // Create a task to perform the sync
        let syncTask = Task<POSCatalog, Error> {
            try await fullSyncService.startFullSync(for: siteID,
                                                    regenerateCatalog: regenerateCatalog,
                                                    allowCellular: allowCellular,
                                                    isBackgroundSync: isBackgroundSync)
        }

        // Store the task for potential cancellation
        ongoingFullSyncTasks[siteID] = syncTask

        defer {
            ongoingFullSyncTasks.removeValue(forKey: siteID)
        }

        do {
            let syncedCatalog = try await syncTask.value
            await emitSyncState(.syncCompleted(siteID: siteID))

            // Track sync completed analytics
            let syncDurationMs = Int(Date().timeIntervalSince(syncStartTime) * 1000)
            let (totalProducts, totalVariations) = await getStorageCounts(for: siteID)
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncCompleted(
                syncType: POSCatalogSyncType.full.rawValue,
                syncStrategy: syncStrategy.rawValue,
                productsSynced: syncedCatalog.products.count,
                variationsSynced: syncedCatalog.variations.count,
                totalProducts: totalProducts,
                totalVariations: totalVariations,
                syncDurationMs: syncDurationMs
            ))
        } catch AFError.explicitlyCancelled, is CancellationError {
            if isFirstSync {
                await emitSyncState(.initialSyncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
            } else {
                await emitSyncState(.syncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
            }
            // Track sync failed analytics
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncFailed(
                syncType: POSCatalogSyncType.full.rawValue,
                syncStrategy: syncStrategy.rawValue,
                error: POSCatalogSyncError.requestCancelled,
                errorClassifier: POSCatalogSyncErrorClassifier.classify
            ))
            throw POSCatalogSyncError.requestCancelled
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator failed to complete sync for site \(siteID): \(error)")
            if isFirstSync {
                await emitSyncState(.initialSyncFailed(siteID: siteID, error: error))
            } else {
                await emitSyncState(.syncFailed(siteID: siteID, error: error))
            }
            // Track sync failed analytics
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncFailed(
                syncType: POSCatalogSyncType.full.rawValue,
                syncStrategy: syncStrategy.rawValue,
                error: error,
                errorClassifier: POSCatalogSyncErrorClassifier.classify
            ))
            throw error
        }

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    // TODO: WOOMOB-1677 - Add logic to check for in-progress catalog generation before starting new sync.
    // When Background App Refresh or foreground app open triggers this, first check if there's a
    // pending catalog generation from a previous session (requires state persistence). If so,
    // poll once for status and download/parse if ready instead of starting a new generation.
    public func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval, isBackgroundSync: Bool) async throws {
        let lastFullSync = await lastFullSyncDate(for: siteID) ?? Date(timeIntervalSince1970: 0)
        let lastFullSyncUTC = ISO8601DateFormatter().string(from: lastFullSync)

        if Date().timeIntervalSince(lastFullSync) >= fullSyncMaxAge {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing full sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performFullSyncIfApplicable(for: siteID, maxAge: fullSyncMaxAge, regenerateCatalog: false, isBackgroundSync: isBackgroundSync)
        } else {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing incremental sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performIncrementalSyncIfApplicable(for: siteID, maxAge: incrementalSyncMaxAge)
        }

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    /// Determines if a full sync should be performed based on the age of the last sync
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Returns: True if a sync should be performed
    private func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async throws -> Bool {
        guard try await checkSyncEligibility(for: siteID, ignoreTemporalCriteria: maxAge == .zero) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Full sync skipped - site \(siteID) is not eligible")
            return false
        }

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

    private func fullSyncInProgress(for siteID: Int64) async -> Bool {
        switch await fullSyncStateModel.state[siteID] {
        case .syncStarted, .initialSyncStarted:
            return true
        default:
            return false
        }
    }

    private func ongoingSyncInProgress(for siteID: Int64) async -> Bool {
        ongoingIncrementalSyncs.contains(siteID)
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

        guard try await shouldPerformIncrementalSync(for: siteID, maxAge: maxAge) else {
            let reason = await getIncrementalSyncSkipReason(for: siteID, maxAge: maxAge)
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncSkipped(reason: reason,
                                                                      syncType: POSCatalogSyncType.incremental.rawValue,
                                                                      syncStrategy: syncStrategy.rawValue))
            return
        }

        if await ongoingSyncInProgress(for: siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Incremental sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        if await fullSyncInProgress(for: siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Full sync already in progress for site \(siteID)")
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

        // Track sync started analytics
        let connectionType = getConnectionType()
        trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncStarted(syncType: POSCatalogSyncType.incremental.rawValue,
                                                                  syncStrategy: syncStrategy.rawValue,
                                                                  connectionType: connectionType))

        let syncStartTime = Date()

        // Create a task to perform the sync
        let syncTask = Task<POSCatalog, Error> {
            try await incrementalSyncService.startIncrementalSync(for: siteID,
                                                                  lastFullSyncDate: lastFullSyncDate,
                                                                  lastIncrementalSyncDate: await lastIncrementalSyncDate(for: siteID))
        }

        // Store the task for potential cancellation
        ongoingIncrementalSyncTasks[siteID] = syncTask

        defer {
            ongoingIncrementalSyncTasks.removeValue(forKey: siteID)
        }

        do {
            let syncedCatalog = try await syncTask.value
            DDLogInfo("✅ POSCatalogSyncCoordinator completed incremental sync for site \(siteID)")

            // Track sync completed analytics
            let syncDurationMs = Int(Date().timeIntervalSince(syncStartTime) * 1000)
            let (totalProducts, totalVariations) = await getStorageCounts(for: siteID)
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncCompleted(
                syncType: POSCatalogSyncType.incremental.rawValue,
                syncStrategy: syncStrategy.rawValue,
                productsSynced: syncedCatalog.products.count + syncedCatalog.productsToRemove.count,
                variationsSynced: syncedCatalog.variations.count,
                totalProducts: totalProducts,
                totalVariations: totalVariations,
                syncDurationMs: syncDurationMs
            ))
        } catch AFError.explicitlyCancelled, is CancellationError {
            // Track sync failed analytics
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncFailed(
                syncType: POSCatalogSyncType.incremental.rawValue,
                syncStrategy: syncStrategy.rawValue,
                error: POSCatalogSyncError.requestCancelled,
                errorClassifier: POSCatalogSyncErrorClassifier.classify
            ))
            throw POSCatalogSyncError.requestCancelled
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator failed to complete incremental sync for site \(siteID): \(error)")
            // Track sync failed analytics
            trackAnalytics(WooAnalyticsEvent.LocalCatalog.syncFailed(
                syncType: POSCatalogSyncType.incremental.rawValue,
                syncStrategy: syncStrategy.rawValue,
                error: error,
                errorClassifier: POSCatalogSyncErrorClassifier.classify
            ))
            throw error
        }

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    private func shouldPerformIncrementalSync(for siteID: Int64, maxAge: TimeInterval) async throws -> Bool {
        guard try await checkSyncEligibility(for: siteID, ignoreTemporalCriteria: maxAge == .zero) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Incremental sync skipped - site \(siteID) is not eligible")
            return false
        }

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

    public func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        if let cached = await fullSyncStateModel.state[siteID] {
            return cached
        }

        let state: POSCatalogSyncState

        if await lastFullSyncDate(for: siteID) == nil {
            state = .syncNeverDone(siteID: siteID)
        } else {
            state = .syncCompleted(siteID: siteID)
        }

        await fullSyncStateModel.updateState(state, for: siteID)
        return state
    }

    public func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        // Check only the last full sync date, incremental syncs don't refresh well enough to consider non-stale.
        guard let lastFullSync = await lastFullSyncDate(for: siteID) else {
            // If we've never done a full sync, we're stale.
            return true
        }

        guard let thresholdDate = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) else {
            // This shouldn't fail, and if it does, we can assume the catalog is fine
            return false
        }

        return lastFullSync < thresholdDate
    }

    public func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        guard let lastSyncDate = await lastFullSyncDate(for: siteID) else {
            return nil
        }
        let timeInterval = Date().timeIntervalSince(lastSyncDate)
        return Int(timeInterval / 3600) // Convert seconds to hours
    }

    public func stopOngoingSyncs(for siteID: Int64) async {
        DDLogInfo("🛑 POSCatalogSyncCoordinator: Stopping ongoing syncs for site \(siteID)")

        // Cancel ongoing full sync task if exists
        if let fullSyncTask = ongoingFullSyncTasks[siteID] {
            fullSyncTask.cancel()
            ongoingFullSyncTasks.removeValue(forKey: siteID)
            DDLogInfo("🛑 POSCatalogSyncCoordinator: Cancelled full sync task for site \(siteID)")
        }

        // Cancel ongoing incremental sync task if exists
        if let incrementalSyncTask = ongoingIncrementalSyncTasks[siteID] {
            incrementalSyncTask.cancel()
            ongoingIncrementalSyncTasks.removeValue(forKey: siteID)
            DDLogInfo("🛑 POSCatalogSyncCoordinator: Cancelled incremental sync task for site \(siteID)")
        }

        // Clean up incremental sync tracking
        if ongoingIncrementalSyncs.contains(siteID) {
            ongoingIncrementalSyncs.remove(siteID)
            DDLogInfo("🛑 POSCatalogSyncCoordinator: Cleaned up incremental sync tracking for site \(siteID)")
        }

        // Update sync state to reflect that syncs are being stopped
        // This will prevent new syncs from starting for this site
        if let currentState = await fullSyncStateModel.state[siteID] {
            switch currentState {
            case .initialSyncStarted, .syncStarted:
                await emitSyncState(.syncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
                DDLogInfo("🛑 POSCatalogSyncCoordinator: Updated sync state to cancelled for site \(siteID)")
            default:
                break
            }
        }
    }

    public func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws {
        DDLogInfo("🟣 POSCatalogSyncCoordinator: Processing background download for site \(siteID)")

        // Parse and persist using the full sync service
        let catalog = try await fullSyncService.parseAndPersistBackgroundDownload(fileURL: fileURL, siteID: siteID)

        DDLogInfo("✅ Background catalog processed: \(catalog.products.count) products, \(catalog.variations.count) variations")

        // Update sync state to completed
        await emitSyncState(.syncCompleted(siteID: siteID))

        // Record first sync date if needed
        recordFirstSyncIfNeeded(for: siteID)
    }

    // MARK: - Analytics Helpers

    private nonisolated func trackAnalytics(_ event: WooAnalyticsEvent) {
        analytics?.track(event.statName.rawValue, properties: event.properties, error: event.error)
    }

    private nonisolated func getConnectionType() -> String {
        guard let observer = connectivityObserver else { return "unknown" }
        switch observer.currentStatus {
        case .reachable(let connectionType):
            switch connectionType {
            case .ethernetOrWiFi:
                return "wifi"
            case .cellular:
                return "cellular"
            case .other:
                return "unknown"
            }
        case .notReachable, .unknown:
            return "unknown"
        }
    }

    private func getStorageCounts(for siteID: Int64) async -> (products: Int, variations: Int) {
        do {
            return try await grdbManager.databaseConnection.read { db in
                let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
                let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
                return (productCount, variationCount)
            }
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Failed to get storage counts: \(error)")
            return (products: 0, variations: 0)
        }
    }

    private func getSyncSkipReason(for siteID: Int64, maxAge: TimeInterval) async -> String {
        // Check eligibility
        do {
            let eligibility = try await catalogEligibilityChecker.catalogEligibility(for: siteID)
            if case .ineligible(let reason) = eligibility {
                return reason.skipReason
            }
        } catch {
            return "eligibility_check_failed"
        }

        // Check sync eligibility
        do {
            let eligibility = try await syncEligibility(for: siteID, ignoreTemporalCriteria: maxAge == .zero)
            if case .ineligible(let reason) = eligibility {
                return reason.skipReason
            }
        } catch {
            return "sync_eligibility_check_failed"
        }

        // Check if sync is needed based on age
        guard let lastSyncDate = await lastFullSyncDate(for: siteID) else {
            return "no_previous_sync" // This shouldn't happen if shouldPerformFullSync returned false
        }

        let age = Date().timeIntervalSince(lastSyncDate)
        if age < maxAge {
            return "catalog_not_stale"
        }

        return "unknown_reason"
    }

    private func getIncrementalSyncSkipReason(for siteID: Int64, maxAge: TimeInterval) async -> String {
        // Check overall local catalog eligibility first
        do {
            let eligibility = try await catalogEligibilityChecker.catalogEligibility(for: siteID)
            if case .ineligible(let reason) = eligibility {
                return reason.skipReason
            }
        } catch {
            return "eligibility_check_failed"
        }

        // Check sync eligibility
        do {
            let eligibility = try await syncEligibility(for: siteID, ignoreTemporalCriteria: maxAge == .zero)
            if case .ineligible(let reason) = eligibility {
                return reason.skipReason
            }
        } catch {
            return "sync_eligibility_check_failed"
        }

        // Check if full sync exists
        guard await lastFullSyncDate(for: siteID) != nil else {
            return "no_full_sync"
        }

        // Check if incremental sync is needed based on age
        if maxAge > 0, let lastIncrementalSyncDate = await lastIncrementalSyncDate(for: siteID) {
            let age = Date().timeIntervalSince(lastIncrementalSyncDate)
            if age <= maxAge {
                return "catalog_not_stale"
            }
        }

        return "unknown_reason"
    }

    public func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        let persistenceService = POSCatalogPersistenceService(grdbManager: grdbManager)
        try await persistenceService.deleteProducts(productIDs, variationIDs: variationIDs, siteID: siteID)
    }

    // MARK: - FTS Rebuild

    public func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async {
        do {
            let needsRebuild = try await grdbManager.databaseConnection.read { db in
                try POSSearchIndexBuilder.needsRebuild(for: siteID, in: db)
            }

            guard needsRebuild else {
                DDLogInfo("📋 POSCatalogSyncCoordinator: FTS rebuild not needed for site \(siteID)")
                return
            }

            DDLogInfo("🔄 POSCatalogSyncCoordinator: Starting background FTS rebuild for site \(siteID)")

            let task = Task {
                defer {
                    backgroundFTSRebuildTasks.removeValue(forKey: siteID)
                }
                do {
                    try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)
                    DDLogInfo("✅ POSCatalogSyncCoordinator: Background FTS rebuild complete for site \(siteID)")
                } catch {
                    DDLogError("⛔️ POSCatalogSyncCoordinator: Background FTS rebuild failed for site \(siteID): \(error)")
                }
            }
            backgroundFTSRebuildTasks[siteID] = task
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Failed to check FTS rebuild need: \(error)")
        }
    }

    /// Waits for any pending background FTS rebuild task to complete.
    public func awaitBackgroundFTSRebuild(for siteID: Int64) async {
        guard let task = backgroundFTSRebuildTasks[siteID] else { return }
        await task.value
    }

}

// MARK: - Syncing State

private extension POSCatalogSyncCoordinator {
    func emitSyncState(_ state: POSCatalogSyncState) async {
        let siteID: Int64 = switch state {
        case .initialSyncStarted(let id),
                .syncStarted(let id),
                .syncCompleted(let id),
                .initialSyncFailed(let id, _),
                .syncFailed(let id, _),
                .syncNeverDone(let id):
            id
        }

        await fullSyncStateModel.updateState(state, for: siteID)
    }
}

@Observable
@MainActor
public class POSCatalogSyncStateModel {
    public var state: [Int64: POSCatalogSyncState] = [:]

    nonisolated public init() {}

    public func updateState(_ newState: POSCatalogSyncState, for siteID: Int64) {
        state[siteID] = newState
    }
}


public enum POSCatalogSyncState: Equatable {
    case initialSyncStarted(siteID: Int64)
    case syncStarted(siteID: Int64)
    case syncCompleted(siteID: Int64)
    case initialSyncFailed(siteID: Int64, error: Error)
    case syncFailed(siteID: Int64, error: Error)
    case syncNeverDone(siteID: Int64)

    public static func == (lhs: POSCatalogSyncState, rhs: POSCatalogSyncState) -> Bool {
        switch (lhs, rhs) {
        case (.initialSyncStarted(let lhsSiteID), .initialSyncStarted(let rhsSiteID)),
            (.syncStarted(let lhsSiteID), .syncStarted(let rhsSiteID)),
            (.syncCompleted(let lhsSiteID), .syncCompleted(let rhsSiteID)),
            (.syncNeverDone(let lhsSiteID), .syncNeverDone(let rhsSiteID)):
            return lhsSiteID == rhsSiteID
        case (.initialSyncFailed(let lhsSiteID, let lhsError), .initialSyncFailed(let rhsSiteID, let rhsError)),
            (.syncFailed(let lhsSiteID, let lhsError), .syncFailed(let rhsSiteID, let rhsError)):
            return lhsSiteID == rhsSiteID && lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Constants

private extension POSCatalogSyncCoordinator {
    enum Constants {
        static let maxDaysSinceLastOpened = 30
    }

    // MARK: - Sync Eligibility

    /// Checks if sync is eligible for the given site based on catalog eligibility and temporal criteria
    func checkSyncEligibility(for siteID: Int64, ignoreTemporalCriteria: Bool = false) async throws -> Bool {
        switch try await syncEligibility(for: siteID, ignoreTemporalCriteria: ignoreTemporalCriteria) {
        case .eligible(reason: let reason):
            switch reason {
            case .neverSynced:
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (no first sync date recorded)")
            case .openedRecently(daysSinceOpened: let daysSinceOpened):
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (last opened \(daysSinceOpened) days ago)")
            case .recentFirstSync(daysSinceFirstSync: let daysSinceFirstSync):
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (within grace period: " +
                          "\(daysSinceFirstSync) days since first sync)")
            case .ignoredTemporalEligibilityCheck:
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) eligible (ignored temporal criteria check)")
            }
            return true
        case .ineligible(reason: let reason):
            switch reason {
            case .notEligibleForLocalCatalog:
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) - Catalog ineligible")
            case .notOpenedRecently(daysSinceOpened: let daysSinceOpened):
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) ineligible (POS last opened \(daysSinceOpened) days ago)")
            case .neverOpenedAndPastFirstSyncGracePeriod(daysSinceFirstSync: let daysSinceFirstSync):
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) ineligible (past 30-day grace period, " +
                          "no recent POS open, \(daysSinceFirstSync) days since first sync)")
            }
            return false
        }
    }

    func syncEligibility(for siteID: Int64, ignoreTemporalCriteria: Bool) async throws -> SyncEligibility {
        guard try await catalogEligibilityChecker.catalogEligibility(for: siteID) == .eligible else {
            return .ineligible(reason: .notEligibleForLocalCatalog)
        }

        guard !ignoreTemporalCriteria else {
            return .eligible(reason: .ignoredTemporalEligibilityCheck)
        }

        // Then check temporal eligibility (30-day criteria)
        let firstSyncDate = siteSettings.getFirstPOSCatalogSyncDate(siteID: siteID)
        let lastOpenedDate = siteSettings.getPOSLastOpenedDate(siteID: siteID)

        // Case 1: No first sync date yet - eligible (will be set on first sync)
        guard let firstSync = firstSyncDate else {
            return .eligible(reason: .neverSynced)
        }

        // Case 2: Has synced before. Check if within 30-day window from first sync
        let daysSinceFirstSync = Calendar.current.dateComponents([.day], from: firstSync, to: Date()).day ?? 0

        if daysSinceFirstSync > Constants.maxDaysSinceLastOpened {
            // More than 30 days since first sync - must have opened POS recently to remain eligible
            guard let lastOpened = lastOpenedDate else {
                return .ineligible(reason: .neverOpenedAndPastFirstSyncGracePeriod(daysSinceFirstSync: daysSinceFirstSync))
            }

            let daysSinceLastOpened = Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day ?? 0

            if daysSinceLastOpened <= Constants.maxDaysSinceLastOpened {
                return .eligible(reason: .openedRecently(daysSinceOpened: daysSinceLastOpened))
            } else {
                return .ineligible(reason: .notOpenedRecently(daysSinceOpened: daysSinceLastOpened))
            }
        } else {
            // Within 30 days of first sync - always eligible (new user grace period)
            return .eligible(reason: .recentFirstSync(daysSinceFirstSync: daysSinceFirstSync))
        }
    }

    enum SyncEligibility {
        case eligible(reason: EligibleReason)
        case ineligible(reason: IneligibleReason)

        enum EligibleReason {
            case neverSynced
            case openedRecently(daysSinceOpened: Int)
            case recentFirstSync(daysSinceFirstSync: Int)
            case ignoredTemporalEligibilityCheck
        }

        enum IneligibleReason {
            case notEligibleForLocalCatalog
            case notOpenedRecently(daysSinceOpened: Int)
            case neverOpenedAndPastFirstSyncGracePeriod(daysSinceFirstSync: Int)

            var skipReason: String {
                switch self {
                    case .notEligibleForLocalCatalog: "not_eligible"
                    case .notOpenedRecently: "pos_not_opened_30_days"
                    case .neverOpenedAndPastFirstSyncGracePeriod: "pos_not_opened_30_days"
                }
            }
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
