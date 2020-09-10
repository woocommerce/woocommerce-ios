import Foundation
import Yosemite

final class OrderPaymentDetailsViewModel {
    private let order: Order
    private let refund: Refund?
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

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
    /// It reads: `Awaiting payment via Credit Card (Stripe)`
    /// or: `Nov 19, 2019 via Credit Card (Stripe)`
    /// or is left blank by returning nil.
    ///
    var paymentSummary: String? {
        if order.paymentMethodTitle.isEmpty {
            return nil
        }

        guard let datePaid = order.datePaid else {
            return String.localizedStringWithFormat(
                NSLocalizedString("Awaiting payment via %@",
                                  comment: "Awaiting payment via (payment method title)"),
                order.paymentMethodTitle)
        }

        let styleDate = datePaid.toString(dateStyle: .medium, timeStyle: .none)
        let template = NSLocalizedString(
            "%1$@ via %2$@",
            comment: "Payment on <date> received via (payment method title)")

        return String.localizedStringWithFormat(template, styleDate, order.paymentMethodTitle)
    }

    /// Refund Summary
    /// - returns: A full sentence summary of the date the refund was created, which payment gateway it was refunded to, and a link to the detailed refund.
    /// Example: Oct 28, 2019 via Credit Card (Stripe)
    ///
    var refundSummary: String? {
        guard let refund = refund else {
            return nil
        }

        // First, localize all the pieces of the sentence.
        let dateCreated = DateFormatter.mediumLengthLocalizedDateFormatter.string(from: refund.dateCreated)

        let hasRefundGateway = refund.isAutomated ?? false

        // Yes, we're making the assumption that the payment method is the same as the refund method.
        let refundType = hasRefundGateway ? order.paymentMethodTitle : NSLocalizedString(
            "manual refund",
            comment: "A manual refund is one where the store owner has given the purchaser alternative funds" +
                " (cash, check, ACH) instead of using the payment gateway to create a refund " +
                "(credit card or debit card was refunded)"
        )

        let template = NSLocalizedString("%@ via %@",
                                         comment: "It reads: \"<date> via <refund method type> – View details\". The text `View details` is a link.")
        let refundText = String.localizedStringWithFormat(template, dateCreated, refundType)

        return refundText
    }

    /// Format the refund amount with the correct currency
    ///
    var refundAmount: String? {
        guard let fullRefund = refund else {
            return nil
        }

        let refundLookUp = order.refunds.filter { $0.refundID == fullRefund.refundID }.first
        guard let condensedRefund = refundLookUp else {
            return nil
        }

        // We want the condensed refund total because it's reported as a negative value
        return currencyFormatter.formatAmount(condensedRefund.total, with: order.currency)
    }

    /// Format the net amount with the correct currency
    ///
    var netAmount: String? {
        guard let netDecimal = calculateNetAmount() else {
            return nil
        }

        return currencyFormatter.formatAmount(netDecimal, with: order.currency)
    }

    var couponLines: [OrderCouponLine] {
        return order.coupons
    }

    init(order: Order, refund: Refund? = nil) {
        self.order = order
        self.refund = refund
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

    /// Calculate the net amount after refunds
    ///
    private func calculateNetAmount() -> NSDecimalNumber? {
        guard let orderTotal = currencyFormatter.convertToDecimal(from: order.total) else {
            return .zero
        }

        let refunds = order.refunds.map {
            currencyFormatter.convertToDecimal(from: $0.total)
        }

        // Can't use .reduce(0,+) here because we're working with NSDecimalNumber.
        var refundTotal: NSDecimalNumber = .zero
        for r in refunds {
            if let refund = r {
                refundTotal = refundTotal.adding(refund)
            }
        }

        return orderTotal.adding(refundTotal)
    }
}
