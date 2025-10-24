import Foundation
@testable import Yosemite

final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performFullSyncInvocationCount = 0
    var performFullSyncSiteID: Int64?
    var performFullSyncResult: Result<Void, Error> = .success(())
    var lastSyncDate: Date?

    var performSmartSyncInvocationCount = 0
    var performSmartSyncSiteID: Int64?
    var performSmartSyncFullSyncMaxAge: TimeInterval?
    var performSmartSyncResult: Result<Void, Error> = .success(())

    var onPerformFullSyncCalled: (() -> Void)?

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

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval) async throws {
        performSmartSyncInvocationCount += 1
        performSmartSyncSiteID = siteID
        performSmartSyncFullSyncMaxAge = fullSyncMaxAge

        switch performSmartSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func setCatalogEligibilityChecker(_ checker: @escaping () async -> Bool) { }
}
