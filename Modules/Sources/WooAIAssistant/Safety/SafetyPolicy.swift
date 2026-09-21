/// `requireConfirmation` suspends the orchestrator loop until the merchant
/// confirms or cancels via the confirm pathway.
public protocol SafetyPolicy: Sendable {
    func decision(for name: String, arguments: String, tool: AITool) async -> SafetyDecision
}

public enum SafetyDecision: Equatable, Sendable {
    case execute

    /// Typed preview shown on the confirmation card.
    case requireConfirmation(preview: ConfirmationPreview)
}
