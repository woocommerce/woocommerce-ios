@testable import Yosemite

final class MockPOSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private(set) var replaceAllCatalogDataCallCount = 0
    private(set) var lastPersistedCatalog: POSCatalog?
    private(set) var lastPersistedSiteID: Int64?

    private(set) var persistIncrementalCatalogDataCallCount = 0
    private(set) var persistIncrementalCatalogDataLastPersistedCatalog: POSCatalog?
    private(set) var persistIncrementalCatalogDataLastPersistedSiteID: Int64?

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        replaceAllCatalogDataCallCount += 1
        lastPersistedSiteID = siteID
        lastPersistedCatalog = catalog
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        persistIncrementalCatalogDataCallCount += 1
        persistIncrementalCatalogDataLastPersistedSiteID = siteID
        persistIncrementalCatalogDataLastPersistedCatalog = catalog
    }
}
