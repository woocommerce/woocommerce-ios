/// Decides what to do with a tool call the LLM wants to dispatch.
///
/// The orchestrator consults the policy before calling the tool. The policy
/// returns a `SafetyDecision` for each call; `requireConfirmation` suspends the
/// loop until the merchant confirms or cancels via the orchestrator's confirm
/// pathway, and `block` synthesizes an error tool result without dispatching.
public protocol SafetyPolicy: Sendable {
    func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision
}

public enum SafetyDecision: Equatable, Sendable {
    /// Dispatch the tool immediately.
    case execute

    /// Pause the loop, emit a confirmation event to the UI, wait for the
    /// merchant's tap. `preview` is the short line shown on the confirmation
    /// card (e.g. "Set order #42 to processing").
    case requireConfirmation(preview: String)

    /// Synthesize an error tool result with `reason` and feed it back to the
    /// LLM so it can explain to the merchant. No dispatch, no UI prompt.
    case block(reason: String)
}
