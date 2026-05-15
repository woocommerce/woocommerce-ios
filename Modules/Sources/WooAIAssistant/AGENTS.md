# WooAIAssistant

An in-app conversational agent for WooCommerce merchants. The agentic loop runs client-side: it streams turns from a remote chat endpoint, dispatches local tools, and renders rich entity cards. Entry is a dismissible dashboard card; tap presents the chat as a full-screen cover. The feature is gated by `FeatureFlag.wooAIAssistant`, a remote kill switch, and site-type eligibility; see `AIAssistantEligibilityChecker` for the wiring.

## Design goals

The module is built as a flexible foundation so future iterations can extend the surface without rebuilding the loop. Two integration axes stay swappable behind protocol seams:

- **Tool providers.** `ToolRegistry` is a protocol. v1 ships `RESTToolRegistry` for local REST tools. An MCP-backed registry can plug in alongside or in place of REST without touching the orchestrator.
- **Chat endpoints.** `AIChatService` is a protocol. v1 ships `JetpackAIQueryClient` pointed at the `jetpack-ai-query` endpoint. A different endpoint or transport requires only an alternate `AIChatService` conformance.

Rich entity cards render through the module and deep-link back into existing app screens via `AssistantExternalNavigationProviding`, so the assistant integrates with the rest of the app without owning navigation state.

## Locked product and technical decisions

- **Client-side agentic loop.** No server-side agent or middleware orchestrates between the model and the app. Both iOS and Android run the same loop shape so guardrails stay in code.
- **`jetpack-ai-query` for the v1 chat endpoint.** Inherits Jetpack AI plan billing. An alternative endpoint is considered for the future; both plug into `AIChatService`.
- **Production uses a model that reliably handles multi-step tool calls and complex queries.** When evaluating a different model for cost or performance, run the `/woo-ai-smoke` suite with scenarios that chain multiple tools across a turn to validate the balance. The current model is set in `AssistantConfiguration`.
- **REST tools for v1.** `RESTToolRegistry` ships first because REST is faster, more reliable, and avoids context-window bloat. The `ToolRegistry` seam stays open for MCP-backed catalogs.
- **`show_cards` is the only render path.** The model decides when to surface UI.
- **Lists and reads return detailed payloads by default.** Tool responses include the fields the model typically needs in a single call, avoiding extra round-trips to fetch per-entity details.
- **Two-level safety, code-controlled.** Tools are `.safe` or `.unsafe`. Unsafe writes gate on a deterministic confirmation modal built from a pre-write snapshot. The model cannot override safety.
- **Destructive actions stay manual.** Operations like refunds or deletions are too high-risk for the assistant and must be initiated from the relevant app screen.
- **Bounded sliding window.** Fits multi-order discussions without a persistence layer. Window size is set in `AssistantConfiguration`.
- **System prompt and tool catalog versioned in lockstep with Android.** Both bump together; see `AssistantTelemetryConstants` for current pinned versions.
- **Two-level feature flag.** Local build-config flag plus a remote kill switch.
- **Cards carry typed entity references, not URLs.** Taps open native screens via the host app's navigation adaptor. The model never produces a URL the app would have to follow.

## Architecture

```
AssistantChatView
  -> AssistantController                          (@Observable, @MainActor)
      -> AgenticChatBackend                       (long-lived per session)
          -> SlidingWindowHistoryBudgeter
          -> AgenticLoopOrchestrator              (actor, the heart)
              -> AIChatService                    (SSE chat over Bearer JWT)
              -> RESTToolRegistry                 (local REST tools)
              -> SafetyPolicy                     (confirmation gate)
              -> AssistantTelemetryTracker        (per-turn events)
```

Each user turn opens an `AsyncThrowingStream<AssistantEvent, Error>`. The controller drains it on the main actor, the backend holds transcript state across turns, and the orchestrator runs the agentic loop within a bounded iteration count.

## Folder map

