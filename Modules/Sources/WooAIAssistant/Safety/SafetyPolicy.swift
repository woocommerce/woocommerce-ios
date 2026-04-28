/// `requireConfirmation` suspends the orchestrator loop until the merchant
/// confirms or cancels via the confirm pathway; `block` synthesizes an error
/// tool result fed back to the LLM without dispatching.
public protocol SafetyPolicy: Sendable {
    func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision
}

public enum SafetyDecision: Equatable, Sendable {
    case execute

    /// `preview` is the short line shown on the confirmation card
    /// (e.g. "Set order #42 to processing").
    case requireConfirmation(preview: String)

    case block(reason: String)
}
