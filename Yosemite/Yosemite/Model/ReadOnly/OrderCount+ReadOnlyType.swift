import Foundation
import Storage


// MARK: - Yosemite.OrderCount: ReadOnlyType
//
extension Yosemite.OrderCount: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageOrderCount = storageEntity as? Storage.OrderCount else {
            return false
        }

        return Int(storageOrderCount.siteID) == siteID
    }
}
