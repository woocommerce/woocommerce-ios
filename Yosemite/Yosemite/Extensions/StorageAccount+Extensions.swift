import Foundation
import Storage
import Networking


/// Storage.Account Convenience Methods.
///
extension Storage.Account {

    /// Updates the Storage.Account with the Networking.Account's Payload.
    ///
    func update(with account: Networking.Account) {
        displayName = account.displayName
        email = account.email
        gravatarUrl = account.gravatarUrl
        userID = Int64(account.userID)
        username = account.username
    }
}


// MARK: - Storage.Account ReadOnlyConvertible
//
extension Storage.Account: ReadOnlyConvertible {

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Networking.Account {
        return Account(userID: Int(userID),
                       displayName: displayName ?? "",
                       email: email ?? "",
                       username: username ?? "",
                       gravatarUrl: gravatarUrl)
    }
}
