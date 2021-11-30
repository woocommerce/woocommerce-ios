import Foundation
import Yosemite

/// View model for `ProductRow`.
///
final class ProductRowViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    let canChangeQuantity: Bool

    /// Product to display
    ///
    let product: Product

    /// Label showing product name
    ///
    var nameLabel: String {
        product.name
    }

    /// Label showing product stock status and price.
    ///
    var stockAndPriceLabel: String {
        let stockLabel = createStockText()
        let priceLabel = createPriceText()

        return [stockLabel, priceLabel]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }

    /// Label showing product SKU
    ///
    var skuLabel: String {
        guard let sku = product.sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }

    /// Quantity of product in the order
    ///
    var quantity: Int64 = 1

    init(product: Product,
         canChangeQuantity: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.product = product
        self.canChangeQuantity = canChangeQuantity
        self.currencyFormatter = currencyFormatter
    }

    /// Create the stock text based on a product's stock status/quantity.
    ///
    private func createStockText() -> String {
        switch product.productStockStatus {
        case .inStock:
            if let stockQuantity = product.stockQuantity, product.manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(Localization.stockFormat, localizedStockQuantity)
            } else {
                return product.productStockStatus.description
            }
        default:
            return product.productStockStatus.description
        }
    }

    /// Create the price text based on a product's price.
    ///
    private func createPriceText() -> String? {
        let unformattedPrice = product.price.isNotEmpty ? product.price : "0"
        return currencyFormatter.formatAmount(unformattedPrice)
    }
}

private extension ProductRowViewModel {
    enum Localization {
        static let stockFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
    }
}
