import Foundation
@testable import Networking

final class MockPOSCatalogSyncRemote: POSCatalogSyncRemoteProtocol {
    // Dictionary mapping pageNumber to Result for products and variations.
    private(set) var productResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
    private(set) var variationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]
    private(set) var incrementalProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
    private(set) var incrementalVariationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]
    private(set) var trashedProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]

    var catalogRequestResult: Result<POSCatalogRequestResponse, Error> = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
    var catalogDownloadResult: Result<POSCatalogResponse, Error> = .success(.init(products: [], variations: []))

    let loadProductsCallCount = Counter()
    let loadProductVariationsCallCount = Counter()
    let loadIncrementalProductsCallCount = Counter()
    let loadIncrementalProductVariationsCallCount = Counter()
    let loadTrashedProductsCallCount = Counter()

    private(set) var lastIncrementalProductsModifiedAfter: Date?
    private(set) var lastIncrementalVariationsModifiedAfter: Date?
    private(set) var lastTrashedProductsModifiedAfter: Date?
    let includeStatusTracker = IncludeStatusTracker()
    private(set) var lastCatalogRequestForceGeneration: Bool?
    private(set) var lastCatalogDownloadAllowCellular: Bool?

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

    func setTrashedProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        trashedProductResults[pageNumber] = result
    }

    func setTrashedProductResults(_ results: [PagedItems<POSProduct>]) {
        for (index, pagedItems) in results.enumerated() {
            trashedProductResults[index + 1] = .success(pagedItems)
        }
    }

    // MARK: - Protocol Methods - Incremental Sync

    func loadProducts(modifiedAfter: Date,
                      siteID: Int64,
                      pageNumber: Int,
                      includeStatus: String?) async throws -> PagedItems<POSProduct> {
        await includeStatusTracker.append(includeStatus)

        // Route to appropriate results based on includeStatus
        if includeStatus == "trash" {
            await loadTrashedProductsCallCount.increment()
            lastTrashedProductsModifiedAfter = modifiedAfter

            if let result = trashedProductResults[pageNumber] {
                switch result {
                case .success(let pagedItems):
                    return pagedItems
                case .failure(let error):
                    throw error
                }
            }
        } else {
            await loadIncrementalProductsCallCount.increment()
            lastIncrementalProductsModifiedAfter = modifiedAfter

            if let result = incrementalProductResults[pageNumber] {
                switch result {
                case .success(let pagedItems):
                    return pagedItems
                case .failure(let error):
                    throw error
                }
            }
        }
        return fallbackResult
    }

    func loadProductVariations(modifiedAfter: Date,
                                siteID: Int64,
                                pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        await loadIncrementalProductVariationsCallCount.increment()
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

    func loadProducts(siteID: Int64,
                      pageNumber: Int,
                      allowCellular: Bool) async throws -> PagedItems<POSProduct> {
        await loadProductsCallCount.increment()

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

    func loadProductVariations(siteID: Int64,
                                pageNumber: Int,
                                allowCellular: Bool) async throws -> PagedItems<POSProductVariation> {
        await loadProductVariationsCallCount.increment()

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

    // MARK: - Protocol Methods - Catalog API

    func requestCatalogGeneration(for siteID: Int64, forceGeneration: Bool, allowCellular: Bool) async throws -> POSCatalogRequestResponse {
        lastCatalogRequestForceGeneration = forceGeneration
        lastCatalogDownloadAllowCellular = allowCellular
        switch catalogRequestResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func downloadCatalog(for siteID: Int64, downloadURL: String, allowCellular: Bool) async throws -> POSCatalogResponse {
        lastCatalogDownloadAllowCellular = allowCellular
        switch catalogDownloadResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    var parseDownloadedCatalogResult: Result<POSCatalogResponse, Error> = .success(.init(products: [], variations: []))
    private(set) var parseDownloadedCatalogCallCount = 0
    private(set) var lastParsedFileURL: URL?
    private(set) var lastParsedSiteID: Int64?

    func parseDownloadedCatalog(from fileURL: URL, siteID: Int64) async throws -> POSCatalogResponse {
        parseDownloadedCatalogCallCount += 1
        lastParsedFileURL = fileURL
        lastParsedSiteID = siteID

        switch parseDownloadedCatalogResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Protocol Methods - Catalog size

    // MARK: - getProductCount tracking
    private(set) var getProductCountCallCount = 0
    private(set) var lastProductCountSiteID: Int64?
    var getProductCountResult: Result<Int, Error> = .success(0)
    var productCountDelay: UInt64 = 0

    // MARK: - getProductVariationCount tracking
    private(set) var getProductVariationCountCallCount = 0
    private(set) var lastVariationCountSiteID: Int64?
    var getProductVariationCountResult: Result<Int, Error> = .success(0)
    var variationCountDelay: UInt64 = 0

    func getProductCount(siteID: Int64) async throws -> Int {
        getProductCountCallCount += 1
        lastProductCountSiteID = siteID

        if productCountDelay > 0 {
            try await Task.sleep(nanoseconds: productCountDelay)
        }

        switch getProductCountResult {
        case .success(let count):
            return count
        case .failure(let error):
            throw error
        }
    }

    func getProductVariationCount(siteID: Int64) async throws -> Int {
        getProductVariationCountCallCount += 1
        lastVariationCountSiteID = siteID

        if variationCountDelay > 0 {
            try await Task.sleep(nanoseconds: variationCountDelay)
        }

        switch getProductVariationCountResult {
        case .success(let count):
            return count
        case .failure(let error):
            throw error
        }
    }
}

/// Thread-safe tracker for includeStatus values
actor IncludeStatusTracker {
    private(set) var values: [String?] = []

    func append(_ value: String?) {
        values.append(value)
    }
}
