import Foundation
import Storage


// MARK: - Storage.AccountSettings: ReadOnlyConvertible
//
extension Storage.AccountSettings: ReadOnlyConvertible {

    /// Updates the Storage.AccountSettings with the ReadOnly.
    ///
    public func update(with accountSettings: Yosemite.AccountSettings) {
        userID = accountSettings.userID
        tracksOptOut = accountSettings.tracksOptOut
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.AccountSettings {
        // `crashReportingOptOut` is intentionally not persisted in storage — the local source
        // of truth for crash reporting lives in user defaults.
        return AccountSettings(userID: userID,
                               tracksOptOut: tracksOptOut,
                               crashReportingOptOut: nil,
                               firstName: firstName,
                               lastName: lastName)
    }
}
