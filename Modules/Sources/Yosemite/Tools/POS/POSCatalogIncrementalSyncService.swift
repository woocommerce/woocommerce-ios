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
    ///   - lastIncrementalSyncDate: The date of the last incremental sync.
    ///   - posProductsOnly: Whether to filter to POS-eligible products only.
    /// - Returns: The synced catalog containing updated products and variations
    @discardableResult
    func startIncrementalSync(for siteID: Int64,
                              lastFullSyncDate: Date,
                              lastIncrementalSyncDate: Date?,
                              posProductsOnly: Bool) async throws -> POSCatalog
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
                                     lastIncrementalSyncDate: Date?,
                                     posProductsOnly: Bool = false) async throws -> POSCatalog {
        let modifiedAfter = latestSyncDate(fullSyncDate: lastFullSyncDate, incrementalSyncDate: lastIncrementalSyncDate)

        DDLogInfo("🔄 Starting incremental catalog sync for site ID: \(siteID), modifiedAfter: \(modifiedAfter), posProductsOnly: \(posProductsOnly)")

        do {
            let catalog = try await loadCatalog(for: siteID, modifiedAfter: modifiedAfter, syncRemote: syncRemote, posProductsOnly: posProductsOnly)
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
                     syncRemote: POSCatalogSyncRemoteProtocol,
                     posProductsOnly: Bool) async throws -> POSCatalog {
        let syncStartDate = Date.now

        if posProductsOnly {
            // Dual-request: Detect products/variations hidden from POS
            return try await loadCatalogWithHiddenDetection(for: siteID,
                                                            modifiedAfter: modifiedAfter,
                                                            syncRemote: syncRemote,
                                                            syncStartDate: syncStartDate)
        } else {
            // Single-request: No hidden detection needed
            return try await loadCatalogWithoutFiltering(for: siteID,
                                                         modifiedAfter: modifiedAfter,
                                                         syncRemote: syncRemote,
                                                         syncStartDate: syncStartDate,
                                                         posProductsOnly: posProductsOnly)
        }
    }

    /// Loads catalog with dual requests to detect products hidden from POS.
    /// Products hidden from POS don't appear in the `posProductsOnly=true` response, they're simply omitted.
    /// To detect these, we compare against a second request without the flag: products present there but
    /// missing from the `posProductsOnly=true` response have been hidden and should be removed from the local DB.
    func loadCatalogWithHiddenDetection(for siteID: Int64,
                                        modifiedAfter: Date,
                                        syncRemote: POSCatalogSyncRemoteProtocol,
                                        syncStartDate: Date) async throws -> POSCatalog {
        // Fetch POS-filtered products (excluding trash)
        async let posProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: nil,
                                                  posProductsOnly: true)
            }
        )

        // Fetch ALL products (excluding trash) to compare and find hidden ones
        async let allProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: nil,
                                                  posProductsOnly: false)
            }
        )

        // Fetch trashed products (POS-filtered) to detect products moved to trash
        async let trashedProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: ProductStatus.trash.rawValue,
                                                  posProductsOnly: true)
            }
        )

        // Fetch POS-filtered variations
        async let posVariationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(modifiedAfter: modifiedAfter,
                                                           siteID: siteID,
                                                           pageNumber: pageNumber,
                                                           posProductsOnly: true)
            }
        )

        let (posProducts, allProducts, trashedProducts, posVariations) = try await (
            posProductsTask, allProductsTask, trashedProductsTask, posVariationsTask
        )

        // Find products hidden from POS: present in "all" but missing from "POS"
        let hiddenProductIDs = findHiddenProductIDs(posProducts: posProducts, allProducts: allProducts)

        // Aggregate regular and trashed products before persist them
        let productsToSync = posProducts + trashedProducts

        return POSCatalog(products: productsToSync,
                          variations: posVariations,
                          syncDate: syncStartDate,
                          productsToRemove: hiddenProductIDs)
    }

    /// Loads catalog without hidden detection - single request mode.
    func loadCatalogWithoutFiltering(for siteID: Int64,
                                     modifiedAfter: Date,
                                     syncRemote: POSCatalogSyncRemoteProtocol,
                                     syncStartDate: Date,
                                     posProductsOnly: Bool) async throws -> POSCatalog {
        // Fetch regular products (excluding trash)
        async let regularProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: nil,
                                                  posProductsOnly: posProductsOnly)
            }
        )

        // Fetch trashed products separately to detect products moved to trash
        async let trashedProductsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProducts(modifiedAfter: modifiedAfter,
                                                  siteID: siteID,
                                                  pageNumber: pageNumber,
                                                  includeStatus: ProductStatus.trash.rawValue,
                                                  posProductsOnly: posProductsOnly)
            }
        )

        async let variationsTask = batchedLoader.loadAll(
            makeRequest: { pageNumber in
                try await syncRemote.loadProductVariations(modifiedAfter: modifiedAfter,
                                                           siteID: siteID,
                                                           pageNumber: pageNumber,
                                                           posProductsOnly: posProductsOnly)
            }
        )

        let (regularProducts, trashedProducts, variations) = try await (regularProductsTask, trashedProductsTask, variationsTask)

        // Union regular and trashed products before persistence
        let allProducts = regularProducts + trashedProducts

        return POSCatalog(products: allProducts, variations: variations, syncDate: syncStartDate)
    }
}

private extension POSCatalogIncrementalSyncService {
    /// Finds product IDs that are present in the unfiltered response but missing from the POS-filtered response.
    /// These products have been hidden from POS and should be removed from the local catalog.
    func findHiddenProductIDs(posProducts: [POSProduct], allProducts: [POSProduct]) -> [Int64] {
        let posProductIDs = Set(posProducts.map { $0.productID })
        return allProducts
            .filter { !posProductIDs.contains($0.productID) }
            .map { $0.productID }
    }
}

// MARK: - Sync date

private extension POSCatalogIncrementalSyncService {
    func latestSyncDate(fullSyncDate: Date, incrementalSyncDate: Date?) -> Date {
        max(fullSyncDate, incrementalSyncDate ?? .distantPast)
    }
}
