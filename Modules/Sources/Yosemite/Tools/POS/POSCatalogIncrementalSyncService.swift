import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import protocol Storage.GRDBManagerProtocol
import struct NetworkingCore.JetpackSite
import struct Combine.AnyPublisher

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public protocol POSCatalogIncrementalSyncServiceProtocol {
    /// Starts an incremental catalog sync process.
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for.
    ///   - lastFullSyncDate: The date of the last full sync to use if no incremental sync date exists.
    func startIncrementalSync(for siteID: Int64, lastFullSyncDate: Date, lastIncrementalSyncDate: Date?) async throws
}

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public final class POSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol {
    private let syncRemote: POSCatalogSyncRemoteProtocol
    private let batchSize: Int
    private let persistenceService: POSCatalogPersistenceServiceProtocol
    private let batchedLoader: BatchedRequestLoader

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             batchSize: Int = 1,
                             grdbManager: GRDBManagerProtocol) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSCatalogIncrementalSyncService due missing credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       ensuresSessionManagerIsInitialized: true)
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

    public func startIncrementalSync(for siteID: Int64, lastFullSyncDate: Date, lastIncrementalSyncDate: Date?) async throws {
        let modifiedAfter = latestSyncDate(fullSyncDate: lastFullSyncDate, incrementalSyncDate: lastIncrementalSyncDate)

        DDLogInfo("🔄 Starting incremental catalog sync for site ID: \(siteID), modifiedAfter: \(modifiedAfter)")

        do {
            let catalog = try await loadCatalog(for: siteID, modifiedAfter: modifiedAfter, syncRemote: syncRemote)
            DDLogInfo("✅ Loaded \(catalog.products.count) products and \(catalog.variations.count) variations for siteID \(siteID)")

            try await persistenceService.persistIncrementalCatalogData(catalog, siteID: siteID)
            DDLogInfo("✅ Persisted \(catalog.products.count) products and \(catalog.variations.count) variations to database for siteID \(siteID)")

        } catch {
            DDLogError("❌ Failed to sync and persist catalog incrementally: \(error)")
            throw error
        }
    }
}

// MARK: - Remote Loading

private extension POSCatalogIncrementalSyncService {
    func loadCatalog(for siteID: Int64, modifiedAfter: Date, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> POSCatalog {
        let syncStartDate = Date.now
        async let productsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter, siteID: siteID, pageNumber: pageNumber)
            }
        )
        async let variationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(modifiedAfter: modifiedAfter, siteID: siteID, pageNumber: pageNumber)
            }
        )

        let (products, variations) = try await (productsTask, variationsTask)
        return POSCatalog(products: products, variations: variations, syncDate: syncStartDate)
    }
}

// MARK: - Sync date

private extension POSCatalogIncrementalSyncService {
    func latestSyncDate(fullSyncDate: Date, incrementalSyncDate: Date?) -> Date {
        max(fullSyncDate, incrementalSyncDate ?? .distantPast)
    }
}
