import Foundation
import UIKit

class OrderDetailsViewModel {
    let summaryTitle: String
    let dateCreated: String
    let paymentStatus: String
    let paymentBackgroundColor: UIColor
    let paymentBorderColor: CGColor
    let customerNote: String?
    let shippingAddress: String?
    let billingAddress: String?
    let shippingViewModel: ContactViewModel
    let billingViewModel: ContactViewModel

    let subtotalLabel: String
    let subtotalValue: String
    let hasDiscount: Bool
    let discountValue: String?
    let shippingLabel: String
    let shippingValue: String
    let hasTaxes: Bool
    let taxesLabel: String?
    let taxesValue: String?
    let totalLabel: String
    let totalValue: String
    let paymentSummary: String

    private let couponLines: [CouponLine]?

    init(order: Order) {
        summaryTitle = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        dateCreated = String.localizedStringWithFormat(NSLocalizedString("Created %@", comment: "Order created date"), order.dateCreatedString) //FIXME: use a formatted date instead of raw timestamp
        paymentStatus = order.status.description
        paymentBackgroundColor = order.status.backgroundColor // MVVM: who should own color responsibilities? Maybe address this down the road.
        paymentBorderColor = order.status.borderColor // same here
        customerNote = order.customerNote
        shippingViewModel = ContactViewModel(with: order.shippingAddress, contactType: ContactType.shipping)
        shippingAddress = shippingViewModel.formattedAddress
        billingViewModel = ContactViewModel(with: order.billingAddress, contactType: ContactType.billing)
        billingAddress = billingViewModel.formattedAddress

        subtotalLabel = NSLocalizedString("Subtotal", comment: "Subtotal label for payment view")
        subtotalValue = order.currencySymbol + order.subtotal

        couponLines = order.couponLines
        if Double(order.discountTotal) != 0 {
            hasDiscount = true
            discountValue = "−" + order.currencySymbol + order.discountTotal
        } else {
            hasDiscount = false
            discountValue = nil
        }

        shippingLabel = NSLocalizedString("Shipping", comment: "Shipping label for payment view")
        shippingValue = order.currencySymbol + order.shippingTotal

        if Double(order.totalTax) != 0 {
            hasTaxes = true
            taxesLabel = NSLocalizedString("Taxes", comment: "Taxes label for payment view")
            taxesValue = order.currencySymbol + order.totalTax
        } else {
            hasTaxes = false
            taxesLabel = nil
            taxesValue = nil
        }

        totalLabel = NSLocalizedString("Total", comment: "Total label for payment view")
        totalValue = order.currencySymbol + order.total
        paymentSummary = NSLocalizedString("Payment of \(totalValue) received via \(order.paymentMethodTitle)", comment: "Payment of <currency symbol><payment total> received via (payment method title)")
    }

    func summarizeCoupons(from lines: [CouponLine]?) -> String? {
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

    var discountLabel: String? {
        return summarizeCoupons(from: couponLines)
    }
}
