import Foundation

/// Helpers for `ProductsTabProductViewModel` from `ProductFormDataModel`.
extension ProductFormDataModel {
    /// Create a description text based on a product data model's stock status/quantity.
    func createStockText(productBundlesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productBundles)) -> String {
        if productBundlesEnabled && productType == .bundle {
            return createProductBundleStockText()
        }

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

    /// Create a description text based on a product bundle data model's stock status/quantity and bundle stock status/quantity.
    private func createProductBundleStockText() -> String {
        // Use bundle stock status if it is insufficent stock
        if let bundleStockStatus, bundleStockStatus == .insufficientStock {
            return bundleStockStatus.description
        }

        switch stockStatus {
        case .inStock:
            let quantityFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
            if let bundleStockQuantity { // Use bundle stock quantity, if set
                let localizedStockQuantity = NumberFormatter.localizedString(from: NSDecimalNumber(value: bundleStockQuantity), number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else if let stockQuantity, manageStock { // Otherwise, use product stock quantity if set and product manages stock
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else {
                return NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
            }
        default:
            return stockStatus.description
        }
    }
}
