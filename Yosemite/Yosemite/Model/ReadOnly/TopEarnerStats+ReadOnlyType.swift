import Foundation
import Storage


// MARK: - Yosemite.TopEarnerStats: ReadOnlyType
//
extension Yosemite.TopEarnerStats: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageTopEarnerStats = storageEntity as? Storage.TopEarnerStats else {
            return false
        }

        return storageTopEarnerStats.siteID == siteID &&
            storageTopEarnerStats.granularity == granularity.rawValue &&
            storageTopEarnerStats.date == date
    }
}
