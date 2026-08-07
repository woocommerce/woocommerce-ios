import Foundation

/// Test-only localized strings for exercising translation-context suggestions.
enum TranslationContextPluginTest {
    static let saveOrderButtonTitle = NSLocalizedString(
        "translation.context.test.order.saveButtonTitle",
        value: "Save",
        comment: "Button title"
    )

    static let processingOrderStatus = NSLocalizedString(
        "translation.context.test.order.processingStatus",
        value: "Processing",
        comment: ""
    )

    static let orderNotePlaceholder = NSLocalizedString(
        "translation.context.test.order.notePlaceholder",
        value: "Add a note",
        comment: ""
    )
}
