import Foundation

/// Terminal state of an orchestrator turn. Set as the loop exits and queryable via
/// `AgenticLoopOrchestrator.lastOutcome` after the event stream finishes. Cross-platform-aligned
/// with Android (#15764) so telemetry buckets match across clients.
enum LoopOutcome: Sendable, Equatable {
    case completed
    case failed(AssistantError)
    case maxIterations(iterations: Int)
    case stopped
}
