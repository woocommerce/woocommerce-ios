import Yosemite

protocol Editor {
    typealias OnContentSave = (_ content: String, _ additionalInfo: String?) -> Void
    var onContentSave: OnContentSave? { get }
}

/// This class takes care of instantiating the editor.
///
final class EditorFactory {
    struct EditorContext {
        let initialContent: String?
        let navigationTitle: String
        let placeholderText: String
        let showSaveChangesActionSheet: Bool
        let isAIGenerationEnabled: Bool
    }

    // MARK: - Editor: Instantiation

    func productDescriptionEditor(product: ProductFormDataModel,
                                  isAIGenerationEnabled: Bool,
                                  onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let context = EditorContext(
            initialContent: product.description,
            navigationTitle: Localization.productDescriptionTitle,
            placeholderText: Localization.placeholderText(product: product),
            showSaveChangesActionSheet: true,
            isAIGenerationEnabled: isAIGenerationEnabled
        )

        return createEditor(context: context, product: product, onContentSave: onContentSave)
    }

    func productShortDescriptionEditor(product: ProductFormDataModel,
                                       onContentSave: @escaping Editor.OnContentSave) -> Editor & UIViewController {
        let context = EditorContext(
            initialContent: product.shortDescription,
            navigationTitle: Localization.productShortDescriptionTitle,
            placeholderText: Localization.placeholderText(product: product),
            showSaveChangesActionSheet: true,
            isAIGenerationEnabled: false
        )

        return createEditor(context: context, product: product, onContentSave: onContentSave)
    }

    // onContentSave is optional because this can be used in SwiftUI with `UIViewControllerRepresentable` and the
    // saving callback is to be managed separately there.
    func customFieldRichTextEditor(initialValue: String,
                                   onContentSave: Editor.OnContentSave? = nil) -> Editor & UIViewController {
        let context = EditorContext(
            initialContent: initialValue,
            navigationTitle: Localization.customFieldsValueTitle,
            placeholderText: Localization.customFieldsValuePlaceholder,
            showSaveChangesActionSheet: true,
            isAIGenerationEnabled: false
        )

        return createEditor(context: context, onContentSave: onContentSave)
    }

    func createEditor(context: EditorContext,
                      product: ProductFormDataModel? = nil,
                      onContentSave: Editor.OnContentSave?) -> Editor & UIViewController {
        let viewProperties = EditorViewProperties(
            navigationTitle: context.navigationTitle,
            placeholderText: context.placeholderText,
            showSaveChangesActionSheet: context.showSaveChangesActionSheet
        )

        let editor = AztecEditorViewController(
            content: context.initialContent,
            product: product,
            viewProperties: viewProperties,
            isAIGenerationEnabled: context.isAIGenerationEnabled
        )

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

        static let customFieldsValueTitle = NSLocalizedString(
            "editorFactory.customFieldsValueTitle",
            value: "Value",
            comment: "The value of custom field to be edited.")

        static let customFieldsValuePlaceholder = NSLocalizedString(
            "editorFactory.customFieldsValuePlaceholder",
            value: "Enter custom field value",
            comment: "Placeholder text inside the editor's text field.")

    }
}
