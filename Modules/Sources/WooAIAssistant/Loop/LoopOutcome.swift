import Foundation

/// Terminal state of an orchestrator turn. Set as the loop exits and
/// queryable via `AgenticLoopOrchestrator.lastOutcome` after the event
/// stream finishes. Cross-platform-aligned with Android (#15764) so
/// telemetry buckets match across clients.
enum LoopOutcome: Sendable, Equatable {
    /// The model produced a final answer with no pending tool calls.
    case completed

    /// An unrecoverable error ended the loop. Distinct from per-call
    /// `outcomeUnknown` failures, which keep the loop running.
    case failed(AssistantError)

    /// `maxIterations` was reached before the model stopped calling
    /// tools. The orchestrator synthesizes a closing assistant message
    /// rather than throwing so the merchant still sees a graceful end.
    case maxIterations(iterations: Int)

    /// The consumer cancelled the stream mid-flight (chat closed,
    /// task cancelled). No `failed`/`completed` was emitted.
    case stopped
}
