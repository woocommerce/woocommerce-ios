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
        crashReportingOptOut = accountSettings.crashReportingOptOut.map(NSNumber.init(value:))
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.AccountSettings {
        return AccountSettings(userID: userID,
                               tracksOptOut: tracksOptOut,
                               crashReportingOptOut: crashReportingOptOut?.boolValue,
                               firstName: firstName,
                               lastName: lastName)
    }
}
