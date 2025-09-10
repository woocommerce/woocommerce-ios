import Foundation
@testable import Yosemite

struct MockPOSCatalogSizeChecker: POSCatalogSizeCheckerProtocol {
    func checkCatalogSize(for siteID: Int64) async throws -> POSCatalogSize {
        return POSCatalogSize(productCount: 0, variationCount: 0)
    }
}
