import Foundation
import Testing
@testable import Hardware

struct PaymentAttemptCancellationTrackerTests {
    @Test func test_cancelActiveAttempt_activeAttemptExists_marksAttemptAsCanceled() {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()

        // When
        let canceledAttemptID = tracker.cancelActiveAttempt()

        // Then
        #expect(canceledAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))
    }

    @Test func test_beginAttempt_previousAttemptWasCanceled_preservesPreviousCancellation() {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let canceledAttemptID = tracker.beginAttempt()
        _ = tracker.cancelActiveAttempt()

        // When
        let newAttemptID = tracker.beginAttempt()

        // Then
        #expect(tracker.isCanceled(canceledAttemptID))
        #expect(tracker.isCanceled(newAttemptID) == false)
    }

    @Test func test_finishAttempt_newerAttemptIsActive_preservesNewerActiveAttempt() {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let oldAttemptID = tracker.beginAttempt()
        _ = tracker.cancelActiveAttempt()
        let newAttemptID = tracker.beginAttempt()

        // When
        tracker.finishAttempt(oldAttemptID)

        // Then
        #expect(tracker.activeAttemptID == newAttemptID)
        #expect(tracker.isCanceled(oldAttemptID) == false)
    }
}
