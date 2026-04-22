import Foundation
@testable import Networking

final class MockBackgroundCatalogDownloadResuming: BackgroundCatalogDownloadResuming, @unchecked Sendable {
    /// If set, the resumer invokes `parseHandler` with this `(fileURL, siteID)` — simulating a
    /// staged catalog file waiting to be persisted. If `nil`, the resumer no-ops.
    var pendingResume: (fileURL: URL, siteID: Int64)?

    private(set) var resumePendingDownloadIfNeededCallCount = 0
    private(set) var lastParseHandlerError: Error?

    func resumePendingDownloadIfNeeded(parseHandler: @escaping (URL, Int64) async throws -> Void) async {
        resumePendingDownloadIfNeededCallCount += 1
        guard let pending = pendingResume else { return }
        do {
            try await parseHandler(pending.fileURL, pending.siteID)
        } catch {
            // Mirror the production contract: errors from the parse handler are surfaced via
            // this spy so tests can assert they were swallowed by the coordinator.
            lastParseHandlerError = error
        }
    }
}
