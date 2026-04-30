import Foundation
import CocoaLumberjackSwift

/// `AssistantBackend` adapter that drives the chat UI through the `AgenticLoopOrchestrator`.
///
/// Wraps a long-lived orchestrator so multi-turn memory survives between sends. Each turn
/// builds a fresh prompt prefix from the per-instance `TranscriptStore` actor and the
/// caller-supplied `systemPromptProvider` so the embedded date stays current across midnight.
///
/// Forwards confirm/cancel taps from the UI straight into the orchestrator's continuation API
/// so unsafe-tool flows resume on the same actor that suspended them.
public final class AgenticChatBackend: AssistantBackendConfirming, Sendable {

    private let orchestrator: AgenticLoopOrchestrator
    private let transcript = TranscriptStore()
    private let systemPromptProvider: @Sendable () -> String?

    /// Per-turn `systemPromptProvider` rebuild keeps the embedded date fresh when a
    /// session spans midnight, which `AssistantSystemPrompt.build()` cares about.
    public init(chatService: AIChatService,
                toolRegistry: ToolRegistry? = nil,
                safetyPolicy: SafetyPolicy = AlwaysExecuteSafetyPolicy(),
                systemPromptProvider: @escaping @Sendable () -> String? = { nil },
                maxIterations: Int = AgenticLoopOrchestrator.defaultMaxIterations) {
        self.systemPromptProvider = systemPromptProvider
        self.orchestrator = AgenticLoopOrchestrator(chatService: chatService,
                                                    toolRegistry: toolRegistry,
                                                    safetyPolicy: safetyPolicy,
                                                    systemPrompt: nil,
                                                    maxIterations: maxIterations)
    }

    /// Static-prompt convenience for tests and callers that don't need per-turn
    /// freshness.
    public convenience init(chatService: AIChatService,
                            toolRegistry: ToolRegistry? = nil,
                            safetyPolicy: SafetyPolicy = AlwaysExecuteSafetyPolicy(),
                            systemPrompt: String?,
                            maxIterations: Int = AgenticLoopOrchestrator.defaultMaxIterations) {
        let captured = systemPrompt
        self.init(chatService: chatService,
                  toolRegistry: toolRegistry,
                  safetyPolicy: safetyPolicy,
                  systemPromptProvider: { captured },
                  maxIterations: maxIterations)
    }

    public func send(turn: AssistantTurn,
                     context: AssistantContext,
                     session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [orchestrator, transcript, systemPromptProvider] in
                var prior = await transcript.messages()
                if let systemPrompt = systemPromptProvider() {
                    prior.insert(.init(role: .system, content: systemPrompt), at: 0)
                }

                var pendingText = ""
                var pendingToolCalls: [OpenAIChat.ToolCall] = []
                var pendingToolResults: [(String, String)] = []

                do {
                    for try await event in orchestrator.run(prompt: turn.prompt,
                                                            priorMessages: prior) {
                        Self.accumulate(event,
                                        text: &pendingText,
                                        toolCalls: &pendingToolCalls,
                                        toolResults: &pendingToolResults)
                        continuation.yield(.event(event))
                    }
                } catch {
                    let message = (error as? AssistantError)?.message ?? error.localizedDescription
                    continuation.yield(.event(.failed(.init(kind: .unknown, message: message))))
                }

                let (sanitizedToolCalls, sanitizedToolResults) =
                    Self.matchedPairs(toolCalls: pendingToolCalls,
                                      toolResults: pendingToolResults)
                await transcript.append(userPrompt: turn.prompt,
                                        assistantText: pendingText,
                                        toolCalls: sanitizedToolCalls,
                                        toolResults: sanitizedToolResults)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// OpenAI rejects an `assistant.tool_calls[i]` without a matching `tool`
    /// message with the same `tool_call_id`. When the orchestrator throws
    /// (or the transport drops) between `toolCallStarted` and
    /// `toolCallCompleted`, dropping the unmatched pairs keeps the next turn
    /// replay valid instead of leaving the chat unrecoverable.
    static func matchedPairs(toolCalls: [OpenAIChat.ToolCall],
                             toolResults: [(String, String)])
    -> ([OpenAIChat.ToolCall], [(String, String)]) {
        let resultIDs = Set(toolResults.map(\.0))
        let matchedCalls = toolCalls.filter { resultIDs.contains($0.id) }
        let matchedCallIDs = Set(matchedCalls.map(\.id))
        let matchedResults = toolResults.filter { matchedCallIDs.contains($0.0) }
        return (matchedCalls, matchedResults)
    }

    /// Drop accumulated history. Call when the merchant starts a fresh chat.
    public func reset() async {
        await transcript.reset()
    }

    public func confirmProposal(_ id: UUID) async {
        await orchestrator.confirm(proposalID: id)
    }

    public func cancelProposal(_ id: UUID) async {
        await orchestrator.cancel(proposalID: id)
    }

    /// `toolCallStarted` records the call shape so the next-turn prefix has
    /// `assistant tool_calls` followed by the matching `tool` results, which
    /// is the wire shape the upstream proxy validates.
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

/// Holds the prefix the next turn needs - user prompts, assistant tool-call messages,
/// and tool result messages in wire-protocol order. Actor isolation keeps the prefix
/// consistent if a confirmation tap arrives while the loop is mid-turn.
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
