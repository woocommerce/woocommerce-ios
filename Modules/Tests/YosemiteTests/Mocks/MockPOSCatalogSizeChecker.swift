import Foundation
@testable import Yosemite

final class MockPOSCatalogSizeChecker: POSCatalogSizeCheckerProtocol {
    var sizeToReturn: Result<POSCatalogSize, Error>
    var checkCatalogSizeCallCount = 0
    var lastCheckedSiteID: Int64?

    init(sizeToReturn: Result<POSCatalogSize, Error> = .success(POSCatalogSize(productCount: 100, variationCount: 50))) {
        self.sizeToReturn = sizeToReturn
    }

    func checkCatalogSize(for siteID: Int64) async throws -> POSCatalogSize {
        checkCatalogSizeCallCount += 1
        lastCheckedSiteID = siteID
        switch sizeToReturn {
        case .success(let size):
            return size
        case .failure(let error):
            throw error
        }
    }
}
