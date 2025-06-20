import Foundation
import Storage


// MARK: - Yosemite.SiteSetting: ReadOnlyType
//
extension Yosemite.SiteSetting: ReadOnlyType {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageSiteSiteSetting = storageEntity as? Storage.SiteSetting else {
            return false
        }

        return siteID == Int(storageSiteSiteSetting.siteID) &&
            storageSiteSiteSetting.settingID == settingID &&
            storageSiteSiteSetting.settingGroupKey == settingGroupKey
    }
}
