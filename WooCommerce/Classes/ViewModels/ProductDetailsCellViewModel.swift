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

    // MARK: - Public properties

    /// The first available image for a product/variation.
    ///
    let imageURL: URL?

    /// Item Name
    ///
    let name: String

    /// Item Quantity as a String
    ///
    let quantity: String

    /// The localized total value of this line item. This is the quantity x price.
    ///
    let total: String

    /// Returns the localized "quantity x price" to use for the subtitle.
    ///
    let subtitle: String

    /// Item SKU
    ///
    let sku: String?

    // MARK: - Initializers

    private init(currency: String,
                 currencyFormatter: CurrencyFormatter,
                 imageURL: URL?,
                 name: String,
                 positiveQuantity: Decimal,
                 positiveTotal: NSDecimalNumber?,
                 positivePrice: NSDecimalNumber?,
                 skuText: String?,
                 attributes: [OrderAttributeViewModel]) {
        self.imageURL = imageURL
        self.name = name
        let quantity = NumberFormatter.localizedString(from: positiveQuantity as NSDecimalNumber, number: .decimal)
        self.quantity = quantity
        self.sku = {
            guard let sku = skuText, sku.isEmpty == false else {
                return nil
            }
            return String.localizedStringWithFormat(Localization.skuFormat, sku)
        }()

        self.total = {
            guard let positiveTotal = positiveTotal else {
                return String()
            }
            return currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
        }()

        self.subtitle = {
            guard let positivePrice = positivePrice else {
                return String()
            }
            let itemPrice = currencyFormatter.formatAmount(positivePrice, with: currency) ?? String()
            return Localization.subtitle(quantity: quantity, price: itemPrice, attributes: attributes)
        }()
    }

    /// Order Item initializer
    ///
    init(item: OrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.init(currency: currency,
                  currencyFormatter: formatter,
                  imageURL: product?.imageURL,
                  name: item.name,
                  positiveQuantity: abs(item.quantity),
                  positiveTotal: formatter.convertToDecimal(from: item.total)?.abs() ?? NSDecimalNumber.zero,
                  positivePrice: item.price.abs(),
                  skuText: item.sku,
                  attributes: item.attributes.map { OrderAttributeViewModel(orderItemAttribute: $0) })
    }

    /// Aggregate Order Item initializer
    ///
    init(aggregateItem: AggregateOrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.init(currency: currency,
                  currencyFormatter: formatter,
                  imageURL: aggregateItem.imageURL ?? product?.imageURL,
                  name: aggregateItem.name,
                  positiveQuantity: abs(aggregateItem.quantity),
                  positiveTotal: aggregateItem.total?.abs(),
                  positivePrice: aggregateItem.price?.abs(),
                  skuText: aggregateItem.sku,
                  attributes: aggregateItem.attributes.map { OrderAttributeViewModel(orderItemAttribute: $0) })
    }

    /// Refunded Order Item initializer
    ///
    init(refundedItem: OrderItemRefund,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil) {
        self.init(currency: currency,
                  currencyFormatter: formatter,
                  imageURL: product?.imageURL,
                  name: refundedItem.name,
                  positiveQuantity: abs(refundedItem.quantity),
                  positiveTotal: formatter.convertToDecimal(from: refundedItem.total)?.abs() ?? NSDecimalNumber.zero,
                  positivePrice: refundedItem.price.abs(),
                  skuText: refundedItem.sku,
                  attributes: []) // Attributes are not supported for a refund item yet.
    }
}

// MARK: - Localization

private extension ProductDetailsCellViewModel {
    enum Localization {
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
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
