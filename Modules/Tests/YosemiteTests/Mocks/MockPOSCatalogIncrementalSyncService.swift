import Foundation
import Synchronization
@testable import Yosemite

final class MockPOSCatalogIncrementalSyncService: POSCatalogIncrementalSyncServiceProtocol, Sendable {
    private struct State {
        var startIncrementalSyncResult: Result<POSCatalog, Error> = .success(POSCatalog(products: [], variations: [], syncDate: .now))
        var startIncrementalSyncCallCount: Int = 0
        var lastSyncSiteID: Int64?
        var lastFullSyncDate: Date?
        var lastIncrementalSyncDate: Date?
        var onSync: (@Sendable (Int64) async throws -> Void)?
    }

    private let state = Mutex(State())

    var startIncrementalSyncResult: Result<POSCatalog, Error> {
        get { state.withLock { $0.startIncrementalSyncResult } }
        set { state.withLock { $0.startIncrementalSyncResult = newValue } }
    }

    private(set) var startIncrementalSyncCallCount: Int {
        get { state.withLock { $0.startIncrementalSyncCallCount } }
        set { state.withLock { $0.startIncrementalSyncCallCount = newValue } }
    }

    private(set) var lastSyncSiteID: Int64? {
        get { state.withLock { $0.lastSyncSiteID } }
        set { state.withLock { $0.lastSyncSiteID = newValue } }
    }

    private(set) var lastFullSyncDate: Date? {
        get { state.withLock { $0.lastFullSyncDate } }
        set { state.withLock { $0.lastFullSyncDate = newValue } }
    }

    private(set) var lastIncrementalSyncDate: Date? {
        get { state.withLock { $0.lastIncrementalSyncDate } }
        set { state.withLock { $0.lastIncrementalSyncDate = newValue } }
    }

    var onSync: (@Sendable (Int64) async throws -> Void)? {
        get { state.withLock { $0.onSync } }
        set { state.withLock { $0.onSync = newValue } }
    }

    @discardableResult
    func startIncrementalSync(for siteID: Int64,
                              lastFullSyncDate: Date,
                              lastIncrementalSyncDate: Date?) async throws -> POSCatalog {
        state.withLock { $0.startIncrementalSyncCallCount += 1 }
        lastSyncSiteID = siteID
        self.lastFullSyncDate = lastFullSyncDate
        self.lastIncrementalSyncDate = lastIncrementalSyncDate

        try await onSync?(siteID)

        switch startIncrementalSyncResult {
        case .success(let catalog):
            return catalog
        case .failure(let error):
            throw error
        }
    }
}
