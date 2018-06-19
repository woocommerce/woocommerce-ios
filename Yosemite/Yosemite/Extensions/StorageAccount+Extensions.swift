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

    /// Returns an immutable version of the receiver.
    ///
    func toStruct() -> Networking.Account {
        return Account(userID: Int(userID),
                       displayName: displayName ?? "",
                       email: email ?? "",
                       username: username ?? "",
                       gravatarUrl: gravatarUrl)
    }
}
