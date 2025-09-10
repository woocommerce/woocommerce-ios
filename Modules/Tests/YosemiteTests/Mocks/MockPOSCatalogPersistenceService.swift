@testable import Yosemite
import Foundation

final class MockPOSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    // MARK: - persistIncrementalCatalogData tracking
    private(set) var persistIncrementalCatalogDataCallCount = 0
    private(set) var persistIncrementalCatalogDataLastPersistedCatalog: POSCatalog?
    var persistIncrementalCatalogDataError: Error?

    // MARK: - loadSite tracking
    var loadSiteResult: Result<POSSite?, Error> = .success(nil)
    private(set) var loadSiteCallCount = 0
    
    // Track specific sites for multi-site tests
    var siteResults: [Int64: POSSite] = [:]
    
    // MARK: - updateSite tracking
    private(set) var updateSiteCallCount = 0
    private(set) var lastUpdatedSite: POSSite?
    
    // Internal storage for updated sites
    private var storedSites: [Int64: POSSite] = [:]

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

    func loadSite(siteID: Int64) async throws -> POSSite? {
        loadSiteCallCount += 1

        // Check if we have a stored site from updateSite calls
        if let storedSite = storedSites[siteID] {
            return storedSite
        }

        // Check if we have a specific result for this site
        if let specificSite = siteResults[siteID] {
            return specificSite
        }

        // Fall back to configured result
        switch loadSiteResult {
        case .success(let site):
            return site
        case .failure(let error):
            throw error
        }
    }

    func updateSite(_ site: POSSite) async throws {
        updateSiteCallCount += 1
        lastUpdatedSite = site
        storedSites[site.siteID] = site
    }
}
