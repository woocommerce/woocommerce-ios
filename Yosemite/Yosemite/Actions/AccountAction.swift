import Foundation
import Networking



// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case loadAccount(userID: Int64, onCompletion: (Account?) -> Void)
    case loadSite(siteID: Int64, onCompletion: (Site?) -> Void)
    case synchronizeAccount(onCompletion: (Result<Account, Error>) -> Void)
    case synchronizeAccountSettings(userID: Int64, onCompletion: (Result<AccountSettings, Error>) -> Void)
    case synchronizeSites(selectedSiteID: Int64?, onCompletion: (Result<Void, Error>) -> Void)
    case synchronizeSitePlan(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
    case updateAccountSettings(userID: Int64, tracksOptOut: Bool, onCompletion: (Result<Void, Error>) -> Void)
}
