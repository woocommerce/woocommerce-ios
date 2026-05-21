/// `requireConfirmation` suspends the orchestrator loop until the merchant
/// confirms or cancels via the confirm pathway.
public protocol SafetyPolicy: Sendable {
    func decision(for name: String, arguments: String, tool: AITool) async -> SafetyDecision
}

public enum SafetyDecision: Equatable, Sendable {
    case execute

    /// Typed preview shown on the confirmation card.
    case requireConfirmation(preview: ConfirmationPreview)

    /// Resolver determined the call can't proceed (e.g. missing entities). The
    /// orchestrator surfaces this as a synthetic tool failure without showing a card.
    case refusePreDispatch(reason: String)
}
