import Foundation
import Testing
@testable import Hardware

struct PaymentAttemptCancellationTrackerTests {
    @Test func canceling_active_attempt_marks_it_as_canceled() {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()

        // When
        let canceledAttemptID = tracker.cancelActiveAttempt()

        // Then
        #expect(canceledAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))
    }

    @Test func beginning_new_attempt_does_not_clear_cancellation_from_previous_attempt() {
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

    @Test func finishing_old_attempt_does_not_clear_new_active_attempt() {
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
