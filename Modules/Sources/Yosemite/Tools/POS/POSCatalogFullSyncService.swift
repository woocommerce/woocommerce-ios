import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import struct Networking.POSCatalogResponse
import struct Networking.POSCatalogRequestResponse
import enum Networking.POSCatalogStatus

public typealias POSCatalogSyncProgressHandler = @Sendable (POSCatalogSyncProgress) async -> Void

public protocol POSCatalogFullSyncServiceProtocol {
    /// Starts a full catalog sync process
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - regenerateCatalog: Whether to force the catalog generation
    ///   - allowCellular: Should cellular data be used if required.
    ///   - isBackgroundSync: Whether this sync is running in a background task context. Limits polling attempts to stay within ~30s window.
    ///   - onProgress: Optional callback invoked with catalog sync progress updates.
    /// - Returns: The synced catalog containing products and variations
    func startFullSync(for siteID: Int64,
                       regenerateCatalog: Bool,
                       allowCellular: Bool,
                       isBackgroundSync: Bool,
                       onProgress: POSCatalogSyncProgressHandler?) async throws -> POSCatalog

    /// Runs a full catalog sync using the legacy paginated REST endpoints, bypassing the catalog file API.
    /// Used as a fallback when the host blocks access to the generated catalog file.
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: The synced catalog containing products and variations
    func startPaginatedFullSync(for siteID: Int64, allowCellular: Bool) async throws -> POSCatalog

    /// Parses and persists a downloaded catalog file from a background download.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog
    ///   - siteID: Site ID for this catalog
    ///   - snapshotDate: When the snapshot's download started. Used as the persisted sync
    ///     watermark so a resumed snapshot doesn't claim to be current,
    ///     keeping the next smart/incremental sync able to refetch everything since then.
    /// - Returns: The parsed catalog
    func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64, snapshotDate: Date) async throws -> POSCatalog
}

/// Metadata from file-based catalog sync, used for analytics tracking.
public struct POSCatalogSyncMetadata {
    /// Number of polling attempts before completion
    public let pollAttempts: Int
    /// Server-side generation duration in milliseconds (completedAt - scheduledAt)
    public let generationDurationMs: Int?

    public init(pollAttempts: Int, generationDurationMs: Int?) {
        self.pollAttempts = pollAttempts
        self.generationDurationMs = generationDurationMs
    }
}

/// POS catalog from full sync.
public struct POSCatalog {
    public let products: [POSProduct]
    public let variations: [POSProductVariation]
    public let syncDate: Date

    /// Product IDs to remove from local catalog when these should be hidden when performing an incremental sync.
    /// This covers the case where products are marked as not available for POS by the merchant in wp-admin,
    /// and the request passes `posProductsOnly=true`. In which case these would be simply omitted.
    /// Variations are not tracked separately, they cascade delete in GRDB when their parent product is removed.
    public let productsToRemove: [Int64]

    /// Metadata from file-based sync polling, nil for paginated syncs.
    public let syncMetadata: POSCatalogSyncMetadata?

    public init(products: [POSProduct],
                variations: [POSProductVariation],
                syncDate: Date,
                productsToRemove: [Int64] = [],
                syncMetadata: POSCatalogSyncMetadata? = nil) {
        self.products = products
        self.variations = variations
        self.syncDate = syncDate
        self.productsToRemove = productsToRemove
        self.syncMetadata = syncMetadata
    }
}

