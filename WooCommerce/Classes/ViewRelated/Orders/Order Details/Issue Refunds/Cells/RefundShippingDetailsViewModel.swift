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
        self.carrierRate = shippingLine.methodTitle.strippedHTML
        self.carrierCost = currencyFormatter.formatAmount(shippingLine.total, with: currency) ?? ""
        self.shippingTax = currencyFormatter.formatAmount(shippingLine.totalTax, with: currency) ?? ""
        self.shippingSubtotal = currencyFormatter.formatAmount(shippingLine.total, with: currency) ?? ""
        self.shippingTotal = {
            let useCase = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: currencyFormatter)
            return currencyFormatter.formatAmount(useCase.calculateRefundValue(), with: currency) ?? ""
        }()
    }
}
