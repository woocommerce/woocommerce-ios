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
        // Relationships are handled in BookingStore
    }

    public func toReadOnly() -> Yosemite.BookingOrderInfo {
        return .init(statusKey: statusKey ?? "",
                     orderID: orderID,
                     orderNumber: orderNumber ?? "",
                     dateCreated: dateCreated ?? Date(),
                     datePaid: datePaid,
                     discountTotal: discountTotal ?? "",
                     paymentInfo: paymentInfo?.toReadOnly(),
                     customerInfo: customerInfo?.toReadOnly(),
                     productInfo: productInfo?.toReadOnly())
    }
}
