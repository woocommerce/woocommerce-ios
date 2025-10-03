@testable import Yosemite

final class MockPOSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    var catalogInfoResult: Result<POSCatalogInfo, Error> = .success(
        .init(productCount: 0, variationCount: 0, lastFullSyncDate: nil, lastIncrementalSyncDate: nil)
    )
    var onLoadCatalogInfoCalled: ((_ continuation: CheckedContinuation<Void, Never>) -> Void)? = nil

    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        if let onLoadCatalogInfoCalled {
            await withCheckedContinuation { continuation in
                onLoadCatalogInfoCalled(continuation)
            }
        }

        switch catalogInfoResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}
