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
    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws

    /// Stream that emits full sync state updates
    var fullSyncStateStream: AsyncStream<POSCatalogSyncState> { get }

    /// Returns the last known full sync state for a site
    /// If no state is cached, determines state from lastSyncDate
    func lastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState
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
        let oneHour: TimeInterval = 60 * 60
        try await performSmartSync(for: siteID, fullSyncMaxAge: twentyFourHours, incrementalSyncMaxAge: oneHour)
    }
}

public enum POSCatalogSyncError: Error, Equatable {
    case syncAlreadyInProgress(siteID: Int64)
    case negativeMaxAge
    case catalogSizeCheckFailed(siteID: Int64)
    case requestCancelled
}

public actor POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let fullSyncService: POSCatalogFullSyncServiceProtocol
    private let incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol
    private let grdbManager: GRDBManagerProtocol
    private let catalogSizeLimit: Int
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol

    /// Tracks ongoing incremental syncs by site ID to prevent duplicates
    private var ongoingIncrementalSyncs: Set<Int64> = []

    /// Stream for full sync state updates
    public nonisolated let fullSyncStateStream: AsyncStream<POSCatalogSyncState>
    /// Continuation for emitting state updates
    private let fullSyncStateStreamContinuation: AsyncStream<POSCatalogSyncState>.Continuation
    /// Cache of last known full sync state for each site
    private var fullSyncStateCache: [Int64: POSCatalogSyncState] = [:]

    public init(fullSyncService: POSCatalogFullSyncServiceProtocol,
                incrementalSyncService: POSCatalogIncrementalSyncServiceProtocol,
                grdbManager: GRDBManagerProtocol,
                catalogSizeLimit: Int? = nil,
                catalogSizeChecker: POSCatalogSizeCheckerProtocol) {
        self.fullSyncService = fullSyncService
        self.incrementalSyncService = incrementalSyncService
        self.grdbManager = grdbManager
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultSizeLimitForPOSCatalog
        self.catalogSizeChecker = catalogSizeChecker

        let (stream, continuation) = AsyncStream<POSCatalogSyncState>.makeStream()
        self.fullSyncStateStream = stream
        self.fullSyncStateStreamContinuation = continuation
    }

    public func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        guard try await shouldPerformFullSync(for: siteID, maxAge: maxAge) else {
            return
        }

        if case .syncStarted = fullSyncStateCache[siteID] {
            DDLogInfo("⚠️ POSCatalogSyncCoordinator: Sync already in progress for site \(siteID)")
            throw POSCatalogSyncError.syncAlreadyInProgress(siteID: siteID)
        }

        await emitSyncState(.syncStarted(siteID: siteID, isInitialSync: lastFullSyncDate(for: siteID) == nil))

        DDLogInfo("🔄 POSCatalogSyncCoordinator starting full sync for site \(siteID)")

        do {
            _ = try await fullSyncService.startFullSync(for: siteID)
            emitSyncState(.syncCompleted(siteID: siteID))
        } catch AFError.explicitlyCancelled, is CancellationError {
            emitSyncState(.syncFailed(siteID: siteID, error: POSCatalogSyncError.requestCancelled))
            throw POSCatalogSyncError.requestCancelled
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator failed to complete sync for site \(siteID): \(error)")
            emitSyncState(.syncFailed(siteID: siteID, error: error))
            throw error
        }

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")
    }

    public func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws {
        let lastFullSync = await lastFullSyncDate(for: siteID) ?? Date(timeIntervalSince1970: 0)
        let lastFullSyncUTC = ISO8601DateFormatter().string(from: lastFullSync)

        if Date().timeIntervalSince(lastFullSync) >= fullSyncMaxAge {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing full sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performFullSyncIfApplicable(for: siteID, maxAge: fullSyncMaxAge)
        } else {
            DDLogInfo("🔄 POSCatalogSyncCoordinator: Performing incremental sync for site \(siteID) (last full sync: \(lastFullSyncUTC) UTC)")
            try await performIncrementalSyncIfApplicable(for: siteID, maxAge: incrementalSyncMaxAge)
        }
    }

    /// Determines if a full sync should be performed based on the age of the last sync
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Returns: True if a sync should be performed
    private func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async throws -> Bool {
        try await shouldPerformFullSync(for: siteID, maxAge: maxAge, maxCatalogSize: catalogSizeLimit)
    }

    private func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval, maxCatalogSize: Int) async throws -> Bool {
        guard try await isCatalogSizeWithinLimit(for: siteID, maxCatalogSize: maxCatalogSize) else {
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

    /// Performs an incremental sync if applicable based on sync conditions
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Throws: POSCatalogSyncError.syncAlreadyInProgress if a sync is already running for this site
    public func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        try await performIncrementalSyncIfApplicable(for: siteID, maxAge: maxAge, maxCatalogSize: catalogSizeLimit)
    }

    private func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, maxCatalogSize: Int) async throws {
        guard maxAge >= 0 else {
            throw POSCatalogSyncError.negativeMaxAge
        }

        guard try await shouldPerformIncrementalSync(for: siteID, maxAge: maxAge, maxCatalogSize: maxCatalogSize) else {
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

        do {
            try await incrementalSyncService.startIncrementalSync(for: siteID,
                                                                  lastFullSyncDate: lastFullSyncDate,
                                                                  lastIncrementalSyncDate: lastIncrementalSyncDate(for: siteID))
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        }

        DDLogInfo("✅ POSCatalogSyncCoordinator completed incremental sync for site \(siteID)")
    }

    private func shouldPerformIncrementalSync(for siteID: Int64, maxAge: TimeInterval, maxCatalogSize: Int) async throws -> Bool {
        guard try await isCatalogSizeWithinLimit(for: siteID, maxCatalogSize: maxCatalogSize) else {
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

    /// Checks if the catalog size is within the specified sync limit
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxCatalogSize: Maximum allowed catalog size for syncing
    /// - Returns: True if catalog size is within limit
    /// - Throws: POSCatalogSyncError.catalogSizeCheckFailed if the size check fails, or requestCancelled if
    ///           the request was explicitly cancelled
    private func isCatalogSizeWithinLimit(for siteID: Int64, maxCatalogSize: Int) async throws -> Bool {
        do {
            let catalogSize = try await catalogSizeChecker.checkCatalogSize(for: siteID)
            guard catalogSize.totalCount <= maxCatalogSize else {
                DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) has catalog size \(catalogSize.totalCount), " +
                          "greater than \(maxCatalogSize), should not sync.")
                return false
            }

            DDLogInfo("📋 POSCatalogSyncCoordinator: Site \(siteID) has catalog size \(catalogSize.totalCount), with " +
                      "\(catalogSize.productCount) products and \(catalogSize.variationCount) variations")
            return true
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        } catch {
            DDLogError("⛔️ POSCatalogSyncCoordinator: Could not get catalog size for site \(siteID)")
            throw POSCatalogSyncError.catalogSizeCheckFailed(siteID: siteID)
        }
    }

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

    public func lastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        if let cached = fullSyncStateCache[siteID] {
            return cached
        }

        if await lastFullSyncDate(for: siteID) == nil {
            return .syncNeverDone(siteID: siteID)
        } else {
            return .syncCompleted(siteID: siteID)
        }
    }
}

