import Foundation
import Yosemite

final class OrderPaymentDetailsViewModel {
    private let order: Order
    private let refund: Refund?
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
    ///
    var refundSummary: NSAttributedString? {
        guard let refund = refund else {
            return nil
        }

        let dateCreated = DateFormatter.mediumLengthLocalizedDateFormatter.string(from: refund.dateCreated)

        let hasRefundGateway = refund.isAutomated ?? false

        // Yes, we're making the assumption that the payment method is the same as the refund method.
        let refundType = hasRefundGateway ? order.paymentMethodTitle : NSLocalizedString("manual refund", comment: "A manual refund is one where the store owner has given the purchaser alternative funds (cash, check, ACH) instead of using the payment gateway to create a refund (credit card or debit card was refunded)")

        let viewDetailsText = NSLocalizedString("View details", comment: "This text is linked so the user can view refund details.")
        let viewDetailsRange = NSRange(location: 0, length: viewDetailsText.count)
        let viewDetailsAttr = NSMutableAttributedString(string: viewDetailsText)
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: StyleManager.wooCommerceBrandColor
        ]
        viewDetailsAttr.addAttributes(linkAttributes, range: viewDetailsRange)

        let template = NSLocalizedString("%@ via %@ (%@)", comment: "It reads: <date> via <refund method type> (View details). The text `View details` is a link.")
        let refundText = String.localizedStringWithFormat(template, dateCreated, refundType, viewDetailsAttr)
        let refundAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.footerLabelFont,
            .foregroundColor: StyleManager.wooGreyMid
        ]

        let refundAttrText = NSMutableAttributedString(string: refundText)
        let range = NSRange(location: 0, length: refundText.count)
        refundAttrText.addAttributes(refundAttributes, range: range)

        return refundAttrText
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
}
