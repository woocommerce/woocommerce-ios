import Foundation
import Storage


// MARK: - Storage.Account: ReadOnlyConvertible
//
extension Storage.Account: ReadOnlyConvertible {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func represents(readOnlyEntity: Any) -> Bool {
        guard let readOnlyAccount = readOnlyEntity as? Yosemite.Account else {
            return false
        }

        return readOnlyAccount.userID == Int(userID)
    }

    /// Updates the Storage.Account with the a ReadOnly.
    ///
    public func update(with account: Yosemite.Account) {
        displayName = account.displayName
        email = account.email
        gravatarUrl = account.gravatarUrl
        userID = Int64(account.userID)
        username = account.username
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Account {
        return Account(userID: Int(userID),
                       displayName: displayName ?? "",
                       email: email ?? "",
                       username: username ?? "",
                       gravatarUrl: gravatarUrl)
    }
}