| Path | Contents |
|---|---|
| `AI/` | OpenAI-compatible wire DTOs (`OpenAIChat.*`). Cross-component vocabulary. |
| `Backend/` | `AssistantBackend` protocol, `AgenticChatBackend`, `HistoryBudgeter`. |
| `Configuration/` | `AssistantConfiguration` (model name, history window size) and `AssistantSystemPrompt`. |
| `Headless/` | `WooAssistantHeadless` smoke driver. |
| `Loop/` | `AgenticLoopOrchestrator`, `AIChatService` protocol, `LoopOutcome`. |
| `Models/` | `AssistantEvent`, `AssistantSession`, `ChatMessage`, `MessageSegment`. |
| `Networking/` | `JetpackAIQueryClient` (SSE), `SSEParser`, `WpComJetpackAIJWTProvider`. |
| `Presentation/` | SwiftUI surface: chat view, message bubble, card host, confirmation card. |
| `Protocols/` | Host-facing DI protocols (analytics, JWT, navigation, external view). |
| `Safety/` | `SafetyPolicy` + `DefaultSafetyPolicy`, `ConfirmationPreview`, `ConfirmationSnapshotResolver`. |
| `State/` | `AssistantController`, `AssistantConversation`. |
| `Telemetry/` | Constants, event enum, error and outcome mappers, `ShowCardsTelemetryReducer`. |
| `Tokens/` | Design tokens: color, font, spacing. |
| `Tools/` | `AITool`, `RESTToolRegistry`, REST executor, tool implementations, card resolver. |

## Entry points

- Feature flags + eligibility: `WooCommerce/Classes/AIAssistant/AIAssistantEligibilityChecker.swift` gates the assistant by a local feature flag, a remote kill switch, and site-type criteria. See the file for current rules.
- Dashboard card: `DashboardCard.CardType.aiAssistant` is rendered as `AIAssistantDashboardCard`. Tap presents `AIAssistantChatScreen` as a full-screen cover.
- Session bootstrap: `AIAssistantChatScreen.onAppear` calls `AIAssistantSessionStore.shared.session(for: siteID)`. The session store builds the `AssistantController`; `AIAssistantDependencyAdaptor.default(...)` supplies the chat service, REST tool registry, safety policy, and system prompt.

## Host app integration

For navigation and view reuse across the chat surface, the module uses adaptor protocols implemented in the main app target. Two seams sit in `Protocols/`:

- **`AssistantExternalNavigationProviding`** opens existing app screens when a card is tapped (orders, products, customers, analytics). Cards emit typed entity IDs; the navigation adaptor resolves them. The module never owns navigation state.
- **`AssistantExternalViewProviding`** lets the module embed host views inside chat surfaces so existing UI can be reused without duplication.

Concrete implementations live in the app target as adaptors (e.g., `AIAssistantExternalNavigationAdaptor`).

External view injection is convenient but couples the module to host UI. As surfaces mature, prefer creating module-owned views where it clarifies the code and gives the module tighter control over rendering.

## Agentic loop

`AgenticLoopOrchestrator` (a public `actor` in `Loop/`) runs a bounded number of iterations per turn with a per-tool-per-turn cap. Both caps are defined in the orchestrator. Actor isolation is required because unsafe tool dispatch suspends on a `CheckedContinuation<Bool, Never>` stored in `pendingDecisions` until the user resolves the confirmation. The entry point returns an `AsyncThrowingStream<AssistantEvent, Error>` that emits text chunks, tool dispatches, card renders, confirmations, and termination.

Per iteration, `runOneTurn` consumes the chat service's `ChatStreamEvent` stream, yields `.textChunk` per text delta, accumulates tool calls, and returns either `.completed` or `.toolCalls(...)`. Tool dispatch enforces dedupe (canonical-signature, in-flight, prior-call, intra-batch). In-flight guards inject one-shot system nudges for empty results, repeated calls, and looping patterns; see `AgenticLoopOrchestrator` for the current heuristics.

