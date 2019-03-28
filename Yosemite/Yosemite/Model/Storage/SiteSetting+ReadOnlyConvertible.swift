import Foundation
import Storage


// Storage.SiteSetting: ReadOnlyConvertible Conformance.
//
extension Storage.SiteSetting: ReadOnlyConvertible {

    /// Updates the Storage.SiteSetting with the a ReadOnly.
    ///
    public func update(with setting: Yosemite.SiteSetting) {
        siteID = Int64(setting.siteID)
        settingID = setting.settingID
        label = setting.label
        settingDescription = setting.settingDescription
        value = setting.value
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteSetting {
        return SiteSetting(siteID: Int(siteID),
                           settingID: settingID ?? "",
                           label: label ?? "",
                           description: settingDescription ?? "",
                           value: value ?? "",
                           settingGroupKey: "") // FIXME: Add the setting group here
    }
}
