import SwiftUI

/// Clear the original binding too, so a discarded or delayed dialog cannot return on unlock.
struct POSDismissPresentationOnLock<Value: Equatable>: ViewModifier {
    @Environment(\.posAccessSession) private var session
    @Binding var value: Value
    let dismissedValue: Value
    var enabled = true

    func body(content: Content) -> some View {
        content
            .onChange(of: session.isLocked, initial: true) { dismissIfLocked() }
            .onChange(of: value) { dismissIfLocked() }
    }

    private func dismissIfLocked() {
        if enabled, session.isLocked, value != dismissedValue { value = dismissedValue }
    }
}
