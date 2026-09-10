import Foundation
import Networking

/// The result of a successful WordPress.com sites synchronization.
///
/// The site IDs come from the sites returned by the networking layer, including an empty result.
/// Consumers must only use them after a successful synchronization.
public struct SiteSynchronizationResult: Equatable {
    /// Whether the response contains sites connected through Jetpack Connection Package.
    public let containsJetpackConnectionPackageSites: Bool

    /// All site IDs returned by `/me/sites`.
    public let siteIDs: [Int64]

    public init(containsJetpackConnectionPackageSites: Bool, siteIDs: [Int64]) {
        self.containsJetpackConnectionPackageSites = containsJetpackConnectionPackageSites
        self.siteIDs = siteIDs
    }
}

public typealias SelectedSiteSynchronizationResult = (site: Site, synchronizationResult: SiteSynchronizationResult)
public typealias SiteLoadResult = (site: Site, synchronizationResult: SiteSynchronizationResult?)

// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case loadAccount(userID: Int64, onCompletion: (Account?) -> Void)
    case loadAndSynchronizeSite(siteID: Int64,
                                forcedUpdate: Bool,
                                shouldSynchronize: Bool,
                                onCompletion: (Result<SiteLoadResult, Error>) -> Void)
    case synchronizeAccount(onCompletion: (Result<Account, Error>) -> Void)
    case synchronizeAccountSettings(userID: Int64, onCompletion: (Result<AccountSettings, Error>) -> Void)
    case synchronizeSites(onCompletion: (Result<SiteSynchronizationResult, Error>) -> Void)
    case synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: String, onCompletion: (Result<SelectedSiteSynchronizationResult, Error>) -> Void)
    case synchronizeSitePlan(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
    case updateAccountSettings(userID: Int64, tracksOptOut: Bool, onCompletion: (Result<Void, Error>) -> Void)
    case updateCrashReportingOptOut(optOut: Bool, onCompletion: (Result<Void, Error>) -> Void)
    case loadNotificationSettings(deviceID: Int64, onCompletion: (Result<NotificationSettings, Error>) -> Void)
    case updateNotificationSettings(notificationSettings: NotificationSettings, onCompletion: (Result<Void, Error>) -> Void)
    case closeAccount(onCompletion: (Result<Void, Error>) -> Void)
}
