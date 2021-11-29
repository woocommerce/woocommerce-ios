import SwiftUI

/// Autofocus for `TextField` and `TextEditor` in iOS 15 and later
///
struct AutofocusTextModifier: ViewModifier {

    @available(iOS 15.0, *)
    @FocusState private var textFieldIsFocused: Bool

    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .focused($textFieldIsFocused)
                .onAppear {
                    // Without delay '.focused' will not work. This might fix in later releases.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        textFieldIsFocused = true
                    }
                }
        }
        else {
            content
        }
    }
}


// MARK: View extension

extension View {

    /// Autofocus in `TextField` and `TextEditor` is available only for iOS15+
    ///
    func focused() -> some View {
        self.modifier(AutofocusTextModifier())
    }
}
