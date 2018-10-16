import Foundation
import Storage


// MARK: - Yosemite.OrderStats: ReadOnlyType
//
extension Yosemite.OrderStats: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageOrderStats = storageEntity as? Storage.OrderStats else {
            return false
        }

        return storageOrderStats.granularity == granularity.rawValue &&
            storageOrderStats.date == date &&
            storageOrderStats.quantity == quantity
    }
}
