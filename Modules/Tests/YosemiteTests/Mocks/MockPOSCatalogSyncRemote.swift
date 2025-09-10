import Foundation
@testable import Networking

final class MockPOSCatalogSyncRemote: POSCatalogSyncRemoteProtocol {
    // Dictionary mapping pageNumber to Result for products and variations.
    private(set) var productResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
    private(set) var variationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]
    private(set) var incrementalProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
    private(set) var incrementalVariationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]

    private(set) var loadProductsCallCount = 0
    private(set) var loadProductVariationsCallCount = 0
    private(set) var loadIncrementalProductsCallCount = 0
    private(set) var loadIncrementalProductVariationsCallCount = 0

    private(set) var lastIncrementalProductsModifiedAfter: Date?
    private(set) var lastIncrementalVariationsModifiedAfter: Date?

    // Fallback result when no specific page result is configured
    private let fallbackResult = PagedItems(items: [] as [POSProduct], hasMorePages: false, totalItems: 0)
    private let fallbackVariationResult = PagedItems(items: [] as [POSProductVariation], hasMorePages: false, totalItems: 0)

    // MARK: - Setup Methods for Full Sync

    func setProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        productResults[pageNumber] = result
    }

    func setVariationResult(pageNumber: Int, result: Result<PagedItems<POSProductVariation>, Error>) {
        variationResults[pageNumber] = result
    }

    func setProductResults(_ results: [PagedItems<POSProduct>]) {
        for (index, pagedItems) in results.enumerated() {
            productResults[index + 1] = .success(pagedItems)
        }
    }

    func setVariationResults(_ results: [PagedItems<POSProductVariation>]) {
        for (index, pagedItems) in results.enumerated() {
            variationResults[index + 1] = .success(pagedItems)
        }
    }

    // MARK: - Setup Methods for Incremental Sync

    func setIncrementalProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        incrementalProductResults[pageNumber] = result
    }

    func setIncrementalVariationResult(pageNumber: Int, result: Result<PagedItems<POSProductVariation>, Error>) {
        incrementalVariationResults[pageNumber] = result
    }

    func setIncrementalProductResults(_ results: [PagedItems<POSProduct>]) {
        for (index, pagedItems) in results.enumerated() {
            incrementalProductResults[index + 1] = .success(pagedItems)
        }
    }

    func setIncrementalVariationResults(_ results: [PagedItems<POSProductVariation>]) {
        for (index, pagedItems) in results.enumerated() {
            incrementalVariationResults[index + 1] = .success(pagedItems)
        }
    }

    // MARK: - Protocol Methods - Incremental Sync

    func loadProducts(modifiedAfter: Date, siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProduct> {
        loadIncrementalProductsCallCount += 1
        lastIncrementalProductsModifiedAfter = modifiedAfter

        if let result = incrementalProductResults[pageNumber] {
            switch result {
            case .success(let pagedItems):
                return pagedItems
            case .failure(let error):
                throw error
            }
        }
        return fallbackResult
    }

    func loadProductVariations(modifiedAfter: Date, siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        loadIncrementalProductVariationsCallCount += 1
        lastIncrementalVariationsModifiedAfter = modifiedAfter

        if let result = incrementalVariationResults[pageNumber] {
            switch result {
            case .success(let pagedItems):
                return pagedItems
            case .failure(let error):
                throw error
            }
        }
        return fallbackVariationResult
    }

    // MARK: - Protocol Methods - Full Sync

    func loadProducts(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProduct> {
        loadProductsCallCount += 1

        if let result = productResults[pageNumber] {
            switch result {
            case .success(let pagedItems):
                return pagedItems
            case .failure(let error):
                throw error
            }
        }
        return fallbackResult
    }

    func loadProductVariations(siteID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        loadProductVariationsCallCount += 1

        if let result = variationResults[pageNumber] {
            switch result {
            case .success(let pagedItems):
                return pagedItems
            case .failure(let error):
                throw error
            }
        }
        return fallbackVariationResult
    }

    // MARK: - Protocol Methods - Catalog size
    var productCount: Int = 0
    func getProductCount(siteID: Int64) async throws -> Int {
        return productCount
    }

    var variationCount: Int = 0
    func getProductVariationCount(siteID: Int64) async throws -> Int {
        return variationCount
    }
}
