@testable import Yosemite

final class MockPOSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    var catalogInfoResult: Result<POSCatalogInfo, Error> = .success(
        .init(productCount: 0, variationCount: 0, lastFullSyncDate: nil, lastIncrementalSyncDate: nil)
    )
    var onLoadCatalogInfoCalled: (() -> Void)?

    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        onLoadCatalogInfoCalled?()

        switch catalogInfoResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}
