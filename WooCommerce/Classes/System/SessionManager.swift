import Foundation
import Yosemite
import KeychainAccess



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

    /// Active Credentials.
    ///
    var credentials: Credentials? {
        get {
            return loadCredentials()
        }
        set {
            guard let credentials = newValue else {
                removeCredentials()
                return
            }

            saveCredentials(credentials)
        }
    }

    /// Active Store's Site ID.
    ///
    var storeID: Int? {
        get {
            return defaults[.defaultStoreID]
        }
        set {
            defaults[.defaultStoreID] = storeID
        }
    }


    /// Designated Initializer.
    ///
    init(defaults: UserDefaults, keychainServiceName: String) {
        self.defaults = defaults
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
    }

    /// Nukes all of the known Session's properties.
    ///
    mutating func reset() {
        credentials = nil
        storeID = nil
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
