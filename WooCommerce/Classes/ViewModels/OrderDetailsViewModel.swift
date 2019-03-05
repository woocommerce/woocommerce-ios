import Foundation
import UIKit
import Gridicons
import Yosemite

class OrderDetailsViewModel {
    let order: Order
    let currencyFormatter: CurrencyFormatter
    let couponLines: [OrderCouponLine]?

    init(order: Order) {
        self.order = order
        self.currencyFormatter = CurrencyFormatter()
        self.couponLines = order.coupons
    }

    var summaryTitle: String? {
        if let billingAddress = order.billingAddress {
            return "#\(order.number) \(billingAddress.firstName) \(billingAddress.lastName)"
        }
        return "#\(order.number)"
    }

    var summaryDateCreated: String {
        let shortFormat = DateFormatter()
        shortFormat.dateFormat = "HH:mm:ss"
        shortFormat.timeStyle = .short
        let time = shortFormat.string(from: order.dateModified)
        return String.localizedStringWithFormat(
            NSLocalizedString("Updated %@ at %@",
                              comment: "Order updated summary date. It reads: Updated {medium formatted date} at {short style time}"),
            order.dateModified.mediumString(),
            time
        )
    }

    var items: [OrderItem] {
        return order.items
    }

    let fulfillTitle = NSLocalizedString("Fulfill order", comment: "Fulfill order button title")

    var isProcessingPayment: Bool {
        return order.statusKey == .processing
    }

    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")

    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

    let productDetails = NSLocalizedString("Details", comment: "The row label to tap for a detailed product list")

    var customerNote: String {
        return order.customerNote ?? String()
    }

    /// Subtotal
    /// - returns: 'Subtotal' label and calculated subtotal for all items
    ///
    let subtotalLabel = NSLocalizedString("Subtotal", comment: "Subtotal label for payment view")

    var subtotal: Decimal {
        let subtotal = order.items.reduce(Decimal(0)) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? Decimal(0)
            return output + itemSubtotal
        }

        return subtotal
    }

    var subtotalValue: String {
        let subAmount = NSDecimalNumber(decimal: subtotal).stringValue

        return CurrencyFormatter().formatAmount(subAmount, with: order.currency) ?? String()
    }

    /// Discounts
    /// - returns: 'Discount' label and a list of discount codes, or nil if zero.
    ///
    var discountLabel: String? {
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

    /// Shipping
    /// - returns 'Shipping' label and amount, including zero amounts.
    ///
    let shippingLabel = NSLocalizedString("Shipping", comment: "Shipping label for payment view")

    var shippingValue: String {
        return currencyFormatter.formatAmount(order.shippingTotal, with: order.currency) ?? String()
    }

    /// Taxes
    /// - returns: 'Taxes' label and total taxes, including zero amounts.
    ///
    var taxesLabel: String? {
        return NSLocalizedString("Taxes", comment: "Taxes label for payment view")
    }

    var taxesValue: String? {
        return currencyFormatter.formatAmount(order.totalTax, with: order.currency)
    }

    /// Total
    /// - returns: 'Total' label and total amount, including zero amounts.
    ///
    let totalLabel = NSLocalizedString("Total", comment: "Total label for payment view")

    var totalValue: String {
        return currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()
    }

    /// Anything above 999.99 or below -999.99 should display a truncated amount
    ///
    var totalFriendlyString: String? {
        return currencyFormatter.formatHumanReadableAmount(order.total, with: order.currency, roundSmallNumbers: false) ?? String()
    }

    /// Payment Summary
    /// - returns: A full sentence summary of how much was paid and using what method.
    ///
    var paymentSummary: String? {
        if order.paymentMethodTitle.isEmpty {
            return nil
        }

        return NSLocalizedString(
            "Payment of \(totalValue) received via \(order.paymentMethodTitle)",
            comment: "Payment of <currency symbol><payment total> received via (payment method title)"
        )
    }

    /// Order Notes Button
    /// - icon and text
    ///
    let addNoteIcon = Gridicon.iconOfType(.addOutline)

    let addNoteText = NSLocalizedString("Add a note", comment: "Button text for adding a new order note")

    /// MARK: Private
    ///
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
