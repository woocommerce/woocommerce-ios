import Foundation
import Storage


// MARK: - Storage.OrderRefundCondensed: ReadOnlyConvertible
//
extension Storage.OrderRefundCondensed: ReadOnlyConvertible {

    /// Updates the Storage.OrderRefundCondensed with the ReadOnly.
    ///
    public func update(with orderRefundCondensed: Yosemite.OrderRefundCondensed) {
        refundID = orderRefundCondensed.refundID
        reason = orderRefundCondensed.reason
        total = orderRefundCondensed.total
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderRefundCondensed {
        return OrderRefundCondensed(refundID: refundID,
                                    reason: reason ?? "",
                                    total: total ?? "")
    }
}