// MARK: - Syncing State

private extension POSCatalogSyncCoordinator {
    func emitSyncState(_ state: POSCatalogSyncState) {
        let siteID: Int64 = switch state {
        case .syncStarted(let id, _), .syncCompleted(let id), .syncFailed(let id, _), .syncNeverDone(let id):
            id
        }

        fullSyncStateCache[siteID] = state
        fullSyncStateStreamContinuation.yield(state)
    }
}

public enum POSCatalogSyncState: Equatable {
    case syncStarted(siteID: Int64, isInitialSync: Bool)
    case syncCompleted(siteID: Int64)
    case syncFailed(siteID: Int64, error: Error)
    case syncNeverDone(siteID: Int64)

    public static func == (lhs: POSCatalogSyncState, rhs: POSCatalogSyncState) -> Bool {
        switch (lhs, rhs) {
        case (.syncStarted(let lhsSiteID, let lhsInitial), .syncStarted(let rhsSiteID, let rhsInitial)):
            return lhsSiteID == rhsSiteID && lhsInitial == rhsInitial
        case (.syncCompleted(let lhsSiteID), .syncCompleted(let rhsSiteID)):
            return lhsSiteID == rhsSiteID
        case (.syncFailed(let lhsSiteID, _), .syncFailed(let rhsSiteID, _)):
            return lhsSiteID == rhsSiteID
        case (.syncNeverDone(let lhsSiteID), .syncNeverDone(let rhsSiteID)):
            return lhsSiteID == rhsSiteID
        default:
            return false
        }
    }
}

// MARK: - Constants

private extension POSCatalogSyncCoordinator {
    enum Constants {
        static let defaultSizeLimitForPOSCatalog = 1000
    }
}
