import Foundation
import Networking



// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case loadAccount(userID: Int, onCompletion: (Account?) -> Void)
    case loadSite(siteID: Int, onCompletion: (Site?) -> Void)
    case synchronizeAccount(onCompletion: (Account?, Error?) -> Void)
    case synchronizeSites(onCompletion: (Error?) -> Void)
}
