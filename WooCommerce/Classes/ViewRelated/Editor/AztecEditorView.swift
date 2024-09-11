import SwiftUI

/// `UIViewControllerRepresentable` to use an Aztec Editor in SwiftUI.
/// This view needs to be wrapped inside a parent View that manages its states and toolbar as needed.
/// Params:
/// - value: Binding to the content of the editor.
/// - viewController: To get the content of the editor, the parent View can pass this and then call `getLatestContent()`
///
struct AztecEditorView: UIViewControllerRepresentable {
    @Binding var value: String
    @Binding var viewController: AztecEditorViewController?

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: value) as! AztecEditorViewController
        viewController = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
    }
}
