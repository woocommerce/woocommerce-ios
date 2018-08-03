import Foundation
import Yosemite


// MARK: - MockupStorage Sample Entity Insertion Methods
//
extension MockupStorageManager {

    /// Inserts a new (Sample) account into the specified context.
    ///
    @discardableResult
    func insertSampleAccount() -> StorageAccount {
        let newAccount = viewStorage.insertNewObject(ofType: StorageAccount.self)
        newAccount.userID = Int64(arc4random())
        newAccount.displayName = "Yosemite"
        newAccount.email = "yosemite@yosemite"
        newAccount.gravatarUrl = "https://something"
        newAccount.username = "yosemite"

        return newAccount
    }
}
