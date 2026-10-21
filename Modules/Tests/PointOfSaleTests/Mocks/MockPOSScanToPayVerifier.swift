import Foundation
@testable import PointOfSale

final class MockPOSScanToPayVerifier: POSScanToPayVerifying {
    /// Successive return values for `checkPaymentStatus()`. The verifier returns the first
    /// element each call, removing it; if the queue is empty it stays on `pending` forever.
    var resultQueue: [Result<POSScanToPayVerificationResult, Error>] = []
    var checkPaymentStatusCallCount = 0
    /// Optional hook invoked each time `checkPaymentStatus()` is called. Useful in tests
    /// that use `fireOnce` to wait for the first poll without guessing `Task.yield()` counts.
    var onCheckPaymentStatusCalled: (() -> Void)?
    var waitForCancellation = false
    private(set) var observedCancellation = false
    var onCancellationObserved: (() -> Void)?

    func checkPaymentStatus() async throws -> POSScanToPayVerificationResult {
        checkPaymentStatusCallCount += 1
        onCheckPaymentStatusCalled?()
        if waitForCancellation {
            do {
                // Deliberately remains in flight until the owner cancels polling.
                // Correct cancellation wakes this immediately; the suite timeout bounds regressions.
                try await Task.sleep(nanoseconds: 3_600_000_000_000)
            } catch is CancellationError {
                observedCancellation = true
                onCancellationObserved?()
            }
        }
        guard !resultQueue.isEmpty else { return .pending }
        let next = resultQueue.removeFirst()
        switch next {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}
