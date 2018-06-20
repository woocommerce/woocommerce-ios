import Foundation
import UIKit

class OrderDetailsViewModel {
    private let order: Order
    private let couponLines: [CouponLine]?

    init(order: Order) {
        self.order = order
        self.couponLines = order.couponLines
    }

    var summaryTitle: String {
        return "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
    }

    var summaryDateCreated: String {
        // "date_created": "2017-03-21T16:46:41",
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let date = format.date(from: order.dateUpdatedString)

        let shortFormat = DateFormatter()
        shortFormat.dateFormat = "HH:mm:ss"
        shortFormat.timeStyle = .short

        guard let orderDate = date else {
            NSLog("Order date not found!")
            return order.dateUpdatedString
        }

        let time = shortFormat.string(from: orderDate)

        let summaryDate = String.localizedStringWithFormat(NSLocalizedString("Updated on %@ at %@", comment: "Order updated summary date"), orderDate.mediumString(), time)
        return summaryDate
    }

    var paymentStatus: String {
        return order.status.description
    }

    var paymentBackgroundColor: UIColor {
        return order.status.backgroundColor // MVVM: who should own color responsibilities? Maybe address this down the road.
    }

    var paymentBorderColor: CGColor {
        return order.status.borderColor // same here
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

    var subtotalValue: String {
        return order.currencySymbol + order.subtotal
    }

    var discountLabel: String? {
        return summarizeCoupons(from: couponLines)
    }

    var discountValue: String? {
        return Double(order.discountTotal) != 0 ? "−" + order.currencySymbol + order.discountTotal : nil
    }

    var shippingLabel: String {
        return NSLocalizedString("Shipping", comment: "Shipping label for payment view")
    }

    var shippingValue: String {
        return order.currencySymbol + order.shippingTotal
    }

    var taxesLabel: String? {
        return Double(order.totalTax) != 0 ? NSLocalizedString("Taxes", comment: "Taxes label for payment view") : nil
    }

    var taxesValue: String? {
        return Double(order.totalTax) != 0 ? order.currencySymbol + order.totalTax : nil
    }

    var totalLabel: String {
        return NSLocalizedString("Total", comment: "Total label for payment view")
    }

    var totalValue: String {
        return order.currencySymbol + order.total
    }

    var paymentSummary: String {
        return NSLocalizedString("Payment of \(totalValue) received via \(order.paymentMethodTitle)", comment: "Payment of <currency symbol><payment total> received via (payment method title)")
    }

    /// MARK: Private
    ///
    private func summarizeCoupons(from lines: [CouponLine]?) -> String? {
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
