import Foundation
import Yosemite
import KeychainAccess


/// CredentialsManager: a simple way to store and retrieve `Credentials` entities.
///
class CredentialsManager {

    /// Shared Instance!
    ///
    static let shared = CredentialsManager(serviceName: Constants.defaultServiceName)

    /// KeychainAccess shared instance
    ///
    private let keychain: Keychain


    /// Returns / Stores the Default Username within the App's UserDefaults
    ///
    private var defaultUsername: String? {
        get {
            return UserDefaults.standard.string(forKey: Constants.defaultUsernameKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.defaultUsernameKey)
        }
    }


    /// Designated Initializer: Exposed only for unit testing purposes. For Main App Usage, please, consider using the
    /// shared instance instead!
    ///
    init(serviceName: String) {
        keychain = Keychain(service: serviceName).accessibility(.afterFirstUnlock)
    }
}


// MARK: - Public Methods
//
extension CredentialsManager {

    /// Indicates if we'd need Default Credentials to be set!
    ///
    var needsDefaultCredentials: Bool {
        return loadDefaultCredentials() == nil
    }

    /// Returns the Default Credentials, if any.
    ///
    func loadDefaultCredentials() -> Credentials? {
        guard let username = defaultUsername, let authToken = keychain[username] else {
            return nil
        }

        return Credentials(username: username, authToken: authToken)
    }

    /// Persists the Credentials's authToken in the keychain, and username in User Defaults.
    ///
    func saveDefaultCredentials(_ credentials: Credentials) {
        guard defaultUsername != credentials.username || keychain[credentials.username] != credentials.username else {
            return
        }

        keychain[credentials.username] = credentials.authToken
        defaultUsername = credentials.username
    }

    /// Nukes both, the AuthToken and Default Username.
    ///
    func removeDefaultCredentials() {
        guard let username = defaultUsername else {
            return
        }

        keychain[username] = nil
        defaultUsername = nil
    }
}


// MARK: - Nested Types
//
private extension CredentialsManager {

    struct Constants {
        static let defaultServiceName = "com.automattic.woocommerce"
        static let defaultUsernameKey = "defaultUsername"
    }
}
