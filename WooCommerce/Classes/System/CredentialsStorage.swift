import Foundation
import Yosemite
import KeychainAccess


/// CredentialsStorage: a simple way to store and retrieve `Credentials` entities.
///
class CredentialsStorage {

    /// KeychainAccess Wrapper.
    ///
    private let keychain: Keychain

    /// Reference to the UserDefaults Instance that should be used.
    ///
    private let defaults: UserDefaults

    

    /// Designated Initializer.
    ///
    init(keychainServiceName: String, defaults: UserDefaults) {
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        self.defaults = defaults
    }

    /// Returns the Default Credentials, if any.
    ///
    func loadCredentials() -> Credentials? {
        guard let username: String = defaults[.defaultUsername], let authToken = keychain[username] else {
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
        guard let username: String = defaults[.defaultUsername] else {
            return
        }

        do {
            try keychain.remove(username)
            defaults.removeObject(forKey: .defaultUsername)
        } catch {
            NSLog("# CredentialsStorage Error: \(error)")
        }
    }
}
