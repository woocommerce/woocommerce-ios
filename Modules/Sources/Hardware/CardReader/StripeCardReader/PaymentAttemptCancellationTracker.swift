import Foundation

/// Tracks cancellation independently from Stripe's PaymentIntent, which may not exist yet when cancellation is requested.
final class PaymentAttemptCancellationTracker {
    private let lock = NSLock()
    private var storedActiveAttemptID: UUID?
    private var canceledAttemptIDs: Set<UUID> = []
    private var cancellationIDs: [UUID: UUID] = [:]
    private var terminalAttemptIDs: Set<UUID> = []
    private var cancellationCompletions: [UUID: [(Result<Void, Error>) -> Void]] = [:]

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

    func cancelActiveAttempt(completion: ((Result<Void, Error>) -> Void)? = nil) -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        guard let activeAttemptID = storedActiveAttemptID else { return nil }
        canceledAttemptIDs.insert(activeAttemptID)
        if let completion {
            cancellationCompletions[activeAttemptID, default: []].append(completion)
        }
        return activeAttemptID
    }

    func beginCancellation(_ attemptID: UUID) -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        guard cancellationIDs[attemptID] == nil else { return nil }
        let cancellationID = UUID()
        cancellationIDs[attemptID] = cancellationID
        return cancellationID
    }

    func completeCancellation(_ attemptID: UUID, cancellationID: UUID, result: Result<Void, Error>, beforeCompletion: () -> Void = {}) {
        lock.lock()
        guard cancellationIDs[attemptID] == cancellationID else {
            lock.unlock()
            return
        }
        cancellationIDs[attemptID] = nil
        let completions = cancellationCompletions.removeValue(forKey: attemptID) ?? []
        let isTerminal = terminalAttemptIDs.remove(attemptID) != nil
        switch (isTerminal, result) {
        case (true, _), (_, .success):
            canceledAttemptIDs.remove(attemptID)
            if storedActiveAttemptID == attemptID {
                storedActiveAttemptID = nil
            }
        default:
            break
        }
        lock.unlock()
        beforeCompletion()
        completions.forEach { $0(result) }
    }

    func isCanceled(_ attemptID: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return canceledAttemptIDs.contains(attemptID)
    }

    func finishAttempt(_ attemptID: UUID) {
        lock.lock()
        // Confirmed payment completion cannot release callers while an SDK cancellation callback is still pending.
        if cancellationIDs[attemptID] != nil {
            terminalAttemptIDs.insert(attemptID)
            lock.unlock()
            return
        }
        let completions = cancellationCompletions.removeValue(forKey: attemptID) ?? []
        canceledAttemptIDs.remove(attemptID)
        if storedActiveAttemptID == attemptID {
            storedActiveAttemptID = nil
        }
        lock.unlock()
        completions.forEach { $0(.success(())) }
    }
}
