import Foundation
@testable import WooAIAssistant

/// Test double for `AssistantBackend` that yields scripted `BackendYield`
/// sequences and exposes per-turn lifecycle signals so tests can wait on
/// deterministic events instead of polling MainActor with `Task.yield`.
actor MockAssistantBackend: AssistantBackendConfirming {

    typealias OnSendStarted = @Sendable (AssistantTurn) -> Void

    var scriptedYields: [[BackendYield]] = []
    private(set) var receivedTurns: [AssistantTurn] = []
    private(set) var confirmedProposalIDs: [UUID] = []
    private(set) var cancelledProposalIDs: [UUID] = []

    /// Auto-finish each turn's stream right after yielding the scripted
    /// events. Tests that need to interleave a stale turn's cleanup with
    /// a newer turn flip this to false and call `finishOldestStream()`.
    var autoFinishStreams = true

    /// Stream continuations queued in FIFO order so a freeze-fix test can
    /// finish the older turn after the newer turn has already started.
    private var pendingContinuations: [AsyncThrowingStream<BackendYield, Error>.Continuation] = []
    private var onSendStarted: OnSendStarted?

    /// Per-turn lifecycle signals. Indices are `receivedTurns` ordinals so
    /// `awaitTurnStarted(at: 0)` resolves once the first turn's `start()`
    /// has yielded its scripted events. `awaitTurnFinished(at:)` resolves
    /// when that turn's stream continuation finishes, whether via auto
    /// finish, `finishOldestStream`, or consumer cancellation.
    private var startedContinuations: [CheckedContinuation<Void, Never>?] = []
    private var startedFlags: [Bool] = []
    private var finishedContinuations: [CheckedContinuation<Void, Never>?] = []
    private var finishedFlags: [Bool] = []

    /// One-shot continuations resumed when a cancel/confirm lands so the
    /// proposal forwarding test stays deterministic.
    private var cancelContinuations: [UUID: CheckedContinuation<Void, Never>] = [:]
    private var confirmContinuations: [UUID: CheckedContinuation<Void, Never>] = [:]

    func setScriptedYields(_ yields: [[BackendYield]]) {
        scriptedYields = yields
    }

    func setAutoFinishStreams(_ value: Bool) {
        autoFinishStreams = value
    }

    func setOnSendStarted(_ closure: OnSendStarted?) {
        onSendStarted = closure
    }

    nonisolated func send(turn: AssistantTurn,
                          context: AssistantContext,
                          session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        AsyncThrowingStream { continuation in
            Task { await self.start(turn: turn, continuation: continuation) }
        }
    }

    func confirmProposal(_ id: UUID) async {
        confirmedProposalIDs.append(id)
        if let continuation = confirmContinuations.removeValue(forKey: id) {
            continuation.resume()
        }
    }

    func cancelProposal(_ id: UUID) async {
        cancelledProposalIDs.append(id)
        if let continuation = cancelContinuations.removeValue(forKey: id) {
            continuation.resume()
        }
    }

    /// Finish the oldest still-open stream. Tests use this to simulate a
    /// stale turn completing after a newer turn has already started.
    func finishOldestStream() {
        guard !pendingContinuations.isEmpty else { return }
        let continuation = pendingContinuations.removeFirst()
        continuation.finish()
    }

    func pendingStreamCount() -> Int {
        pendingContinuations.count
    }

    func awaitTurnStarted(at index: Int) async {
        ensureSignalCapacity(forIndex: index)
        if startedFlags[index] { return }
        await withCheckedContinuation { continuation in
            startedContinuations[index] = continuation
        }
    }

    func awaitTurnFinished(at index: Int) async {
        ensureSignalCapacity(forIndex: index)
        if finishedFlags[index] { return }
        await withCheckedContinuation { continuation in
            finishedContinuations[index] = continuation
        }
    }

    func awaitProposalCancelled(_ id: UUID) async {
        if cancelledProposalIDs.contains(id) { return }
        await withCheckedContinuation { continuation in
            cancelContinuations[id] = continuation
        }
    }

    private func start(turn: AssistantTurn,
                       continuation: AsyncThrowingStream<BackendYield, Error>.Continuation) {
        let turnIndex = receivedTurns.count
        receivedTurns.append(turn)
        ensureSignalCapacity(forIndex: turnIndex)

        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.markFinished(at: turnIndex) }
        }

        let yields = scriptedYields.isEmpty ? [] : scriptedYields.removeFirst()
        for yield in yields {
            continuation.yield(yield)
        }
        onSendStarted?(turn)

        startedFlags[turnIndex] = true
        if let waiter = startedContinuations[turnIndex] {
            startedContinuations[turnIndex] = nil
            waiter.resume()
        }

        if autoFinishStreams {
            continuation.finish()
        } else {
            pendingContinuations.append(continuation)
        }
    }

    private func markFinished(at index: Int) {
        ensureSignalCapacity(forIndex: index)
        if finishedFlags[index] { return }
        finishedFlags[index] = true
        if let waiter = finishedContinuations[index] {
            finishedContinuations[index] = nil
            waiter.resume()
        }
    }

    private func ensureSignalCapacity(forIndex index: Int) {
        while startedFlags.count <= index {
            startedFlags.append(false)
            startedContinuations.append(nil)
            finishedFlags.append(false)
            finishedContinuations.append(nil)
        }
    }
}
