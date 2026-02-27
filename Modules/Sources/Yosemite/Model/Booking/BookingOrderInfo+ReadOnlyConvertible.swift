import Foundation
import Storage

// MARK: - Storage.BookingOrderInfo: ReadOnlyConvertible
//
extension Storage.BookingOrderInfo: ReadOnlyConvertible {
    public func update(with orderInfo: Yosemite.BookingOrderInfo) {
        statusKey = orderInfo.statusKey
        datePaid = orderInfo.datePaid
        // Relationships are handled in BookingStore
    }

    public func toReadOnly() -> Yosemite.BookingOrderInfo {
        return .init(statusKey: statusKey ?? "",
                     datePaid: datePaid,
                     paymentInfo: paymentInfo?.toReadOnly(),
                     customerInfo: customerInfo?.toReadOnly(),
                     productInfo: productInfo?.toReadOnly())
    }
}
