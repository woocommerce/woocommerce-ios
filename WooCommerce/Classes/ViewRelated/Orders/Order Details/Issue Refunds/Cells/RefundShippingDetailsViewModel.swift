import Foundation
import Yosemite

/// Represents shipping details for an order to be refunded. Meant to be rendered by `RefundShippingDetailsTableViewCell`
///
struct RefundShippingDetailsViewModel {
    let carrierRate: String
    let carrierCost: String
    let shippingTax: String
    let shippingSubtotal: String
    let shippingTotal: String
}

// MARK: Convenience Initializers
extension RefundShippingDetailsViewModel {
    /// Creates a `RefundShippingDetailsViewModel` based on a `ShippingLine`
    ///
    init(shippingLine: ShippingLine, currency: String, currencySettings: CurrencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.carrierRate = shippingLine.methodTitle
        self.carrierCost = currencyFormatter.formatAmount(shippingLine.total, with: currency) ?? ""
        self.shippingTax = currencyFormatter.formatAmount(shippingLine.totalTax, with: currency) ?? ""
        self.shippingSubtotal = currencyFormatter.formatAmount(shippingLine.total, with: currency) ?? ""
        self.shippingTotal = {
            let calculatedTotal = Self.calculateShippingTotal(of: shippingLine, using: currencyFormatter)
            return currencyFormatter.formatAmount(calculatedTotal, with: currency) ?? ""
        }()
    }

    /// Calculates the shipping total by adding the shipping cost + the shipping tax
    ///
    private static func calculateShippingTotal(of shippingLine: ShippingLine, using currencyFormatter: CurrencyFormatter) -> NSDecimalNumber {
        guard let cost = currencyFormatter.convertToDecimal(from: shippingLine.total),
            let tax = currencyFormatter.convertToDecimal(from: shippingLine.totalTax) else {
                return .zero
        }
        return cost.adding(tax)
    }
}
