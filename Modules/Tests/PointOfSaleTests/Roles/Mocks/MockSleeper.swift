import Testing

/// Suspends each sleep until the test resumes it.
@MainActor
final class MockSleeper {
    let calls: AsyncStream<Duration>
    private(set) var durations: [Duration] = []
    private let callContinuation: AsyncStream<Duration>.Continuation
    private var pending: [CheckedContinuation<Void, Never>] = []
    private var isFinished = false

    init() {
        let stream = AsyncStream<Duration>.makeStream()
        calls = stream.stream
        callContinuation = stream.continuation
    }

    func sleep(_ duration: Duration) async throws {
        guard !isFinished else {
            throw CancellationError()
        }
        await withCheckedContinuation { continuation in
            pending.append(continuation)
            durations.append(duration)
            // Store the gate before signalling readiness; both operations run on the main actor.
            callContinuation.yield(duration)
        }
        try Task.checkCancellation()
    }

    func resumeNext() {
        guard !pending.isEmpty else {
            Issue.record("No sleep is pending")
            return
        }
        pending.removeFirst().resume()
    }

    func finish() {
        isFinished = true
        let continuations = pending
        pending.removeAll()
        continuations.forEach { $0.resume() }
        callContinuation.finish()
    }
}