public final class POSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    enum PollingConfig {
        /// Initial delay between poll attempts (3 seconds)
        static let initialDelay: TimeInterval = 3.0
        /// Multiplier applied to delay after each attempt (1.3x)
        static let multiplier: Double = 1.3
        /// Maximum delay between poll attempts (20 seconds)
        static let maxInterval: TimeInterval = 20.0
        /// Maximum polling attempts for background execution (~18/20s total, within iOS 30s limit)
        static let backgroundMaxAttempts = 4
    }

    private let syncRemote: POSCatalogSyncRemoteProtocol
    private let persistenceService: POSCatalogPersistenceServiceProtocol
    private let batchedLoader: BatchedRequestLoader
    private let usesCatalogAPI: Bool

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             batchSize: Int = 2,
                             grdbManager: GRDBManagerProtocol,
                             usesCatalogAPI: Bool) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSCatalogFullSyncService due missing credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let syncRemote = POSCatalogSyncRemote(network: network)
        let persistenceService = POSCatalogPersistenceService(grdbManager: grdbManager)
        self.init(syncRemote: syncRemote, batchSize: batchSize, persistenceService: persistenceService, usesCatalogAPI: usesCatalogAPI)
    }

    init(
        syncRemote: POSCatalogSyncRemoteProtocol,
        batchSize: Int,
        retryDelay: TimeInterval = 2.0,
        persistenceService: POSCatalogPersistenceServiceProtocol,
        usesCatalogAPI: Bool
    ) {
        self.syncRemote = syncRemote
        self.persistenceService = persistenceService
        self.batchedLoader = BatchedRequestLoader(batchSize: batchSize, retryDelay: retryDelay)
        self.usesCatalogAPI = usesCatalogAPI
    }

    // MARK: - Protocol Conformance

    public func startFullSync(for siteID: Int64,
                              regenerateCatalog: Bool = false,
                              allowCellular: Bool,
                              isBackgroundSync: Bool,
                              onProgress: POSCatalogSyncProgressHandler? = nil) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting full catalog sync for site ID: \(siteID) with regenerateCatalog: \(regenerateCatalog), " +
                  "allowCellular: \(allowCellular), isBackgroundSync: \(isBackgroundSync)")

        do {
            // Sync from network
            let catalog: POSCatalog
            if usesCatalogAPI {
                let maxAttempts = isBackgroundSync ? PollingConfig.backgroundMaxAttempts : .max
                catalog = try await loadCatalogFromCatalogAPI(for: siteID,
                                                              syncRemote: syncRemote,
                                                              regenerateCatalog: regenerateCatalog,
                                                              allowCellular: allowCellular,
                                                              maxAttempts: maxAttempts,
                                                              onProgress: onProgress)
            } else {
                catalog = try await loadCatalog(for: siteID, syncRemote: syncRemote, allowCellular: allowCellular)
            }
            DDLogInfo("✅ Loaded \(catalog.products.count) products and \(catalog.variations.count) variations for siteID \(siteID)")

            // Persist to database
            try await persistenceService.replaceAllCatalogData(catalog, siteID: siteID)
            DDLogInfo("✅ Persisted \(catalog.products.count) products and \(catalog.variations.count) variations to database for siteID \(siteID)")

            return catalog
        } catch {
            DDLogError("❌ Failed to sync and persist catalog: \(error)")
            throw error
        }
    }

    public func startPaginatedFullSync(for siteID: Int64, allowCellular: Bool) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting paginated full catalog sync for site ID: \(siteID) with allowCellular: \(allowCellular)")

        let catalog = try await loadCatalog(for: siteID, syncRemote: syncRemote, allowCellular: allowCellular)
        DDLogInfo("✅ Loaded \(catalog.products.count) products and \(catalog.variations.count) variations for siteID \(siteID)")

        try await persistenceService.replaceAllCatalogData(catalog, siteID: siteID)
        DDLogInfo("✅ Persisted \(catalog.products.count) products and \(catalog.variations.count) variations to database for siteID \(siteID)")

        return catalog
    }

    public func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64, snapshotDate: Date) async throws -> POSCatalog {
        DDLogInfo("🟣 Parsing background catalog download for site \(siteID)")

        let catalogResponse = try await syncRemote.parseDownloadedCatalog(from: fileURL, siteID: siteID)

        let catalog = POSCatalog(
            products: catalogResponse.products,
            variations: catalogResponse.variations,
            syncDate: snapshotDate
        )

        DDLogInfo("✅ Loaded \(catalog.products.count) products and \(catalog.variations.count) variations for siteID \(siteID)")

        // Persist to database
        try await persistenceService.replaceAllCatalogData(catalog, siteID: siteID)
        DDLogInfo("✅ Persisted \(catalog.products.count) products and \(catalog.variations.count) variations to database for siteID \(siteID)")

        return catalog
    }
}

// MARK: - Remote Loading

