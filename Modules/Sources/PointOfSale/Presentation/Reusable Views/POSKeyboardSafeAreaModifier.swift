import SwiftUI
import class WooFoundation.KeyboardObserver

private struct POSKeyboardSafeAreaModifier: ViewModifier {
    @Environment(\.keyboardObserver) private var keyboardObserver

    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(keyboardObserver.isKeyboardVisible ? [] : .keyboard, edges: .bottom)
    }
}

extension View {
    /// A rotated UIKit-hosted presentation can retain SwiftUI's keyboard inset after dismissal.
    /// Apply inside navigation/presentation roots, where each host owns its keyboard region.
    /// Visible keyboards, including the external-keyboard helper bar, keep normal avoidance.
    func posIgnoresHiddenKeyboardSafeArea() -> some View {
        modifier(POSKeyboardSafeAreaModifier())
    }
}
