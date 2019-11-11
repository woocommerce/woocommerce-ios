import Foundation
import Storage


// MARK: - Yosemite.Refund: ReadOnlyType
//
extension Yosemite.Refund: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageRefund = storageEntity as? Storage.Refund else {
            return false
        }

        return siteID == Int(storageRefund.siteID) && refundID == Int(storageRefund.refundID)
    }
}
