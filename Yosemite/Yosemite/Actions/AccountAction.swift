import Foundation
import Networking



// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case loadAccount(userID: Int64, onCompletion: (Account?) -> Void)
    case loadAndSynchronizeSite(siteID: Int64, forcedUpdate: Bool, isJetpackConnectionPackageSupported: Bool, onCompletion: (Result<Site, Error>) -> Void)
    case synchronizeAccount(onCompletion: (Result<Account, Error>) -> Void)
    case synchronizeAccountSettings(userID: Int64, onCompletion: (Result<AccountSettings, Error>) -> Void)
    /// The boolean in the completion block indicates whether the sites contain any JCP sites (connected to Jetpack without Jetpack-the-plugin).
    case synchronizeSites(selectedSiteID: Int64?, isJetpackConnectionPackageSupported: Bool, onCompletion: (Result<Bool, Error>) -> Void)
    case synchronizeSitePlan(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
    case updateAccountSettings(userID: Int64, tracksOptOut: Bool, onCompletion: (Result<Void, Error>) -> Void)
}
