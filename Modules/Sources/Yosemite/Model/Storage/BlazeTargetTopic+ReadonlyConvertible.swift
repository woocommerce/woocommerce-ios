import Foundation
import Storage

// MARK: - Storage.BlazeTargetTopic: ReadOnlyConvertible
//
extension Storage.BlazeTargetTopic: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeTargetTopic` from the ReadOnly representation (`Networking.BlazeTargetTopic`)
    ///
    public func update(with campaign: Yosemite.BlazeTargetTopic) {
        id = campaign.id
        name = campaign.name
        locale = campaign.locale
    }

    /// Returns a ReadOnly (`Networking.BlazeTargetTopic`) version of the `Storage.BlazeTargetTopic`
    ///
    public func toReadOnly() -> BlazeTargetTopic {
        .init(id: id, name: name, locale: locale)
    }
}
