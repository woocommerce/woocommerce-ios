import Foundation
import Yosemite
import WooFoundation

/// Calculates the values(subtotal, total and tax) to be refunded.
///
struct RefundItemsValuesCalculationUseCase {

    /// Items and their quantities to be refunded
    ///
    let refundItems: [RefundableOrderItem]

    /// Formatter to convert string values to decimal values
    ///
    let currencyFormatter: CurrencyFormatter
    let numberOfDecimals: Int

    /// Calculates the values(subtotal, total and tax) to be refunded.
    ///
    func calculateRefundValues() -> RefundValues {
        let lines = refundItems.filter { $0.quantity > 0 }.map {
            RefundCreationUseCase.productLine(for: $0, currencyFormatter: currencyFormatter, numberOfDecimals: numberOfDecimals)
        }
        let subtotal = lines.reduce(Decimal.zero) { $0 + (Decimal(string: $1.total) ?? .zero) }
        let tax = lines.reduce(Decimal.zero) { total, line in
            total + line.taxes.reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) }
        }
        // Older order responses can omit the tax breakdown. Keep the display fallback;
        // a request cannot allocate these taxes without their rate IDs.
        let unallocatedTax = refundItems.filter { $0.item.taxes.isEmpty && $0.item.quantity > 0 }.reduce(Decimal.zero) {
            $0 + (currencyFormatter.convertToDecimal($1.item.totalTax) as Decimal? ?? .zero) / $1.item.quantity * $1.decimalQuantity
        }
        return RefundValues(subtotal: subtotal, tax: tax + unallocatedTax)
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
