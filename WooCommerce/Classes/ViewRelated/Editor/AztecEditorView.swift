import SwiftUI

struct AztecEditorView: UIViewControllerRepresentable {
    let initialValue: String

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: initialValue)
        return controller as! AztecEditorViewController
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
    }
}
