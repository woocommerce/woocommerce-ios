import Foundation
@testable import Yosemite

final class MockPOSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol {
    var startIncrementalSyncResult: Result<Void, Error> = .success(())

    private(set) var startIncrementalSyncCallCount = 0
    private(set) var lastSyncSiteID: Int64?
    private(set) var lastFullSyncDate: Date?
    private(set) var lastIncrementalSyncDate: Date?

    private var syncContinuation: CheckedContinuation<Void, Never>?
    private var shouldBlockSync = false

    func startIncrementalSync(for siteID: Int64, lastFullSyncDate: Date, lastIncrementalSyncDate: Date?) async throws {
        startIncrementalSyncCallCount += 1
        lastSyncSiteID = siteID
        self.lastFullSyncDate = lastFullSyncDate
        self.lastIncrementalSyncDate = lastIncrementalSyncDate

        if shouldBlockSync {
            await withCheckedContinuation { continuation in
                syncContinuation = continuation
            }
        }

        switch startIncrementalSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

extension MockPOSCatalogIncrementalSyncService {
    func blockNextSync() {
        shouldBlockSync = true
    }

    func resumeBlockedSync() {
        syncContinuation?.resume()
        syncContinuation = nil
        shouldBlockSync = false
    }
}
