import Foundation
import CocoaLumberjackSwift

/// Runs the client-side agentic loop on top of an `AIChatService`, a `ToolRegistry`, and a
/// `SafetyPolicy`.
///
/// Actor-isolated because unsafe tool calls suspend the loop while the merchant resolves a
/// confirmation card; the pending continuation has to live somewhere safe from concurrent access.
/// Callers resume the loop via `confirm(proposalID:)` / `cancel(proposalID:)`.
actor AgenticLoopOrchestrator {

    static let defaultMaxIterations = 5

    /// 4 keeps "list + 3 drill-downs" flows legitimate while catching varied-args fanouts.
    static let defaultPerToolPerTurnCap = 4

    private let chatService: AIChatService
    private let toolRegistry: ToolRegistry?
    private let safetyPolicy: SafetyPolicy
    private let systemPrompt: String?
    private let maxIterations: Int
    private let perToolPerTurnCap: Int

    private var pendingDecisions: [UUID: CheckedContinuation<Bool, Never>] = [:]

    private let diagnostics: LoopDiagnosticsHandler

    private(set) var lastOutcome: LoopOutcome?

    init(chatService: AIChatService,
         toolRegistry: ToolRegistry?,
         safetyPolicy: SafetyPolicy = AlwaysExecuteSafetyPolicy(),
         systemPrompt: String? = nil,
         maxIterations: Int = AgenticLoopOrchestrator.defaultMaxIterations,
         perToolPerTurnCap: Int = AgenticLoopOrchestrator.defaultPerToolPerTurnCap,
         diagnostics: @escaping LoopDiagnosticsHandler = noopLoopDiagnostics) {
        self.chatService = chatService
        self.toolRegistry = toolRegistry
        self.safetyPolicy = safetyPolicy
        self.systemPrompt = systemPrompt
        self.maxIterations = maxIterations
        self.perToolPerTurnCap = perToolPerTurnCap
        self.diagnostics = diagnostics
    }

    nonisolated func run(prompt: String,
                         priorMessages: [OpenAIChat.Message] = []) -> AsyncThrowingStream<AssistantEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                do {
                    try await self.runLoop(prompt: prompt,
                                           priorMessages: priorMessages,
                                           continuation: continuation)
                    continuation.finish()
                } catch let error as AssistantError {
                    await self.setOutcome(.failed(error))
                    continuation.yield(.failed(error))
                    continuation.finish()
                } catch is CancellationError {
                    await self.setOutcomeIfUnset(.stopped)
                    continuation.finish()
                } catch {
                    let assistantError = AssistantError(kind: .unknown,
                                                        message: error.localizedDescription)
                    await self.setOutcome(.failed(assistantError))
                    continuation.yield(.failed(assistantError))
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await self.handleStreamTerminated() }
            }
        }
    }

    // MARK: - External confirmation entry points

    func confirm(proposalID: UUID) {
        if let continuation = pendingDecisions.removeValue(forKey: proposalID) {
            continuation.resume(returning: true)
        }
    }

    func cancel(proposalID: UUID) {
        if let continuation = pendingDecisions.removeValue(forKey: proposalID) {
            continuation.resume(returning: false)
        }
    }

    private func cancelAllPending() {
        let pending = pendingDecisions
        pendingDecisions.removeAll()
        for continuation in pending.values {
            continuation.resume(returning: false)
        }
    }

    private func setOutcome(_ outcome: LoopOutcome) {
        lastOutcome = outcome
    }

    private func setOutcomeIfUnset(_ outcome: LoopOutcome) {
        guard lastOutcome == nil else { return }
        lastOutcome = outcome
    }

    /// Stamps `.stopped` so a post-stream `lastOutcome` query reads as a terminal state rather than nil.
    private func handleStreamTerminated() {
        cancelAllPending()
        if lastOutcome == nil {
            lastOutcome = .stopped
        }
    }

    /// Suspend the loop until the UI resolves this proposal. The pre- and post-store `Task.isCancelled`
    /// checks plus the `onCancel` hop guarantee the continuation is always resumed even if cancellation
    /// arrives between yielding `.confirmationRequired` and registering the continuation here.
    private func waitForDecision(proposalID: UUID) async -> Bool {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(returning: false)
                    return
                }
                pendingDecisions[proposalID] = continuation
                if Task.isCancelled {
                    if let stored = pendingDecisions.removeValue(forKey: proposalID) {
                        stored.resume(returning: false)
                    }
                }
            }
        } onCancel: {
            Task { await self.cancel(proposalID: proposalID) }
        }
    }

    // MARK: - Loop

    private func runLoop(prompt: String,
                         priorMessages: [OpenAIChat.Message],
                         continuation: AsyncThrowingStream<AssistantEvent, Error>.Continuation) async throws {
        var messages = buildInitialMessages(prompt: prompt, priorMessages: priorMessages)
        let tools: [AITool]
        if let registry = toolRegistry {
            do {
                tools = try await registry.availableTools()
            } catch {
                DDLogError("AgenticLoopOrchestrator availableTools failed: \(error)")
                tools = []
            }
        } else {
            tools = []
        }
        let toolDefinitions = tools.isEmpty ? nil : tools.map { Self.openAIDefinition(for: $0) }
        let toolsByName = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })

        diagnostics(.turnStarted(prompt: prompt))

        // Each guard key fires at most once so we don't spam the model with duplicate system notes.
        var firedGuards: Set<String> = []

        for _ in 0..<maxIterations {
            try Task.checkCancellation()
            applyInFlightGuards(messages: &messages,
                                toolsByName: toolsByName,
                                fired: &firedGuards)
            let outcome = try await runOneTurn(messages: messages,
                                               tools: toolDefinitions,
                                               continuation: continuation)

            switch outcome {
            case .completed:
                continuation.yield(.completed(routeConfidence: nil))
                lastOutcome = .completed
                return

            case .toolCalls(let calls):
                messages.append(.init(role: .assistant, content: "", toolCalls: calls))

                let priorSignatures = Self.computePriorCallSignatures(in: messages)
                let priorResults = Self.computePriorResultsBySignature(in: messages)
                let priorTurnTallies = Self.computePerToolPriorTallies(in: messages)

                let payloads = try await dispatchTools(calls,
                                                       toolsByName: toolsByName,
                                                       priorCallSignatures: priorSignatures,
                                                       priorResultsBySignature: priorResults,
                                                       priorPerToolTallies: priorTurnTallies,
                                                       continuation: continuation)
                for (call, payload) in zip(calls, payloads) {
                    messages.append(.init(role: .tool, content: payload, toolCallID: call.id))
                }
                continue
            }
        }

        diagnostics(.maxIterationsHit(iterations: maxIterations))
        // Soft-end the turn so the merchant sees a closing message rather than a bare error banner.
        continuation.yield(.textChunk(Localization.iterationCapClosing))
        continuation.yield(.completed(routeConfidence: nil))
        lastOutcome = .maxIterations(iterations: maxIterations)
    }

    private func runOneTurn(messages: [OpenAIChat.Message],
                            tools: [OpenAIChat.ToolDefinition]?,
                            continuation: AsyncThrowingStream<AssistantEvent, Error>.Continuation) async throws -> TurnOutcome {
        var pendingCalls: [OpenAIChat.ToolCall] = []
        var didEmitText = false
        var finishReason: OpenAIChat.FinishReason?
        var didReceiveCompletedEvent = false

        let stream = chatService.streamTurn(messages: messages,
                                            tools: tools,
                                            toolChoice: nil)
        for try await event in stream {
            try Task.checkCancellation()
            switch event {
            case .textDelta(let text):
                continuation.yield(.textChunk(text))
                didEmitText = true
            case .toolCall(let call):
                pendingCalls.append(call)
            case .completed(let reason):
                finishReason = reason
                didReceiveCompletedEvent = true
            }
        }

        // A stream ending without `.completed` is an upstream truncation, not a clean finish.
        if !didReceiveCompletedEvent {
            throw AssistantError(kind: .upstreamFailure,
                                 message: Localization.noFinishEvent)
        }

        if finishReason == .length {
            throw AssistantError(kind: .upstreamFailure,
                                 message: Localization.lengthLimitFailure)
        }

        if pendingCalls.isEmpty {
            if !didEmitText {
                continuation.yield(.textChunk(Localization.emptyResponseFallback))
            }
            return .completed
        }
        return .toolCalls(pendingCalls)
    }

    /// Dispatch every call in `calls` under the safety policy and return the per-call payloads in input
    /// order. Identical calls (across the turn or within this batch) replay the cached payload via a
    /// success-shaped `cached_result_reused` envelope rather than an error shape, because models treat
    /// the latter as retryable and keep firing variations until the iteration cap trips.
    private func dispatchTools(_ calls: [OpenAIChat.ToolCall],
                               toolsByName: [String: AITool],
                               priorCallSignatures: [String: Int],
                               priorResultsBySignature: [String: String],
                               priorPerToolTallies: [String: Int],
                               continuation: AsyncThrowingStream<AssistantEvent, Error>.Continuation)
    async throws -> [String] {
        guard let registry = toolRegistry else {
            for call in calls {
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                let payload = #"{"error":"No tool registry is configured for this client."}"#
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: payload))
            }
            return calls.map { _ in #"{"error":"No tool registry is configured for this client."}"# }
        }

        var approvedIndices: [Int] = []
        var resolvedResults = [String?](repeating: nil, count: calls.count)
        var liveSignatures = priorCallSignatures
        let liveResults = priorResultsBySignature
        var liveTurnTallies = priorPerToolTallies

        // Without intra-batch dedupe the task group fires the registry once per duplicate in parallel.
        var firstPrimaryByIntraSignature: [String: Int] = [:]
        var intraBatchSecondaryToPrimary: [Int: Int] = [:]

        for (index, call) in calls.enumerated() {
            let signature = Self.canonicalCallSignature(name: call.function.name,
                                                        argumentsJSON: call.function.arguments)
            let priorSeen = liveSignatures[signature, default: 0]
            liveSignatures[signature] = priorSeen + 1

            let priorToolCount = liveTurnTallies[call.function.name, default: 0]
            liveTurnTallies[call.function.name] = priorToolCount + 1
            if priorToolCount >= perToolPerTurnCap {
                let payload = Self.perToolCapJSON(toolName: call.function.name,
                                                  cap: perToolPerTurnCap)
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: payload))
                resolvedResults[index] = payload
                continue
            }

            if priorSeen >= 1, let cachedPayload = liveResults[signature] {
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                let replay = Self.duplicateReplayJSON(priorSeen: priorSeen,
                                                      name: call.function.name,
                                                      cachedPayload: cachedPayload)
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: replay))
                resolvedResults[index] = replay
                continue
            }

            if let primaryIndex = firstPrimaryByIntraSignature[signature] {
                intraBatchSecondaryToPrimary[index] = primaryIndex
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                continue
            }

            firstPrimaryByIntraSignature[signature] = index

            guard let tool = toolsByName[call.function.name] else {
                let payload = Self.errorJSON("Unknown tool: \(call.function.name)")
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: payload))
                resolvedResults[index] = payload
                continue
            }

            let decision = safetyPolicy.decision(for: call.function.name,
                                                 arguments: call.function.arguments,
                                                 tool: tool)
            switch decision {
            case .execute:
                approvedIndices.append(index)

            case .requireConfirmation(let preview):
                let proposal = ToolProposal(toolName: call.function.name,
                                            toolCallID: call.id,
                                            preview: preview)
                continuation.yield(.confirmationRequired(proposal: proposal))
                diagnostics(.confirmationRequested(toolName: call.function.name,
                                                   safetyLevel: tool.safetyLevel))
                let approved = await waitForDecision(proposalID: proposal.id)
                continuation.yield(.confirmationResolved(proposalID: proposal.id, approved: approved))
                diagnostics(.confirmationResolved(toolName: call.function.name, approved: approved))
                if approved {
                    approvedIndices.append(index)
                } else {
                    let payload = Self.userCancelledJSON()
                    continuation.yield(.toolCallStarted(id: call.id,
                                                        name: call.function.name,
                                                        argumentsJSON: call.function.arguments))
                    continuation.yield(.toolCallCompleted(id: call.id,
                                                          name: call.function.name,
                                                          resultJSON: payload))
                    resolvedResults[index] = payload
                }
            }
        }

        if !approvedIndices.isEmpty {
            for index in approvedIndices {
                let call = calls[index]
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
            }
            try await withThrowingTaskGroup(of: (Int, ToolResult).self) { group in
                for index in approvedIndices {
                    let call = calls[index]
                    group.addTask {
                        let result = await registry.execute(name: call.function.name,
                                                            arguments: call.function.arguments,
                                                            toolCallID: call.id)
                        return (index, result)
                    }
                }
                for try await (index, result) in group {
                    let call = calls[index]
                    let payload = self.handleToolResult(result,
                                                        for: call,
                                                        continuation: continuation)
                    resolvedResults[index] = payload
                }
            }
        }

        // Mirror primary errors/cancellations directly rather than wrapping them in a success envelope.
        for (secondaryIndex, primaryIndex) in intraBatchSecondaryToPrimary.sorted(by: { $0.key < $1.key }) {
            let call = calls[secondaryIndex]
            if let primaryPayload = resolvedResults[primaryIndex] {
                let replay: String
                if Self.payloadIsErrorOrCancelled(primaryPayload) {
                    replay = primaryPayload
                } else {
                    replay = Self.duplicateReplayJSON(priorSeen: 1,
                                                      name: call.function.name,
                                                      cachedPayload: primaryPayload)
                }
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: replay))
                resolvedResults[secondaryIndex] = replay
            } else {
                let payload = Self.errorJSON("Primary dispatch produced no result for duplicate call.")
                continuation.yield(.toolCallCompleted(id: call.id,
                                                      name: call.function.name,
                                                      resultJSON: payload))
                resolvedResults[secondaryIndex] = payload
            }
        }

        return resolvedResults.map { payload -> String in
            guard let payload else {
                assertionFailure("dispatchTools left a nil result slot - safety-branch coverage gap")
                return #"{"error":"missing tool result"}"#
            }
            return payload
        }
    }

    /// Translate a `ToolResult` into the model-visible JSON payload that ends up as the tool message
    /// content, while also yielding the AssistantEvents the UI needs.
    private func handleToolResult(_ result: ToolResult,
                                  for call: OpenAIChat.ToolCall,
                                  continuation: AsyncThrowingStream<AssistantEvent, Error>.Continuation) -> String {
        switch result {
        case .success(let success):
            let payload = Self.encodeJSON(success.structured)
            continuation.yield(.toolResult(toolCallID: call.id,
                                           toolName: call.function.name,
                                           payload: success.structured))
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload

        case .failed(let failed) where failed.kind == .outcomeUnknown:
            // Per-call event, not a terminal failure: the model still gets a tool message so it can
            // react, and the UI gets a typed failed event so it can render the distinct unknown state.
            let payload = Self.outcomeUnknownJSON(toolName: call.function.name)
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            continuation.yield(.failed(.init(kind: .outcomeUnknown,
                                             message: failed.reason)))
            return payload

        case .failed(let failed):
            let payload = Self.errorJSON(failed.reason)
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload

        case .rejectedBySafety(let rejection):
            let payload = Self.errorJSON(rejection.reason)
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload

        case .awaitingConfirmation:
            // The orchestrator already gates confirmations via SafetyPolicy; reaching this case means
            // a tool short-circuited the gate, so degrade to a tool failure rather than hanging.
            let payload = Self.errorJSON("Tool returned awaitingConfirmation past safety gate.")
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload
        }
    }

    /// Inject a one-shot system nudge when this turn's transcript shows the model misbehaving (an
    /// empty-list retry loop or the same tool called 3+ times). Each guard key fires at most once.
    private func applyInFlightGuards(messages: inout [OpenAIChat.Message],
                                     toolsByName: [String: AITool],
                                     fired: inout Set<String>) {
        guard let lastUserIdx = messages.lastIndex(where: { $0.role == .user }) else { return }
        let thisTurn = Array(messages[(lastUserIdx + 1)...])
        guard !thisTurn.isEmpty else { return }

        var callCountByName: [String: Int] = [:]
        var emptyListTools: Set<String> = []
        for (i, msg) in thisTurn.enumerated() {
            guard msg.role == .assistant, let calls = msg.toolCalls else { continue }
            for call in calls {
                let name = call.function.name
                callCountByName[name, default: 0] += 1
                if i + 1 < thisTurn.count {
                    let next = thisTurn[i + 1]
                    let isListLikeTool = name.hasSuffix("_list") || name.hasSuffix("_search")
                    if next.role == .tool,
                       let content = next.content,
                       let data = content.data(using: .utf8),
                       let parsed = try? JSONSerialization.jsonObject(with: data),
                       let array = parsed as? [Any],
                       array.isEmpty,
                       isListLikeTool {
                        emptyListTools.insert(name)
                    }
                }
            }
        }

        var nudges: [String] = []

        for tool in emptyListTools.sorted() where !fired.contains("empty:\(tool)") {
            fired.insert("empty:\(tool)")
            nudges.append(
                "`\(tool)` returned no matches. DO NOT retry with spelling / " +
                "capitalisation variations. Answer the merchant now using " +
                "`show_cards` (when you have entity IDs to render) or plain " +
                "text explaining no match."
            )
        }

        for (tool, count) in callCountByName.sorted(by: { $0.key < $1.key }) {
            guard count >= 3, !fired.contains("repeat:\(tool)") else { continue }
            fired.insert("repeat:\(tool)")
            nudges.append(
                "STOP. You've called `\(tool)` \(count) times in this turn. " +
                "Do NOT call it again. Answer the merchant now using " +
                "`show_cards` or plain text - retrying the same tool with " +
                "different parameters is counterproductive."
            )
        }

        if !nudges.isEmpty {
            messages.append(.init(role: .system, content: nudges.joined(separator: "\n\n")))
        }
    }

    private func buildInitialMessages(prompt: String,
                                      priorMessages: [OpenAIChat.Message]) -> [OpenAIChat.Message] {
        var messages: [OpenAIChat.Message] = []
        if let systemPrompt {
            messages.append(.init(role: .system, content: systemPrompt))
        }
        messages.append(contentsOf: priorMessages)
        messages.append(.init(role: .user, content: prompt))
        return messages
    }

    // MARK: - Tool definition translation

    private static func openAIDefinition(for tool: AITool) -> OpenAIChat.ToolDefinition {
        OpenAIChat.ToolDefinition(function: .init(name: tool.name,
                                                  description: tool.description,
                                                  parameters: tool.parametersSchema))
    }

    // MARK: - Error JSON encoding

    private static func payloadIsErrorOrCancelled(_ payload: String) -> Bool {
        guard let data = payload.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        if parsed["error"] != nil {
            return true
        }
        if let status = parsed["status"] as? String, status == "user_cancelled" {
            return true
        }
        return false
    }

    private static func errorJSON(_ message: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: ["error": message]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"error":"unknown"}"#
    }

    private static func userCancelledJSON() -> String {
        #"{"status":"user_cancelled","reason":"User declined this action in the iOS confirmation prompt."}"#
    }

    private static func outcomeUnknownJSON(toolName: String) -> String {
        let body: [String: Any] = [
            "outcome": "unknown",
            "tool": toolName,
            "advice": "Ask the merchant to verify the operation by viewing the order in the native UI."
        ]
        if let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"outcome":"unknown"}"#
    }

    private static func perToolCapJSON(toolName: String, cap: Int) -> String {
        let body: [String: Any] = [
            "error": "per_tool_cap_exceeded",
            "tool": toolName,
            "cap": cap,
            "hint": "You've already called this tool \(cap) times this turn. " +
                    "Answer the merchant now using show_cards or plain text. " +
                    "Do not call this tool again."
        ]
        if let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"error":"per_tool_cap_exceeded"}"#
    }

    /// Success-shaped envelope wrapping the cached payload. Escalates at `priorSeen >= 2` with
    /// `must_respond_now` + `stop_reason` markers; falls back to `data_raw` on cached JSON parse failure.
    static func duplicateReplayJSON(priorSeen: Int,
                                    name: String,
                                    cachedPayload: String) -> String {
        let isEscalated = priorSeen >= 2
        let hint: String
        if isEscalated {
            hint = "STOP. `\(name)` has now been called \(priorSeen + 1) times this " +
                   "turn with identical arguments. The `data` field below is the " +
                   "SAME result you already received. Your NEXT action MUST be to " +
                   "answer the merchant - call `show_cards` or reply in plain text " +
                   "using this data and any other tool results you have. Do NOT " +
                   "call any tool again."
        } else {
            hint = "You already called `\(name)` with these exact arguments. " +
                   "The `data` field below is the cached result from that earlier " +
                   "call. Respond to the user now using this data - do not retry."
        }
        var body: [String: Any] = [
            "status": "cached_result_reused",
            "tool": name,
            "prior_identical_calls_this_turn": priorSeen,
            "must_respond_now": isEscalated,
            "hint": hint
        ]
        if isEscalated {
            body["stop_reason"] = "duplicate_tool_call"
        }
        if let bytes = cachedPayload.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: bytes, options: [.fragmentsAllowed]) {
            body["data"] = parsed
        } else {
            body["data_raw"] = cachedPayload
        }
        if let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"status":"cached_result_reused"}"#
    }

    /// Canonical (name, args) key. Re-serializes with sorted keys so reorderings collapse to the same
    /// signature; malformed JSON args fall back to the raw string.
    static func canonicalCallSignature(name: String, argumentsJSON: String) -> String {
        guard let data = argumentsJSON.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) else {
            return "\(name)|\(argumentsJSON)"
        }
        if let canonical = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]),
           let str = String(data: canonical, encoding: .utf8) {
            return "\(name)|\(str)"
        }
        return "\(name)|\(argumentsJSON)"
    }

    /// Per-signature counts of tool calls already dispatched this turn (everything after the last user
    /// message). Excludes the tail tool-call message because those calls are about to dispatch, not prior.
    static func computePriorCallSignatures(in messages: [OpenAIChat.Message]) -> [String: Int] {
        guard let lastUserIdx = messages.lastIndex(where: { $0.role == .user }) else { return [:] }
        var upperBound = messages.count
        if let last = messages.last, last.role == .assistant, last.toolCalls != nil {
            upperBound -= 1
        }
        var counts: [String: Int] = [:]
        guard lastUserIdx + 1 < upperBound else { return counts }
        for msg in messages[(lastUserIdx + 1)..<upperBound] {
            guard msg.role == .assistant, let calls = msg.toolCalls else { continue }
            for call in calls {
                let sig = canonicalCallSignature(name: call.function.name,
                                                 argumentsJSON: call.function.arguments)
                counts[sig, default: 0] += 1
            }
        }
        return counts
    }

    /// First tool-result payload captured per canonical signature this turn. First wins because the
    /// duplicates we want to short-circuit are the ones AFTER the original response.
    static func computePriorResultsBySignature(in messages: [OpenAIChat.Message]) -> [String: String] {
        guard let lastUserIdx = messages.lastIndex(where: { $0.role == .user }) else { return [:] }
        var results: [String: String] = [:]
        var resultByCallID: [String: String] = [:]
        for msg in messages[(lastUserIdx + 1)...] {
            guard msg.role == .tool, let id = msg.toolCallID, let content = msg.content else { continue }
            if resultByCallID[id] == nil {
                resultByCallID[id] = content
            }
        }
        for msg in messages[(lastUserIdx + 1)...] {
            guard msg.role == .assistant, let calls = msg.toolCalls else { continue }
            for call in calls {
                let sig = canonicalCallSignature(name: call.function.name,
                                                 argumentsJSON: call.function.arguments)
                if results[sig] == nil, let payload = resultByCallID[call.id] {
                    results[sig] = payload
                }
            }
        }
        return results
    }

    /// Per-tool-name tallies across the turn, excluding the tail tool-call message about to dispatch
    /// (so the cap fires on the 5th call, not the 4th).
    static func computePerToolPriorTallies(in messages: [OpenAIChat.Message]) -> [String: Int] {
        guard let lastUserIdx = messages.lastIndex(where: { $0.role == .user }) else { return [:] }
        var upperBound = messages.count
        if let last = messages.last, last.role == .assistant, last.toolCalls != nil {
            upperBound -= 1
        }
        var counts: [String: Int] = [:]
        guard lastUserIdx + 1 < upperBound else { return counts }
        for msg in messages[(lastUserIdx + 1)..<upperBound] {
            guard msg.role == .assistant, let calls = msg.toolCalls else { continue }
            for call in calls {
                counts[call.function.name, default: 0] += 1
            }
        }
        return counts
    }

    private static func encodeJSON(_ value: AnyCodableJSON) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            DDLogError("AgenticLoopOrchestrator failed to encode tool payload: \(error)")
            return "{}"
        }
    }

    private enum Localization {
        static let iterationCapClosing = NSLocalizedString(
            "ai.assistant.loop.iteration_cap_closing",
            value: "(I took a few more steps than expected - here's what I found.)",
            comment: "Soft assistant message synthesized when the agentic loop hits its iteration cap before the model produced a final answer."
        )
        static let lengthLimitFailure = NSLocalizedString(
            "ai.assistant.loop.length_limit",
            value: "The model hit its response length limit mid-turn. Try breaking the question into smaller parts.",
            comment: "Failure message surfaced when the model's response was truncated by max-tokens. Suggests the merchant split the question."
        )
        static let emptyResponseFallback = NSLocalizedString(
            "ai.assistant.loop.empty_response_fallback",
            value: "(No response from the model.)",
            comment: "Fallback assistant text shown when the model finished a turn with no content and no tool calls."
        )
        static let noFinishEvent = NSLocalizedString(
            "ai.assistant.loop.no_finish_event",
            value: "The chat service ended the stream without finishing cleanly. Try again.",
            comment: "Failure surfaced when the chat service's stream ends without emitting a finish event, indicating an upstream truncation."
        )
    }
}

// MARK: - Internal helpers

private enum TurnOutcome {
    case completed
    case toolCalls([OpenAIChat.ToolCall])
}

/// Degenerate policy used when the caller hasn't specified safety at
/// all (tests, read-only prototypes). Every call executes.
struct AlwaysExecuteSafetyPolicy: SafetyPolicy {
    func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision {
        .execute
    }
}
