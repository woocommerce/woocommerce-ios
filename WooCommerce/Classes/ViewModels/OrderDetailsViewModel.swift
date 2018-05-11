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

    init(order: Order) {
        summaryTitle = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        dateCreated = String.localizedStringWithFormat(NSLocalizedString("Created %@", comment: "Order created date"), order.dateCreatedString) //FIXME: use a formatted date instead of raw timestamp
        paymentStatus = order.status.description
        paymentBackgroundColor = order.status.backgroundColor // MVVM: who should own color responsibilities? Maybe address this down the road.
        paymentBorderColor = order.status.borderColor // same here
        customerNote = order.customerNote
        let shippingContact = ContactViewModel(with: order.shippingAddress, contactType: ContactType.shipping)
        shippingAddress = shippingContact.formattedAddress
        let billingContact = ContactViewModel(with: order.billingAddress, contactType: ContactType.billing)
        billingAddress = billingContact.formattedAddress
    }
}
