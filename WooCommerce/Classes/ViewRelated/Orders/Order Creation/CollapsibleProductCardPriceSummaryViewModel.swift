import Foundation
import WooFoundation

/// View model for `CollapsibleProductCardPriceSummary`
///
final class CollapsibleProductCardPriceSummaryViewModel {
    /// Whether the product is priced individually. Defaults to `true`.
    ///
    /// Used to control how the price is displayed, e.g. when a product is part of a bundle.
    ///
    let pricedIndividually: Bool

    /// Unformatted product price (not including discounts)
    ///
    private let priceBeforeDiscount: String?

    /// Unformatted product subtotal (price x quantity, not including discounts)
    ///
    private let subtotal: String

    /// Quantity of product in the order. The source of truth is from the the quantity stepper view model `stepperViewModel`.
    ///
    @Published var quantity: Decimal

    private let currencyFormatter: CurrencyFormatter

    init(pricedIndividually: Bool,
         quantity: Decimal,
         priceBeforeDiscount: String?,
         subtotal: String,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.pricedIndividually = pricedIndividually
        self.quantity = quantity
        self.priceBeforeDiscount = pricedIndividually ? priceBeforeDiscount : "0"
        self.subtotal = pricedIndividually ? subtotal : "0"
        self.currencyFormatter = currencyFormatter
    }
}

extension CollapsibleProductCardPriceSummaryViewModel {
    /// Formatted price label based on a product's price and quantity.
    /// Reads as '8 x $10.00'
    ///
    var priceQuantityLine: String {
        let formattedQuantity = quantity.formatted()
        let formattedPrice = {
            guard let priceBeforeDiscount, let formattedPrice = currencyFormatter.formatAmount(priceBeforeDiscount) else {
                return "-"
            }
            return formattedPrice
        }()
        return String.localizedStringWithFormat(Localization.priceQuantityLine, formattedQuantity, formattedPrice)
    }

    /// Formatted price label from multiplying product's price and quantity.
    ///
    var subtotalLabel: String? {
        currencyFormatter.formatAmount(subtotal)
    }
}

private extension CollapsibleProductCardPriceSummaryViewModel {
    enum Localization {
        static let priceQuantityLine = NSLocalizedString(
            "collapsibleProductCardPriceSummaryViewModel.priceQuantityLine",
            value: "%@ × %@",
            comment: "Formatted price label based on a product's price and quantity. Reads as '8 x $10.00'. " +
            "Please take care to use the multiplication symbol ×, not a letter x, where appropriate.")
    }
}
