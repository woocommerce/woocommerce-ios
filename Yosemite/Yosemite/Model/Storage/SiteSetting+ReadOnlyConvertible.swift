import Foundation
import Storage


// Storage.SiteSetting: ReadOnlyConvertible Conformance.
//
extension Storage.SiteSetting: ReadOnlyConvertible {

    /// Updates the Storage.SiteSetting with the a ReadOnly.
    ///
    public func update(with setting: Yosemite.SiteSetting) {
        siteID = setting.siteID
        settingID = setting.settingID
        label = setting.label
        settingDescription = setting.settingDescription
        value = setting.value
        settingGroupKey = setting.settingGroupKey
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteSetting {
        return SiteSetting(siteID: siteID,
                           settingID: settingID ?? "",
                           label: label ?? "",
                           description: settingDescription ?? "",
                           value: value ?? "",
                           settingGroupKey: settingGroupKey ?? SiteSettingGroup.general.rawValue) // Default to general group
    }
}
