import Foundation

/// Terminal state of a turn, queryable via `AgenticLoopOrchestrator.lastOutcome`. Cases mirror the
/// Android client's `LoopOutcome` so cross-platform telemetry buckets line up.
enum LoopOutcome: Sendable, Equatable {
    case completed
    case failed(AssistantError)
    case maxIterations(iterations: Int)
    case stopped
}
