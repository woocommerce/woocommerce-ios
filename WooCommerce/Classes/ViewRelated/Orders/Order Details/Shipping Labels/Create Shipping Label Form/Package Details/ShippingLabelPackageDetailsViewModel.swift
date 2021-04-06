import UIKit
import Yosemite

/// View model for `ShippingLabelPackageDetails`.
///
struct ShippingLabelPackageDetailsViewModel {

    let orderItems: [OrderItem]
    private let currency: String
    private let currencyFormatter: CurrencyFormatter

    var itemsRows: [ItemToFulfillRow] {
        orderItems.map { (item) -> ItemToFulfillRow in
            let positivePrice = item.price.abs()
            let positiveQuantity = abs(item.quantity)
            let quantity = NumberFormatter.localizedString(from: positiveQuantity as NSDecimalNumber, number: .decimal)
            let itemPrice = currencyFormatter.formatAmount(positivePrice, with: currency) ?? String()
            let attributes = item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }
            let subtitle = Localization.subtitle(quantity: quantity, price: itemPrice, attributes: attributes)
            return ItemToFulfillRow(title: item.name, subtitle: subtitle)
        }
    }

    init(items: [OrderItem], currency: String, formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.orderItems = items
        self.currency = currency
        self.currencyFormatter = formatter
    }
}

private extension ShippingLabelPackageDetailsViewModel {
    enum Localization {
        static let subtitleFormat =
            NSLocalizedString("%1$@ x %2$@", comment: "In Shipping Labels Package Details,"
                                + " the pattern used to show the quantity multiplied by the price. For example, “23 x $400.00”."
                                + " The %1$@ is the quantity. The %2$@ is the formatted price with currency (e.g. $400.00).")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@ x %3$@", comment: "In Shipping Labels Package Details if the product has attributes,"
                                + " the pattern used to show the attributes and quantity multiplied by the price. For example, “purple, has logo・23 x $400.00”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the quantity. The %3$@ is the formatted price with currency (e.g. $400.00).")
        static func subtitle(quantity: String, price: String, attributes: [VariationAttributeViewModel]) -> String {
            let attributesText = attributes.map { $0.nameOrValue }.joined(separator: ", ")
            if attributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, quantity, price)
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, quantity, price)
            }
        }
    }
}
