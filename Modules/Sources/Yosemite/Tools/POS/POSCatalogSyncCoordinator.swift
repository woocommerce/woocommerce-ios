// periphery:ignore:all
import Foundation
import Storage
import GRDB
import Alamofire

public protocol POSCatalogSyncCoordinatorProtocol {
    /// Performs a full catalog sync if applicable for the specified site
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    ///   - regenerateCatalog: Whether to always generate a new catalog. If false, a cached catalog will be used if available.
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool) async throws

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
    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws

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

    /// Stops all ongoing sync tasks for the specified site
    /// - Parameter siteID: The site ID to stop syncs for
    func stopOngoingSyncs(for siteID: Int64) async
}

public extension POSCatalogSyncCoordinatorProtocol {
    func performFullSync(for siteID: Int64, regenerateCatalog: Bool = false) async throws {
        try await performFullSyncIfApplicable(for: siteID, maxAge: .zero, regenerateCatalog: regenerateCatalog)
    }

    func performIncrementalSync(for siteID: Int64) async throws {
        try await performIncrementalSyncIfApplicable(for: siteID, maxAge: .zero)
    }

    /// Performs a smart sync with a default 24-hour threshold for full sync
    func performSmartSync(for siteID: Int64) async throws {
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        let oneHour: TimeInterval = 60 * 60
        try await performSmartSync(for: siteID, fullSyncMaxAge: twentyFourHours, incrementalSyncMaxAge: oneHour)
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

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol
    private let grdbManager: GRDBManagerProtocol
    private let catalogEligibilityChecker: POSLocalCatalogEligibilityServiceProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol

    /// Tracks ongoing incremental syncs by site ID to prevent duplicates
    private var ongoingIncrementalSyncs: Set<Int64> = []

    /// Tracks ongoing full sync tasks by site ID for cancellation
    private var ongoingFullSyncTasks: [Int64: Task<Void, Error>] = [:]

    /// Tracks ongoing incremental sync tasks by site ID for cancellation
    private var ongoingIncrementalSyncTasks: [Int64: Task<Void, Error>] = [:]

    /// Observable model for full sync state updates
    public nonisolated let fullSyncStateModel: POSCatalogSyncStateModel = .init()

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

    public func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        guard try await shouldPerformFullSync(for: siteID, maxAge: maxAge) else {
            throw POSCatalogSyncError.shouldNotSync
        }

        if await fullSyncInProgress(for: siteID) {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        let isFirstSync = await lastFullSyncDate(for: siteID) == nil

        emitSyncState(isFirstSync ? .initialSyncStarted(siteID: siteID) : .syncStarted(siteID: siteID))

        let allowCellular = isFirstSync || siteSettings.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)
        DDLogInfo("🔄 POSCatalogSyncCoordinator starting full sync for site \(siteID)")

        // Create a task to perform the sync
        let syncTask = Task<Void, Error> {
            _ = try await fullSyncService.startFullSync(for: siteID,
                                                        regenerateCatalog: regenerateCatalog,
                                                        allowCellular: allowCellular)
        }

        // Store the task for potential cancellation
        ongoingFullSyncTasks[siteID] = syncTask

        defer {
            ongoingFullSyncTasks.removeValue(forKey: siteID)
        }

        do {
            try await syncTask.value
            emitSyncState(.syncCompleted(siteID: siteID))
        } catch AFError.explicitlyCancelled, is CancellationError {
            if isFirstSync {
                emitSyncState(.initialSyncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
            } else {
                emitSyncState(.syncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
            }
            throw POSCatalogSyncError.requestCancelled
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator failed to complete sync for site \(siteID): \(error)")
            if isFirstSync {
                emitSyncState(.initialSyncFailed(siteID: siteID, error: error))
            } else {
                emitSyncState(.syncFailed(siteID: siteID, error: error))
            }
            throw error
        }

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    public func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws {
        let lastFullSync = await lastFullSyncDate(for: siteID) ?? Date(timeIntervalSince1970: 0)
        let lastFullSyncUTC = ISO8601DateFormatter().string(from: lastFullSync)

        if Date().timeIntervalSince(lastFullSync) >= fullSyncMaxAge {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing full sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performFullSyncIfApplicable(for: siteID, maxAge: fullSyncMaxAge, regenerateCatalog: false)
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
        guard try await checkSyncEligibility(for: siteID) else {
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
        switch fullSyncStateModel.state[siteID] {
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

        // Create a task to perform the sync
        let syncTask = Task<Void, Error> {
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
            try await syncTask.value
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        }

        DDLogInfo("✅ POSCatalogSyncCoordinator completed incremental sync for site \(siteID)")

        // Record first sync date if this was the first successful sync
        recordFirstSyncIfNeeded(for: siteID)
    }

    private func shouldPerformIncrementalSync(for siteID: Int64, maxAge: TimeInterval) async throws -> Bool {
        guard try await checkSyncEligibility(for: siteID) else {
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
        if let cached = fullSyncStateModel.state[siteID] {
            return cached
        }

        let state: POSCatalogSyncState

        if await lastFullSyncDate(for: siteID) == nil {
            state = .syncNeverDone(siteID: siteID)
        } else {
            state = .syncCompleted(siteID: siteID)
        }

        fullSyncStateModel.state[siteID] = state
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
        if let currentState = fullSyncStateModel.state[siteID] {
            switch currentState {
            case .initialSyncStarted, .syncStarted:
                emitSyncState(.syncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
                DDLogInfo("🛑 POSCatalogSyncCoordinator: Updated sync state to cancelled for site \(siteID)")
            default:
                break
            }
        }
    }
}

// MARK: - Syncing State

private extension POSCatalogSyncCoordinator {
    func emitSyncState(_ state: POSCatalogSyncState) {
        let siteID: Int64 = switch state {
        case .initialSyncStarted(let id),
                .syncStarted(let id),
                .syncCompleted(let id),
                .initialSyncFailed(let id, _),
                .syncFailed(let id, _),
                .syncNeverDone(let id):
            id
        }

        fullSyncStateModel.state[siteID] = state
    }
}

@Observable
public class POSCatalogSyncStateModel {
    public var state: [Int64: POSCatalogSyncState] = [:]

    public init() {}
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
    func checkSyncEligibility(for siteID: Int64) async throws -> Bool {
        guard try await catalogEligibilityChecker.catalogEligibility(for: siteID) == .eligible else {
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
