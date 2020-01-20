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
    private let total: NSDecimalNumber

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
        return positiveQuantity.description
    }

    /// Refunded Product Price
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        guard positiveQuantity > 1 else {
            return currencyFormatter.formatAmount(total, with: currency) ?? String()
        }

        let itemTotal = currencyFormatter.formatAmount(total, with: currency) ?? String()
        let itemSubtotal = currencyFormatter.formatAmount(positivePrice, with: currency) ?? String()

        let priceTemplate = NSLocalizedString("%@ (%@ x %@)",
                                              comment: "<item total> (<item individual price> multipled by <quantity>)")
        let priceText = String.localizedStringWithFormat(priceTemplate, itemTotal, itemSubtotal, quantity)

        return priceText
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
        self.total = currencyFormatter.convertToDecimal(from: item.total)?.abs() ?? NSDecimalNumber.zero
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
        self.total = aggregateItem.total.abs()
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
        self.total = currencyFormatter.convertToDecimal(from: refundedItem.total)?.abs() ?? NSDecimalNumber.zero
        self.positivePrice = refundedItem.price.abs()
        self.skuText = refundedItem.sku
    }
}
