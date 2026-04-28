import Combine
import Foundation
import Yosemite
import UIKit
import KeychainAccess
import protocol Networking.ApplicationPasswordUseCase
import class Networking.OneTimeApplicationPasswordUseCase
import class Networking.DefaultApplicationPasswordUseCase
import class Kingfisher.ImageCache
import class Networking.AlamofireNetwork

// MARK: - SessionManager Notifications
//
extension NSNotification.Name {

    /// Posted whenever the Default Account is updated.
    ///
    public static let defaultAccountWasUpdated = Foundation.Notification.Name(rawValue: "DefaultAccountWasUpdated")

    /// Posted after a Log out event happens.
    ///
    public static let logOutEventReceived = Foundation.Notification.Name(rawValue: "LogOutEventReceived")

    /// Posted whenever the app is about to terminate.
    ///
    public static let applicationTerminating = Foundation.Notification.Name(rawValue: "ApplicationTerminating")
}

private extension UserDefaults {
    @objc dynamic var defaultStoreID: Int {
        integer(forKey: Key.defaultStoreID.rawValue)
    }
}

/// SessionManager provides persistent storage for Session-Y Properties.
///
final class SessionManager: SessionManagerProtocol {

    /// Standard Session Manager
    ///
    static var standard: SessionManager {
        return SessionManager(defaults: .standard, keychainServiceName: WooConstants.keychainServiceName)
    }

    /// Reference to the UserDefaults Instance that should be used.
    ///
    private let defaults: UserDefaults

    /// KeychainAccess Wrapper.
    ///
    private let keychain: Keychain

    /// Cache which stores product images
    ///
    private let imageCache: ImageCache

    /// Serial queue for thread-safe credentials access
    ///
    private let credentialsQueue = DispatchQueue(label: "com.woocommerce.session.credentials", qos: .userInitiated)

    /// Makes sure the credentials are in sync with the watch session.
    ///
    private lazy var watchDependenciesSynchronizer = {
        let storedDependencies: WatchDependencies? = {
            guard let storeID = self.defaultStoreID, let credentials = self.loadCredentials() else {
                return nil
            }
            return WatchDependencies(storeID: storeID,
                                     storeName: defaultSite?.name ?? "",
                                     currencySettings: ServiceLocator.currencySettings,
                                     credentials: credentials,
                                     supportsJetpackVisitorStats: defaultSite?.supportsJetpackVisitorStats ?? false,
                                     enablesCrashReports: defaults[.userOptedInCrashLogging] ?? true,
                                     account: defaultAccount)
        }()

        return WatchDependenciesSynchronizer(storedDependencies: storedDependencies)
    }()

    /// Default Credentials.
    ///
    var defaultCredentials: Credentials? {
        get {
            credentialsQueue.sync {
                loadCredentials()
            }
        }
        set {
            let shouldUpdateWatchSync = credentialsQueue.sync { () -> Bool in
                let currentCredentials = loadCredentials()
                guard newValue != currentCredentials else {
                    return false
                }

                removeCredentials()

                if let credentials = newValue {
                    saveCredentials(credentials)
                }

                return true
            }

            // Update watch synchronizer outside the sync block to avoid potential deadlocks
            // from @Published property triggering Combine subscribers that might read credentials
            if shouldUpdateWatchSync {
                watchDependenciesSynchronizer.credentials = newValue
            }
        }
    }

    /// Ephemeral: Default Account.
    ///
    var defaultAccount: Yosemite.Account? {
        didSet {
            defaults[.defaultAccountID] = defaultAccount?.userID
            NotificationCenter.default.post(name: .defaultAccountWasUpdated, object: defaultAccount)
            watchDependenciesSynchronizer.account = defaultAccount
        }
    }

    /// Default AccountID: Returns the last known Account's User ID.
    ///
    var defaultAccountID: Int64? {
        return defaults[.defaultAccountID]
    }

    /// Default StoreID.
    ///
    var defaultStoreID: Int64? {
        get {
            return defaults[.defaultStoreID]
        }
        set {
            defaults[.defaultStoreID] = newValue
            defaultStoreIDSubject.send(newValue)

            watchDependenciesSynchronizer.storeID = defaultStoreID
        }
    }

    /// Unique WooCommerce Store UUID.
    /// Do not confuse with `defaultStoreID` which is in fact the WPCom `siteID`.
    ///
    var defaultStoreUUID: String?

    /// Roles for the default Store Site.
    ///
    var defaultRoles: [User.Role] {
        get {
            guard let rawRoles = defaults[.defaultRoles] as? [String] else {
                return []
            }
            return rawRoles.compactMap { User.Role(rawValue: $0) }
        }
        set {
            defaults[.defaultRoles] = newValue.map(\.rawValue)
        }
    }

    var defaultStoreIDPublisher: AnyPublisher<Int64?, Never> {
        defaultStoreIDSubject.eraseToAnyPublisher()
    }

    private let defaultStoreIDSubject: CurrentValueSubject<Int64?, Never>

    var defaultSitePublisher: AnyPublisher<Site?, Never> {
        $defaultSite.eraseToAnyPublisher()
    }

    /// Anonymous UserID.
    ///
    var anonymousUserID: String? {
        if let anonID = defaults[.defaultAnonymousID] as? String, !anonID.isEmpty {
            return anonID
        } else if let keychainAnonID = keychain.anonymousID, !keychainAnonID.isEmpty {
            defaults[.defaultAnonymousID] = keychainAnonID
            return keychainAnonID
        } else {
            let newValue = UUID().uuidString
            defaults[.defaultAnonymousID] = newValue
            keychain.anonymousID = newValue
            return newValue
        }
    }

