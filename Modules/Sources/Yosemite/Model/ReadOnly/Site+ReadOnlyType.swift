import Foundation
import Storage


// MARK: - Yosemite.Site: ReadOnlyType
//
extension Yosemite.Site: ReadOnlyType {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageSite = storageEntity as? Storage.Site else {
            return false
        }

        return siteID == Int(storageSite.siteID)
    }
}
