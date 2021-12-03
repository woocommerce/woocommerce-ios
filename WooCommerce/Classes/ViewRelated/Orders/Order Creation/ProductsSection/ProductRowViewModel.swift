import Foundation
import Yosemite

/// View model for `ProductRow`.
///
final class ProductRowViewModel: ObservableObject, Identifiable {
    /// Product ID
    /// Required by SwiftUI as a unique identifier
    ///
    let id: Int64

    private let currencyFormatter: CurrencyFormatter

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    let canChangeQuantity: Bool

    /// Product to display
    ///
    private let product: Product

    /// Label showing product name
    ///
    let nameLabel: String

    /// Label showing product stock status and price.
    ///
    lazy var stockAndPriceLabel: String = {
        let stockLabel = createStockText()
        let priceLabel = createPriceText()

        return [stockLabel, priceLabel]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }()

    /// Label showing product SKU
    ///
    lazy var skuLabel: String = {
        guard let sku = product.sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }()

    /// Quantity of product in the order
    ///
    @Published var quantity: Int64 = 1

    init(product: Product,
         canChangeQuantity: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.id = product.productID
        self.product = product
        self.nameLabel = product.name
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

// MARK: SwiftUI Preview Helpers
extension ProductRowViewModel {
    static let sampleProduct = Product().copy(productID: 2, name: "Love Ficus", sku: "123456", price: "20", stockQuantity: 7, stockStatusKey: "instock")
}
