import Foundation

/// Typed kinds the transport layer and orchestrator classify errors into.
/// Surfaced through `ToolResult.Failed.kind`, transport telemetry, and the
/// confirmation/retry decisions higher layers make.
public enum AssistantErrorKind: String, Sendable, Codable {
    case network
    case auth
    case rateLimit          = "rate_limit"
    case timeout
    case upstreamFailure    = "upstream_failure"
    case toolFailed         = "tool_failed"
    case invalidToolCall    = "invalid_tool_call"
    case outcomeUnknown     = "outcome_unknown"
    case cancelled
    case unknown
}
