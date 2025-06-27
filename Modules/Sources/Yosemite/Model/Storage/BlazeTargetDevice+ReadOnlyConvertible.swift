import Foundation
import Storage

// MARK: - Storage.BlazeTargetDevice: ReadOnlyConvertible
//
extension Storage.BlazeTargetDevice: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeTargetDevice` from the ReadOnly representation (`Networking.BlazeTargetDevice`)
    ///
    public func update(with campaign: Yosemite.BlazeTargetDevice) {
        id = campaign.id
        name = campaign.name
        locale = campaign.locale
    }

    /// Returns a ReadOnly (`Networking.BlazeTargetDevice`) version of the `Storage.BlazeTargetDevice`
    ///
    public func toReadOnly() -> BlazeTargetDevice {
        .init(id: id, name: name, locale: locale)
    }
}
