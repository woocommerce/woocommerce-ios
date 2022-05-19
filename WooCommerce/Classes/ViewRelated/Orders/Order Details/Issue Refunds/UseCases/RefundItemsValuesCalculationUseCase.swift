import Foundation
import Yosemite

/// Calculates the values(subtotal, total and tax) to be refunded.
///
struct RefundItemsValuesCalculationUseCase {

    /// Items and their quantities to be refunded
    ///
    let refundItems: [RefundableOrderItem]

    /// Formatter to convert string values to decimal values
    ///
    let currencyFormatter: CurrencyFormatter

    /// Calculates the values(subtotal, total and tax) to be refunded.
    ///
    func calculateRefundValues() -> RefundValues {
        let zero = RefundValues(subtotal: 0, tax: 0)
        return refundItems.reduce(zero) { previousValues, refundItem -> RefundValues in

            // Figure out `itemTotal` by dividing `item.total` by the purchased `quantity`.
            // Using price is not safe right now.
            // See: https://github.com/woocommerce/woocommerce-ios/issues/6885
            let itemTotal: Decimal = {
                let refundItemTotal = currencyFormatter.convertToDecimal(from: refundItem.item.total) ?? 0
                return (refundItemTotal as Decimal) / refundItem.item.quantity
            }()

            // Figure out `itemTax` by dividing `totalTax` by the purchased `quantity`.
            let itemTax: Decimal = {
                let totalTax = currencyFormatter.convertToDecimal(from: refundItem.item.totalTax) ?? 0
                return (totalTax as Decimal) / refundItem.item.quantity
            }()

            let quantityToRefund = Decimal(refundItem.quantity)

            // Accumulate the evaluated item values
            let subtotal = previousValues.subtotal + (itemTotal * quantityToRefund)
            let tax = previousValues.tax + (itemTax * quantityToRefund)

            return RefundValues(subtotal: subtotal, tax: tax)
        }
    }
}

// MARK: Helper types
extension RefundItemsValuesCalculationUseCase {
    /// Tuple to return calculations results
    ///
    struct RefundValues {
        let subtotal: Decimal
        let tax: Decimal
        var total: Decimal {
            return subtotal + tax
        }
    }
}
