import Foundation
@testable import Yosemite

final class MockPOSCatalogSizeChecker: POSCatalogSizeCheckerProtocol {
    // MARK: - checkCatalogSize tracking
    private(set) var checkCatalogSizeCallCount = 0
    private(set) var lastCheckedSiteID: Int64?
    var checkCatalogSizeResult: Result<POSCatalogSize, Error> = .success(POSCatalogSize(productCount: 100, variationCount: 50)) // 150 total - well under limit

    func checkCatalogSize(for siteID: Int64) async throws -> POSCatalogSize {
        checkCatalogSizeCallCount += 1
        lastCheckedSiteID = siteID

        switch checkCatalogSizeResult {
        case .success(let size):
            return size
        case .failure(let error):
            throw error
        }
    }
}
