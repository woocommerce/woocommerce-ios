import Foundation
import UIKit
import Gridicons
import Yosemite

class OrderDetailsViewModel {
    let order: Order
    let moneyFormatter: MoneyFormatter
    let couponLines: [OrderCouponLine]?

    let orderStatusViewModel: OrderStatusViewModel

    init(order: Order) {
        self.order = order
        self.moneyFormatter = MoneyFormatter()
        self.couponLines = order.coupons
        self.orderStatusViewModel = OrderStatusViewModel(orderStatus: order.status)
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
        return String.localizedStringWithFormat(NSLocalizedString("Updated %@ at %@",
                                                                  comment: "Order updated summary date. It reads: Updated {medium formatted date} at {short style time}"), order.dateModified.mediumString(), time)
    }

    var items: [OrderItem] {
        return order.items
    }

    let fulfillTitle = NSLocalizedString("Fulfill order", comment: "Fulfill order button title")

    var paymentStatus: String {
        return order.status.description
    }

    var paymentBackgroundColor: UIColor {
        return orderStatusViewModel.backgroundColor
    }

    var paymentBorderColor: CGColor {
        return orderStatusViewModel.borderColor
    }

    var isProcessingPayment: Bool {
        return order.status == .processing
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
        return moneyFormatter.format(value: subtotal, currencyCode: order.currency) ?? String()
    }

    /// Discounts
    /// - returns: 'Discount' label and a list of discount codes, or nil if nonexistent.
    ///
    var discountLabel: String? {
        return summarizeCoupons(from: couponLines)
    }

    var discountValue: String? {
        guard let discount = Decimal(string: order.discountTotal) else {
            return nil
        }

        if discount.isZero {
            return nil
        }

        guard let formattedDiscount = moneyFormatter.format(value: discount, currencyCode: order.currency) else {
            return nil
        }

        return "-" + formattedDiscount
    }

    /// Shipping
    /// - returns 'Shipping' label and amount, including zero amounts.
    ///
    let shippingLabel = NSLocalizedString("Shipping", comment: "Shipping label for payment view")

    var shippingValue: String {
        if let shippingTotal = Decimal(string: order.shippingTotal) {
            return moneyFormatter.format(value: shippingTotal, currencyCode: order.currency) ?? String()
        }

        return moneyFormatter.format(value: "0.00", currencyCode: order.currency) ?? String()
    }

    /// Taxes
    /// - returns: 'Taxes' label and total taxes, or nil if nonexistent.
    ///
    var taxesLabel: String? {
        if Decimal(string: order.totalTax) != nil {
            return NSLocalizedString("Taxes", comment: "Taxes label for payment view")
        }

        return nil
    }

    var taxesValue: String? {
        if let totalTax = Decimal(string: order.totalTax) {
            return moneyFormatter.formatIfNonZero(value: totalTax, currencyCode: order.currency)
        }

        return nil
    }

    /// Total
    /// - returns: 'Total' label and total amount, including zero amounts.
    ///
    let totalLabel = NSLocalizedString("Total", comment: "Total label for payment view")

    var totalValue: String {
        return moneyFormatter.format(value: order.total, currencyCode: order.currency) ?? String()
    }

    // FIXME: This is not correctly formatted currency.
    /// Anything above 999.99 or below -999.99 should display a truncated amount
    ///
    var totalFriendlyString: String? {
        let totalString = NSString(string: order.total)
        let totalDouble = totalString.doubleValue
        if totalDouble >= 1000.0 || totalDouble <= -1000.0 {
            let totalRounded = totalDouble.friendlyString()
            let symbol = moneyFormatter.currencySymbol(currencyCode: order.currency) ?? String()
            return symbol + totalRounded
        }

        return totalValue
    }

    /// Payment Summary
    /// - returns: A full sentence summary of how much was paid and using what method.
    ///
    var paymentSummary: String {
        return NSLocalizedString("Payment of \(totalValue) received via \(order.paymentMethodTitle)", comment: "Payment of <currency symbol><payment total> received via (payment method title)")
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
