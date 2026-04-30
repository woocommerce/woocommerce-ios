import Foundation
import Observation

/// Coordinates merchant intents against an `AssistantBackend` and routes the
/// resulting events into an `AssistantConversation`. The chat UI talks to the
/// controller, never directly to the backend, so backends can swap freely.
@MainActor
@Observable
public final class AssistantController {

    public let conversation: AssistantConversation

    private let backend: AssistantBackend
    private let context: AssistantContext
    private var activeTask: Task<Void, Never>?

    /// Per-turn UUID captured at `run()` entry. The cleanup at exit only clears
    /// `activeTask` when this token is still the active one. A newer `send()`
    /// bumps the token, so a stale turn finishing late cannot nil out the
    /// in-flight turn's reference - using `Task` identity instead has bitten
    /// this controller before with a "follow-up question freezes the chat"
    /// repro that survives because Task equality is not what intuition suggests
    /// under cancellation.
    private var activeTurnToken: UUID?

    public init(backend: AssistantBackend,
                context: AssistantContext,
                conversation: AssistantConversation? = nil) {
        self.backend = backend
        self.context = context
        self.conversation = conversation ?? AssistantConversation()
    }

    // MARK: - Intents

    public func send(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, activeTask == nil else { return }
        _ = conversation.appendUserMessage(trimmed)
        let assistantMessageID = conversation.beginAssistantMessage()
        conversation.setStreaming(.sending)
        let token = UUID()
        activeTurnToken = token
        activeTask = Task { [weak self] in
            await self?.run(prompt: trimmed,
                            assistantMessageID: assistantMessageID,
                            token: token)
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
        activeTurnToken = nil
        conversation.setStreaming(.idle)
    }

    /// `false` while a turn is in flight OR while a confirmation segment is
    /// awaiting the merchant's tap; either way the input bar disables.
    public var canSend: Bool {
        activeTask == nil
    }

    // MARK: - Confirmation forwarders

    public func confirmProposal(_ id: UUID) {
        guard let gate = backend as? AssistantBackendConfirming else { return }
        Task { await gate.confirmProposal(id) }
    }

    public func cancelProposal(_ id: UUID) {
        guard let gate = backend as? AssistantBackendConfirming else { return }
        Task { await gate.cancelProposal(id) }
    }

    // MARK: - Run loop

    private func run(prompt: String,
                     assistantMessageID: ChatMessage.ID,
                     token: UUID) async {
        let turn = AssistantTurn(prompt: prompt)
        let stream = backend.send(turn: turn,
                                  context: context,
                                  session: conversation.session)
        do {
            for try await yield in stream {
                if Task.isCancelled { break }
                guard activeTurnToken == token else { break }
                switch yield {
                case .event(let event):
                    conversation.apply(event, to: assistantMessageID)
                    if case .textChunk = event {
                        conversation.setStreaming(.streaming)
                    }
                case .sessionUpdate(let session):
                    conversation.replaceSession(session)
                }
            }
            if activeTurnToken == token {
                switch conversation.streamingState {
                case .failed, .outcomeUnknown:
                    break
                default:
                    conversation.setStreaming(.idle)
                }
            }
        } catch {
            if activeTurnToken == token {
                let message = (error as? AssistantError)?.message ?? error.localizedDescription
                conversation.apply(.failed(.init(kind: .unknown, message: message)),
                                   to: assistantMessageID)
            }
        }
        if activeTurnToken == token {
            activeTask = nil
            activeTurnToken = nil
        }
    }
}
