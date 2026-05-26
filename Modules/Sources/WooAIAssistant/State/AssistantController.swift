import Foundation
import Observation

@MainActor
@Observable
public final class AssistantController {

    public let conversation: AssistantConversation
    public let telemetryTracker: AssistantTelemetryTracker

    private let backend: AssistantBackend
    private let context: AssistantContext
    private let idGenerator: AssistantIdGenerator
    private let clock: SystemClock

    private(set) var activeTask: Task<Void, Never>?
    private var activeTurnToken: UUID?
    private var activeAssistantMessageID: ChatMessage.ID?
    private var activeTelemetryContext: AssistantTelemetryContext?
    private var activeTurnStartMs: Int64?
    private var activeTurnIsRetry: Bool = false
    private var conversationStartedTracked = false

    public init(backend: AssistantBackend,
                context: AssistantContext,
                conversation: AssistantConversation? = nil,
                telemetryTracker: AssistantTelemetryTracker = NoopAssistantTelemetryTracker(),
                idGenerator: AssistantIdGenerator = UUIDAssistantIdGenerator(),
                clock: SystemClock = MonotonicSystemClock()) {
        self.backend = backend
        self.context = context
        self.conversation = conversation ?? AssistantConversation(idGenerator: idGenerator)
        self.telemetryTracker = telemetryTracker
        self.idGenerator = idGenerator
        self.clock = clock
    }

    public func send(_ prompt: String) {
        send(prompt, isRetry: false)
    }

    public func retry(_ prompt: String) {
        send(prompt, isRetry: true)
    }

    /// Convenience entry point for the error-banner "Retry" affordance: walks the transcript
    /// backwards to find the most recent merchant prompt and re-fires it through `retry(_:)`.
    /// No-ops when a turn is already in flight or no user prompt exists, so the UI can wire
    /// this directly to a button without extra guards. Like `retry(_:)`, this re-appends a
    /// user message bubble - duplicate-bubble UX is a known limitation tracked separately.
    public func retryLastFailedTurn() {
        guard canSend else { return }
        guard let lastUserText = mostRecentUserPromptText() else { return }
        retry(lastUserText)
    }

    private func mostRecentUserPromptText() -> String? {
        for message in conversation.messages.reversed() where message.role == .user {
            var combined = ""
            for segment in message.segments {
                if case .text(_, let content) = segment {
                    combined += content
                }
            }
            let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }

    private func send(_ prompt: String, isRetry: Bool) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, activeTask == nil else { return }
        _ = conversation.appendUserMessage(trimmed)
        let assistantMessageID = conversation.beginAssistantMessage()
        activeAssistantMessageID = assistantMessageID
        conversation.setStreaming(.sending)
        let token = UUID()
        activeTurnToken = token
        let telemetryContext = AssistantTelemetryContext(
            conversationID: conversation.conversationID,
            requestID: idGenerator.nextID(),
            messageID: assistantMessageID.uuidString
        )
        activeTelemetryContext = telemetryContext
        activeTurnStartMs = clock.nowMs()
        activeTurnIsRetry = isRetry
        conversation.recordTelemetryContext(telemetryContext, for: assistantMessageID)
        if !conversationStartedTracked {
            conversationStartedTracked = true
            telemetryTracker.track(.conversationStarted(context: telemetryContext))
        }
        telemetryTracker.track(.turnStarted(context: telemetryContext,
                                            isRetry: isRetry,
                                            completionStack: AssistantTelemetryConstants.completionStack,
                                            promptVersion: AssistantTelemetryConstants.promptVersion,
                                            toolCatalogVersion: AssistantTelemetryConstants.toolCatalogVersion))
        activeTask = Task { [weak self] in
            await self?.run(prompt: trimmed,
                            assistantMessageID: assistantMessageID,
                            telemetryContext: telemetryContext,
                            isRetry: isRetry,
                            token: token)
        }
    }

