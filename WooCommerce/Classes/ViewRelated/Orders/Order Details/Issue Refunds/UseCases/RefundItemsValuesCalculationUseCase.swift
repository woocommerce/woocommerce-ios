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
        let zero = RefundValues(subtotal: 0, tax: 0, fees: 0)
        return refundItems.reduce(zero) { previousValues, refundItem -> RefundValues in

            let itemPrice = refundItem.item.price as Decimal
            let quantityToRefund = Decimal(refundItem.quantity)

            // Figure out `itemTax` by dividing `totalTax` by the purchased `quantity`.
            let itemTax: Decimal = {
                let totalTax = currencyFormatter.convertToDecimal(from: refundItem.item.totalTax) ?? 0
                return (totalTax as Decimal) / refundItem.item.quantity
            }()

            // Accumulate the evaluated item values
            let subtotal = previousValues.subtotal + (itemPrice * quantityToRefund)
            let tax = previousValues.tax + (itemTax * quantityToRefund)

            #warning("fees to be fixed later")
            return RefundValues(subtotal: subtotal, tax: tax, fees: 0)
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
        let fees: Decimal
        var total: Decimal {
            return subtotal + tax
        }
    }
}
