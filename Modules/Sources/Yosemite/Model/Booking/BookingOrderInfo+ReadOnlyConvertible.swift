import Foundation
import Storage

// MARK: - Storage.BookingOrderInfo: ReadOnlyConvertible
//
extension Storage.BookingOrderInfo: ReadOnlyConvertible {
    public func update(with orderInfo: Yosemite.BookingOrderInfo) {
        statusKey = orderInfo.statusKey
        orderID = orderInfo.orderID
        orderNumber = orderInfo.orderNumber
        dateCreated = orderInfo.dateCreated
        datePaid = orderInfo.datePaid
        discountTotal = orderInfo.discountTotal
        customerEmail = orderInfo.customerEmail
        // Relationships are handled in BookingStore
    }

    public func toReadOnly() -> Yosemite.BookingOrderInfo {
        let readOnlyLineItems: [Yosemite.BookingOrderLineItem] = (lineItems?.array as? [Storage.BookingOrderLineItem])?.map { $0.toReadOnly() } ?? []
        let readOnlyRefunds: [Yosemite.BookingOrderRefund] = (refunds as? Set<Storage.BookingOrderRefund>)?.map { $0.toReadOnly() } ?? []

        return .init(statusKey: statusKey ?? "",
                     orderID: orderID,
                     orderNumber: orderNumber ?? "",
                     dateCreated: dateCreated ?? Date(),
                     datePaid: datePaid,
                     discountTotal: discountTotal ?? "",
                     customerEmail: customerEmail,
                     paymentInfo: paymentInfo?.toReadOnly(),
                     customerInfo: customerInfo?.toReadOnly(),
                     productInfo: productInfo?.toReadOnly(),
                     lineItems: readOnlyLineItems,
                     refunds: readOnlyRefunds)
    }
}
