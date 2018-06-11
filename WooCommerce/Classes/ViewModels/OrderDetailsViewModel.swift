import Foundation
import UIKit

class OrderDetailsViewModel {
    let summaryTitle: String
    private let dateCreatedString: String
    let paymentStatus: String
    let paymentBackgroundColor: UIColor
    let paymentBorderColor: CGColor
    let customerNote: String?
    let shippingAddress: String?
    let billingAddress: String?
    let shippingViewModel: ContactViewModel
    let billingViewModel: ContactViewModel

    init(order: Order) {
        summaryTitle = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        dateCreatedString = order.dateCreatedString
        paymentStatus = order.status.description
        paymentBackgroundColor = order.status.backgroundColor // MVVM: who should own color responsibilities? Maybe address this down the road.
        paymentBorderColor = order.status.borderColor // same here
        customerNote = order.customerNote
        shippingViewModel = ContactViewModel(with: order.shippingAddress, contactType: ContactType.shipping)
        shippingAddress = shippingViewModel.formattedAddress
        billingViewModel = ContactViewModel(with: order.billingAddress, contactType: ContactType.billing)
        billingAddress = billingViewModel.formattedAddress
    }

    var summaryDateCreated: String {
        // "date_created": "2017-03-21T16:46:41",
        let format = ISO8601DateFormatter()
        let gmt = TimeZone(abbreviation: "GMT")
        format.timeZone = gmt
        format.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let date = format.date(from: dateCreatedString)

        let shortFormat = DateFormatter()
        shortFormat.dateFormat = "HH:mm:ss"
        shortFormat.timeStyle = .short

        guard let orderDate = date else {
            NSLog("Order date not found!")
            return dateCreatedString
        }

        let time = shortFormat.string(from: orderDate)

        let summaryDate = String.localizedStringWithFormat(NSLocalizedString("Updated on \(orderDate.mediumString()) at \(time)", comment: "Order created date"))
        return summaryDate
    }
}
