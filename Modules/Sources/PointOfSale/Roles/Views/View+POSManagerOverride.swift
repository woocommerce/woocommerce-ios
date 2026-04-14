import SwiftUI

extension View {
    /// Attaches a manager override modal driven by the given handler.
    /// Use with `POSManagerOverrideHandler.requestPermission(...)` to gate restricted actions.
    func posManagerOverrideModal(handler: POSManagerOverrideHandler,
                                 permissions: POSPermissionProviding) -> some View {
        posModal(isPresented: Binding(
            get: { handler.isShowingOverride },
            set: { if !$0 { handler.cancel() } }
        )) {
            POSManagerOverrideView(
                actionDescription: handler.actionDescription,
                overrideState: handler.overrideState,
                onPINEntered: { pin in
                    Task { @MainActor in
                        await handler.handlePINEntered(pin, permissions: permissions)
                    }
                },
                onCancelled: {
                    handler.cancel()
                }
            )
        }
    }
}
