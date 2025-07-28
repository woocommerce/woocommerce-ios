import Foundation
import Storage


// MARK: - Yosemite.Account: ReadOnlyType
//
extension Yosemite.Account: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageAccount = storageEntity as? Storage.Account else {
            return false
        }

        return Int(storageAccount.userID) == userID
    }
}
