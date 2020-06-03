import Foundation
import Yosemite


// MARK: - View Model for a product details cell
//
struct ProductDetailsCellViewModel {
    // MARK: - Private properties

    /// Yosemite.Order.currency
    ///
    private let currency: String

    /// Yosemite.Product
    ///
    private let product: Product?

    /// Currency Formatter
    ///
    private let currencyFormatter: CurrencyFormatter

    /// Item Quantity
    /// represented as a positive value
    ///
    private let positiveQuantity: Decimal

    /// Item Total
    /// represented as a positive value
    ///
    private let positiveTotal: NSDecimalNumber

    /// Item Price
    /// represented as a positive value
    ///
    private let positivePrice: NSDecimalNumber

    /// Item SKU
    ///
    private let skuText: String?

    // MARK: - Public properties

    /// Item Name
    ///
    var name: String

    /// Item Quantity as a String
    ///
    var quantity: String {
        return NumberFormatter.localizedString(from: positiveQuantity as NSDecimalNumber, number: .decimal)
    }

    /// The localized total value of this line item. This is the quantity x price.
    ///
    var total: String {
        currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
    }

    /// Returns the localized "quantity x price" to use for the subtitle.
    ///
    var subtitle: String {
        let itemPrice = currencyFormatter.formatAmount(positivePrice, with: currency) ?? String()

        return Localization.subtitle(quantity: quantity, price: itemPrice)
    }

    /// Item SKU
    ///
    var sku: String? {
        guard let sku = skuText, sku.isEmpty == false else {
            return nil
        }

        let skuTemplate = NSLocalizedString("SKU: %@", comment: "SKU label, followed by the SKU")
        let skuText = String.localizedStringWithFormat(skuTemplate, sku)

        return skuText
    }

    /// Grab the first available image for a product.
    ///
    var imageURL: URL? {
        guard let productImageURLString = product?.images.first?.src else {
            return nil
        }

        return URL(string: productImageURLString)
    }

    // MARK: - Initializers

    /// Order Item initializer
    ///
    init(item: OrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
        self.name = item.name
        self.positiveQuantity = abs(item.quantity)
        self.positiveTotal = currencyFormatter.convertToDecimal(from: item.total)?.abs() ?? NSDecimalNumber.zero
        self.positivePrice = item.price.abs()
        self.skuText = item.sku
    }

    /// Aggregate Order Item initializer
    ///
    init(aggregateItem: AggregateOrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
        self.name = aggregateItem.name
        self.positiveQuantity = abs(aggregateItem.quantity)
        self.positiveTotal = aggregateItem.total.abs()
        self.positivePrice = aggregateItem.price.abs()
        self.skuText = aggregateItem.sku
    }

    /// Refunded Order Item initializer
    ///
    init(refundedItem: OrderItemRefund,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
        self.name = refundedItem.name
        self.positiveQuantity = abs(refundedItem.quantity)
        self.positiveTotal = currencyFormatter.convertToDecimal(from: refundedItem.total)?.abs() ?? NSDecimalNumber.zero
        self.positivePrice = refundedItem.price.abs()
        self.skuText = refundedItem.sku
    }
}

// MARK: - Localization

private extension ProductDetailsCellViewModel {
    enum Localization {
        static func subtitle(quantity: String, price: String) -> String {
            let format = NSLocalizedString("%1$@ x %2$@", comment: "In Order Details,"
                + " the pattern used to show the quantity multiplied by the price. For example, “23 x $400.00”."
                + " The %1$@ is the quantity. The %2$@ is the formatted price with currency (e.g. $400.00).")
            return String.localizedStringWithFormat(format, quantity, price)
        }
    }
}
