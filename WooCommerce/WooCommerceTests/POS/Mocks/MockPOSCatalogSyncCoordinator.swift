import Foundation
@testable import Yosemite

final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performFullSyncInvocationCount = 0
    var performFullSyncSiteID: Int64?
    var performFullSyncResult: Result<Void, Error> = .success(())

    func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
        true
    }

    var onPerformFullSyncCalled: ((_ continuation: CheckedContinuation<Void, Never>) -> Void)? = nil

    func performFullSync(for siteID: Int64) async throws {
        if let onPerformFullSyncCalled {
            await withCheckedContinuation { continuation in
                onPerformFullSyncCalled(continuation)
            }
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

    func performIncrementalSyncIfApplicable(for siteID: Int64, forceSync: Bool) async throws {}
}
