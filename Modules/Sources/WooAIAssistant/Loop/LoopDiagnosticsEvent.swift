import Foundation

/// Telemetry events emitted by `AgenticLoopOrchestrator` so the host
/// app can measure how safety and loop behaviors land in production.
/// All events are optional consumer-side: the orchestrator does not
/// care if anyone is listening.
enum LoopDiagnosticsEvent: Sendable, Equatable {
    /// A user prompt entered the loop.
    case turnStarted(prompt: String)

    /// Confirmation card was shown to the user.
    case confirmationRequested(toolName: String, safetyLevel: AIToolSafetyLevel)

    /// User responded to the confirmation card.
    case confirmationResolved(toolName: String, approved: Bool)

    /// The loop hit `maxIterations` and bailed. Indicates a model loop
    /// or a missing tool.
    case maxIterationsHit(iterations: Int)
}

/// Optional sink the orchestrator publishes to. Default: no-op.
/// Consumers (the iOS analytics provider) wrap their event pipeline
/// in this and forward to `WooAnalyticsEvent` etc.
typealias LoopDiagnosticsHandler = @Sendable (LoopDiagnosticsEvent) -> Void

let noopLoopDiagnostics: LoopDiagnosticsHandler = { _ in }
