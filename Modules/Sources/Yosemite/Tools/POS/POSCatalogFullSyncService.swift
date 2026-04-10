import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import struct Networking.POSCatalogResponse

public protocol POSCatalogFullSyncServiceProtocol {
    /// Starts a full catalog sync process
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - regenerateCatalog: Whether to force the catalog generation
    ///   - allowCellular: Should cellular data be used if required.
    ///   - isBackgroundSync: Whether this sync is running in a background task context. Limits polling attempts to stay within ~30s window.
    /// - Returns: The synced catalog containing products and variations
    func startFullSync(for siteID: Int64, regenerateCatalog: Bool, allowCellular: Bool, isBackgroundSync: Bool) async throws -> POSCatalog

    /// Parses and persists a downloaded catalog file from a background download.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog
    ///   - siteID: Site ID for this catalog
    /// - Returns: The parsed catalog
    func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64) async throws -> POSCatalog
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

    public init(products: [POSProduct],
                variations: [POSProductVariation],
                syncDate: Date,
                productsToRemove: [Int64] = []) {
        self.products = products
        self.variations = variations
        self.syncDate = syncDate
        self.productsToRemove = productsToRemove
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
                              isBackgroundSync: Bool) async throws -> POSCatalog {
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
                                                              maxAttempts: maxAttempts)
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

    public func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64) async throws -> POSCatalog {
        DDLogInfo("🟣 Parsing background catalog download for site \(siteID)")

        let syncStartDate = Date.now
        let catalogResponse = try await syncRemote.parseDownloadedCatalog(from: fileURL, siteID: siteID)

        let catalog = POSCatalog(
            products: catalogResponse.products,
            variations: catalogResponse.variations,
            syncDate: syncStartDate
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
        return POSCatalog(products: products,
                          variations: variations,
                          syncDate: syncStartDate)
    }

    func loadCatalogFromCatalogAPI(for siteID: Int64,
                                   syncRemote: POSCatalogSyncRemoteProtocol,
                                   regenerateCatalog: Bool,
                                   allowCellular: Bool,
                                   maxAttempts: Int) async throws -> POSCatalog {
        let downloadStartTime = CFAbsoluteTimeGetCurrent()
        let catalog = try await downloadCatalog(for: siteID,
                                                syncRemote: syncRemote,
                                                regenerateCatalog: regenerateCatalog,
                                                allowCellular: allowCellular,
                                                maxAttempts: maxAttempts)
        let downloadTime = CFAbsoluteTimeGetCurrent() - downloadStartTime
        DDLogInfo("🟣 Catalog download completed - Time: \(String(format: "%.2f", downloadTime))s")

        return .init(products: catalog.products, variations: catalog.variations, syncDate: .init())
    }
}

private extension POSCatalogFullSyncService {
    func downloadCatalog(for siteID: Int64,
                         syncRemote: POSCatalogSyncRemoteProtocol,
                         regenerateCatalog: Bool,
                         allowCellular: Bool,
                         maxAttempts: Int) async throws -> POSCatalogResponse {
        DDLogInfo("🟣 Starting catalog request...")

        // 1. Requests catalog until download URL is available.
        let response = try await syncRemote.requestCatalogGeneration(for: siteID, forceGeneration: regenerateCatalog, allowCellular: allowCellular)
        let downloadURL: String?
        if let url = response.downloadURL {
            downloadURL = url
        } else {
            // 2. Polls for completion until download URL is available.
            downloadURL = try await pollForCatalogCompletion(siteID: siteID,
                                                             syncRemote: syncRemote,
                                                             allowCellular: allowCellular,
                                                             maxAttempts: maxAttempts)
        }

        // 3. Downloads catalog using the provided URL.
        guard let downloadURL else {
            throw POSCatalogSyncError.invalidData
        }
        DDLogInfo("🟣 Catalog ready for download: \(downloadURL)")
        return try await syncRemote.downloadCatalog(for: siteID, downloadURL: downloadURL, allowCellular: allowCellular)
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
                                  maxAttempts: Int) async throws -> String {
        var attempts = 0
        var currentDelay = PollingConfig.initialDelay

        while attempts < maxAttempts {
            let response = try await syncRemote.requestCatalogGeneration(for: siteID,
                                                                         forceGeneration: false,
                                                                         allowCellular: allowCellular)

            switch response.status {
            case .completed:
                guard let downloadURL = response.downloadURL else {
                    throw POSCatalogSyncError.invalidData
                }
                DDLogInfo("🟣 Catalog generation completed after \(attempts + 1) poll(s)")
                return downloadURL
            case .scheduled, .inProgress:
                DDLogInfo("🟣 Catalog request \(response.status)... (attempt \(attempts + 1), " +
                          "progress: \(response.progress ?? -1), processed: \(response.processed ?? -1)/\(response.total ?? -1))")

                try await Task.sleep(nanoseconds: UInt64(currentDelay) * NSEC_PER_SEC)
                attempts += 1

                // Calculate next delay with exponential backoff, capped at max interval
                currentDelay = min(currentDelay * PollingConfig.multiplier, PollingConfig.maxInterval)
            case .failed:
                throw POSCatalogSyncError.generationFailed
            }
        }

        DDLogWarn("🟣 Catalog polling timed out after \(attempts) attempts")
        throw POSCatalogSyncError.timeout
    }
}
