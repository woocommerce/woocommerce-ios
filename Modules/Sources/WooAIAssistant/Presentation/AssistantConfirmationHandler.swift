import SwiftUI

/// Environment-injected so confirmation cards stay retain-cycle free and previewable.
struct AssistantConfirmationHandler: Sendable {
    var onConfirm: @MainActor (UUID) -> Void = { _ in }
    var onCancel: @MainActor (UUID) -> Void = { _ in }
}

private struct AssistantConfirmationHandlerKey: EnvironmentKey {
    static let defaultValue = AssistantConfirmationHandler()
}

extension EnvironmentValues {
    var assistantConfirmationHandler: AssistantConfirmationHandler {
        get { self[AssistantConfirmationHandlerKey.self] }
        set { self[AssistantConfirmationHandlerKey.self] = newValue }
    }
}
