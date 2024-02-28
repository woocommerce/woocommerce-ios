import Foundation

extension ProductSelectorView.Configuration {
    static let configurationForOrder = ProductSelectorView.Configuration(
        multipleSelectionEnabled: false,
        treatsAllProductsAsSimple: true,
        prefersLargeTitle: false,
        title: Localization.productSelectorTitle,
        cancelButtonTitle: Localization.productSelectorCancel,
        productRowAccessibilityHint: Localization.productRowAccessibilityHint,
        variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint
    )

    private enum Localization {
        static let productSelectorTitle = NSLocalizedString(
            "configurationForOrder.productSelectorTitle",
            value: "Product",
            comment: "Title for the screen to select product for filtering orders")
        static let productSelectorCancel = NSLocalizedString(
            "configurationForOrder.productSelectorCancel",
            value: "Cancel",
            comment: "Text for the cancel button in the Product selector screen")
        static let productRowAccessibilityHint = NSLocalizedString(
            "configurationForOrder.productRowAccessibilityHint",
            value: "Selects product for filtering order.",
            comment: "Accessibility hint for selecting a product from the order filter screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "configurationForOrder.variableProductRowAccessibilityHint",
            value: "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product to select product for filtering orders"
        )
    }
}