Each terminating path emits a typed outcome through a `.terminated` event. The iteration-cap branch additionally yields a soft closing text chunk. The outcome enum and the controller-side mapper live in `Loop/LoopOutcome.swift` and `State/AssistantController.swift`.

## Chat service

The orchestrator depends on the `AIChatService` protocol. v1 implements it with `JetpackAIQueryClient` (`Networking/`), which streams over SSE with Bearer JWT auth. SSE framing, UTF-8 handling, and tool-call delta assembly live across `SSEParser` and `JetpackAIQueryClient`.

JWT minting is brokered by `WpComJetpackAIJWTProvider`, an actor with single-flight caching that prevents concurrent callers from minting redundant tokens. In production, `AIAssistantJWTAdaptor` performs the mint via the WPCOM tunnel.

Auth and rate-limit retries are event-gated: they only fire before any event has crossed the stream, so partial responses never get replayed.

A different chat service implementation could use a different transport or auth scheme; the seam is the `AIChatService` protocol.

## REST tools

Tools live in `Tools/Implementations/` and are registered with `RESTToolRegistry`. Each tool exposes an `AITool` definition with a name, JSON parameter schema, description, and an `AIToolSafetyLevel` of `.safe` or `.unsafe`. The executor (`RESTToolDispatch`) bounds `per_page` to a safe range, routes through `WCRESTClient`, and converts non-2xx responses to typed `ToolResult.Failed`.

Channel discipline is absolute. Tool results have two channels:

- **`structured`** is model-visible and compact. It goes back into the conversation as a tool message.
- **`uiStructured`** is app-only and full-fidelity. It never re-enters model context.

The orchestrator threads `structured` back to the model and extracts `uiStructured` only for `show_cards`. Read-tool list payloads stay summarized to keep large entity fan-outs out of the model context.

v1 calls REST directly via `WCRESTClient`. Tools may later transition to Yosemite-backed implementations to share caching and types with the rest of the app; the `ToolRegistry` seam is what makes that swap possible without touching the orchestrator.

Adding a new tool requires three touchpoints: the implementation in `Tools/Implementations/`, registration in `AIAssistantDependencyAdaptor` for production, and registration in `WooAssistantHeadless` for smoke evaluation. Production and headless catalogs are mirrored lists, not a shared source.

## Cards

`show_cards` is the sole path that emits `.cardRender` events. It accepts a small batch of references of the form `{family, id}`. `CardReferenceResolver` dispatches by family path strategy; see `Tools/Cards/CardReferenceResolver.swift` and `Tools/Cards/CardFamily.swift` for the current families and their fetch strategies.

When `ShowCardsTool` succeeds, the orchestrator pairs each rendered card with a synthetic toolCallID and emits `.toolResult` + `.cardRender`. `MessageCardHost` routes by a tool-name-derived `TypedCardDispatcher.Route` to typed `EntityCard<Payload, Row>` views; unknown families fall back to `RawJSONCard`. Synthetic-ID parsing and first-wins `(family, id)` dedupe live in `MessageBubble` and are mirrored in `WooAssistantHeadless` so harness output matches the SwiftUI surface.

Adding a new card family touches several files: `CardFamily` (the enum and registry), `CardReferenceResolver` (fetch strategy), `ShowCardsTool` (reference parsing and rejection codes), `MessageCardHost` / `TypedCardDispatcher` (rendering route), and the telemetry reducer in `Telemetry/`.

## Safety and confirmations

`SafetyPolicy.decision(for:arguments:tool:)` is consulted before every tool dispatch. `DefaultSafetyPolicy` returns `.execute` for `.safe` and `.requireConfirmation(preview:)` for `.unsafe`. The preview is built by `DefaultConfirmationPreviewBuilder` and enriched by `DefaultConfirmationSnapshotResolver`, which fetches a pre-write GET so the modal renders the authoritative before-state.

The orchestrator yields `.confirmationRequired(proposal:)`, suspends in `waitForDecision`, and resumes when the UI invokes `confirm(proposalID:)` or `cancel(proposalID:)` via `AgenticChatBackend`. This is why the orchestrator is an actor: the continuation must live on isolated state.

