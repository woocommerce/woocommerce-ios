import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import struct Networking.POSCatalogResponse

// TODO - remove the periphery ignore comment when the catalog is integrated with POS.
// periphery:ignore
public protocol POSCatalogFullSyncServiceProtocol {
    /// Starts a full catalog sync process
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for
    ///   - regenerateCatalog: Whether to force the catalog generation
    ///   - allowCellular: Should cellular data be used if required.
    /// - Returns: The synced catalog containing products and variations
    func startFullSync(for siteID: Int64, regenerateCatalog: Bool, allowCellular: Bool) async throws -> POSCatalog

    /// Parses and persists a downloaded catalog file from a background download.
    /// - Parameters:
    ///   - fileURL: Local file URL of the downloaded catalog
    ///   - siteID: Site ID for this catalog
    /// - Returns: The parsed catalog
    func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64) async throws -> POSCatalog
}

/// POS catalog from full sync.
// TODO - remove the periphery ignore comment when the catalog is integrated with POS.
// periphery:ignore
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

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public final class POSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
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
                              allowCellular: Bool) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting full catalog sync for site ID: \(siteID) with regenerateCatalog: \(regenerateCatalog), " +
                  "allowCellular: \(allowCellular)")

        do {
            // Sync from network
            let catalog: POSCatalog
            if usesCatalogAPI {
                catalog = try await loadCatalogFromCatalogAPI(for: siteID,
                                                              syncRemote: syncRemote,
                                                              regenerateCatalog: regenerateCatalog,
                                                              allowCellular: allowCellular)
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
        return POSCatalog(products: products, variations: variations, syncDate: syncStartDate)
    }

    func loadCatalogFromCatalogAPI(for siteID: Int64,
                                   syncRemote: POSCatalogSyncRemoteProtocol,
                                   regenerateCatalog: Bool,
                                   allowCellular: Bool) async throws -> POSCatalog {
        let downloadStartTime = CFAbsoluteTimeGetCurrent()
        let catalog = try await downloadCatalog(for: siteID,
                                                syncRemote: syncRemote,
                                                regenerateCatalog: regenerateCatalog,
                                                allowCellular: allowCellular)
        let downloadTime = CFAbsoluteTimeGetCurrent() - downloadStartTime
        DDLogInfo("🟣 Catalog download completed - Time: \(String(format: "%.2f", downloadTime))s")

        return .init(products: catalog.products, variations: catalog.variations, syncDate: .init())
    }
}

private extension POSCatalogFullSyncService {
    func downloadCatalog(for siteID: Int64,
                         syncRemote: POSCatalogSyncRemoteProtocol,
                         regenerateCatalog: Bool,
                         allowCellular: Bool) async throws -> POSCatalogResponse {
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
                                                             allowCellular: allowCellular)
        }

        // 3. Downloads catalog using the provided URL.
        guard let downloadURL else {
            throw POSCatalogSyncError.invalidData
        }
        DDLogInfo("🟣 Catalog ready for download: \(downloadURL)")
        return try await syncRemote.downloadCatalog(for: siteID, downloadURL: downloadURL, allowCellular: allowCellular)
    }

    // TODO: WOOMOB-1677 - This blocking polling approach is incompatible with background execution.
    // Background App Refresh tasks have ~30 seconds of execution time, but catalog generation
    // typically takes 5-10 minutes. This needs to be refactored to use stateful polling that
    // resumes across multiple background refresh sessions and foreground app opens.
    func pollForCatalogCompletion(siteID: Int64,
                                  syncRemote: POSCatalogSyncRemoteProtocol,
                                  allowCellular: Bool) async throws -> String {
        // Each attempt is made 1 second after the last one completes.
        let maxAttempts = 1000
        var attempts = 0

        while attempts < maxAttempts {
            let response = try await syncRemote.requestCatalogGeneration(for: siteID,
                                                                         forceGeneration: false,
                                                                         allowCellular: allowCellular)

            switch response.status {
            case .completed:
                guard let downloadURL = response.downloadURL else {
                    throw POSCatalogSyncError.invalidData
                }
                return downloadURL
            case .scheduled, .inProgress:
                // Only logs every 10th attempt to avoid flooding logs for large catalogs.
                if attempts % 10 == 0 {
                    DDLogInfo("🟣 Catalog request \(response.status)... (attempt \(attempts + 1)/\(maxAttempts))")
                }
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                attempts += 1
            case .failed:
                throw POSCatalogSyncError.generationFailed
            }
        }

        throw POSCatalogSyncError.timeout
    }
}
