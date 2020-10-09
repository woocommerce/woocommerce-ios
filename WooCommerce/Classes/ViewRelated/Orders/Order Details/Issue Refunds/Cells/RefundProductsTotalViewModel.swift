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

    /// Tuple to group an order item with its refund quantity
    ///
    struct RefundItem {
        let item: OrderItem
        let quantity: Int
    }

    /// Tuple to store calculations results
    ///
    private struct RefundValues {
        let subtotal: Decimal
        let tax: Decimal
        var total: Decimal {
            return subtotal + tax
        }
    }

    /// Creates a `RefundProductsTotalViewModel` based on a list of items to refund.
    ///
    init(refundItems: [RefundItem], currency: String, currencySettings: CurrencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let values = Self.calculateRefundValues(refundItems: refundItems, currencyFormatter: currencyFormatter)

        self.productsTax = currencyFormatter.formatAmount(values.tax, with: currency) ?? ""
        self.productsSubtotal = currencyFormatter.formatAmount(values.subtotal, with: currency) ?? ""
        self.productsTotal = currencyFormatter.formatAmount(values.total, with: currency) ?? ""
    }

    /// Calculates the items subtotal, taxes and total to refund
    ///
    static private func calculateRefundValues(refundItems: [RefundItem], currencyFormatter: CurrencyFormatter) -> RefundValues {
        let zero = RefundValues(subtotal: 0, tax: 0)
        return refundItems.reduce(zero) { previousValues, refundItem -> RefundValues in

            let itemPrice = refundItem.item.price as Decimal
            let quantityToRefund = Decimal(refundItem.quantity)

            // Figure out `itemTax` by dividing `totalTax` by the purchased `quantity`.
            let itemTax: Decimal = {
                let totalTax = currencyFormatter.convertToDecimal(from: refundItem.item.totalTax) ?? 0
                return (totalTax as Decimal) / refundItem.item.quantity
            }()

            // Acumulate the evaluated item values
            let subtotal = previousValues.subtotal + (itemPrice * quantityToRefund)
            let tax = previousValues.tax + (itemTax * quantityToRefund)

            return RefundValues(subtotal: subtotal, tax: tax)
        }
    }
}
