import Foundation
@testable import Yosemite

final class MockPOSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol {
    var startIncrementalSyncResult: Result<POSCatalog, Error> = .success(POSCatalog(products: [], variations: [], syncDate: .now))

    private(set) var startIncrementalSyncCallCount = 0
    private(set) var lastSyncSiteID: Int64?
    private(set) var lastFullSyncDate: Date?
    private(set) var lastIncrementalSyncDate: Date?

    private var syncContinuations: [CheckedContinuation<Void, Never>] = []
    private var shouldBlockSync = false
    private var syncBlockedContinuations: [CheckedContinuation<Void, Never>] = []

    @discardableResult
    func startIncrementalSync(for siteID: Int64,
                              lastFullSyncDate: Date,
                              lastIncrementalSyncDate: Date?,
                              posProductsOnly: Bool) async throws -> POSCatalog {
        startIncrementalSyncCallCount += 1
        lastSyncSiteID = siteID
        self.lastFullSyncDate = lastFullSyncDate
        self.lastIncrementalSyncDate = lastIncrementalSyncDate

        if shouldBlockSync {
            await withCheckedContinuation { continuation in
                syncContinuations.append(continuation)
                // Signal that a sync is now blocked and ready
                if !syncBlockedContinuations.isEmpty {
                    syncBlockedContinuations.removeFirst().resume()
                }
            }
        }

        switch startIncrementalSyncResult {
        case .success(let catalog):
            return catalog
        case .failure(let error):
            throw error
        }
    }
}

extension MockPOSCatalogIncrementalSyncService {
    func blockNextSync() {
        shouldBlockSync = true
    }

    func waitUntilSyncBlocked() async {
        await withCheckedContinuation { continuation in
            syncBlockedContinuations.append(continuation)
        }
    }

    func resumeBlockedSync() {
        syncContinuations.forEach { $0.resume() }
        syncContinuations.removeAll()
        shouldBlockSync = false
    }
}
