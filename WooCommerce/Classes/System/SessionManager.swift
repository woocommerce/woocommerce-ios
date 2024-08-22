import Combine
import Foundation
import Yosemite
import KeychainAccess
import protocol Networking.ApplicationPasswordUseCase
import class Networking.OneTimeApplicationPasswordUseCase
import class Networking.DefaultApplicationPasswordUseCase
import class Kingfisher.ImageCache

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
                                     enablesCrashReports: defaults[.userOptedInCrashLogging] ?? true,
                                     account: defaultAccount)
        }()

        return WatchDependenciesSynchronizer(storedDependencies: storedDependencies)
    }()

    /// Default Credentials.
    ///
    var defaultCredentials: Credentials? {
        get {
            return loadCredentials()
        }
        set {
            guard newValue != defaultCredentials else {
                return
            }

            removeCredentials()

            if let credentials = newValue {
                saveCredentials(credentials)
            }

            watchDependenciesSynchronizer.credentials = newValue
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
        }
    }

    /// Designated Initializer.
    ///
    init(defaults: UserDefaults,
         keychainServiceName: String,
         imageCache: ImageCache = ImageCache.default) {
        self.defaults = defaults
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        self.imageCache = imageCache

        defaultStoreIDSubject = .init(defaults[.defaultStoreID])

        // Listens when the core data stack is rest.
        NotificationCenter.default.addObserver(self, selector: #selector(handleStorageDidReset), name: .StorageManagerDidResetStorage, object: nil)
    }

    /// Nukes all of the known Session's properties.
    ///
    func reset() {
        deleteApplicationPassword()
        defaultAccount = nil
        defaultCredentials = nil
        defaultStoreID = nil
        defaultStoreUUID = nil
        defaultSite = nil
        defaults[.storePhoneNumber] = nil
        defaults[.completedAllStoreOnboardingTasks] = nil
        defaults[.hasSavedPrivacyBannerSettings] = nil
        defaults[.usedProductDescriptionAI] = nil
        defaults[.hasDismissedWriteWithAITooltip] = nil
        defaults[.numberOfTimesWriteWithAITooltipIsShown] = nil
        defaults[.storeProfilerAnswers] = nil
        defaults[.aiPromptTone] = nil
        defaults[.numberOfTimesProductCreationAISurveySuggested] = nil
        defaults[.didStartProductCreationAISurvey] = nil
        defaults[.themesPendingInstall] = nil
        defaults[.siteIDPendingStoreSwitch] = nil
        defaults[.expectedStoreNamePendingStoreSwitch] = nil
        resetTimestampsValues()
        imageCache.clearCache()
    }

    /// Deletes application password
    ///
    func deleteApplicationPassword() {
        let useCase: ApplicationPasswordUseCase? = {
            switch loadCredentials() {
            case let .wporg(username, password, siteAddress):
                return try? DefaultApplicationPasswordUseCase(username: username,
                                                              password: password,
                                                              siteAddress: siteAddress,
                                                              keychain: keychain)
            case let .applicationPassword(_, _, siteAddress):
                return OneTimeApplicationPasswordUseCase(siteAddress: siteAddress, keychain: keychain)
            default:
                return nil
            }
        }()
        guard let useCase else {
            return
        }

        Task {
            try await useCase.deletePassword()
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

    /// Updates the timestamps that control when background data is fetched.
    ///
    @objc func handleStorageDidReset() {
        resetTimestampsValues()
    }

    /// Removes timestamp values.
    ///
    func resetTimestampsValues() {
        defaults[.latestBackgroundOrderSyncDate] = nil
        DashboardTimestampStore.resetStore(store: defaults)
    }
}
