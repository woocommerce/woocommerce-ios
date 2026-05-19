import Foundation
@testable import WooAIAssistant

@MainActor
final class MockAssistantBackend: AssistantBackendConfirming {

    private(set) var recordedTurns: [AssistantTurn] = []
    private(set) var confirmedProposalIDs: [UUID] = []
    private(set) var cancelledProposalIDs: [UUID] = []
    private(set) var resetCallCount: Int = 0

    private var scripts: [[BackendYield]] = []
    private var heldIndices: Set<Int> = []
    private var pendingByIndex: [Int: AsyncThrowingStream<BackendYield, Error>.Continuation] = [:]
    private var resetGate: CheckedContinuation<Void, Never>?
    private var resetIsHeld = false
    private var resetWaiter: CheckedContinuation<Void, Never>?
    private var cancelledProposalWaiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    func script(_ events: [BackendYield]) {
        scripts.append(events)
    }

    func script(_ scripts: [[BackendYield]]) {
        for entry in scripts { self.scripts.append(entry) }
    }

    func holdStream(at index: Int) {
        heldIndices.insert(index)
    }

    func releaseStream(at index: Int) {
        heldIndices.remove(index)
        guard let continuation = pendingByIndex.removeValue(forKey: index) else { return }
        continuation.finish()
    }

    func send(turn: AssistantTurn,
              context: AssistantContext,
              session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        let index = recordTurn(turn)
        return AsyncThrowingStream { continuation in
            self.start(index: index, continuation: continuation)
        }
    }

    func confirmProposal(_ id: UUID) async {
        recordConfirmedProposal(id)
    }

    func cancelProposal(_ id: UUID) async {
        recordCancelledProposal(id)
    }

    func reset() async {
        resetCallCount += 1
        if resetIsHeld {
            await withCheckedContinuation { continuation in
                resetGate = continuation
                resetWaiter?.resume()
                resetWaiter = nil
            }
        } else {
            resetWaiter?.resume()
            resetWaiter = nil
        }
    }

    func holdReset() {
        resetIsHeld = true
    }

    func releaseReset() {
        resetIsHeld = false
        resetGate?.resume()
        resetGate = nil
    }

    func waitForResetCall() async {
        if resetCallCount > 0 { return }
        await withCheckedContinuation { continuation in
            resetWaiter = continuation
        }
    }

    func waitForCancelledProposal(_ id: UUID) async {
        if cancelledProposalIDs.contains(id) { return }
        await withCheckedContinuation { continuation in
            cancelledProposalWaiters[id] = continuation
        }
    }

    private func recordTurn(_ turn: AssistantTurn) -> Int {
        let index = recordedTurns.count
        recordedTurns.append(turn)
        return index
    }

    private func start(index: Int,
                       continuation: AsyncThrowingStream<BackendYield, Error>.Continuation) {
        let events = scripts.isEmpty ? [] : scripts.removeFirst()
        for event in events { continuation.yield(event) }
        if heldIndices.contains(index) {
            pendingByIndex[index] = continuation
        } else {
            continuation.finish()
        }
    }

    private func recordConfirmedProposal(_ id: UUID) {
        confirmedProposalIDs.append(id)
    }

    private func recordCancelledProposal(_ id: UUID) {
        cancelledProposalIDs.append(id)
        cancelledProposalWaiters.removeValue(forKey: id)?.resume()
    }
}
