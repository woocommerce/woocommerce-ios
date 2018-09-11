import Foundation
import UIKit
import Gridicons
import Yosemite

class OrderDetailsViewModel {
    let order: Order
    let orderStatusViewModel: OrderStatusViewModel
    let couponLines: [OrderCouponLine]?

    init(order: Order) {
        self.order = order
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

    var shippingViewModel: ContactViewModel? {
        if let shippingAddress = order.shippingAddress {
            return ContactViewModel(with: shippingAddress, contactType: ContactType.shipping)
        }

        return nil
    }

    var billingViewModel: ContactViewModel? {
        if let billingAddress = order.billingAddress {
            return ContactViewModel(with: billingAddress, contactType: ContactType.billing)
        }

        return nil
    }

    let subtotalLabel = NSLocalizedString("Subtotal", comment: "Subtotal label for payment view")

    var subtotal: String {
        let subtotal = order.items.reduce(0.0) { (output, item) in
            let itemSubtotal = Double(item.subtotal) ?? 0.0
            return output + itemSubtotal
        }

        return String(format: "%.2f", subtotal)
    }

    var subtotalValue: String {
        return currencySymbol + subtotal
    }

    var discountLabel: String? {
        return summarizeCoupons(from: couponLines)
    }

    var discountValue: String? {
        return Double(order.discountTotal) != 0 ? "−" + currencySymbol + order.discountTotal : nil
    }

    let shippingLabel = NSLocalizedString("Shipping", comment: "Shipping label for payment view")

    var shippingValue: String {
        return currencySymbol + order.shippingTotal
    }

    var taxesLabel: String? {
        return Double(order.totalTax) != 0 ? NSLocalizedString("Taxes", comment: "Taxes label for payment view") : nil
    }

    var taxesValue: String? {
        return Double(order.totalTax) != 0 ? currencySymbol + order.totalTax : nil
    }

    let totalLabel = NSLocalizedString("Total", comment: "Total label for payment view")

    var totalValue: String {
        return currencySymbol + order.total
    }

    var paymentSummary: String {
        return NSLocalizedString("Payment of \(totalValue) received via \(order.paymentMethodTitle)", comment: "Payment of <currency symbol><payment total> received via (payment method title)")
    }

    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: order.currency)
        return locale.displayName(forKey: .currencySymbol, value: order.currency) ?? String()
    }

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
