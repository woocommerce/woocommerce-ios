import Foundation
import CocoaLumberjackSwift

/// `AssistantBackend` adapter that drives the chat UI through `AgenticLoopOrchestrator`.
public final class AgenticChatBackend: AssistantBackendConfirming, Sendable {

    private let orchestrator: AgenticLoopOrchestrator
    private let transcript = TranscriptStore()
    private let systemPromptProvider: @Sendable () -> String?
    private let historyBudgeter: HistoryBudgeter

    public init(chatService: AIChatService,
                toolRegistry: ToolRegistry? = nil,
                safetyPolicy: SafetyPolicy = AlwaysExecuteSafetyPolicy(),
                systemPromptProvider: @escaping @Sendable () -> String? = { nil },
                historyBudgeter: HistoryBudgeter = SlidingWindowHistoryBudgeter(),
                maxIterations: Int = AgenticLoopOrchestrator.defaultMaxIterations) {
        self.systemPromptProvider = systemPromptProvider
        self.historyBudgeter = historyBudgeter
        self.orchestrator = AgenticLoopOrchestrator(chatService: chatService,
                                                    toolRegistry: toolRegistry,
                                                    safetyPolicy: safetyPolicy,
                                                    systemPrompt: nil,
                                                    maxIterations: maxIterations)
    }

    public convenience init(chatService: AIChatService,
                            toolRegistry: ToolRegistry? = nil,
                            safetyPolicy: SafetyPolicy = AlwaysExecuteSafetyPolicy(),
                            systemPrompt: String?,
                            historyBudgeter: HistoryBudgeter = SlidingWindowHistoryBudgeter(),
                            maxIterations: Int = AgenticLoopOrchestrator.defaultMaxIterations) {
        let captured = systemPrompt
        self.init(chatService: chatService,
                  toolRegistry: toolRegistry,
                  safetyPolicy: safetyPolicy,
                  systemPromptProvider: { captured },
                  historyBudgeter: historyBudgeter,
                  maxIterations: maxIterations)
    }

    public func send(turn: AssistantTurn,
                     context: AssistantContext,
                     session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [orchestrator, transcript, systemPromptProvider, historyBudgeter] in
                let rawTranscript = await transcript.messages()
                let systemMessage: OpenAIChat.Message? = systemPromptProvider().map {
                    .init(role: .system, content: $0)
                }
                let prior = historyBudgeter.budget(systemPrompt: systemMessage,
                                                   priorMessages: rawTranscript,
                                                   currentUserPrompt: turn.prompt)

                var pendingText = ""
                var pendingToolCalls: [OpenAIChat.ToolCall] = []
                var pendingToolResults: [(String, String)] = []
                var didFail = false

                do {
                    for try await event in orchestrator.run(prompt: turn.prompt,
                                                            priorMessages: prior) {
                        Self.accumulate(event,
                                        text: &pendingText,
                                        toolCalls: &pendingToolCalls,
                                        toolResults: &pendingToolResults)
                        if case .failed(let err) = event, err.kind != .outcomeUnknown {
                            didFail = true
                        }
                        continuation.yield(.event(event))
                    }
                } catch {
                    didFail = true
                    let message = (error as? AssistantError)?.message ?? error.localizedDescription
                    continuation.yield(.event(.failed(.init(kind: .unknown, message: message))))
                }

                if !didFail && !Task.isCancelled {
                    let (sanitizedToolCalls, sanitizedToolResults) =
                        Self.matchedPairs(toolCalls: pendingToolCalls,
                                          toolResults: pendingToolResults)
                    await transcript.append(userPrompt: turn.prompt,
                                            assistantText: pendingText,
                                            toolCalls: sanitizedToolCalls,
                                            toolResults: sanitizedToolResults)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // OpenAI rejects an assistant `tool_calls[i]` without a matching `tool` result,
    // and requires `tool` messages in the same order as the assistant's `tool_calls`.
    static func matchedPairs(toolCalls: [OpenAIChat.ToolCall],
                             toolResults: [(String, String)])
    -> ([OpenAIChat.ToolCall], [(String, String)]) {
        let resultsByID = Dictionary(toolResults.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        let matchedCalls = toolCalls.filter { resultsByID[$0.id] != nil }
        let matchedResults = matchedCalls.compactMap { call -> (String, String)? in
            guard let payload = resultsByID[call.id] else { return nil }
            return (call.id, payload)
        }
        return (matchedCalls, matchedResults)
    }

    public func reset() async {
        await transcript.reset()
    }

    public func confirmProposal(_ id: UUID) async {
        await orchestrator.confirm(proposalID: id)
    }

    public func cancelProposal(_ id: UUID) async {
        await orchestrator.cancel(proposalID: id)
    }

    private static func accumulate(_ event: AssistantEvent,
                                   text: inout String,
                                   toolCalls: inout [OpenAIChat.ToolCall],
                                   toolResults: inout [(String, String)]) {
        switch event {
        case .textChunk(let chunk):
            text += chunk
        case .toolCallStarted(let id, let name, let argumentsJSON):
            toolCalls.append(.init(id: id,
                                   function: .init(name: name,
                                                   arguments: argumentsJSON ?? "")))
        case .toolCallCompleted(let id, _, let resultJSON):
            toolResults.append((id, resultJSON ?? "{}"))
        case .toolResult, .cardRender, .confirmationRequired,
             .confirmationResolved, .completed, .failed:
            break
        }
    }
}

private actor TranscriptStore {

    private var stored: [OpenAIChat.Message] = []

    func messages() -> [OpenAIChat.Message] { stored }

    func append(userPrompt: String,
                assistantText: String,
                toolCalls: [OpenAIChat.ToolCall],
                toolResults: [(String, String)]) {
        stored.append(.init(role: .user, content: userPrompt))
        if !toolCalls.isEmpty {
            stored.append(.init(role: .assistant, content: nil, toolCalls: toolCalls))
            for (callID, payload) in toolResults {
                stored.append(.init(role: .tool, content: payload, toolCallID: callID))
            }
        }
        if !assistantText.isEmpty {
            stored.append(.init(role: .assistant, content: assistantText))
        }
    }

    func reset() { stored.removeAll() }
}
