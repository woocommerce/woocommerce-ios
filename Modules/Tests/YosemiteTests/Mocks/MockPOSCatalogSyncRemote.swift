import Foundation
import Synchronization
@testable import Networking

final class MockPOSCatalogSyncRemote: POSCatalogSyncRemoteProtocol {
    // All mutable fixtures and recorded calls share one lock; compound operations stay atomic.
    private struct State {
        var productResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
        var variationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]
        var incrementalProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
        var incrementalVariationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] = [:]
        var trashedProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
        var allProductResults: [Int: Result<PagedItems<POSProduct>, Error>] = [:]
        var catalogRequestResult: Result<POSCatalogRequestResponse, Error> = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        var catalogDownloadResult: Result<POSCatalogResponse, Error> = .success(.init(products: [], variations: []))
        var catalogRequestSequence: [Result<POSCatalogRequestResponse, Error>] = []
        var catalogRequestSequenceIndex: Int = 0
        var catalogRequestCallCount: Int = 0
        var lastIncrementalProductsModifiedAfter: Date? = nil
        var lastIncrementalVariationsModifiedAfter: Date? = nil
        var lastTrashedProductsModifiedAfter: Date? = nil
        var lastCatalogRequestForceGeneration: Bool? = nil
        var lastCatalogDownloadAllowCellular: Bool? = nil
        var lastCatalogDownloadSnapshotDate: Date? = nil
        var parseDownloadedCatalogResult: Result<POSCatalogResponse, Error> = .success(.init(products: [], variations: []))
        var parseDownloadedCatalogCallCount: Int = 0
        var lastParsedFileURL: URL? = nil
        var lastParsedSiteID: Int64? = nil
    }

    private let state = Mutex(State())

    var productResults: [Int: Result<PagedItems<POSProduct>, Error>] {
        state.withLock { $0.productResults }
    }

    var variationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] {
        state.withLock { $0.variationResults }
    }

    var incrementalProductResults: [Int: Result<PagedItems<POSProduct>, Error>] {
        state.withLock { $0.incrementalProductResults }
    }

    var incrementalVariationResults: [Int: Result<PagedItems<POSProductVariation>, Error>] {
        state.withLock { $0.incrementalVariationResults }
    }

    var trashedProductResults: [Int: Result<PagedItems<POSProduct>, Error>] {
        state.withLock { $0.trashedProductResults }
    }

    var allProductResults: [Int: Result<PagedItems<POSProduct>, Error>] {
        state.withLock { $0.allProductResults }
    }

    var catalogRequestResult: Result<POSCatalogRequestResponse, Error> {
        get { state.withLock { $0.catalogRequestResult } }
        set { state.withLock { $0.catalogRequestResult = newValue } }
    }

    var catalogDownloadResult: Result<POSCatalogResponse, Error> {
        get { state.withLock { $0.catalogDownloadResult } }
        set { state.withLock { $0.catalogDownloadResult = newValue } }
    }

    var catalogRequestSequence: [Result<POSCatalogRequestResponse, Error>] {
        get { state.withLock { $0.catalogRequestSequence } }
        set { state.withLock { $0.catalogRequestSequence = newValue } }
    }

    var catalogRequestCallCount: Int {
        state.withLock { $0.catalogRequestCallCount }
    }

    var lastIncrementalProductsModifiedAfter: Date? {
        state.withLock { $0.lastIncrementalProductsModifiedAfter }
    }

    var lastIncrementalVariationsModifiedAfter: Date? {
        state.withLock { $0.lastIncrementalVariationsModifiedAfter }
    }

    var lastTrashedProductsModifiedAfter: Date? {
        state.withLock { $0.lastTrashedProductsModifiedAfter }
    }

    var lastCatalogRequestForceGeneration: Bool? {
        state.withLock { $0.lastCatalogRequestForceGeneration }
    }

    var lastCatalogDownloadAllowCellular: Bool? {
        state.withLock { $0.lastCatalogDownloadAllowCellular }
    }

    var lastCatalogDownloadSnapshotDate: Date? {
        state.withLock { $0.lastCatalogDownloadSnapshotDate }
    }

    var parseDownloadedCatalogResult: Result<POSCatalogResponse, Error> {
        get { state.withLock { $0.parseDownloadedCatalogResult } }
        set { state.withLock { $0.parseDownloadedCatalogResult = newValue } }
    }

    var parseDownloadedCatalogCallCount: Int {
        state.withLock { $0.parseDownloadedCatalogCallCount }
    }

    var lastParsedFileURL: URL? {
        state.withLock { $0.lastParsedFileURL }
    }

    var lastParsedSiteID: Int64? {
        state.withLock { $0.lastParsedSiteID }
    }

    let loadProductsCallCount = Counter()
    let loadProductVariationsCallCount = Counter()
    let loadIncrementalProductsCallCount = Counter()
    let loadIncrementalProductVariationsCallCount = Counter()
    let loadTrashedProductsCallCount = Counter()
    let includeStatusTracker = IncludeStatusTracker()

    // Fallback result when no specific page result is configured
    private let fallbackResult = PagedItems(items: [] as [POSProduct], hasMorePages: false, totalItems: 0)
    private let fallbackVariationResult = PagedItems(items: [] as [POSProductVariation], hasMorePages: false, totalItems: 0)

    // MARK: - Setup Methods for Full Sync

    func setProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        state.withLock { $0.productResults[pageNumber] = result }
    }

    func setVariationResult(pageNumber: Int, result: Result<PagedItems<POSProductVariation>, Error>) {
        state.withLock { $0.variationResults[pageNumber] = result }
    }

    func setProductResults(_ results: [PagedItems<POSProduct>]) {
        state.withLock { state in
            for (index, pagedItems) in results.enumerated() {
                state.productResults[index + 1] = .success(pagedItems)
            }
        }
    }

    func setVariationResults(_ results: [PagedItems<POSProductVariation>]) {
        state.withLock { state in
            for (index, pagedItems) in results.enumerated() {
                state.variationResults[index + 1] = .success(pagedItems)
            }
        }
    }

    // MARK: - Setup Methods for Incremental Sync

    func setIncrementalProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        state.withLock { $0.incrementalProductResults[pageNumber] = result }
    }

    func setIncrementalVariationResult(pageNumber: Int, result: Result<PagedItems<POSProductVariation>, Error>) {
        state.withLock { $0.incrementalVariationResults[pageNumber] = result }
    }

    func setIncrementalProductResults(_ results: [PagedItems<POSProduct>]) {
        state.withLock { state in
            for (index, pagedItems) in results.enumerated() {
                state.incrementalProductResults[index + 1] = .success(pagedItems)
            }
        }
    }

    func setIncrementalVariationResults(_ results: [PagedItems<POSProductVariation>]) {
        state.withLock { state in
            for (index, pagedItems) in results.enumerated() {
                state.incrementalVariationResults[index + 1] = .success(pagedItems)
            }
        }
    }

    func setTrashedProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        state.withLock { $0.trashedProductResults[pageNumber] = result }
    }

    func setTrashedProductResults(_ results: [PagedItems<POSProduct>]) {
        state.withLock { state in
            for (index, pagedItems) in results.enumerated() {
                state.trashedProductResults[index + 1] = .success(pagedItems)
            }
        }
    }

    // MARK: - Setup Methods for unfiltered product requests (hidden product detection)
    func setAllProductResult(pageNumber: Int, result: Result<PagedItems<POSProduct>, Error>) {
        state.withLock { $0.allProductResults[pageNumber] = result }
    }

    // MARK: - Protocol Methods - Incremental Sync

    func loadProducts(modifiedAfter: Date,
                      siteID: Int64,
                      pageNumber: Int,
                      includeStatus: String?,
                      posProductsOnly: Bool) async throws -> PagedItems<POSProduct> {
        await includeStatusTracker.append(includeStatus)

        // Route to appropriate results based on includeStatus and posProductsOnly
        if includeStatus == "trash" {
            await loadTrashedProductsCallCount.increment()
            state.withLock { $0.lastTrashedProductsModifiedAfter = modifiedAfter }

            if let result = trashedProductResults[pageNumber] {
                switch result {
                case .success(let pagedItems):
                    return pagedItems
                case .failure(let error):
                    throw error
                }
            }
        } else if !posProductsOnly {
            // Unfiltered request (posProductsOnly=false) — used for hidden product detection.
            // Uses allProductResults if configured, otherwise returns fallback.
            if let result = allProductResults[pageNumber] {
                switch result {
                case .success(let pagedItems):
                    return pagedItems
                case .failure(let error):
                    throw error
                }
            }
            return fallbackResult
        } else {
            await loadIncrementalProductsCallCount.increment()
            state.withLock { $0.lastIncrementalProductsModifiedAfter = modifiedAfter }

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
        state.withLock { $0.lastIncrementalVariationsModifiedAfter = modifiedAfter }

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
        let result = state.withLock { state in
            state.catalogRequestCallCount += 1
            state.lastCatalogRequestForceGeneration = forceGeneration
            state.lastCatalogDownloadAllowCellular = allowCellular

            // Select and consume a sequence entry in the same critical section.
            if state.catalogRequestSequenceIndex < state.catalogRequestSequence.count {
                let result = state.catalogRequestSequence[state.catalogRequestSequenceIndex]
                state.catalogRequestSequenceIndex += 1
                return result
            }
            return state.catalogRequestResult
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func downloadCatalog(for siteID: Int64, downloadURL: String, allowCellular: Bool, snapshotDate: Date) async throws -> POSCatalogResponse {
        let result = state.withLock { state in
            state.lastCatalogDownloadAllowCellular = allowCellular
            state.lastCatalogDownloadSnapshotDate = snapshotDate
            return state.catalogDownloadResult
        }
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func parseDownloadedCatalog(from fileURL: URL, siteID: Int64) async throws -> POSCatalogResponse {
        let result = state.withLock { state in
            state.parseDownloadedCatalogCallCount += 1
            state.lastParsedFileURL = fileURL
            state.lastParsedSiteID = siteID
            return state.parseDownloadedCatalogResult
        }

        switch result {
        case .success(let response):
            return response
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
