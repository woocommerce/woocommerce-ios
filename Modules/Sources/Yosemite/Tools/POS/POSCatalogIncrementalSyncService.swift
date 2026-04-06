import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import protocol Storage.GRDBManagerProtocol
import struct NetworkingCore.JetpackSite
import struct Combine.AnyPublisher
import struct Networking.POSTypedVariation

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public protocol POSCatalogIncrementalSyncServiceProtocol {
    /// Starts an incremental catalog sync process.
    /// - Parameters:
    ///   - siteID: The site ID to sync catalog for.
    ///   - lastFullSyncDate: The date of the last full sync to use if no incremental sync date exists.
    ///   - lastIncrementalSyncDate: The date of the last incremental sync.
    /// - Returns: The synced catalog containing updated products and variations
    @discardableResult
    func startIncrementalSync(for siteID: Int64,
                              lastFullSyncDate: Date,
                              lastIncrementalSyncDate: Date?) async throws -> POSCatalog
}

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public final class POSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol {
    private let syncRemote: POSCatalogSyncRemoteProtocol
    private let persistenceService: POSCatalogPersistenceServiceProtocol
    private let batchedLoader: BatchedRequestLoader

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             batchSize: Int = 1,
                             grdbManager: GRDBManagerProtocol) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSCatalogIncrementalSyncService due missing credentials")
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
    @discardableResult
    public func startIncrementalSync(for siteID: Int64,
                                     lastFullSyncDate: Date,
                                     lastIncrementalSyncDate: Date?) async throws -> POSCatalog {
        let modifiedAfter = latestSyncDate(fullSyncDate: lastFullSyncDate, incrementalSyncDate: lastIncrementalSyncDate)

        DDLogInfo("🔄 Starting incremental catalog sync for site ID: \(siteID), modifiedAfter: \(modifiedAfter)")

        do {
            let catalog = try await loadCatalog(for: siteID, modifiedAfter: modifiedAfter, syncRemote: syncRemote)
            DDLogInfo("✅ Loaded \(catalog.products.count) updated products and \(catalog.variations.count) updated variations for siteID \(siteID)")

            try await persistenceService.persistIncrementalCatalogData(catalog, siteID: siteID)
            DDLogInfo("✅ Persisted \(catalog.products.count) updated products and \(catalog.variations.count) updated variations to database for siteID \(siteID)")

            return catalog
        } catch {
            DDLogError("❌ Failed to sync and persist catalog incrementally: \(error)")
            throw error
        }
    }
}

// MARK: - Remote Loading

private extension POSCatalogIncrementalSyncService {
    func loadCatalog(for siteID: Int64,
                     modifiedAfter: Date,
                     syncRemote: POSCatalogSyncRemoteProtocol) async throws -> POSCatalog {
        let syncStartDate = Date.now

        // Fetch POS-filtered products (excluding trash) — the remote always sends pos_products_only=true
        async let posProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: nil)
            }
        )

        // Fetch trashed products to detect products moved to trash
        async let trashedProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: ProductStatus.trash.rawValue)
            }
        )

        // Fetch POS-filtered variations
        async let posVariationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(modifiedAfter: modifiedAfter,
                                                           siteID: siteID,
                                                           pageNumber: pageNumber)
            }
        )

        let (posProducts, trashedProducts, posVariations) = try await (
            posProductsTask, trashedProductsTask, posVariationsTask
        )

        // Aggregate regular and trashed products before persisting
        let productsToSync = posProducts + trashedProducts

        return POSCatalog(products: productsToSync,
                          variations: posVariations.map { POSTypedVariation(variation: $0, typeKey: "variation") },
                          syncDate: syncStartDate)
    }
}

// MARK: - Sync date

private extension POSCatalogIncrementalSyncService {
    func latestSyncDate(fullSyncDate: Date, incrementalSyncDate: Date?) -> Date {
        max(fullSyncDate, incrementalSyncDate ?? .distantPast)
    }
}
