import Foundation
import Yosemite

/// Represents products cost details for an order to be refunded. Meant to be rendered by `RefundProductsTotalTableViewCell`
///
struct RefundProductsTotalViewModel {
    let productsTax: String
    let productsSubtotal: String
    let productsTotal: String
}

// MARK: Convenience Initializers
extension RefundProductsTotalViewModel {
    /// Creates a `RefundProductsTotalViewModel` based on a list of items to refund.
    ///
    init(refundItems: [RefundItemsValuesCalculationUseCase.RefundItem], currency: String, currencySettings: CurrencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: currencyFormatter)
        let values = useCase.calculateRefundValues()

        self.productsTax = currencyFormatter.formatAmount(values.tax, with: currency) ?? ""
        self.productsSubtotal = currencyFormatter.formatAmount(values.subtotal, with: currency) ?? ""
        self.productsTotal = currencyFormatter.formatAmount(values.total, with: currency) ?? ""
    }
}
