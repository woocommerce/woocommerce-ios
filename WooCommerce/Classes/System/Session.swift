import Foundation
import Networking



/// Represents the current Session's State: Credentials + Active SiteID.
///
struct Session {

    /// KeychainAccess Wrapper.
    ///
    private let credentialsStorage: CredentialsStorage

    /// Reference to the UserDefaults Instance that should be used.
    ///
    private let defaultsStorage: UserDefaults

    /// Active Credentials.
    ///
    var credentials: Credentials? {
        get {
            return credentialsStorage.loadCredentials()
        }
        set {
            guard let credentials = newValue else {
                credentialsStorage.removeCredentials()
                return
            }

            credentialsStorage.saveCredentials(credentials)
        }
    }

    /// Active Store's Site ID.
    ///
    var storeID: Int? {
        get {
            return defaultsStorage[.defaultStoreID]
        }
        set {
            defaultsStorage[.defaultStoreID] = storeID
        }
    }


    /// Designated Initializer.
    ///
    init(keychainServiceName: String, defaultsStorage: UserDefaults) {
        self.defaultsStorage = defaultsStorage
        self.credentialsStorage = CredentialsStorage(keychainServiceName: keychainServiceName, defaults: defaultsStorage)
    }

    /// Nukes all of the known Session's properties.
    ///
    mutating func reset() {
        credentials = nil
        storeID = nil
    }
}
