import Foundation
import UIKit
import Yosemite

extension String {
    /// Create a description text based on a product data model's stock status/quantity.
    static func createStockText(productType: ProductType,
                                manageStock: Bool,
                                stockStatus: ProductStockStatus,
                                stockQuantity: Decimal?,
                                bundleStockStatus: ProductStockStatus?,
                                bundleStockQuantity: Int64?) -> String {
        if productType == .bundle {
            return createProductBundleStockText(manageStock: manageStock,
                                                productStockStatus: stockStatus,
                                                stockQuantity: stockQuantity,
                                                bundleStockStatus: bundleStockStatus,
                                                bundleStockQuantity: bundleStockQuantity)
        }

        switch stockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(Localization.stockQuantity, localizedStockQuantity)
            } else {
                return Localization.inStock
            }
        default:
            return stockStatus.description
        }
    }

    /// Create a description text based on a product bundle data model's stock status/quantity and bundle stock status/quantity.
    private static func createProductBundleStockText(manageStock: Bool,
                                                     productStockStatus: ProductStockStatus,
                                                     stockQuantity: Decimal?,
                                                     bundleStockStatus: ProductStockStatus?,
                                                     bundleStockQuantity: Int64?) -> String {
        // Use bundle stock status if it is insufficent stock
        if let bundleStockStatus, bundleStockStatus == .insufficientStock {
            return bundleStockStatus.description
        }

        switch productStockStatus {
        case .inStock:
            let quantityFormat = Localization.stockQuantity
            if let bundleStockQuantity { // Use bundle stock quantity, if set
                let localizedStockQuantity = NumberFormatter.localizedString(from: NSDecimalNumber(value: bundleStockQuantity), number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else if let stockQuantity, manageStock { // Otherwise, use product stock quantity if set and product manages stock
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else {
                return Localization.inStock
            }
        default:
            return productStockStatus.description
        }
    }
}

private enum Localization {
    static let inStock = NSLocalizedString(
        "string.createStockText.inStock",
        value: "In stock",
        comment: "Label about product's inventory stock status shown on Products tab"
    )

    static let stockQuantity = NSLocalizedString(
        "string.createStockText.count",
        value: "%1$@ in stock",
        comment: "Label about product's inventory stock status shown on Products tab " +
        "Placeholder is the stock quantity. Reads as: '20 in stock'."
    )
}