private extension POSCatalogFullSyncService {
    func loadCatalog(for siteID: Int64,
                     syncRemote: POSCatalogSyncRemoteProtocol,
                     allowCellular: Bool) async throws -> POSCatalog {
        let syncStartDate = Date.now
        // Loads products and variations in batches in parallel.
        async let productsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  allowCellular: allowCellular)
            }
        )
        async let variationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(siteID: siteID,
                                                           pageNumber: pageNumber,
                                                           allowCellular: allowCellular)
            }
        )

        let (products, variations) = try await (productsTask, variationsTask)

        // Prefer the server's clock as the sync watermark (the earliest across responses), falling
        // back to the device clock only when no `Date` header was provided. See PagedItems.serverDate.
        let serverDates = [products.serverDate, variations.serverDate].compactMap { $0 }
        let syncDate = serverDates.min() ?? syncStartDate

        return POSCatalog(products: products.items,
                          variations: variations.items,
                          syncDate: syncDate)
    }

    func loadCatalogFromCatalogAPI(for siteID: Int64,
                                   syncRemote: POSCatalogSyncRemoteProtocol,
                                   regenerateCatalog: Bool,
                                   allowCellular: Bool,
                                   maxAttempts: Int,
                                   onProgress: POSCatalogSyncProgressHandler?) async throws -> POSCatalog {
        let downloadStartTime = CFAbsoluteTimeGetCurrent()
        let (catalog, pollingResult, snapshotDate) = try await downloadCatalog(for: siteID,
                                                                               syncRemote: syncRemote,
                                                                               regenerateCatalog: regenerateCatalog,
                                                                               allowCellular: allowCellular,
                                                                               maxAttempts: maxAttempts,
                                                                               onProgress: onProgress)
        let downloadTime = CFAbsoluteTimeGetCurrent() - downloadStartTime
        DDLogInfo("🟣 Catalog download completed - Time: \(String(format: "%.2f", downloadTime))s")

        let generationDurationMs = Self.computeGenerationDuration(scheduledAt: pollingResult.scheduledAt,
                                                                   completedAt: pollingResult.completedAt)
        let metadata = POSCatalogSyncMetadata(pollAttempts: pollingResult.pollAttempts,
                                              generationDurationMs: generationDurationMs)

        // Use the server's `scheduled_at` as the sync watermark, not the device clock. The catalog
        // file is a snapshot taken somewhere in [scheduled_at, completed_at]; `scheduled_at` is the
        // only safe lower bound for the next incremental's `modified_after` cursor — anything modified
        // during generation is then re-fetched rather than skipped. Falls back to the device clock if
        // the server omitted/garbled the timestamp.
        return .init(products: catalog.products, variations: catalog.variations, syncDate: snapshotDate, syncMetadata: metadata)
    }

    /// Computes server-side generation duration in milliseconds from ISO8601 timestamp strings.
    private static func computeGenerationDuration(scheduledAt: String?, completedAt: String?) -> Int? {
        guard let scheduledAt, let completedAt,
              let scheduled = parseISO8601(scheduledAt),
              let completed = parseISO8601(completedAt) else {
            return nil
        }
        return Int(completed.timeIntervalSince(scheduled) * 1000)
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        // Server format has no timezone suffix (e.g. "2026-01-23T08:30:55"). Treat as UTC.
        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.timeZone = TimeZone(secondsFromGMT: 0)
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return fallback.date(from: string)
    }
}

private extension POSCatalogFullSyncService {
    /// Result from polling for catalog generation completion.
    struct CatalogPollingResult {
        let downloadURL: String
        let pollAttempts: Int
        let scheduledAt: String?
        let completedAt: String?
    }

