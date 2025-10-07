import Foundation
@testable import Yosemite

final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performFullSyncInvocationCount = 0
    var performFullSyncSiteID: Int64?
    var performFullSyncResult: Result<Void, Error> = .success(())
    var shouldDelayResponse = false

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        if shouldDelayResponse {
            try await Task.sleep(for: .milliseconds(100))
        }

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
}
