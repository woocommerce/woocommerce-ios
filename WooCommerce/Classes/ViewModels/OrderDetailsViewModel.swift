import Foundation
import UIKit
import Gridicons
import Yosemite

class OrderDetailsViewModel {
    let orderStatusViewModel: OrderStatusViewModel
    let order: Order
    let couponLines: [OrderCouponLine]?
    let notes: [OrderNote]?

    init(order: Order) {
        self.order = order
        self.couponLines = order.coupons
        self.orderStatusViewModel = OrderStatusViewModel(orderStatus: order.status)

        // FIXME: Add order notes to remote/models
        //self.notes = order.notes
        self.notes = nil
    }

    var summaryTitle: String {
        return "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
    }

    var summaryDateCreated: String {
        let shortFormat = DateFormatter()
        shortFormat.dateFormat = "HH:mm:ss"
        shortFormat.timeStyle = .short
        let time = shortFormat.string(from: order.dateModified)
        return String.localizedStringWithFormat(NSLocalizedString("Updated on %@ at %@",
                                                                  comment: "Order updated summary date"), order.dateModified.mediumString(), time)
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

    var customerNote: String? {
        return order.customerNote
    }

    var shippingViewModel: ContactViewModel {
        return ContactViewModel(with: order.shippingAddress, contactType: ContactType.shipping)
    }
    var shippingAddress: String? {
        return shippingViewModel.formattedAddress
    }

    private(set) lazy var billingViewModel = ContactViewModel(with: order.billingAddress, contactType: ContactType.billing)
    private(set) lazy var billingAddress = billingViewModel.formattedAddress

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

    var orderNotes: [OrderNoteViewModel] {
        guard let notes = notes else {
            return []
        }

        return notes.map { note in
            return OrderNoteViewModel(with: note)
        }
    }

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
