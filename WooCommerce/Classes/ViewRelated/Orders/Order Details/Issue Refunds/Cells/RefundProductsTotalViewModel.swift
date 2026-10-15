import Foundation
import Yosemite
import WooFoundation

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
    init(refundItems: [RefundableOrderItem], currency: String, currencySettings: CurrencySettings, allocatedLines: [OrderItemRefund]? = nil,
         includesUnallocatedTax: Bool = false) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let useCase = RefundItemsValuesCalculationUseCase(refundItems: refundItems, currencyFormatter: currencyFormatter,
                                                           numberOfDecimals: currencySettings.fractionDigits)
        let values: RefundItemsValuesCalculationUseCase.RefundValues
        if let allocatedLines {
            values = .init(subtotal: allocatedLines.reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) },
                           tax: allocatedLines.flatMap(\.taxes).reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) })
        } else {
            values = useCase.calculateRefundValues()
        }

        let itemsWithoutTaxRates = refundItems.filter { $0.item.taxes.isEmpty && $0.item.quantity > 0 }
        let fallbackTax = includesUnallocatedTax && allocatedLines != nil ? itemsWithoutTaxRates.reduce(Decimal.zero) {
            $0 + (currencyFormatter.convertToDecimal($1.item.totalTax) as Decimal? ?? .zero) / $1.item.quantity * $1.decimalQuantity
        } : .zero
        self.productsTax = currencyFormatter.formatAmount(values.tax + fallbackTax, with: currency) ?? ""
        self.productsSubtotal = currencyFormatter.formatAmount(values.subtotal, with: currency) ?? ""
        self.productsTotal = currencyFormatter.formatAmount(values.total + fallbackTax, with: currency) ?? ""
    }
}
