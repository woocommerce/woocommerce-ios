import Foundation

class OrderDetailsSummaryViewModel {
    let title: String
    let dateCreated: String
    let paymentStatus: String

    init(order: Order) {
        self.title = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        self.dateCreated = String.localizedStringWithFormat(NSLocalizedString("Created %@", comment: "Order created date"), order.dateCreatedString) // FIXME: needs fuzzy date //FIXME: use a formatted date instead of raw timestamp
        self.paymentStatus = order.status.description
    }
}
