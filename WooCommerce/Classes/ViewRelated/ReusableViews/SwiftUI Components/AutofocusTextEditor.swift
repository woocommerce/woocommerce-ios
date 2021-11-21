import SwiftUI

/// Renders a TextEditor with autofocus in iOS 15 and later devices
///
struct AutofocusTextEditor: View {

    @Binding var text: String

    @available(iOS 15.0, *)
    @FocusState private var textEditorIsFocused: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            TextEditor(text: $text)
                .focused($textEditorIsFocused)
                .onAppear {
                    // Without delay '.focused' will not work. This might fix in later releases.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        textEditorIsFocused = true
                    }
                }
        }
        else {
            TextEditor(text: $text)
        }
    }
}

// MARK: - Preview
struct AutofocusTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        AutofocusTextEditor(text: .constant("Sample Note"))
    }
}
