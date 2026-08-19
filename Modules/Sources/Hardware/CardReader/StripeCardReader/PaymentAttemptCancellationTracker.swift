import Foundation

/// Tracks cancellation independently from Stripe's PaymentIntent, which may not exist yet when cancellation is requested.
final class PaymentAttemptCancellationTracker {
    private let lock = NSLock()
    private var storedActiveAttemptID: UUID?
    private var canceledAttemptIDs: Set<UUID> = []

    var activeAttemptID: UUID? {
        lock.lock()
        defer { lock.unlock() }
        return storedActiveAttemptID
    }

    func beginAttempt() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        let attemptID = UUID()
        storedActiveAttemptID = attemptID
        return attemptID
    }

    func cancelActiveAttempt() -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        guard let activeAttemptID = storedActiveAttemptID else { return nil }
        canceledAttemptIDs.insert(activeAttemptID)
        return activeAttemptID
    }

    func isCanceled(_ attemptID: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return canceledAttemptIDs.contains(attemptID)
    }

    func finishAttempt(_ attemptID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        canceledAttemptIDs.remove(attemptID)
        if storedActiveAttemptID == attemptID {
            storedActiveAttemptID = nil
        }
    }
}
