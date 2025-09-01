import Foundation
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderRefund
import WooFoundation

struct PointOfSaleOrderDetailsViewHelper {
    private let currencyFormatter: CurrencyFormatter

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Calculates the products subtotal by summing line item subtotals
    /// Follows the same pattern as OrderPaymentDetailsViewModel.subtotal
    func productsSubtotal(for order: POSOrder) -> String {
        let subtotal = order.lineItems.reduce(.zero) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? .zero
            return output + itemSubtotal
        }

        return currencyFormatter.formatAmount(subtotal, with: order.currency) ?? ""
    }

    /// Determines if the products subtotal should be shown
    func shouldShowProductsSubtotal(for order: POSOrder) -> Bool {
        !order.lineItems.isEmpty
    }

    /// Calculates the net payment after refunds
    /// Uses Decimal arithmetic for precision matching OrderPaymentDetailsViewModel pattern
    func netPaymentAfterRefunds(for order: POSOrder) -> String {
        guard !order.refunds.isEmpty else { return "" }

        let refundedTotal = order.refunds.reduce(.zero) { output, refund in
            let refundAmount = Decimal(string: refund.total) ?? .zero
            return output + abs(refundAmount)
        }
        let orderTotal = Decimal(string: order.total) ?? .zero
        let netPayment = orderTotal - refundedTotal
        let netPaymentAmount = NSDecimalNumber(decimal: netPayment).stringValue

        return currencyFormatter.formatAmount(netPaymentAmount, with: order.currency) ?? ""
    }

    /// Determines if the net payment should be shown
    func shouldShowNetPayment(for order: POSOrder) -> Bool {
        !order.refunds.isEmpty
    }

    /// Formats discount total (already includes negative sign from data)
    /// Follows TotalsView pattern using discountTotal directly
    func formattedDiscountTotal(for order: POSOrder) -> String? {
        guard let discountTotal = Double(order.discountTotal), discountTotal != 0 else {
            return nil
        }

        return currencyFormatter.formatAmount(order.discountTotal, with: order.currency)
    }

    /// Determines if discount should be shown
    func shouldShowDiscount(for order: POSOrder) -> Bool {
        guard let discountTotal = Double(order.discountTotal) else { return false }
        return discountTotal != 0
    }

    /// Formats tax total
    func formattedTaxTotal(for order: POSOrder) -> String? {
        guard let taxTotal = Double(order.totalTax), taxTotal != 0 else {
            return nil
        }

        return currencyFormatter.formatAmount(order.totalTax, with: order.currency)
    }

    /// Formats the main order total
    func formattedOrderTotal(for order: POSOrder) -> String {
        currencyFormatter.formatAmount(order.total, with: order.currency) ?? ""
    }

    /// Formats the paid amount - 0.00 for unpaid orders, total for paid orders
    /// Follows the same pattern as Order.paymentTotal using datePaid logic
    func formattedPaidAmount(for order: POSOrder) -> String {
        // If no payment date, show 0.00 as paid amount (unpaid/failed orders)
        if order.datePaid == nil {
            return currencyFormatter.formatAmount("0.00", with: order.currency) ?? ""
        }

        // If payment date exists, show the total as paid amount
        return currencyFormatter.formatAmount(order.total, with: order.currency) ?? ""
    }

    /// Formats individual refund total (already includes negative sign)
    func formattedRefundTotal(_ refund: POSOrderRefund, currency: String) -> String {
        return currencyFormatter.formatAmount(refund.total, with: currency) ?? ""
    }

    /// Formats an item price with the given currency
    func formatItemPrice(_ price: NSDecimalNumber, with currency: String) -> String {
        return currencyFormatter.formatAmount(price, with: currency) ?? ""
    }

    /// Formats an item total with the given currency
    func formatItemTotal(_ total: String, with currency: String) -> String {
        return currencyFormatter.formatAmount(total, with: currency) ?? ""
    }
}