    func downloadCatalog(for siteID: Int64,
                         syncRemote: POSCatalogSyncRemoteProtocol,
                         regenerateCatalog: Bool,
                         allowCellular: Bool,
                         maxAttempts: Int,
                         onProgress: POSCatalogSyncProgressHandler?) async throws -> (POSCatalogResponse, CatalogPollingResult, Date) {
        DDLogInfo("🟣 Starting catalog request...")

        // 1. Requests catalog until download URL is available.
        let response = try await syncRemote.requestCatalogGeneration(for: siteID, forceGeneration: regenerateCatalog, allowCellular: allowCellular)
        let pollingResult: CatalogPollingResult
        if let url = response.downloadURL {
            pollingResult = CatalogPollingResult(downloadURL: url,
                                                pollAttempts: 0,
                                                scheduledAt: response.scheduledAt,
                                                completedAt: response.completedAt)
        } else {
            await reportProgress(for: response, onProgress: onProgress)
            // 2. Polls for completion until download URL is available.
            pollingResult = try await pollForCatalogCompletion(siteID: siteID,
                                                               syncRemote: syncRemote,
                                                               allowCellular: allowCellular,
                                                               maxAttempts: maxAttempts,
                                                               onProgress: onProgress)
        }

        // 3. Downloads catalog using the provided URL.
        DDLogInfo("🟣 Catalog ready for download: \(pollingResult.downloadURL)")
        let snapshotDate = pollingResult.scheduledAt.flatMap(Self.parseISO8601) ?? Date()
        let catalog = try await syncRemote.downloadCatalog(for: siteID,
                                                           downloadURL: pollingResult.downloadURL,
                                                           allowCellular: allowCellular,
                                                           snapshotDate: snapshotDate)
        return (catalog, pollingResult, snapshotDate)
    }

    /// Polls for catalog generation completion using exponential backoff.
    ///
    /// - Parameters:
    ///   - siteID: The site ID to poll catalog generation for
    ///   - syncRemote: The remote service to use for polling
    ///   - allowCellular: Whether cellular data should be used
    ///   - maxAttempts: Maximum number of polling attempts.
    ///     - Background passes a limit to stay within within iOS ~30s execution window
    ///     - Foreground passes `.max` to poll indefinitely
    /// - Returns: The download URL when catalog generation completes
    /// - Throws: `POSCatalogSyncError.timeout` if max attempts exceeded, `.generationFailed` if job fails
    ///
    /// Uses exponential backoff starting at 3s, multiplied by 1.3x each attempt, capped at ~20s.
    /// Foreground polling continues as long as the server reports progress.
    func pollForCatalogCompletion(siteID: Int64,
                                  syncRemote: POSCatalogSyncRemoteProtocol,
                                  allowCellular: Bool,
                                  maxAttempts: Int,
                                  onProgress: POSCatalogSyncProgressHandler?) async throws -> CatalogPollingResult {
        var attempts = 0
        var currentDelay = PollingConfig.initialDelay
        var lastStatus: POSCatalogStatus = .scheduled

        while attempts < maxAttempts {
            let response = try await syncRemote.requestCatalogGeneration(for: siteID,
                                                                         forceGeneration: false,
                                                                         allowCellular: allowCellular)
            lastStatus = response.status

            switch response.status {
            case .completed:
                guard let downloadURL = response.downloadURL else {
                    throw POSCatalogSyncError.invalidData
                }
                DDLogInfo("🟣 Catalog generation completed after \(attempts + 1) poll(s)")
                return CatalogPollingResult(downloadURL: downloadURL,
                                            pollAttempts: attempts + 1,
                                            scheduledAt: response.scheduledAt,
                                            completedAt: response.completedAt)
            case .scheduled, .inProgress:
                DDLogInfo("🟣 Catalog request \(response.status)... (attempt \(attempts + 1), " +
                          "progress: \(response.progress ?? -1), processed: \(response.processed ?? -1)/\(response.total ?? -1))")
                await reportProgress(for: response, onProgress: onProgress)

                try await Task.sleep(nanoseconds: UInt64(currentDelay) * NSEC_PER_SEC)
                attempts += 1

                // Calculate next delay with exponential backoff, capped at max interval
                currentDelay = min(currentDelay * PollingConfig.multiplier, PollingConfig.maxInterval)
            case .failed:
                throw POSCatalogSyncError.generationFailed(pollAttempts: attempts + 1)
            }
        }

        DDLogWarn("🟣 Catalog polling timed out after \(attempts) attempts")
        throw POSCatalogSyncError.timeout(pollAttempts: attempts, lastGenerationState: lastStatus.rawValue)
    }

    func reportProgress(for response: POSCatalogRequestResponse, onProgress: POSCatalogSyncProgressHandler?) async {
        guard let progress = POSCatalogSyncProgress(response: response) else {
            return
        }
        await onProgress?(progress)
    }
}
