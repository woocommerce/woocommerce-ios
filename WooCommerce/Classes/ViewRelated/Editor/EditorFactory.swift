import Yosemite

/// This class takes care of instantiating the correct editor based on the App settings, feature flags,
/// etc.
///
class EditorFactory {

    // MARK: - Editor: Instantiation

    func instantiateEditor(for product: Product) -> UIViewController {
        return AztecEditorViewController(content: product.fullDescription)
    }
}