    public func cancel() {
        let cancelledContext = activeTelemetryContext
        let startedAt = activeTurnStartMs
        let wasRetry = activeTurnIsRetry
        activeTask?.cancel()
        activeTask = nil
        activeTurnToken = nil
        if let messageID = activeAssistantMessageID {
            conversation.markCancelled(messageID: messageID)
        }
        activeAssistantMessageID = nil
        activeTelemetryContext = nil
        activeTurnStartMs = nil
        activeTurnIsRetry = false
        for proposalID in pendingProposalIDs() {
            conversation.applyConfirmationResolution(proposalID: proposalID, approved: false)
            cancelProposal(proposalID)
        }
        conversation.setStreaming(.idle)
        if let cancelledContext, let startedAt {
            telemetryTracker.suppressToolEvents(for: cancelledContext.requestID)
            let duration = max(0, clock.nowMs() - startedAt)
            telemetryTracker.track(.turnCompleted(context: cancelledContext,
                                                  outcome: .cancelledByUser,
                                                  durationMs: duration,
                                                  errorKind: nil,
                                                  isRetry: wasRetry,
                                                  completionStack: AssistantTelemetryConstants.completionStack,
                                                  promptVersion: AssistantTelemetryConstants.promptVersion,
                                                  toolCatalogVersion: AssistantTelemetryConstants.toolCatalogVersion))
        }
    }

    private func pendingProposalIDs() -> [UUID] {
        var ids: [UUID] = []
        for message in conversation.messages {
            for segment in message.segments {
                if case .confirmation(_, let proposalID, _, _, .pending) = segment {
                    ids.append(proposalID)
                }
            }
        }
        return ids
    }

    public func startNewConversation() {
        cancel()
        let token = UUID()
        activeTurnToken = token
        activeTask = Task { [weak self] in
            guard let self else { return }
            await backend.reset()
            guard activeTurnToken == token else { return }
            conversation.reset()
            conversationStartedTracked = false
            activeTask = nil
            activeTurnToken = nil
        }
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
                     telemetryContext: AssistantTelemetryContext,
                     isRetry: Bool,
                     token: UUID) async {
        let turn = AssistantTurn(prompt: prompt,
                                 telemetryContext: telemetryContext)
        let stream = backend.send(turn: turn,
                                  context: context,
                                  session: conversation.session)
        var observedOutcome: LoopOutcome?
        var observedTerminalError: AssistantError?
        var sawCompleted = false
        do {
            for try await yield in stream {
                if Task.isCancelled { break }
                guard activeTurnToken == token else { break }
                switch yield {
                case .event(let event):
                    switch event {
                    case .terminated(let outcome):
                        observedOutcome = outcome
                    case .failed(let error) where error.kind != .outcomeUnknown:
                        observedTerminalError = error
                    case .completed:
                        sawCompleted = true
                    default:
                        break
                    }
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
                let assistantError = (error as? AssistantError)
                    ?? AssistantError(kind: .unknown, message: error.localizedDescription)
                observedTerminalError = assistantError
                conversation.apply(.failed(assistantError), to: assistantMessageID)
            }
        }
        if activeTurnToken == token {
            emitTurnCompletedIfNeeded(context: telemetryContext,
                                      observedOutcome: observedOutcome,
                                      observedTerminalError: observedTerminalError,
                                      sawCompleted: sawCompleted,
                                      isRetry: isRetry)
        }
        if activeTurnToken == token {
            activeTask = nil
            activeTurnToken = nil
            activeAssistantMessageID = nil
            activeTelemetryContext = nil
            activeTurnStartMs = nil
            activeTurnIsRetry = false
        }
    }

    private func emitTurnCompletedIfNeeded(context: AssistantTelemetryContext,
                                           observedOutcome: LoopOutcome?,
                                           observedTerminalError: AssistantError?,
                                           sawCompleted: Bool,
                                           isRetry: Bool) {
        guard let startedAt = activeTurnStartMs else { return }
        let outcome: AssistantTelemetryOutcome
        let errorKind: AssistantTelemetryErrorKind?
        if let observedOutcome {
            outcome = AssistantOutcomeMapper.map(observedOutcome)
            if case .failed(let error) = observedOutcome, outcome == .failed {
                errorKind = AssistantErrorKindMapper.map(error)
            } else {
                errorKind = nil
            }
        } else if let observedTerminalError {
            outcome = .failed
            errorKind = AssistantErrorKindMapper.map(observedTerminalError)
        } else if sawCompleted {
            outcome = .success
            errorKind = nil
        } else {
            outcome = .failed
            errorKind = .unknown
        }
        let duration = max(0, clock.nowMs() - startedAt)
        telemetryTracker.track(.turnCompleted(context: context,
                                              outcome: outcome,
                                              durationMs: duration,
                                              errorKind: errorKind,
                                              isRetry: isRetry,
                                              completionStack: AssistantTelemetryConstants.completionStack,
                                              promptVersion: AssistantTelemetryConstants.promptVersion,
                                              toolCatalogVersion: AssistantTelemetryConstants.toolCatalogVersion))
    }
}
