import Foundation
import Storage


// MARK: - Yosemite.SiteVisitStats: ReadOnlyType
//
extension Yosemite.SiteVisitStats: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageSiteVisitStats = storageEntity as? Storage.SiteVisitStats else {
            return false
        }

        return storageSiteVisitStats.siteID == siteID &&
            storageSiteVisitStats.granularity == granularity.rawValue &&
            storageSiteVisitStats.date == date
    }
}
