import Foundation
import Storage


// MARK: - Yosemite.Order: ReadOnlyType
//
extension Yosemite.Order: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageOrder = storageEntity as? Storage.Order else {
            return false
        }

        return siteID == Int(storageOrder.siteID) && orderID == Int(storageOrder.orderID)
    }
}
