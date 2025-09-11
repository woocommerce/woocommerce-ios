@testable import Yosemite
import Foundation

final class MockPOSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    // MARK: - persistIncrementalCatalogData tracking
    private(set) var persistIncrementalCatalogDataCallCount = 0
    private(set) var persistIncrementalCatalogDataLastPersistedCatalog: POSCatalog?
    var persistIncrementalCatalogDataError: Error?

    // MARK: - Protocol Implementation

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        // Not used in current tests
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        persistIncrementalCatalogDataCallCount += 1
        persistIncrementalCatalogDataLastPersistedCatalog = catalog

        if let error = persistIncrementalCatalogDataError {
            throw error
        }
    }
}
