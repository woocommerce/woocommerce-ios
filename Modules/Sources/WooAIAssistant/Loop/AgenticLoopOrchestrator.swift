import Foundation
import CocoaLumberjackSwift

/// Runs the client-side agentic loop on top of an `AIChatService`,
/// a `ToolRegistry`, and a `SafetyPolicy`.
///
/// Actor-isolated because unsafe tool calls suspend the loop while the
/// merchant resolves a confirmation card. The pending continuation has
/// to live somewhere safe from concurrent access, and the actor's
/// serial mailbox is the cleanest fit. Callers resume the loop via
/// `confirm(proposalID:)` / `cancel(proposalID:)`.
///
/// Per-turn behavior:
/// 1. Build messages: system prompt + prior transcript + user prompt.
/// 2. Call the chat service with tools attached.
/// 3. Yield text deltas to the UI as they arrive.
/// 4. Collect `toolCall` events; once the turn completes, for each
///    call: consult `SafetyPolicy` (execute / requireConfirmation),
///    suspend on confirmation if needed, dispatch via the registry,
///    yield events for the UI, and append the result back into the
///    transcript so the model can react.
/// 5. Loop up to `maxIterations` times; if the cap is hit synthesize
///    a graceful close instead of throwing.
///
/// Access: this class is `internal` rather than `public` because its
/// `AIChatService` dependency uses `OpenAIChat` types that are still
/// internal on trunk. C2 will widen the surface when the transport
/// lands.
actor AgenticLoopOrchestrator {

    static let defaultMaxIterations = 5

    /// Max times the SAME tool name may dispatch in a single turn
    /// (regardless of arguments) before subsequent calls to that tool
    /// receive a synthetic per-tool-cap error message instead of
    /// dispatching. 4 keeps "list + 3 drill-downs" flows legitimate
    /// while catching varied-args fanouts (5-7 orders_list with
    /// different orderby/status/extra_fields permutations).
    static let defaultPerToolPerTurnCap = 4

    private let chatService: AIChatService
    private let toolRegistry: ToolRegistry?
    private let safetyPolicy: SafetyPolicy
    private let systemPrompt: String?
    private let maxIterations: Int
    private let perToolPerTurnCap: Int

    /// Pending confirmation continuations keyed by proposal id. The
    /// loop suspends on `waitForDecision` and the UI resolves via
    /// `confirm(proposalID:)` / `cancel(proposalID:)`.
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

    /// Execute a single user turn. Streams orchestrator events to the UI.
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

    /// Call when the user taps Confirm on a proposal card.
    func confirm(proposalID: UUID) {
        if let continuation = pendingDecisions.removeValue(forKey: proposalID) {
            continuation.resume(returning: true)
        }
    }

    /// Call when the user taps Cancel on a proposal card.
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

    /// Stream consumer disconnected. Treat as cancellation: free
    /// pending continuations and stamp the outcome so a follow-up
    /// `lastOutcome` query reads as `.stopped` rather than nil.
    private func handleStreamTerminated() {
        cancelAllPending()
        if lastOutcome == nil {
            lastOutcome = .stopped
        }
    }

    /// Suspend the loop until the UI resolves this proposal. Wraps
    /// the checked continuation in a task-cancellation handler so
    /// that if the outer stream terminates (consumer died, caller
    /// cancelled) between yielding `.confirmationRequired` and
    /// registering this continuation, the proposal still cancels
    /// cleanly. Otherwise we'd leak a continuation and hang the
    /// actor forever.
    ///
    /// Two cancellation races were flagged in review:
    ///   (a) Cancel arrives BEFORE the continuation is stored.
    ///       `Task.isCancelled` catches that before we touch the
    ///       dictionary.
    ///   (b) Cancel arrives AFTER the store but before `onCancel`'s
    ///       enqueued Task reaches the actor. `onCancel` fires
    ///       immediately (outside the actor), and its
    ///       `Task { await self.cancel(...) }` runs later on the
    ///       actor hop - by then the continuation is in the
    ///       dictionary and gets properly resumed(false). Safe.
    /// The post-store `Task.isCancelled` re-check is belt-and-braces
    /// for (b) in case the scheduler reorders the onCancel work
    /// past another actor hop.
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
            // onCancel runs outside the actor, so hop back in via
            // Task to mutate `pendingDecisions` safely.
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

        // Per-turn state for mid-flight guards. Each guard key
        // ("empty:<tool>" or "repeat:<tool>") fires at most once per
        // turn so we don't spam the model with duplicate system notes.
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
        // Graceful recovery: the model looped past the cap. Synthesize
        // a closing message + completed event so the merchant sees a
        // soft end instead of a bare error banner.
        continuation.yield(.textChunk(Localization.iterationCapClosing))
        continuation.yield(.completed(routeConfidence: nil))
        lastOutcome = .maxIterations(iterations: maxIterations)
    }

    /// Drains one chat-service stream. Returns either `.completed`
    /// (final answer text was emitted) or `.toolCalls(...)` (more
    /// loop work).
    private func runOneTurn(messages: [OpenAIChat.Message],
                            tools: [OpenAIChat.ToolDefinition]?,
                            continuation: AsyncThrowingStream<AssistantEvent, Error>.Continuation) async throws -> TurnOutcome {
        var pendingCalls: [OpenAIChat.ToolCall] = []
        var didEmitText = false
        var finishReason: OpenAIChat.FinishReason?

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
            }
        }

        // finish_reason == "length" means the model hit max_tokens
        // mid-response. Any assistant-with-tool-calls message would
        // carry partial arguments JSON and fail validation; any text
        // is truncated. Surface as an explicit failure.
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

    /// Dispatch every call in `calls`, consulting the safety policy
    /// for each. Returns the tool-result JSON payload for each call
    /// in input order so they pair with the parent assistant
    /// message's tool_calls array correctly.
    ///
    /// `priorCallSignatures` carries the per-signature count of
    /// identical tool calls already made earlier in this turn, and
    /// `priorResultsBySignature` carries the FIRST tool-result
    /// payload captured for each such signature. When the model
    /// fires an identical re-call we replay that cached payload
    /// wrapped in a directive envelope instructing the model to
    /// respond with what it already has - no error shape, so the
    /// model treats the duplicate as "already answered, here's the
    /// same data" rather than "tool failed, let me retry with
    /// different args". The envelope escalates at the 3rd+ call
    /// with a stronger `must_respond_now` marker.
    ///
    /// Why replay-with-hint beats the previous error-shape approach:
    /// mini/gpt-4o treated `duplicate_call_blocked` as a retryable
    /// failure and kept issuing variations (spelling tweaks,
    /// reorderings) until the iteration cap tripped. A successful
    /// result envelope matches the model's mental model - it gets
    /// the data it asked for, with a hint saying "you've now been
    /// asked to respond".
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

        // First occurrence of each (tool, args) signature within THIS
        // batch becomes the "primary" and dispatches normally.
        // Subsequent identical calls become intra-batch secondaries:
        // we skip safety resolution + dispatch for them, and fill
        // their resolved payload from the primary's result after the
        // task group completes. Without this the task group fires
        // the registry once per duplicate in parallel (liveResults
        // only grew from PRIOR iterations), burning HTTP calls.
        var firstPrimaryByIntraSignature: [String: Int] = [:]
        var intraBatchSecondaryToPrimary: [Int: Int] = [:]

        for (index, call) in calls.enumerated() {
            let signature = Self.canonicalCallSignature(name: call.function.name,
                                                        argumentsJSON: call.function.arguments)
            let priorSeen = liveSignatures[signature, default: 0]
            liveSignatures[signature] = priorSeen + 1

            // Per-tool-per-turn cap: tally tool name across the
            // whole turn (regardless of args). When the cap is hit,
            // synthesize an error tool message instructing the
            // model to wrap up.
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

            // Circuit-breaker: replay the cached payload on the 2nd+
            // identical call. Threshold is 1 (we short-circuit the
            // SECOND identical call) because:
            //   - The previous error-shape result was read by mini
            //     as a retryable failure and just provoked more
            //     variations, saturating the 5-iter cap.
            //   - Returning the same payload as the first call,
            //     wrapped in a hint, matches the model's mental
            //     model and stops the loop in 1-2 iterations.
            //   - Parallel-identical bursts within a single
            //     assistant message still land - only the EXTRA
            //     calls replay; the first call in the batch
            //     dispatches normally.
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

            // Intra-batch duplicate: a call with this exact signature
            // already claimed the primary slot earlier in THIS batch.
            // Defer resolution - fill in the replay envelope after
            // the primary's task group result lands.
            if let primaryIndex = firstPrimaryByIntraSignature[signature] {
                intraBatchSecondaryToPrimary[index] = primaryIndex
                continuation.yield(.toolCallStarted(id: call.id,
                                                    name: call.function.name,
                                                    argumentsJSON: call.function.arguments))
                continue
            }

            firstPrimaryByIntraSignature[signature] = index

            // Unknown tool names default to .unsafe so the safety
            // policy gates them. This pairs with the registry's own
            // unknown-tool failure path.
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

        // Dispatch approved calls in parallel and plug their results
        // back into the same index slots.
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

        // Fill in intra-batch secondaries with the primary's payload
        // wrapped in the duplicateReplay envelope. Deterministic
        // order (sorted by secondary index) so events emit in the
        // same order the model issued the calls. The primary's
        // resolved payload is nested verbatim under `data` - if it
        // was a successful result the secondary sees a
        // cached_result_reused hint; if the primary was blocked /
        // cancelled / errored, the secondary sees the same outcome
        // nested, which is still semantically correct ("the
        // identical earlier call ended this way, don't retry").
        for (secondaryIndex, primaryIndex) in intraBatchSecondaryToPrimary.sorted(by: { $0.key < $1.key }) {
            let call = calls[secondaryIndex]
            if let primaryPayload = resolvedResults[primaryIndex] {
                let replay = Self.duplicateReplayJSON(priorSeen: 1,
                                                      name: call.function.name,
                                                      cachedPayload: primaryPayload)
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

    /// Translate a `ToolResult` into the model-visible JSON payload
    /// that ends up as the tool message content, while also yielding
    /// the trunk events the UI needs (`toolCallCompleted`,
    /// `toolResult` for cards, `failed` for outcomeUnknown).
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
            // outcome_unknown is a per-call event, NOT a terminal
            // failure. The model still gets a tool message so it can
            // react (advise the merchant to verify in the native UI),
            // and the UI gets a typed failed event so it can render
            // the distinct unknown state.
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
            // Distinct from .failed for analytics, but the
            // orchestrator hands the same shape to the model so the
            // recovery path is identical.
            let payload = Self.errorJSON(rejection.reason)
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload

        case .awaitingConfirmation:
            // Should not happen at this layer: the orchestrator
            // already gates confirmations via SafetyPolicy. Treat as
            // a tool failure so the loop continues rather than
            // hanging on a missing UI handshake.
            let payload = Self.errorJSON("Tool returned awaitingConfirmation past safety gate.")
            continuation.yield(.toolCallCompleted(id: call.id,
                                                   name: call.function.name,
                                                   resultJSON: payload))
            return payload
        }
    }

    /// Mid-flight guards: inspect what's happened so far in this
    /// turn and inject a single system nudge if the model is
    /// misbehaving.
    ///
    /// Conditions (each fires at most once per turn):
    /// 1. Empty-list retry loop: a `*_list` / `*_search` tool
    ///    returned an empty array AND the model is still iterating.
    /// 2. Same-tool repeat: the same tool name was called 3+ times
    ///    in this turn. The two-tier safe/unsafe taxonomy uses one
    ///    threshold for both.
    ///
    /// Nudges land as `.system` messages mid-conversation; OpenAI
    /// chat completions accepts those, and the next request will
    /// see them as authoritative guidance.
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

    /// Wrap a cached tool-result payload in a directive envelope
    /// telling the model it's seeing the same data it already got.
    /// Shape is a SUCCESS envelope (not an error) so the model
    /// doesn't treat this as a retryable failure. At priorSeen >= 2
    /// the hint escalates with `must_respond_now` + `stop_reason`
    /// markers.
    ///
    /// `data` is always the original tool result payload, round-
    /// tripped through JSON parsing so it nests cleanly under
    /// `data`. Invalid cached JSON falls back to a string payload
    /// under `data_raw`.
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

    /// Canonical (name, args) key used to detect identical duplicate
    /// calls. JSON is parsed and re-serialized with sorted keys so
    /// `{"a":1,"b":2}` and `{"b":2,"a":1}` collapse to the same
    /// key. Falls back to the raw args string on parse failure
    /// (malformed args can't be deduped reliably).
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

    /// Count how many times each (tool_name, canonical_args)
    /// signature appears in the assistant.toolCalls messages of THIS
    /// turn - i.e. everything after the last user message. Used as
    /// the prior count fed into the circuit-breaker.
    static func computePriorCallSignatures(in messages: [OpenAIChat.Message]) -> [String: Int] {
        guard let lastUserIdx = messages.lastIndex(where: { $0.role == .user }) else { return [:] }
        // Exclude the tail if it's the current-turn assistant tool-
        // call message: those calls are what we're ABOUT to dispatch,
        // not "prior" invocations. Without this the count is off-by-
        // one and the dedupe replay escalates on the 2nd call instead
        // of the 3rd.
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

    /// Walk this turn's messages and, for every canonical (tool, args)
    /// signature, capture the FIRST tool-result payload that followed
    /// it. Used by the dedupe replay: when the model fires an
    /// identical call we hand it back the cached payload instead of
    /// a blocked-error so it stops retrying and can answer with the
    /// data it already has.
    ///
    /// "First wins" because downstream calls with the same sig are
    /// the duplicates we're trying to short-circuit - the original
    /// response is the canonical data. Signatures where the paired
    /// tool-result message is missing (mid-dispatch, transcript
    /// truncation) are skipped.
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

    /// Tally tool calls by NAME (regardless of args) across this
    /// turn, EXCLUDING the current-turn tool_calls message we're
    /// about to dispatch - so the cap fires on the 5th call to the
    /// same tool, not the 4th.
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
    init() {}
    func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision {
        .execute
    }
}
