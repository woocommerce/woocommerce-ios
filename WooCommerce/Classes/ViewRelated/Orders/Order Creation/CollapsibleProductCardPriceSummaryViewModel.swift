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

    /// Whether the product is a Subscription-type product
    ///
    let isSubscriptionProduct: Bool

    /// Unformatted product price
    ///
    private let price: String?

    /// Quantity of product in the order. The source of truth is from the the quantity stepper view model `stepperViewModel`.
    ///
    @Published var quantity: Decimal

    private let currencyFormatter: CurrencyFormatter

    init(pricedIndividually: Bool,
         isSubscriptionProduct: Bool,
         quantity: Decimal,
         price: String?,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.pricedIndividually = pricedIndividually
        self.isSubscriptionProduct = isSubscriptionProduct
        self.quantity = quantity
        self.price = pricedIndividually ? price : "0"
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
            guard let price = pricedIndividually ? price : "0",
                    let formattedPrice = currencyFormatter.formatAmount(price) else {
                return "-"
            }
            return formattedPrice
        }()
        return String.localizedStringWithFormat(Localization.priceQuantityLine, formattedQuantity, formattedPrice)
    }

    /// Formatted price label from multiplying product's price and quantity.
    ///
    var priceBeforeDiscountsLabel: String? {
        guard let price = pricedIndividually ? price : "0" else {
            return nil
        }
        let productSubtotal = quantity * (currencyFormatter.convertToDecimal(price)?.decimalValue ?? Decimal.zero)
        return currencyFormatter.formatAmount(productSubtotal)
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
