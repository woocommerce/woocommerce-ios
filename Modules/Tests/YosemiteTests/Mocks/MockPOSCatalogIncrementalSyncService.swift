import Foundation
@testable import Yosemite

final class MockPOSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol {
    private(set) var startIncrementalSyncCallCount = 0
    private(set) var lastSiteID: Int64?
    private(set) var lastFullSyncDate: Date?
    
    var shouldThrowError: Error?
    
    func startIncrementalSync(for siteID: Int64, lastFullSyncDate: Date) async throws {
        startIncrementalSyncCallCount += 1
        self.lastSiteID = siteID
        self.lastFullSyncDate = lastFullSyncDate
        
        if let error = shouldThrowError {
            throw error
        }
    }
}

extension MockPOSCatalogIncrementalSyncService {
    func reset() {
        startIncrementalSyncCallCount = 0
        lastSiteID = nil
        lastFullSyncDate = nil
        shouldThrowError = nil
    }
}
