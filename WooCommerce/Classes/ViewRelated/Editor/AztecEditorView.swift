import SwiftUI
/// A SwiftUI wrapper for the Aztec rich text editor.
/// Because `AztecViewController` has its own navigation bar that does not appear when shown with `UIViewControllerRepresentable`,
/// this view wraps Aztec in a `UINavigationController` to make the bar appear. This is especially needed to ensure that
/// Aztec's "Done" button is shown.
///
/// - Parameter initialValue: The initial value of the editor.
/// - Parameter onCancel: Optional closure to add to call when the user cancels the editor. Adds a "Cancel" button to the
///                       navigation bar.
///
struct AztecEditorView: UIViewControllerRepresentable {
    let initialValue: String
    let onCancel: (() -> Void)?

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = EditorFactory().customFieldRichTextEditor(initialValue: initialValue)
        let navigationController = UINavigationController(rootViewController: controller)

        if onCancel != nil {
            let cancelButton = UIBarButtonItem(title: Localization.cancel,
                                               style: .plain,
                                               target: context.coordinator,
                                               action: #selector(Coordinator.onCancel))
            controller.navigationItem.leftBarButtonItem = cancelButton
        }

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: AztecEditorView

        init(_ aztecEditorView: AztecEditorView) {
            self.parent = aztecEditorView
        }

        @objc func onCancel() {
            parent.onCancel?()
        }
    }
}

private extension AztecEditorView {
    enum Localization {
        static let cancel = NSLocalizedString(
            "aztedEditorView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Aztec Editor View"
        )
    }
}
