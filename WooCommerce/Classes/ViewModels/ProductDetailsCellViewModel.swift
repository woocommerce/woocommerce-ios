import Foundation
import Yosemite
import WooFoundation

// MARK: - View Model for a Variation Attribute
//
struct VariationAttributeViewModel: Equatable {

    /// Attribute name
    ///
    let name: String

    /// Attribute value
    ///
    let value: String?

    /// Returns the attribute value, or "Any \(name)" if the attribute value is nil or empty
    ///
    var nameOrValue: String {
        guard let value = value, value.isNotEmpty else {
            return String(format: Localization.anyAttributeFormat, name)
        }
        return value
    }

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    init(orderItemAttribute: OrderItemAttribute) {
        self.init(name: orderItemAttribute.name, value: orderItemAttribute.value)
    }

    init(productVariationAttribute: ProductVariationAttribute) {
        self.init(name: productVariationAttribute.name, value: productVariationAttribute.option)
    }
}

extension VariationAttributeViewModel {
    enum Localization {
        static let anyAttributeFormat =
            NSLocalizedString("Any %1$@", comment: "Format of a product variation attribute description where the attribute is set to any value.")
    }
}


// MARK: - View Model for a product details cell
//
struct ProductDetailsCellViewModel {

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

    let addOns: AddOnsViewModel

    /// Wether the item has add-ons associated to it.
    ///
    let hasAddOns: Bool

    /// Whether the item is a child with a parent item.
    ///
    let isChildProduct: Bool

    // MARK: - Initializers

    private init(currency: String,
                 currencyFormatter: CurrencyFormatter,
                 imageURL: URL?,
                 name: String,
                 positiveQuantity: Decimal,
                 total: NSDecimalNumber?,
                 price: NSDecimalNumber?,
                 skuText: String?,
                 attributes: [VariationAttributeViewModel],
                 addOns: AddOnsViewModel,
                 hasAddOns: Bool,
                 isChildProduct: Bool) {
        self.imageURL = imageURL
        self.name = name
        let quantity = NumberFormatter.localizedString(from: positiveQuantity as NSDecimalNumber, number: .decimal)
        self.quantity = quantity
        self.hasAddOns = hasAddOns
        self.sku = {
            guard let sku = skuText, sku.isEmpty == false else {
                return nil
            }
            return String.localizedStringWithFormat(Localization.skuFormat, sku)
        }()

        self.total = {
            guard let total = total else {
                return String()
            }
            return currencyFormatter.formatAmount(total, with: currency) ?? String()
        }()

        self.subtitle = {
            guard let price = price else {
                return String()
            }
            let itemPrice = currencyFormatter.formatAmount(price, with: currency) ?? String()
            return Localization.subtitle(quantity: quantity,
                                         price: itemPrice,
                                         attributes: attributes,
                                         addOns: addOns)
        }()

        self.addOns = addOns

        self.isChildProduct = isChildProduct
    }

    /// Order Item initializer
    ///
    init(item: OrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil,
         hasAddOns: Bool,
         isChildWithParent: Bool) {
        self.init(currency: currency,
                  currencyFormatter: formatter,
                  imageURL: product?.imageURL,
                  name: item.name,
                  positiveQuantity: abs(item.quantity),
                  total: formatter.convertToDecimal(item.total) ?? NSDecimalNumber.zero,
                  price: item.price,
                  skuText: item.sku,
                  attributes: item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) },
                  addOns: .init(addOns: item.addOns),
                  hasAddOns: hasAddOns,
                  isChildProduct: isChildWithParent)
    }

    /// Aggregate Order Item initializer
    ///
    init(aggregateItem: AggregateOrderItem,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         product: Product? = nil,
         hasAddOns: Bool,
         isChildWithParent: Bool) {
        self.init(currency: currency,
                  currencyFormatter: formatter,
                  imageURL: aggregateItem.imageURL ?? product?.imageURL,
                  name: aggregateItem.name,
                  positiveQuantity: abs(aggregateItem.quantity),
                  total: aggregateItem.total,
                  price: aggregateItem.price,
                  skuText: aggregateItem.sku,
                  attributes: aggregateItem.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) },
                  addOns: .init(addOns: aggregateItem.addOns),
                  hasAddOns: hasAddOns,
                  isChildProduct: isChildWithParent)
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
                  total: formatter.convertToDecimal(refundedItem.total) ?? NSDecimalNumber.zero,
                  price: refundedItem.price,
                  skuText: refundedItem.sku,
                  attributes: [], // Attributes are not supported for a refund item yet.
                  addOns: .init(addOns: []),
                  hasAddOns: false, // AddOns are not supported for a refund item yet.
                  isChildProduct: false) // Parent/child relationships are not supported for a refund item.
    }
}

// MARK: - Localization

private extension ProductDetailsCellViewModel {
    enum Localization {
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        static let subtitleFormat =
            NSLocalizedString("%1$@ × %2$@", comment: "In Order Details,"
                              + " the pattern used to show the quantity multiplied by the price. For example, “23 × $400.00”."
                              + " The %1$@ is the quantity. The %2$@ is the formatted price with currency (e.g. $400.00)."
                              + " Please take care to use the multiplication symbol ×, not a letter x, where appropriate.")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@ × %3$@", comment: "In Order Details > product details: if the product has attributes,"
                              + " the pattern used to show the attributes and quantity multiplied by the price. For example, “purple, has logo・23 × $400.00”."
                              + " The %1$@ is the list of attributes (e.g. from variation)."
                              + " The %2$@ is the quantity. The %3$@ is the formatted price with currency (e.g. $400.00)."
                              + " Please take care to use the multiplication symbol ×, not a letter x, where appropriate.")
        static func subtitle(quantity: String, price: String, attributes: [VariationAttributeViewModel], addOns: AddOnsViewModel) -> String {
            // Only the attributes that are not in the order item add-ons are shown since add-ons are displayed separately.
            let nonAddOnAttributes: [VariationAttributeViewModel] = {
                let addOns = addOns.addOns
                return attributes.filter { attribute in
                    !addOns.contains(where: { $0.key == attribute.name && $0.value == attribute.value })
                }
            }()
            let attributesText = nonAddOnAttributes.map { $0.nameOrValue }.joined(separator: ", ")
            if nonAddOnAttributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, quantity, price)
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, quantity, price)
            }
        }
    }
}
