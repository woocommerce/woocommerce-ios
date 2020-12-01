import Foundation
import Yosemite


// MARK: - View Model for a product details cell
//
struct ProductDetailsCellViewModel {
    /// An attribute of order for product details UI.
    struct OrderAttributeViewModel {
        /// The value of the attribute.
        let value: String
    }

    // MARK: - Private properties

    /// Yosemite.Order.currency
    ///
    private let currency: String

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

    /// Attributes of an order item.
    ///
    private let attributes: [OrderAttributeViewModel]

    // MARK: - Public properties

    /// The first available image for a product/variation.
    ///
    let imageURL: URL?

    /// Item Name
    ///
    let name: String

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

        return Localization.subtitle(quantity: quantity, price: itemPrice, attributes: attributes)
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

    // MARK: - Initializers

    /// Order Item initializer
    ///
    init(item: OrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.imageURL = product?.imageURL
        self.name = item.name
        self.positiveQuantity = abs(item.quantity)
        self.positiveTotal = currencyFormatter.convertToDecimal(from: item.total)?.abs() ?? NSDecimalNumber.zero
        self.positivePrice = item.price.abs()
        self.skuText = item.sku
        self.attributes = item.attributes.map { OrderAttributeViewModel(orderItemAttribute: $0) }
    }

    /// Aggregate Order Item initializer
    ///
    init(aggregateItem: AggregateOrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.imageURL = aggregateItem.imageURL ?? product?.imageURL
        self.name = aggregateItem.name
        self.positiveQuantity = abs(aggregateItem.quantity)
        self.positiveTotal = aggregateItem.total.abs()
        self.positivePrice = aggregateItem.price.abs()
        self.skuText = aggregateItem.sku
        self.attributes = aggregateItem.attributes.map { OrderAttributeViewModel(orderItemAttribute: $0) }
    }

    /// Refunded Order Item initializer
    ///
    init(refundedItem: OrderItemRefund,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.currency = currency
        self.currencyFormatter = formatter
        self.imageURL = product?.imageURL
        self.name = refundedItem.name
        self.positiveQuantity = abs(refundedItem.quantity)
        self.positiveTotal = currencyFormatter.convertToDecimal(from: refundedItem.total)?.abs() ?? NSDecimalNumber.zero
        self.positivePrice = refundedItem.price.abs()
        self.skuText = refundedItem.sku
        // Attributes are not supported for a refund item yet.
        self.attributes = []
    }
}

// MARK: - Localization

private extension ProductDetailsCellViewModel {
    enum Localization {
        static let subtitleFormat =
            NSLocalizedString("%1$@ x %2$@", comment: "In Order Details,"
                                + " the pattern used to show the quantity multiplied by the price. For example, “23 x $400.00”."
                                + " The %1$@ is the quantity. The %2$@ is the formatted price with currency (e.g. $400.00).")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@ x %3$@", comment: "In Order Details > product details: if the product has attributes,"
                                + " the pattern used to show the attributes and quantity multiplied by the price. For example, “purple, has logo・23 x $400.00”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the quantity. The %3$@ is the formatted price with currency (e.g. $400.00).")
        static func subtitle(quantity: String, price: String, attributes: [OrderAttributeViewModel]) -> String {
            let attributesText = attributes.map { $0.value }.joined(separator: ", ")
            if attributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, quantity, price)
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, quantity, price)
            }
        }
    }
}

private extension ProductDetailsCellViewModel.OrderAttributeViewModel {
    init(orderItemAttribute: OrderItemAttribute) {
        self.value = orderItemAttribute.value
    }
}

private extension Product {
    /// Returns the URL of the first image, if available. Otherwise, nil is returned.
    var imageURL: URL? {
        guard let productImageURLString = images.first?.src else {
            return nil
        }
        return URL(string: productImageURLString)
    }
}
