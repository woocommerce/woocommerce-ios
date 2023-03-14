import Foundation

/// Helpers for `ProductsTabProductViewModel` from `ProductFormDataModel`.
extension ProductFormDataModel {
    /// Create a description text based on a product data model's stock status/quantity.
    func createStockText(productBundlesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productBundles)) -> String {
        // When feature flag is enabled: If product is a product bundle with a bundle stock status, use that as the product stock status.
        let stockStatus = {
            switch (productBundlesEnabled, productType, bundleStockStatus) {
            case (true, .bundle, .some(let bundleStockStatus)):
                return bundleStockStatus
            default:
                return self.stockStatus
            }
        }()

        switch stockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
                return String.localizedStringWithFormat(format, localizedStockQuantity)
            } else {
                return NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
            }
        default:
            return stockStatus.description
        }
    }
}
