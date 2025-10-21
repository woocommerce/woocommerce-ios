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
    /// - Parameter siteID: The site ID to sync catalog for
    /// - Returns: The synced catalog containing products and variations
    func startFullSync(for siteID: Int64) async throws -> POSCatalog
}

/// POS catalog from full sync.
// TODO - remove the periphery ignore comment when the catalog is integrated with POS.
// periphery:ignore
public struct POSCatalog {
    public let products: [POSProduct]
    public let variations: [POSProductVariation]
    public let syncDate: Date
}

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public final class POSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    private let syncRemote: POSCatalogSyncRemoteProtocol
    private let persistenceService: POSCatalogPersistenceServiceProtocol
    private let batchedLoader: BatchedRequestLoader

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             batchSize: Int = 2,
                             grdbManager: GRDBManagerProtocol) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSCatalogFullSyncService due missing credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let syncRemote = POSCatalogSyncRemote(network: network)
        let persistenceService = POSCatalogPersistenceService(grdbManager: grdbManager)
        self.init(syncRemote: syncRemote, batchSize: batchSize, persistenceService: persistenceService)
    }

    init(
        syncRemote: POSCatalogSyncRemoteProtocol,
        batchSize: Int,
        retryDelay: TimeInterval = 2.0,
        persistenceService: POSCatalogPersistenceServiceProtocol
    ) {
        self.syncRemote = syncRemote
        self.persistenceService = persistenceService
        self.batchedLoader = BatchedRequestLoader(batchSize: batchSize, retryDelay: retryDelay)
    }

    // MARK: - Protocol Conformance

    public func startFullSync(for siteID: Int64) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting full catalog sync for site ID: \(siteID)")

        let usesCatalogEndpoint = true

        do {
            // Sync from network
            let catalog: POSCatalog
            if usesCatalogEndpoint {
                catalog = try await loadCatalogFromCatalogEndpoint(for: siteID, syncRemote: syncRemote)
            } else {
                catalog = try await loadCatalog(for: siteID, syncRemote: syncRemote)
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
}

// MARK: - Remote Loading

private extension POSCatalogFullSyncService {
    func loadCatalog(for siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> POSCatalog {
        let syncStartDate = Date.now
        // Loads products and variations in batches in parallel.
        async let productsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(siteID: siteID, pageNumber: pageNumber)
            }
        )
        async let variationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(siteID: siteID, pageNumber: pageNumber)
            }
        )

        let (products, variations) = try await (productsTask, variationsTask)
        return POSCatalog(products: products, variations: variations, syncDate: syncStartDate)
    }

    func loadCatalogFromCatalogEndpoint(for siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> POSCatalog {
        let downloadStartTime = CFAbsoluteTimeGetCurrent()
        let catalog = try await downloadCatalog(for: siteID, syncRemote: syncRemote)
        let downloadTime = CFAbsoluteTimeGetCurrent() - downloadStartTime
        print("🟣 Download completed - Time: \(String(format: "%.2f", downloadTime))s")

        return .init(products: catalog.products, variations: catalog.variations, syncDate: .init())
    }
}

private extension POSCatalogFullSyncService {
    func downloadCatalog(for siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> POSCatalogResponse {
        print("🟣 Starting catalog generation...")

        // 1. Generate catalog and get job ID
        let jobResponse = try await syncRemote.generateCatalog(for: siteID)
        let downloadURL: String?
        if let url = jobResponse.downloadURL {
            downloadURL = url
            print("🟣 Catalog ready for download: \(url)")
        } else if let jobID = jobResponse.jobID {
            // 2. Poll for completion
            downloadURL = try await pollForCatalogCompletion(jobID: jobID, siteID: siteID, syncRemote: syncRemote)
            print("🟣 Catalog generation started")
        } else {
            downloadURL = nil
        }

        // 3. Download using the provided URL
        guard let downloadURL else {
            throw POSCatalogSyncError.invalidData
        }
        return try await syncRemote.downloadCatalog(for: siteID, downloadURL: downloadURL)
    }

    func pollForCatalogCompletion(jobID: String, siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> String {
        let maxAttempts = 1000 // each attempt is made 1 second after the last one completes
        var attempts = 0

        while attempts < maxAttempts {
            let statusResponse = try await syncRemote.checkCatalogStatus(for: siteID, jobID: jobID)

            switch statusResponse.status {
            case .complete:
                guard let downloadURL = statusResponse.downloadURL else {
                    throw POSCatalogSyncError.invalidData
                }
                return downloadURL
            case .pending, .processing:
                print("🟣 Catalog generation \(statusResponse.status)... (attempt \(attempts + 1)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                attempts += 1
            case .failed:
                throw POSCatalogSyncError.generationFailed
            }
        }

        throw POSCatalogSyncError.timeout
    }
}
