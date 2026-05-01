import Foundation
import Observation

/// Routes merchant intents into `AssistantBackend` and applies events to `AssistantConversation`.
@MainActor
@Observable
public final class AssistantController {

    public let conversation: AssistantConversation

    private let backend: AssistantBackend
    private let context: AssistantContext

    private(set) var activeTask: Task<Void, Never>?
    private var activeTurnToken: UUID?
    private var activeAssistantMessageID: ChatMessage.ID?

    public init(backend: AssistantBackend,
                context: AssistantContext,
                conversation: AssistantConversation? = nil) {
        self.backend = backend
        self.context = context
        self.conversation = conversation ?? AssistantConversation()
    }

    public func send(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, activeTask == nil else { return }
        _ = conversation.appendUserMessage(trimmed)
        let assistantMessageID = conversation.beginAssistantMessage()
        activeAssistantMessageID = assistantMessageID
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
        if let messageID = activeAssistantMessageID {
            conversation.markCancelled(messageID: messageID)
        }
        activeAssistantMessageID = nil
        conversation.setStreaming(.idle)
    }

    public var canSend: Bool {
        activeTask == nil
    }

    public func confirmProposal(_ id: UUID) {
        guard let gate = backend as? AssistantBackendConfirming else { return }
        Task { await gate.confirmProposal(id) }
    }

    public func cancelProposal(_ id: UUID) {
        guard let gate = backend as? AssistantBackendConfirming else { return }
        Task { await gate.cancelProposal(id) }
    }

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
            activeAssistantMessageID = nil
        }
    }
}
