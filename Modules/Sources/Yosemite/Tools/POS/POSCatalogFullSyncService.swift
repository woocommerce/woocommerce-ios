import Foundation
import protocol Networking.POSCatalogSyncRemoteProtocol
import class Networking.AlamofireNetwork
import class Networking.POSCatalogSyncRemote
import CocoaLumberjackSwift

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
}

// TODO - remove the periphery ignore comment when the service is integrated with POS.
// periphery:ignore
public final class POSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    private let syncRemote: POSCatalogSyncRemoteProtocol
    private let batchSize: Int

    public convenience init?(credentials: Credentials?, batchSize: Int = 2) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSCatalogFullSyncService due missing credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials, ensuresSessionManagerIsInitialized: true)
        let syncRemote = POSCatalogSyncRemote(network: network)
        self.init(syncRemote: syncRemote, batchSize: batchSize)
    }

    init(syncRemote: POSCatalogSyncRemoteProtocol, batchSize: Int) {
        self.syncRemote = syncRemote
        self.batchSize = batchSize
    }

    // MARK: - Protocol Conformance

    public func startFullSync(for siteID: Int64) async throws -> POSCatalog {
        DDLogInfo("🔄 Starting full catalog sync for site ID: \(siteID)")

        do {
            // Loads products and variations in batches in parallel.
            async let productsTask = loadAllProducts(for: siteID, syncRemote: syncRemote)
            async let variationsTask = loadAllProductVariations(for: siteID, syncRemote: syncRemote)

            let (products, variations) = try await (productsTask, variationsTask)
            let catalog = POSCatalog(products: products, variations: variations)
            DDLogInfo("✅ Loaded \(catalog.products.count) products and \(catalog.variations.count) variations for siteID \(siteID)")
            return .init(products: products, variations: variations)
        } catch {
            throw error
        }
    }

    // MARK: - Private Methods

    private func loadAllProducts(for siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> [POSProduct] {
        DDLogInfo("🔄 Starting products sync for site ID: \(siteID)")

        var allProducts: [POSProduct] = []
        var currentPage = 1
        var hasMorePages = true

        while hasMorePages {
            let pagesToFetch = Array(currentPage..<(currentPage + batchSize))

            let batchResults = try await withThrowingTaskGroup(of: PageResult<POSProduct>.self) { group in
                for pageNumber in pagesToFetch {
                    group.addTask {
                        let result = try await syncRemote.loadProducts(siteID: siteID, pageNumber: pageNumber)
                        return PageResult(pageNumber: pageNumber, items: result)
                    }
                }

                var results: [PageResult<POSProduct>] = []
                for try await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.pageNumber < $1.pageNumber })
            }

            // Processes results in order and checks if there are more pages.
            let newProducts = batchResults.flatMap { $0.items.items }
            allProducts.append(contentsOf: newProducts)

            let highestPageResult = batchResults.last?.items
            hasMorePages = (highestPageResult?.hasMorePages ?? false) && !newProducts.isEmpty
            currentPage += batchSize

            DDLogInfo("📥 Loaded batch: \(batchResults.count) pages, total products: \(allProducts.count), hasMorePages: \(hasMorePages)")
        }

        DDLogInfo("✅ Products sync complete: \(allProducts.count) products loaded")
        return allProducts
    }

    private func loadAllProductVariations(for siteID: Int64, syncRemote: POSCatalogSyncRemoteProtocol) async throws -> [POSProductVariation] {
        DDLogInfo("🔄 Starting variations sync for site ID: \(siteID)")

        var allVariations: [POSProductVariation] = []
        var currentPage = 1
        var hasMorePages = true

        while hasMorePages {
            let pagesToFetch = Array(currentPage..<(currentPage + batchSize))

            let batchResults = try await withThrowingTaskGroup(of: PageResult<POSProductVariation>.self) { group in
                for pageNumber in pagesToFetch {
                    group.addTask {
                        let result = try await syncRemote.loadProductVariations(siteID: siteID, pageNumber: pageNumber)
                        return PageResult(pageNumber: pageNumber, items: result)
                    }
                }

                var results: [PageResult<POSProductVariation>] = []
                for try await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.pageNumber < $1.pageNumber })
            }

            // Processes results in order and checks if there are more pages.
            let newVariations = batchResults.flatMap { $0.items.items }
            allVariations.append(contentsOf: newVariations)

            let highestPageResult = batchResults.last?.items
            hasMorePages = (highestPageResult?.hasMorePages ?? false) && !newVariations.isEmpty
            currentPage += batchSize

            DDLogInfo("📥 Loaded batch: \(batchResults.count) pages, total variations: \(allVariations.count), hasMorePages: \(hasMorePages)")
        }

        DDLogInfo("✅ Variations sync complete: \(allVariations.count) variations loaded")
        return allVariations
    }
}

private struct PageResult<T> {
    let pageNumber: Int
    let items: PagedItems<T>
}
