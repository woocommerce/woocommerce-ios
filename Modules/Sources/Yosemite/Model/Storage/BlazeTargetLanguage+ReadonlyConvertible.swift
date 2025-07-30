import Foundation
import Storage

// MARK: - Storage.BlazeTargetLanguage: ReadOnlyConvertible
//
extension Storage.BlazeTargetLanguage: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeTargetLanguage` from the ReadOnly representation (`Networking.BlazeTargetLanguage`)
    ///
    public func update(with campaign: Yosemite.BlazeTargetLanguage) {
        id = campaign.id
        name = campaign.name
        locale = campaign.locale
    }

    /// Returns a ReadOnly (`Networking.BlazeTargetLanguage`) version of the `Storage.BlazeTargetLanguage`
    ///
    public func toReadOnly() -> BlazeTargetLanguage {
        .init(id: id, name: name, locale: locale)
    }
}
