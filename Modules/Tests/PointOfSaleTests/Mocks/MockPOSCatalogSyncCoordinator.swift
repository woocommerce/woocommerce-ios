import Foundation
@testable import Yosemite

final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performFullSyncInvocationCount = 0
    var performFullSyncSiteID: Int64?
    var performFullSyncResult: Result<Void, Error> = .success(())

    var onPerformFullSyncCalled: (() -> Void)?

    var lastFullSyncDate: Date?

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        onPerformFullSyncCalled?()

        performFullSyncInvocationCount += 1
        performFullSyncSiteID = siteID

        switch performFullSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {}

    func getLastFullSyncDate(for siteID: Int64) async -> Date? {
        return lastFullSyncDate
    }
}
