import SwiftUI

/// Injected through the SwiftUI environment so confirmation cards can reach
/// `AssistantController` without holding a reference - keeps cards retain
/// cycle free and renderable from previews without a live controller.
struct AssistantConfirmationHandler {
    var onConfirm: (UUID) -> Void = { _ in }
    var onCancel: (UUID) -> Void = { _ in }
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
