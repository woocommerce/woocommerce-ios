import Foundation
@testable import Networking

final class MockBackgroundCatalogParseResuming: BackgroundCatalogParseResuming, @unchecked Sendable {
    /// If set, the resumer invokes `parseHandler` with this `(fileURL, siteID, snapshotDate)` —
    /// simulating a staged catalog file waiting to be persisted. If `nil`, the resumer no-ops.
    var pendingResume: (fileURL: URL, siteID: Int64, snapshotDate: Date)?

    private(set) var resumePendingParseIfNeededCallCount = 0
    private(set) var lastParseHandlerError: Error?

    private(set) var discardPendingParseCallCount = 0
    private(set) var discardPendingParseSiteIDs: [Int64] = []

    func discardPendingParse(for siteID: Int64) {
        discardPendingParseCallCount += 1
        discardPendingParseSiteIDs.append(siteID)
    }

    func resumePendingParseIfNeeded(parseHandler: @escaping (URL, Int64, Date) async throws -> Void) async {
        resumePendingParseIfNeededCallCount += 1
        guard let pending = pendingResume else { return }
        do {
            try await parseHandler(pending.fileURL, pending.siteID, pending.snapshotDate)
        } catch {
            // Mirror the production contract: errors from the parse handler are surfaced via
            // this spy so tests can assert they were swallowed by the coordinator.
            lastParseHandlerError = error
        }
    }
}
