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

    @Test func test_cancelActiveAttempt_when_creation_is_pending_then_waits_for_callback() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var results: [Result<Void, Error>] = []

        // When
        _ = tracker.cancelActiveAttempt { results.append($0) }

        // Then
        #expect(results.isEmpty)
        #expect(tracker.activeAttemptID == attemptID)

        // When: creation returns an intent, and Stripe later confirms its cancellation.
        let cancellationID = try #require(tracker.beginCancellation(attemptID))
        #expect(results.isEmpty)
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .success(()))

        // Then
        #expect(results.count == 1)
        try #require(results.first).get()
        #expect(tracker.activeAttemptID == nil)
    }

    @Test func test_cancelActiveAttempt_when_repeated_then_shares_cancellation_and_completes_all_waiters() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var completionCount = 0
        _ = tracker.cancelActiveAttempt { _ in completionCount += 1 }
        let cancellationID = try #require(tracker.beginCancellation(attemptID))

        // When
        _ = tracker.cancelActiveAttempt { _ in completionCount += 1 }
        let duplicateCancellationID = tracker.beginCancellation(attemptID)

        // Then
        #expect(duplicateCancellationID == nil)
        #expect(completionCount == 0)

        // When
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .success(()))
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .success(()))

        // Then
        #expect(completionCount == 2)
    }

    @Test func test_completeCancellation_when_stripe_fails_then_returns_error_and_keeps_attempt_unresolved() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var result: Result<Void, Error>?
        _ = tracker.cancelActiveAttempt { result = $0 }
        let cancellationID = try #require(tracker.beginCancellation(attemptID))

        // When
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .failure(TestError.cancellationFailed))

        // Then
        #expect(throws: TestError.cancellationFailed) { try #require(result).get() }
        #expect(tracker.activeAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))
    }

    @Test func test_completeCancellation_when_old_callback_arrives_during_retry_then_does_not_resolve_retry() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        _ = tracker.cancelActiveAttempt()
        let oldCancellationID = try #require(tracker.beginCancellation(attemptID))
        tracker.completeCancellation(attemptID, cancellationID: oldCancellationID, result: .failure(TestError.cancellationFailed))
        var completionCount = 0
        _ = tracker.cancelActiveAttempt { _ in completionCount += 1 }
        let retryCancellationID = try #require(tracker.beginCancellation(attemptID))

        // When
        tracker.completeCancellation(attemptID, cancellationID: oldCancellationID, result: .success(()))

        // Then
        #expect(completionCount == 0)
        #expect(tracker.activeAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))

        // When
        tracker.completeCancellation(attemptID, cancellationID: retryCancellationID, result: .success(()))

        // Then
        #expect(completionCount == 1)
        #expect(tracker.activeAttemptID == nil)
    }

    @Test func test_finishAttempt_when_creation_returns_no_intent_then_resolves_pending_cancellation() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var result: Result<Void, Error>?
        _ = tracker.cancelActiveAttempt { result = $0 }

        // When
        tracker.finishAttempt(attemptID)

        // Then
        try #require(result).get()
        #expect(tracker.activeAttemptID == nil)
    }

    @Test func test_completeCancellation_when_waiter_reenters_then_service_state_is_cleared_before_callback() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var intentIsActive = true
        _ = tracker.cancelActiveAttempt { _ in
            #expect(intentIsActive == false)
            #expect(tracker.activeAttemptID == nil)
            _ = tracker.beginAttempt()
        }
        let cancellationID = try #require(tracker.beginCancellation(attemptID))

        // When
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .success(())) {
            intentIsActive = false
        }

        // Then
        #expect(tracker.activeAttemptID != nil)
        #expect(tracker.activeAttemptID != attemptID)
    }

    @Test func test_finishAttempt_when_payment_succeeds_without_cancellation_then_clears_attempt_for_next_payment() {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()

        // When
        tracker.finishAttempt(attemptID)

        // Then
        #expect(tracker.activeAttemptID == nil)
        #expect(tracker.cancelActiveAttempt() == nil)
        let nextAttemptID = tracker.beginAttempt()
        #expect(nextAttemptID != attemptID)
        #expect(tracker.activeAttemptID == nextAttemptID)
    }

    @Test(arguments: [false, true])
    func test_finishAttempt_when_payment_succeeds_during_cancellation_then_waits_for_real_callback(cancellationSucceeds: Bool) throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var results: [Result<Void, Error>] = []
        _ = tracker.cancelActiveAttempt { results.append($0) }
        let cancellationID = try #require(tracker.beginCancellation(attemptID))

        // When
        tracker.finishAttempt(attemptID)
        let repeatedAttemptID = tracker.cancelActiveAttempt { results.append($0) }

        // Then
        #expect(results.isEmpty)
        #expect(repeatedAttemptID == attemptID)
        #expect(tracker.activeAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))
        #expect(tracker.beginCancellation(attemptID) == nil)

        // When
        let result: Result<Void, Error> = cancellationSucceeds ? .success(()) : .failure(TestError.cancellationFailed)
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: result)
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: result)

        // Then
        #expect(results.count == 2)
        for result in results {
            if cancellationSucceeds {
                try result.get()
            } else {
                #expect(throws: TestError.cancellationFailed) { try result.get() }
            }
        }
        #expect(tracker.activeAttemptID == nil)
        #expect(!tracker.isCanceled(attemptID))
        #expect(tracker.cancelActiveAttempt() == nil)
    }

    @Test func test_finishAttempt_when_payment_succeeds_after_failed_cancellation_then_retires_attempt_without_repeating_callback() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let attemptID = tracker.beginAttempt()
        var results: [Result<Void, Error>] = []
        _ = tracker.cancelActiveAttempt { results.append($0) }
        let cancellationID = try #require(tracker.beginCancellation(attemptID))
        tracker.completeCancellation(attemptID, cancellationID: cancellationID, result: .failure(TestError.cancellationFailed))
        #expect(tracker.activeAttemptID == attemptID)
        #expect(tracker.isCanceled(attemptID))

        // When
        tracker.finishAttempt(attemptID)

        // Then
        #expect(results.count == 1)
        #expect(throws: TestError.cancellationFailed) { try #require(results.first).get() }
        #expect(tracker.activeAttemptID == nil)
        #expect(!tracker.isCanceled(attemptID))
    }

    @Test func test_finishAttempt_when_old_payment_succeeds_during_cancellation_then_preserves_newer_attempt() throws {
        // Given
        let tracker = PaymentAttemptCancellationTracker()
        let oldAttemptID = tracker.beginAttempt()
        _ = tracker.cancelActiveAttempt()
        let cancellationID = try #require(tracker.beginCancellation(oldAttemptID))
        let nextAttemptID = tracker.beginAttempt()

        // When
        tracker.finishAttempt(oldAttemptID)
        tracker.completeCancellation(oldAttemptID, cancellationID: cancellationID, result: .failure(TestError.cancellationFailed))

        // Then
        #expect(tracker.activeAttemptID == nextAttemptID)
        #expect(!tracker.isCanceled(oldAttemptID))
        #expect(!tracker.isCanceled(nextAttemptID))
    }

    private enum TestError: Error, Equatable {
        case cancellationFailed
    }
}
