import SwiftUI

/// `UIViewControllerRepresentable` to use an Aztec Editor in SwiftUI.
/// This view needs to be wrapped inside a parent View that manages its states and toolbar as needed.
/// Params:
/// - value: Binding to the content of the editor.
/// - viewController: To get the content of the editor, the parent View can pass this and then call `getLatestContent()`
///
struct AztecEditorView: UIViewControllerRepresentable {
    @Binding var value: String
    let onContentChanged: (String) -> Void

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: value)

        guard let aztecController = controller as? AztecEditorViewController else {
            fatalError("EditorFactory must return an AztecEditorViewController, but returned \(type(of: controller))")
        }

        aztecController.onContentChanged = onContentChanged
        return controller as! AztecEditorViewController
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
    }
}
