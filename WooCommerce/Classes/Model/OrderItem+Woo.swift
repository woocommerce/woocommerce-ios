import Foundation
import Yosemite
import WooFoundation

// MARK: - OrderItem Helper Methods
//
extension OrderItem {
    /// Returns the variant if it exists
    ///
    var productOrVariationID: Int64 {
        if variationID == 0 {
            return productID
        }

        return variationID
    }

    /// Calculates a single line item price before discount and taxes
    /// This value correctly reflects a single line item price within order
    ///
    /// OrderItem subtotal - excludes discounts and depends on item quantity
    /// OrderItem total - includes discounts and depends on item quantity
    /// OrderItem price - includes discounts
    /// Product price - always static and doesn't take into
    /// account whether taxes are included or excluded from product
    ///
    /// - Parameter orderItem
    ///
    var pricePreDiscount: NSDecimalNumber {
        let formatter = CurrencyFormatter(currencySettings: CurrencySettings())

        guard quantity != .zero,
              let subtotalDecimal = formatter.convertToDecimal(subtotal) else {
            return .zero
        }

        return subtotalDecimal.dividing(by: .init(decimal: quantity))
    }
}
