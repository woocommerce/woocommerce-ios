import Yosemite

protocol Editor {
    typealias OnContentSave = (_ content: String, _ additionalInfo: String?) -> Void
    var onContentSave: OnContentSave? { get }
}

/// This class takes care of instantiating the editor.
///
final class EditorFactory {
    struct EditorContext {
        let initialContent: String
        let navigationTitle: String
        let placeholderText: String
        let showSaveChangesActionSheet: Bool
        let additionalInfo: String
        let isAIGenerationEnabled: Bool
    }

    // MARK: - Editor: Instantiation

    func productDescriptionEditor(product: ProductFormDataModel,
                                  isAIGenerationEnabled: Bool,
                                  onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let context = EditorContext(
            initialContent: product.description ?? "",
            navigationTitle: Localization.productDescriptionTitle,
            placeholderText: Localization.placeholderText(product: product),
            showSaveChangesActionSheet: true,
            additionalInfo: product.name,
            isAIGenerationEnabled: isAIGenerationEnabled
        )

        return createEditor(context: context, onContentSave: onContentSave)
    }

    func productShortDescriptionEditor(product: ProductFormDataModel,
                                       onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let context = EditorContext(
            initialContent: product.shortDescription ?? "",
            navigationTitle: Localization.productShortDescriptionTitle,
            placeholderText: Localization.placeholderText(product: product),
            showSaveChangesActionSheet: true,
            additionalInfo: product.name,
            isAIGenerationEnabled: false
        )

        return createEditor(context: context, onContentSave: onContentSave)
    }

    func createEditor(context: EditorContext, onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let viewProperties = EditorViewProperties(
            navigationTitle: context.navigationTitle,
            placeholderText: context.placeholderText,
            showSaveChangesActionSheet: context.showSaveChangesActionSheet
        )

        let editor = AztecEditorViewController(
            content: context.initialContent,
            viewProperties: viewProperties,
            isAIGenerationEnabled: context.isAIGenerationEnabled
        )

        editor.onContentSave = { content, _ in
            onContentSave(content, context.additionalInfo)
        }

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
