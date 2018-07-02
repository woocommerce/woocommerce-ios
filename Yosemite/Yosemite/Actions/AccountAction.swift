import Foundation
import Networking



// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case synchronizeAccount(onCompletion: (Account?, Error?) -> Void)
    case retrieveAccount(userId: Int, onCompletion: (Account?) -> Void)
}
