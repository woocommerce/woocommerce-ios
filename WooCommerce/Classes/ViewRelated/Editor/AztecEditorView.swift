import SwiftUI

/// `UIViewControllerRepresentable` to use an Aztec Editor in SwiftUI.
/// Params:
/// - content: the content of the editor. It's a Binding so that the parent View can get the latest Editor content.
///
struct AztecEditorView: UIViewControllerRepresentable {
    @Binding var content: String

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: content)
        var ignoreInitialContent = true

        guard let aztecController = controller as? AztecEditorViewController else {
            fatalError("EditorFactory must return an AztecEditorViewController, but returned \(type(of: controller))")
        }

        aztecController.onContentChanged = { text in
            /// In addition to user's change action, this callback is invokeddssd during the View Controller's `viewDidLoad` too.
            /// This check is needed to avoid setting the value back to the binding at that point, as doing so will trigger the
            /// "Modifying state during view update, this will cause undefined behavior" issue.
            if ignoreInitialContent {
                ignoreInitialContent = false
                return
            }

            content = text
        }
        return aztecController
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
    }
}
