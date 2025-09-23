@testable import Yosemite

final class MockPOSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    var catalogInfoResult: Result<POSCatalogInfo, Error> = .success(
        .init(productCount: 0, variationCount: 0, lastFullSyncDate: nil, lastIncrementalSyncDate: nil)
    )
    var shouldDelayResponse = false

    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        if shouldDelayResponse {
            try await Task.sleep(for: .milliseconds(100))
        }

        switch catalogInfoResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}
