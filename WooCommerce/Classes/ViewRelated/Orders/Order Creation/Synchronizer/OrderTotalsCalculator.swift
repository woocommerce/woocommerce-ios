import Foundation
import Yosemite

/// Helper to calculate the totals on an `Order`.
///
final class OrderTotalsCalculator {
    // MARK: Private properties

    private let order: Order

    private let currencyFormatter: CurrencyFormatter

    /// Total shipping amount on an order.
    ///
    private var shippingTotal: NSDecimalNumber {
        currencyFormatter.convertToDecimal(from: order.shippingTotal) ?? .zero
    }

    /// Total taxes amount on an order.
    ///
    private var taxesTotal: NSDecimalNumber {
        currencyFormatter.convertToDecimal(from: order.totalTax) ?? .zero
    }

    // MARK: Calculated totals

    /// Total value of all items on an order.
    ///
    var itemsTotal: NSDecimalNumber {
        order.items
            .map { $0.subtotal }
            .compactMap { currencyFormatter.convertToDecimal(from: $0) }
            .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })
    }

    /// Base amount used to calculate percentage-based fees for an order.
    ///
    var feesBaseAmountForPercentage: NSDecimalNumber {
        itemsTotal.adding(shippingTotal).adding(taxesTotal)
    }

    /// Total value of all fee lines on an order.
    ///
    var feesTotal: NSDecimalNumber {
        order.fees
            .map { $0.total }
            .compactMap { currencyFormatter.convertToDecimal(from: $0) }
            .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })
    }

    init(for order: Order, using currencyFormatter: CurrencyFormatter) {
        self.order = order
        self.currencyFormatter = currencyFormatter
    }

    /// Returns a copy of the order with a new, locally calculated order total.
    ///
    func updateOrderTotal() -> Order {
        let orderTotal = itemsTotal.adding(shippingTotal).adding(feesTotal).adding(taxesTotal)
        return order.copy(total: orderTotal.stringValue)
    }
}
