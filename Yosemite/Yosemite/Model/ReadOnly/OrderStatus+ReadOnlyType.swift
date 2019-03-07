import Foundation
import Storage


// MARK: - Yosemite.OrderStatus: ReadOnlyType
//
extension Yosemite.OrderStatus: ReadOnlyType {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageOrderStatus = storageEntity as? Storage.OrderStatus else {
            return false
        }

        return siteID == Int(storageOrderStatus.siteID) &&
            storageOrderStatus.slug == slug
    }
}
