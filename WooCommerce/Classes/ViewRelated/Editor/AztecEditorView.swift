import SwiftUI

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
