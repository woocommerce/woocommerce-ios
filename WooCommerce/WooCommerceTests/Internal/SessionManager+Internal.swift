import Foundation
import Yosemite
@testable import WooCommerce


// MARK: - SessionManager: Testing Methods
//
extension SessionManager {

    /// Returns a SessionManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: SessionManager {
        return SessionManager(defaults: SessionSettings.defaults, keychainServiceName: SessionSettings.keychainServiceName)
    }

    /// Create an instance of unit testing.
    ///
    static func makeForTesting(authenticated: Bool = false) -> SessionManager {
        let manager = SessionManager(defaults: SessionSettings.defaults, keychainServiceName: SessionSettings.keychainServiceName)
        // Force setting to `nil` if `authenticated` is `false` so that any auto-loaded credentials
        // will be removed.
        manager.defaultCredentials = authenticated ? SessionSettings.credentials : nil
        return manager
    }

    func setStoreId(_ id: Int64?) {
        UserDefaults(suiteName: "storesManagerTests")!.set(id, forKey: .defaultStoreID)
    }
}


// MARK: - Testing Constants
//
enum SessionSettings {
    static let credentials = Credentials(username: "username", authToken: "authToken", siteAddress: "siteAddress")
    static let defaults = UserDefaults(suiteName: "storesManagerTests")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
