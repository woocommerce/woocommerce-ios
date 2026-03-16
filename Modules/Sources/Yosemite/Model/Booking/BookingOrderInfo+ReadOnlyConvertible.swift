import Foundation
import Storage

// MARK: - Storage.BookingOrderInfo: ReadOnlyConvertible
//
extension Storage.BookingOrderInfo: ReadOnlyConvertible {
    public func update(with orderInfo: Yosemite.BookingOrderInfo) {
        statusKey = orderInfo.statusKey
        datePaid = orderInfo.datePaid
        total = orderInfo.total as NSDecimalNumber
        refundTotal = orderInfo.refundTotal as NSDecimalNumber
        paymentStatusMetadata = orderInfo.paymentStatusMetadata
        // Relationships are handled in BookingStore
    }

    public func toReadOnly() -> Yosemite.BookingOrderInfo {
        return .init(statusKey: statusKey ?? "",
                     datePaid: datePaid,
                     total: total as Decimal? ?? 0,
                     refundTotal: refundTotal as Decimal? ?? 0,
                     paymentStatusMetadata: paymentStatusMetadata,
                     paymentInfo: paymentInfo?.toReadOnly(),
                     customerInfo: customerInfo?.toReadOnly(),
                     productInfo: productInfo?.toReadOnly())
    }
}
