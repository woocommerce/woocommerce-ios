public struct DefaultSafetyPolicy: SafetyPolicy {

    public init() {}

    public func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision {
        switch tool.safetyLevel {
        case .safe:
            return .execute
        case .unsafe:
            return .requireConfirmation(preview: ToolPreviews.defaultBuilder(name, arguments))
        }
    }
}
