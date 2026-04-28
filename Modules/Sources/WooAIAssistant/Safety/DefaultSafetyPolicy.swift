/// Default policy that keys off `AIToolSafetyLevel` plus the read-only Labs toggle.
///
/// `isReadOnly` is closure-injected (not read directly) because the toggle lives
/// in app-target Labs settings; the assistant module stays UI-agnostic and the
/// host wires the closure at construction. Every `.unsafe` write requires
/// confirmation: there is no auto-execute path for mutations regardless of
/// shape, so the merchant always taps through.
public struct DefaultSafetyPolicy: SafetyPolicy {

    private let isReadOnly: @Sendable () -> Bool

    public init(isReadOnly: @escaping @Sendable () -> Bool) {
        self.isReadOnly = isReadOnly
    }

    public func decision(for name: String, arguments: String, tool: AITool) -> SafetyDecision {
        switch tool.safetyLevel {
        case .safe:
            return .execute
        case .unsafe:
            if isReadOnly() {
                return .block(reason: readOnlyBlockMessage(for: name))
            }
            return .requireConfirmation(preview: ToolPreviews.defaultBuilder(name, arguments))
        }
    }

    private func readOnlyBlockMessage(for name: String) -> String {
        "Read-only mode is on - the assistant can't run '\(name)'. Toggle it off in Labs settings to allow this change."
    }
}
