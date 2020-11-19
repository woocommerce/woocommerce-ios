import Foundation
import Storage

// Storage.ShippingLabelRefund: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelRefund: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelRefund with the a ReadOnly ShippingLabelRefund.
    ///
    public func update(with refund: Yosemite.ShippingLabelRefund) {
        self.dateRequested = refund.dateRequested
        self.status = refund.status.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelRefund {
        .init(dateRequested: dateRequested, status: .init(rawValue: status))
    }
}
