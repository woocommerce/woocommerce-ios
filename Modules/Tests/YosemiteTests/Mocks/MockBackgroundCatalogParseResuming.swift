import Foundation
import Synchronization
@testable import Networking

final class MockBackgroundCatalogParseResuming: BackgroundCatalogParseResuming, Sendable {
    private struct State {
        var pendingResume: (fileURL: URL, siteID: Int64, snapshotDate: Date)?
        var resumePendingParseIfNeededCallCount = 0
        var lastParseHandlerError: Error?
        var discardPendingParseCallCount = 0
        var discardPendingParseSiteIDs: [Int64] = []
    }

    private let state = Mutex(State())

    /// A staged catalog file to pass to the coordinator's parse handler, or nil to no-op.
    var pendingResume: (fileURL: URL, siteID: Int64, snapshotDate: Date)? {
        get { state.withLock { $0.pendingResume } }
        set { state.withLock { $0.pendingResume = newValue } }
    }

    var resumePendingParseIfNeededCallCount: Int {
        state.withLock { $0.resumePendingParseIfNeededCallCount }
    }

    var lastParseHandlerError: Error? {
        state.withLock { $0.lastParseHandlerError }
    }

    var discardPendingParseCallCount: Int {
        state.withLock { $0.discardPendingParseCallCount }
    }

    var discardPendingParseSiteIDs: [Int64] {
        state.withLock { $0.discardPendingParseSiteIDs }
    }

    func discardPendingParse(for siteID: Int64) {
        state.withLock {
            $0.discardPendingParseCallCount += 1
            $0.discardPendingParseSiteIDs.append(siteID)
        }
    }

    func resumePendingParseIfNeeded(parseHandler: @escaping (URL, Int64, Date) async throws -> Void) async {
        let pending = state.withLock {
            $0.resumePendingParseIfNeededCallCount += 1
            return $0.pendingResume
        }
        guard let pending else { return }
        do {
            try await parseHandler(pending.fileURL, pending.siteID, pending.snapshotDate)
        } catch {
            // Mirror the production contract: errors from the parse handler are surfaced via
            // this spy so tests can assert they were swallowed by the coordinator.
            state.withLock { $0.lastParseHandlerError = error }
        }
    }
}
