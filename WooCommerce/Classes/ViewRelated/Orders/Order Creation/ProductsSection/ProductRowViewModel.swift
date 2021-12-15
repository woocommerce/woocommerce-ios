import Foundation
import Yosemite

/// View model for `ProductRow`.
///
final class ProductRowViewModel: ObservableObject, Identifiable, Equatable {
    private let currencyFormatter: CurrencyFormatter

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    let canChangeQuantity: Bool

    /// Closure to be invoked when the quantity changes
    ///
    private let onQuantityChange: ((Decimal) -> Void)?

    // MARK: Product properties

    /// Product ID
    ///
    let id: Int64

    /// Product name
    ///
    let name: String

    /// Product SKU
    ///
    private let sku: String?

    /// Product price
    ///
    private let price: String

    /// Product stock status
    ///
    private let stockStatus: ProductStockStatus

    /// Product stock quantity
    ///
    private let stockQuantity: Decimal?

    /// Whether the product's stock quantity is managed
    ///
    private let manageStock: Bool

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
        guard let sku = sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }()

    /// Quantity of product in the order
    ///
    @Published private(set) var quantity: Decimal = 1 {
        willSet {
            onQuantityChange?(newValue)
        }
    }

    /// Whether the quantity can be decremented.
    /// Quantity has a minimum value of 1.
    ///
    var shouldDisableQuantityDecrementer: Bool {
        quantity <= 1
    }

    init(id: Int64,
         name: String,
         sku: String?,
         price: String,
         stockStatusKey: String,
         stockQuantity: Decimal?,
         manageStock: Bool,
         canChangeQuantity: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         onQuantityChange: ((Decimal) -> Void)? = nil) {
        self.id = id
        self.name = name
        self.sku = sku
        self.price = price
        self.stockStatus = .init(rawValue: stockStatusKey)
        self.stockQuantity = stockQuantity
        self.manageStock = manageStock
        self.canChangeQuantity = canChangeQuantity
        self.currencyFormatter = currencyFormatter
        self.onQuantityChange = onQuantityChange
    }

    convenience init(product: Product,
                     canChangeQuantity: Bool,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     onQuantityChange: ((Decimal) -> Void)? = nil) {
        self.init(id: product.productID,
                  name: product.name,
                  sku: product.sku,
                  price: product.price,
                  stockStatusKey: product.stockStatusKey,
                  stockQuantity: product.stockQuantity,
                  manageStock: product.manageStock,
                  canChangeQuantity: canChangeQuantity,
                  currencyFormatter: currencyFormatter,
                  onQuantityChange: onQuantityChange)
    }

    /// Create the stock text based on a product's stock status/quantity.
    ///
    private func createStockText() -> String {
        switch stockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(Localization.stockFormat, localizedStockQuantity)
            } else {
                return stockStatus.description
            }
        default:
            return stockStatus.description
        }
    }

    /// Create the price text based on a product's price.
    ///
    private func createPriceText() -> String? {
        let unformattedPrice = price.isNotEmpty ? price : "0"
        return currencyFormatter.formatAmount(unformattedPrice)
    }

    /// Increment the product quantity.
    ///
    func incrementQuantity() {
        quantity += 1
    }

    /// Decrement the product quantity.
    /// This must check that the quantity is above the minimum value before decrementing it.
    ///
    func decrementQuantity() {
        guard shouldDisableQuantityDecrementer == false else {
            return
        }
        quantity -= 1
    }
}

private extension ProductRowViewModel {
    enum Localization {
        static let stockFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
    }
}

extension ProductRowViewModel {
    static func == (lhs: ProductRowViewModel, rhs: ProductRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
