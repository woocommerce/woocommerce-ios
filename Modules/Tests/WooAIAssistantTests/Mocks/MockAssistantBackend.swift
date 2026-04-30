import Foundation
@testable import WooAIAssistant

@MainActor
final class MockAssistantBackend: AssistantBackendConfirming {

    private(set) var recordedTurns: [AssistantTurn] = []
    private(set) var confirmedProposalIDs: [UUID] = []
    private(set) var cancelledProposalIDs: [UUID] = []

    private var scripts: [[BackendYield]] = []
    private var heldIndices: Set<Int> = []
    private var pendingByIndex: [Int: AsyncThrowingStream<BackendYield, Error>.Continuation] = [:]

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

    nonisolated public func send(turn: AssistantTurn,
                                 context: AssistantContext,
                                 session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        let index = MainActor.assumeIsolated { self.recordTurn(turn) }
        return AsyncThrowingStream { continuation in
            MainActor.assumeIsolated {
                self.start(index: index, continuation: continuation)
            }
        }
    }

    public nonisolated func confirmProposal(_ id: UUID) async {
        await MainActor.run {
            self.confirmedProposalIDs.append(id)
        }
    }

    public nonisolated func cancelProposal(_ id: UUID) async {
        await MainActor.run {
            self.cancelledProposalIDs.append(id)
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
}