    /// Default Store Site
    ///
    @Published var defaultSite: Site? {
        didSet {
            watchDependenciesSynchronizer.storeName = defaultSite?.name
            watchDependenciesSynchronizer.supportsJetpackVisitorStats = defaultSite?.supportsJetpackVisitorStats ?? false
        }
    }

    /// Cached WooCommerce version for the default store.
    ///
    var cachedWooCommerceVersion: String?

    /// Keeps strong reference of the use case to keep the password deletion request alive
    /// periphery: ignore
    var applicationPasswordUseCase: ApplicationPasswordUseCase?

    /// Designated Initializer.
    ///
    init(defaults: UserDefaults,
         keychainServiceName: String,
         imageCache: ImageCache = ImageCache.default) {
        self.defaults = defaults
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        self.imageCache = imageCache

        defaultStoreIDSubject = .init(defaults[.defaultStoreID])

        // Listens when the core data stack is reset.
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimestampsValues), name: .StorageManagerDidResetStorage, object: nil)


        // Listens when the cached data is invalidated.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetTimestampsValues),
                                               name: .StorageManagerDidDropDatabase,
                                               object: nil)
    }

    /// Nukes all of the known Session's properties.
    ///
    func reset() {
        defaultAccount = nil
        defaultCredentials = nil
        defaultStoreID = nil
        defaultStoreUUID = nil
        defaultSite = nil
        cachedWooCommerceVersion = nil
        defaults[.storePhoneNumber] = nil
        defaults[.completedAllStoreOnboardingTasks] = nil
        defaults[.hasSavedPrivacyBannerSettings] = nil
        defaults[.usedProductDescriptionAI] = nil
        defaults[.hasDismissedWriteWithAITooltip] = nil
        defaults[.numberOfTimesWriteWithAITooltipIsShown] = nil
        defaults[.storeProfilerAnswers] = nil
        defaults[.aiPromptTone] = nil
        defaults[.themesPendingInstall] = nil
        defaults[.hiddenStoreIDs] = nil
        defaults[.blazeNoCampaignReminderOpened] = nil
        defaults[.blazeAbandonedCampaignCreationReminderOpened] = nil
        defaults[.blazeSelectedCampaignObjective] = nil
        defaults[.wpcomSiteSuspended] = nil
        defaults[.tapToPayAwarenessMomentFirstLaunchCompleted] = nil
        defaults[.applicationPasswordUnsupportedList] = nil
        defaults[.applicationPasswordsExperimentRemoteFFValue] = nil
        defaults[.ciabBookingsTabAvailable] = nil
        defaults[.hideWPComConnectionOnDashboard] = nil
        defaults[.debugMinWooVersionForSelfDrivenPushNotifications] = nil
        PendingAuthFlowStorage(userDefaults: defaults).clear()
        resetTimestampsValues()
        imageCache.clearCache()
    }

    /// Deletes application password
    ///
    func deleteApplicationPassword(using creds: Credentials?, locally: Bool) {
        let useCase: ApplicationPasswordUseCase? = credentialsQueue.sync {
            let credentials = creds ?? loadCredentials()
            switch credentials {
            case let .wporg(username, password, siteAddress):
                return try? DefaultApplicationPasswordUseCase(username: username,
                                                              password: password,
                                                              siteAddress: siteAddress)
            case let .applicationPassword(_, _, siteAddress):
                return OneTimeApplicationPasswordUseCase(siteAddress: siteAddress)
            case .wpcom:
                guard let siteID = defaultStoreID else {
                    return nil
                }
                let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil)
                return DefaultApplicationPasswordUseCase(type: .wpcom(siteID: siteID), network: network)
            case .none:
                return nil
            }
        }
        guard let useCase else {
            return
        }

        applicationPasswordUseCase = useCase
        Task { @MainActor in
            try await useCase.deletePassword(locally: locally)
            applicationPasswordUseCase = nil
        }
    }
}


// MARK: - Private Methods
//
private extension SessionManager {

    /// Returns the Default Credentials, if any.
    ///
    func loadCredentials() -> Credentials? {
        guard let username = defaults[.defaultUsername] as? String,
              let secret = keychain[username],
              let siteAddress = defaults[.defaultSiteAddress] as? String else {
            return nil
        }

        // To cover the case of previous versions which don't have the credential type stored in user defaults
        guard let defaultCredentialsType = defaults[.defaultCredentialsType] as? String else {
            return .wpcom(username: username, authToken: secret, siteAddress: siteAddress)
        }

        return Credentials(rawType: defaultCredentialsType, username: username, secret: secret, siteAddress: siteAddress)
    }

    /// Persists the Credentials's authToken in the keychain, and username in User Settings.
    ///
    func saveCredentials(_ credentials: Credentials) {
        defaults[.defaultUsername] = credentials.username
        defaults[.defaultSiteAddress] = credentials.siteAddress
        defaults[.defaultCredentialsType] = credentials.rawType
        keychain[credentials.username] = credentials.secret
    }

    /// Nukes both, the AuthToken and Default Username.
    ///
    func removeCredentials() {
        guard let username = defaults[.defaultUsername] as? String else {
            return
        }

        keychain[username] = nil
        defaults[.defaultUsername] = nil
        defaults[.defaultCredentialsType] = nil
    }

    /// Removes timestamp values.
    ///
    @objc func resetTimestampsValues() {
        defaults[.latestBackgroundOrderSyncDate] = nil
        DashboardTimestampStore.resetStore(store: defaults)
    }
}
