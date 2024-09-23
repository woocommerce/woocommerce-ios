import SwiftUI

/// `UIViewControllerRepresentable` to use an Aztec Editor in SwiftUI.
/// It can be used as-is, or be wrapped inside a parent View that manages its states and toolbar as needed.
/// Params:
/// - initialValue: Initial value in the editor
/// - onContentChanged: callback to to be called when the content is changed.
///
struct AztecEditorView: UIViewControllerRepresentable {
    let initialValue: String
    let onContentChanged: (String) -> Void

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: initialValue)

        guard let aztecController = controller as? AztecEditorViewController else {
            fatalError("EditorFactory must return an AztecEditorViewController, but returned \(type(of: controller))")
        }

        aztecController.onContentChanged = onContentChanged
        return controller as! AztecEditorViewController
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
    }
}
