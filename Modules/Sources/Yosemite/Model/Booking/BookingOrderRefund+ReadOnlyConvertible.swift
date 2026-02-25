import Foundation
import Storage

// MARK: - Storage.BookingOrderRefund: ReadOnlyConvertible
//
extension Storage.BookingOrderRefund: ReadOnlyConvertible {
    public func update(with refund: Yosemite.BookingOrderRefund) {
        refundID = refund.refundID
        reason = refund.reason
        total = refund.total
    }

    public func toReadOnly() -> Yosemite.BookingOrderRefund {
        return .init(refundID: refundID,
                     reason: reason,
                     total: total ?? "")
    }
}
