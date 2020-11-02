import Yosemite

protocol Editor {
    typealias OnContentSave = (_ content: String) -> Void
    var onContentSave: OnContentSave? { get }
}

/// This class takes care of instantiating the editor.
///
final class EditorFactory {

    // MARK: - Editor: Instantiation

    func productDescriptionEditor(product: ProductFormDataModel,
                                  onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let navigationTitle = NSLocalizedString("Description", comment: "The navigation bar title of the Aztec editor screen.")
        let viewProperties = EditorViewProperties(navigationTitle: navigationTitle, showSaveChangesActionSheet: true)
        let editor = AztecEditorViewController(content: product.description, viewProperties: viewProperties)
        editor.onContentSave = onContentSave
        return editor
    }

    func productShortDescriptionEditor(product: ProductFormDataModel,
                                       onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let navigationTitle = NSLocalizedString("Short description",
                                                comment: "The navigation bar title of the edit short description screen.")
        let viewProperties = EditorViewProperties(navigationTitle: navigationTitle, showSaveChangesActionSheet: true)
        let editor = AztecEditorViewController(content: product.shortDescription, viewProperties: viewProperties)
        editor.onContentSave = onContentSave
        return editor
    }
}
