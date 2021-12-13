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
        let viewProperties = EditorViewProperties(navigationTitle: Localization.productDescriptionTitle,
                                                  placeholderText: Localization.placeholderText(product: product),
                                                  showSaveChangesActionSheet: true)
        let editor = AztecEditorViewController(content: product.description, viewProperties: viewProperties)
        editor.onContentSave = onContentSave
        return editor
    }

    func productShortDescriptionEditor(product: ProductFormDataModel,
                                       onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let viewProperties = EditorViewProperties(navigationTitle: Localization.productShortDescriptionTitle,
                                                  placeholderText: Localization.placeholderText(product: product),
                                                  showSaveChangesActionSheet: true)
        let editor = AztecEditorViewController(content: product.shortDescription, viewProperties: viewProperties)
        editor.onContentSave = onContentSave
        return editor
    }
}

private extension EditorFactory {

    enum Localization {
        static let productDescriptionTitle = NSLocalizedString("Description",
                                                               comment: "The navigation bar title of the Aztec editor screen.")
        static let productShortDescriptionTitle = NSLocalizedString("Short description",
                                                                    comment: "The navigation bar title of the edit short description screen.")
        static let placeholderDefault = NSLocalizedString("Describe your product to your future customers...",
                                                          comment: "The default placeholder text for the of the Aztec editor screen.")
        static let placeholderFormat = NSLocalizedString("Tell us more about %1$@...",
                                                         comment: "The placeholder text for the of the Aztec editor screen.")

        static func placeholderText(product: ProductFormDataModel) -> String {
            guard product.name.isNotEmpty else {
                return placeholderDefault
            }
            return String(format: Localization.placeholderFormat, product.name)
        }
    }
}
