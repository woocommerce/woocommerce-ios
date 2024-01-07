import Foundation
import Yosemite
import WooFoundation

final class OrderPaymentDetailsViewModel {
    private let order: Order
    private let refund: Refund?
    private let currencyFormatter: CurrencyFormatter

    var subtotal: Decimal {
        let subtotal = order.items.reduce(Constants.decimalZero) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? Constants.decimalZero
            return output + itemSubtotal
        }

        return subtotal
    }

    var subtotalValue: String {
        let subAmount = NSDecimalNumber(decimal: subtotal).stringValue

        return currencyFormatter.formatAmount(subAmount, with: order.currency) ?? String()
    }

    var shouldHideSubtotal: Bool {
        subtotal == 0
    }

    /// Discounts
    /// - returns: 'Discount' label and a list of discount codes, or nil if zero.
    ///
    var discountText: String? {
        return summarizeCoupons(from: couponLines)
    }

    var discountValue: String? {
        guard let discount = currencyFormatter.convertToDecimal(order.discountTotal), discount.isZero() == false else {
            return nil
        }

        guard let formattedDiscount = currencyFormatter.formatAmount(order.discountTotal, with: order.currency) else {
            return nil
        }

        return "-" + formattedDiscount
    }

    var shouldHideDiscount: Bool {
        discountValue == nil
    }

    var shippingValue: String {
        return currencyFormatter.formatAmount(order.shippingTotal, with: order.currency) ?? String()
    }

    var shouldHideShipping: Bool {
        return currencyFormatter.convertToDecimal(order.shippingTotal) == 0
    }

    var taxesValue: String? {
        return currencyFormatter.formatAmount(order.totalTax, with: order.currency)
    }

    var shouldHideTaxes: Bool {
        return currencyFormatter.convertToDecimal(order.totalTax) == 0
    }

    var totalValue: String {
        order.totalValue
    }

    var paymentTotal: String {
        order.paymentTotal
    }

    private var feesTotal: Decimal {
        let subtotal = order.fees.reduce(Constants.decimalZero) { (output, fee) in
            let feeSubtotal = Decimal(string: fee.total) ?? Constants.decimalZero
            return output + feeSubtotal
        }

        return subtotal
    }

    var feesValue: String {
        let amount = NSDecimalNumber(decimal: feesTotal).stringValue

        return currencyFormatter.formatAmount(amount, with: order.currency) ?? String()
    }

    var shouldHideFees: Bool {
        feesTotal == Constants.decimalZero
    }

    /// Payment Summary
    /// - returns: A full sentence summary of how much (if any) was paid, when, and using what method.
    ///
    /// It reads: `Awaiting payment via Credit Card (Stripe)`
    /// or: `Payment on Nov 19, 2019 via Credit Card (Stripe)`
    /// or is left blank if is paid, but has no payment method title associated.
    ///
    var paymentSummary: String? {

        guard let datePaid = order.datePaid else {
            return awaitingPaymentTitle
        }

        if order.paymentMethodTitle.isEmpty {
            return nil
        }

        let styleDate = datePaid.toStringInSiteTimeZone(dateStyle: .medium, timeStyle: .none)
        let template = NSLocalizedString(
            "%1$@ via %2$@",
            comment: "Payment on <date> received via (payment method title)")

        return String.localizedStringWithFormat(template, styleDate, order.paymentMethodTitle)
    }

    /// Awaiting payment
    ///
    private var awaitingPaymentTitle: String? {
        if order.paymentMethodTitle.isEmpty {
            return String.localizedStringWithFormat(
                NSLocalizedString("Awaiting payment", comment: "The title on the payment row of the Order Details screen when the payment is still pending"))
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("Awaiting payment via %@",
                              comment: "The title on the payment row of the Order Details screen" +
                              "when the payment for a specific payment method is still pending." +
                              "Reads like: Awaiting payment via Stripe."),
            order.paymentMethodTitle)
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
        let dateCreated = {
            let dateFormatter = DateFormatter.mediumLengthLocalizedDateFormatter
            dateFormatter.timeZone = .siteTimezone
            return dateFormatter.string(from: refund.dateCreated)
        }()

        let hasRefundGateway = refund.isAutomated ?? false

        // Yes, we're making the assumption that the payment method is the same as the refund method.
        let refundType = hasRefundGateway ? order.paymentMethodTitle : NSLocalizedString(
            "manual refund",
            comment: "A manual refund is one where the store owner has given the purchaser alternative funds" +
                " (cash, check, ACH) instead of using the payment gateway to create a refund " +
                "(credit card or debit card was refunded)"
        )

        let template = NSLocalizedString("%@ via %@",
                                         comment: "Label for a refund on an order, which reads \"<date> via <refund method type>\", " +
                                         "e.g. \"25 Apr 2022 via WooCommerce In-Person Payments\". " +
                                         "Shown in a cell with a title \"Refunded\" for context")
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

        // We can not assume the total is negative.
        return currencyFormatter.formatAmount(condensedRefund.normalizedTotalAsNegative, with: order.currency)
    }

    var couponLines: [OrderCouponLine] {
        return order.coupons
    }

    /// Gift Cards
    /// - returns: 'Gift Cards' label and a list of gift card codes, or nil if there are none.
    ///
    var giftCardsText: String? {
        guard order.appliedGiftCards.isNotEmpty else {
            return nil
        }

        let codes = order.appliedGiftCards.map { $0.code }.joined(separator: ", ")

        return NSLocalizedString("Gift Cards", comment: "Gift Cards label for payment view") + " (" + codes + ")"
    }

    /// Gift cards total
    ///  - returns: Total amount of gift cards applied to the order, expressed in a negative amount.
    ///
    var giftCardsValue: String? {
        let giftCardsTotal = -order.appliedGiftCards.map { $0.amount }.reduce(0, +)

        return currencyFormatter.formatAmount(giftCardsTotal.description, with: order.currency)
    }

    var shouldHideGiftCards: Bool {
        giftCardsText == nil
    }

    init(order: Order, refund: Refund? = nil, currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.order = order
        self.refund = refund
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
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

private extension OrderPaymentDetailsViewModel {
    enum Constants {
        static let decimalZero = Decimal(0)
    }
}


private extension OrderRefundCondensed {
    /// Present the refund total as a negative number,
    /// by prefixing it with a minus symbol.
    var normalizedTotalAsNegative: String {
        guard total.hasPrefix("-") else {
            return "-" + total
        }

        return total
    }
}
