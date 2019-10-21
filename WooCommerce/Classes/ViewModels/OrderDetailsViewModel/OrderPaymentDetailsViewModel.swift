import Foundation
import Yosemite

final class OrderPaymentDetailsViewModel {
    private let order: Order
    private let currencyFormatter = CurrencyFormatter()

    var subtotal: Decimal {
        let subtotal = order.items.reduce(Decimal(0)) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? Decimal(0)
            return output + itemSubtotal
        }

        return subtotal
    }

    var subtotalValue: String {
        let subAmount = NSDecimalNumber(decimal: subtotal).stringValue

        return currencyFormatter.formatAmount(subAmount, with: order.currency) ?? String()
    }

    /// Discounts
    /// - returns: 'Discount' label and a list of discount codes, or nil if zero.
    ///
    var discountText: String? {
        return summarizeCoupons(from: couponLines)
    }

    var discountValue: String? {
        guard let discount = currencyFormatter.convertToDecimal(from: order.discountTotal), discount.isZero() == false else {
            return nil
        }

        guard let formattedDiscount = currencyFormatter.formatAmount(order.discountTotal, with: order.currency) else {
            return nil
        }

        return "-" + formattedDiscount
    }

    var shippingValue: String {
        return currencyFormatter.formatAmount(order.shippingTotal, with: order.currency) ?? String()
    }

    var taxesValue: String? {
        return currencyFormatter.formatAmount(order.totalTax, with: order.currency)
    }

    var totalValue: String {
        return currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()
    }

    var paymentTotal: String {
        if order.datePaid == nil {
            return currencyFormatter.formatAmount("0.00", with: order.currency) ?? String()
        }

        return totalValue
    }

    /// Payment Summary
    /// - returns: A full sentence summary of how much (if any) was paid, when, and using what method.
    ///
    var paymentSummary: String? {
        if order.paymentMethodTitle.isEmpty {
            return nil
        }

        guard let datePaid = order.datePaid else {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Awaiting payment via %@",
                    comment: "Awaiting payment via (payment method title)"),
                order.paymentMethodTitle)
        }

        let styleDate = datePaid.toString(dateStyle: .medium, timeStyle: .none)
        let template = NSLocalizedString(
            "%1$@ via %2$@",
            comment: "Payment on <date> received via (payment method title)")

        return String.localizedStringWithFormat(template, styleDate, order.paymentMethodTitle)
    }

    var couponLines: [OrderCouponLine] {
        return order.coupons
    }

    init(order: Order) {
        self.order = order
    }

    private func summarizeCoupons(from lines: [OrderCouponLine]?) -> String? {
        guard let couponLines = lines else {
            return nil
        }

        let output = couponLines.reduce("") { (output, line) in
            let prefix = output.isEmpty ? "" : ","
            return output + prefix + line.code
        }

        guard !output.isEmpty else {
            return nil
        }

        return NSLocalizedString("Discount", comment: "Discount label for payment view") + " (" + output + ")"
    }
}
