import Foundation
import Storage


// MARK: - Storage.AccountSettings: ReadOnlyConvertible
//
extension Storage.AccountSettings: ReadOnlyConvertible {

    /// Updates the Storage.AccountSettings with the a ReadOnly.
    ///
    public func update(with accountSettings: Yosemite.AccountSettings) {
        userID = accountSettings.userID
        tracksOptOut = accountSettings.tracksOptOut
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.AccountSettings {
        return AccountSettings(userID: userID,
                               tracksOptOut: tracksOptOut)
    }
}