## Telemetry

`AssistantTelemetryConstants` pins the prompt version, tool catalog version, and completion stack identifier attached to every event. These are versioned in lockstep with Android.

Per-turn events cover the conversation lifecycle (start, turn start, tool call results, card render, card taps, turn end). The full event enum and its outcome and error taxonomies live in `Telemetry/`. Emission is split: `AssistantController` owns turn-level events; `AgenticLoopOrchestrator` owns tool and card events. Unknown tool names canonicalize so hallucinated function names never enter telemetry.

The app-target bridge `WooAssistantTelemetryTracker` maps each module event to a `WooAnalyticsEvent.aiAssistant*` factory on `ServiceLocator.analytics`.

## History budgeting

`SlidingWindowHistoryBudgeter` runs in `AgenticChatBackend.send` before each turn. It prepends the system prompt, takes the most recent messages within the configured window, then trims a leading orphan `tool` message or an assistant turn whose `tool_call` IDs are not all matched within the window. This is required to avoid OpenAI 400 errors on orphan tool messages. The window size lives in `AssistantConfiguration`.

The orchestrator does not re-budget. Budgeter invariants must hold at the message-list boundary.

## Smoke evaluation harness

The `Headless/` subfolder exists only for offline evaluation through the `/woo-ai-smoke` skill. It is not part of the production runtime; the app never instantiates `WooAssistantHeadless`.

`WooAssistantHeadless` (an `actor`) mirrors the production wiring (same tool catalog, safety policy, and prompt) but talks to the site directly via `HeadlessURLSessionWCRESTClient` and mints the JWT through a Jetpack-local app-password path. Differences from production: a higher iteration cap suited to long evaluation runs, an optional read-only mode that hard-denies all confirmations, and a configurable default confirmation policy. Credentials load from a smoke-harness-staged env file; see the `/woo-ai-smoke` skill for path conventions.

Each turn returns a `ConversationTurnResult` carrying the per-turn assistant output, tool calls, cards, confirmations, and any failure message; cards mirror the SwiftUI dedupe rules so JSONL output matches the chat surface.

## Testing

Tests live in `Modules/Tests/WooAIAssistantTests/` mirroring the source folder layout. New tests use Swift Testing (`@Test`, `#expect()`) with snake_case method names. Slow runs almost always trace to a hanging continuation-based mock; fix the mock, not the runner.

The end-to-end evaluation loop is the `/woo-ai-smoke` skill. It drives `WooAssistantHeadless` against a real demo store and writes JSONL run records under `.claude/skills/woo-ai-smoke/runs/`. Always run smokes via subagent; the log volume is large.

## Anti-patterns and non-goals

- Do not inline card JSON into model text. Cards emit only through `show_cards`.
- Do not let full entity payloads enter `structured`. UI-only data goes to `uiStructured`.
- Do not bypass `HistoryBudgeter`. Orphan-tool-message trim invariants must hold.
- Any tool that writes or changes data must declare `.unsafe` to gate on the confirmation system. The safety model is intentionally binary: `.safe` for reads, `.unsafe` for writes. No third tier.
- Do not retry once data has crossed the stream. Auth and rate-limit retries are event-gated.
- Do not introduce a second card-render path.
- Do not bump `promptVersion` or `toolCatalogVersion` unilaterally; both platforms move together.
- Tests: no `Task.sleep`, `Task.yield`, `NSLock`, `OSAllocatedUnfairLock`, `DispatchSemaphore`, or `@unchecked Sendable`. Mocks are synchronous; tests drive the unit's natural async surface.
- Tests: no `static` helpers like `Self.awaitX(...)`; they signal hidden shared state.
- Builds: for module-only changes, scope `xcodebuild` to `-scheme WooAIAssistant`. App-target tests under `WooCommerceTests/` rely on CI.

---

Last reviewed: 2026-05-15.
