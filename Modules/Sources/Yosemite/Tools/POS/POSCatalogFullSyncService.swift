import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

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
    private let batchSize: Int
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

    init(syncRemote: POSCatalogSyncRemoteProtocol, batchSize: Int, persistenceService: POSCatalogPersistenceServiceProtocol) {
        self.syncRemote = syncRemote
        self.batchSize = batchSize
        self.persistenceService = persistenceService
        self.batchedLoader = BatchedRequestLoader(batchSize: batchSize)
    }

    // MARK: - Protocol Conformance

    public func startFullSync(for siteID: Int64) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting full catalog sync for site ID: \(siteID)")

        do {
            // Sync from network
            let catalog = try await loadCatalog(for: siteID, syncRemote: syncRemote)
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

}
