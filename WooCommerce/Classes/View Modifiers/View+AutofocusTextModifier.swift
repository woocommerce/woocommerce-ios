import SwiftUI

/// Autofocus for `TextField` and `TextEditor` in iOS 15 and later
///
@available(iOS 15.0, *)
struct AutofocusTextModifier: ViewModifier {

    @FocusState private var textFieldIsFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($textFieldIsFocused)
            .onAppear {
                // Without delay '.focused' will not work. This might fix in later releases.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    textFieldIsFocused = true
                }
            }
    }
}


// MARK: View extension

extension View {

    /// Autofocus in `TextField` and `TextEditor` is available only for iOS15+
    ///
    func focused() -> some View {
        Group {
            if #available(iOS 15.0, *) {
                self.modifier(AutofocusTextModifier())
            } else {
                self
            }
        }
    }
}
