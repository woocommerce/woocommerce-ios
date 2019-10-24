import Yosemite

protocol Editor {
    typealias OnContentSave = (_ content: String) -> Void
    var onContentSave: OnContentSave? { get }

    init(content: String?)
}

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    // MARK: - Editor: Instantiation

    func instantiateEditor(for product: Product, onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let editor = AztecEditorViewController(content: product.fullDescription)
        editor.onContentSave = onContentSave
        return editor
    }
}
