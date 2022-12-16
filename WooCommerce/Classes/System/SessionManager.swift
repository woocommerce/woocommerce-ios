import Combine
import Foundation
import Yosemite
import KeychainAccess

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

    /// Default Credentials.
    ///
    var defaultCredentials: WPCOMCredentials? {
        get {
            return loadCredentials()
        }
        set {
            guard newValue != defaultCredentials else {
                return
            }

            removeCredentials()

            guard let credentials = newValue else {
                return
            }

            saveCredentials(credentials)
        }
    }

    /// Ephemeral: Default Account.
    ///
    var defaultAccount: Yosemite.Account? {
        didSet {
            defaults[.defaultAccountID] = defaultAccount?.userID
            NotificationCenter.default.post(name: .defaultAccountWasUpdated, object: defaultAccount)
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
        }
    }

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
    @Published var defaultSite: Site?

    /// Designated Initializer.
    ///
    init(defaults: UserDefaults, keychainServiceName: String) {
        self.defaults = defaults
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)

        defaultStoreIDSubject = .init(defaults[.defaultStoreID])
    }

    /// Nukes all of the known Session's properties.
    ///
    func reset() {
        defaultAccount = nil
        defaultCredentials = nil
        defaultStoreID = nil
        defaultSite = nil
    }
}


// MARK: - Private Methods
//
private extension SessionManager {

    /// Returns the Default Credentials, if any.
    ///
    func loadCredentials() -> WPCOMCredentials? {
        guard let username = defaults[.defaultUsername] as? String,
            let authToken = keychain[username],
            let siteAddress = defaults[.defaultSiteAddress] as? String else {
            return nil
        }

        return WPCOMCredentials(username: username, authToken: authToken, siteAddress: siteAddress)
    }

    /// Persists the Credentials's authToken in the keychain, and username in User Settings.
    ///
    func saveCredentials(_ credentials: WPCOMCredentials) {
        defaults[.defaultUsername] = credentials.username
        defaults[.defaultSiteAddress] = credentials.siteAddress
        keychain[credentials.username] = credentials.authToken
    }

    /// Nukes both, the AuthToken and Default Username.
    ///
    func removeCredentials() {
        guard let username = defaults[.defaultUsername] as? String else {
            return
        }

        keychain[username] = nil
        defaults[.defaultUsername] = nil
    }
}
