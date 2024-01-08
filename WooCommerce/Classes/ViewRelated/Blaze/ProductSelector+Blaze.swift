import Foundation

extension ProductSelectorView.Configuration {
    static let configurationForBlaze = ProductSelectorView.Configuration(
        multipleSelectionEnabled: false,
        treatsAllProductsAsSimple: true,
        prefersLargeTitle: false,
        title: BlazeLocalization.productSelectorTitle,
        cancelButtonTitle: BlazeLocalization.productSelectorCancel,
        productRowAccessibilityHint: BlazeLocalization.productRowAccessibilityHint,
        variableProductRowAccessibilityHint: BlazeLocalization.variableProductRowAccessibilityHint
    )

    enum BlazeLocalization {
        static let productSelectorTitle = NSLocalizedString(
            "configurationForBlaze.productSelectorTitle",
            value: "Ready to promote",
            comment: "Title for the screen to select product for Blaze campaign")
        static let productSelectorCancel = NSLocalizedString(
            "configurationForBlaze.productSelectorCancel",
            value: "Cancel",
            comment: "Text for the cancel button in the Add Product screen")
        static let productRowAccessibilityHint = NSLocalizedString(
            "configurationForBlaze.productRowAccessibilityHint",
            value: "Selects product for Blaze campaign.",
            comment: "Accessibility hint for selecting a product in the Add Product screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "configurationForBlaze.variableProductRowAccessibilityHint",
            value: "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Add Product screen"
        )
    }
}
