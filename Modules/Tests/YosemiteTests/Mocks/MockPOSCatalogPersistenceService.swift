@testable import Yosemite
import Foundation

final class MockPOSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    // MARK: - replaceAllCatalogData tracking
    private(set) var replaceAllCatalogDataCallCount = 0
    private(set) var replaceAllCatalogDataLastPersistedCatalog: POSCatalog?
    var replaceAllCatalogDataError: Error?

    // MARK: - persistIncrementalCatalogData tracking
    private(set) var persistIncrementalCatalogDataCallCount = 0
    private(set) var persistIncrementalCatalogDataLastPersistedCatalog: POSCatalog?
    var persistIncrementalCatalogDataError: Error?

    // MARK: - Protocol Implementation

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        replaceAllCatalogDataCallCount += 1
        replaceAllCatalogDataLastPersistedCatalog = catalog

        if let error = replaceAllCatalogDataError {
            throw error
        }
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        persistIncrementalCatalogDataCallCount += 1
        persistIncrementalCatalogDataLastPersistedCatalog = catalog

        if let error = persistIncrementalCatalogDataError {
            throw error
        }
    }

    func deleteProducts(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        // no-op
    }
}
