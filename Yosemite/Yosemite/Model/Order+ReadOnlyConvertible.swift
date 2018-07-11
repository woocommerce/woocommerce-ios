import Foundation
import Storage


// MARK: - Storage.order: ReadOnlyConvertible
//
extension Storage.Order: ReadOnlyConvertible {

    /// Updates the Storage.Order with the a ReadOnly.
    ///
    public func update(with order: Yosemite.Order) {
        orderID = Int64(order.orderID)
        parentID = Int64(order.parentID)
        customerID = Int64(order.customerID)
        number = order.number
        status = order.status.rawValue
        currency = order.currency
        customerNote = order.customerNote
        dateCreated = order.dateCreated
        dateModified = order.dateModified
        datePaid = order.datePaid
        discountTotal = order.discountTotal
        discountTax = order.discountTax
        shippingTotal = order.shippingTotal
        shippingTax = order.shippingTax
        total = order.total
        totalTax = order.totalTax
        paymentMethodTitle = order.paymentMethodTitle

        // TODO: items, coupons, billing address, and shipping address
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Order {
        return Order(orderID: Int(orderID),
                     parentID: Int(parentID),
                     customerID: Int(customerID),
                     number: number ?? "",
                     status: OrderStatus(rawValue: status),
                     currency: currency ?? "",
                     customerNote: customerNote ?? "",
                     dateCreated: dateCreated ?? Date(),
                     dateModified: dateModified ?? Date(),
                     datePaid: datePaid ?? Date(),
                     discountTotal: discountTotal ?? "",
                     discountTax: discountTax ?? "",
                     shippingTotal: shippingTotal ?? "",
                     shippingTax: shippingTax ?? "",
                     total: total ?? "",
                     totalTax: totalTax ?? "",
                     paymentMethodTitle: paymentMethodTitle ?? "",
                     items: [],
                     billingAddress: blankAddress(),
                     shippingAddress: blankAddress(),
                     coupons: [])

        // TODO: ^^^^ items, coupons, billing address, and shipping address ^^^^
    }

    private func blankAddress() -> Yosemite.Address {
        return Address(firstName: "",
                       lastName: "",
                       company: "",
                       address1: "",
                       address2: "",
                       city: "",
                       state: "",
                       postcode: "",
                       country: "",
                       phone: "",
                       email: "")
    }
}
