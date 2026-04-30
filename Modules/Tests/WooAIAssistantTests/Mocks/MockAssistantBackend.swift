import Foundation
@testable import WooAIAssistant

/// Test double for `AssistantBackend` that yields scripted `BackendYield`
/// sequences and exposes per-stream finish control so tests can keep a
/// turn's stream open while a newer turn runs in parallel - the scenario
/// the controller's per-turn UUID token has to survive.
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
    }

    func cancelProposal(_ id: UUID) async {
        cancelledProposalIDs.append(id)
    }

    /// Finish the oldest still-open stream. Tests use this to simulate a
    /// stale turn completing after a newer turn has already started.
    func finishOldestStream() {
        guard !pendingContinuations.isEmpty else { return }
        pendingContinuations.removeFirst().finish()
    }

    func pendingStreamCount() -> Int {
        pendingContinuations.count
    }

    private func start(turn: AssistantTurn,
                       continuation: AsyncThrowingStream<BackendYield, Error>.Continuation) {
        receivedTurns.append(turn)
        let yields = scriptedYields.isEmpty ? [] : scriptedYields.removeFirst()
        for yield in yields {
            continuation.yield(yield)
        }
        onSendStarted?(turn)
        if autoFinishStreams {
            continuation.finish()
        } else {
            pendingContinuations.append(continuation)
        }
    }
}
