import Foundation
import Yosemite
import KeychainAccess



// MARK: - SessionManager Notifications
//
extension NSNotification.Name {

    /// Posted whenever the Default Account is updated.
    ///
    public static let defaultAccountWasUpdated = Foundation.Notification.Name(rawValue: "DefaultAccountWasUpdated")

    /// Posted whenever the app is about to terminate.
    ///
    public static let applicationTerminating = Foundation.Notification.Name(rawValue: "ApplicationTerminating")
}


/// SessionManager provides persistent storage for Session-Y Properties.
///
struct SessionManager {

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
    var defaultCredentials: Credentials? {
        get {
            return loadCredentials()
        }
        set {
            guard newValue != defaultCredentials else {
                return
            }

            guard let credentials = newValue else {
                removeCredentials()
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
    var defaultAccountID: Int? {
        return defaults[.defaultAccountID]
    }

    /// Default StoreID.
    ///
    var defaultStoreID: Int? {
        get {
            return defaults[.defaultStoreID]
        }
        set {
            defaults[.defaultStoreID] = newValue
        }
    }

    /// Anonymous UserID.
    ///
    var anonymousUserID: String? {
        get {
            if let anonID = defaults[.defaultAnonymousID] as? String, !anonID.isEmpty {
                return anonID
            } else {
                let newValue = UUID().uuidString
                defaults[.defaultAnonymousID] = newValue
                return newValue
            }
        }
    }

    /// Default Store Site
    ///
    var defaultSite: Yosemite.Site?
    
    /// Default Store Currency
    var defaultSiteMoneyFormat: MoneyFormatSettings?

    /// Designated Initializer.
    ///
    init(defaults: UserDefaults, keychainServiceName: String) {
        self.defaults = defaults
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
    }

    /// Nukes all of the known Session's properties.
    ///
    mutating func reset() {
        defaultAccount = nil
        defaultCredentials = nil
        defaultStoreID = nil
    }
}


// MARK: - Private Methods
//
private extension SessionManager {

    /// Returns the Default Credentials, if any.
    ///
    func loadCredentials() -> Credentials? {
        guard let username = defaults[.defaultUsername] as? String, let authToken = keychain[username] else {
            return nil
        }

        return Credentials(username: username, authToken: authToken)
    }

    /// Persists the Credentials's authToken in the keychain, and username in User Settings.
    ///
    func saveCredentials(_ credentials: Credentials) {
        defaults[.defaultUsername] = credentials.username
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
