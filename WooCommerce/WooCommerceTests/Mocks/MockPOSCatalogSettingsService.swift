import Foundation
import protocol Yosemite.POSCatalogSettingsServiceProtocol
import struct Yosemite.POSCatalogInfo

final class MockPOSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    var catalogInfoResult: Result<POSCatalogInfo, Error> = .success(
        .init(productCount: 0, variationCount: 0, lastFullSyncDate: nil, lastIncrementalSyncDate: nil)
    )

    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        try catalogInfoResult.get()
    }
}
