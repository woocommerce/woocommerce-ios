import Foundation
import Yosemite
@testable import WooCommerce


// MARK: - SessionManager: Testing Methods
//
extension SessionManager {

    /// Returns a SessionManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: SessionManager {
        let sessionManager = SessionManager(defaults: SessionSettings.defaults, keychainServiceName: SessionSettings.keychainServiceName)
        sessionManager.setStoreId(nil)
        return sessionManager
    }

    /// Create an instance of unit testing.
    ///
    static func makeForTesting(authenticated: Bool = false, isWPCom: Bool = true) -> SessionManager {
        let manager = SessionManager(defaults: SessionSettings.defaults, keychainServiceName: SessionSettings.keychainServiceName)
        // Force setting to `nil` if `authenticated` is `false` so that any auto-loaded credentials
        // will be removed.
        let credentials: Credentials = {
            isWPCom ? SessionSettings.wpcomCredentials : SessionSettings.wporgCredentials
        }()
        manager.defaultCredentials = authenticated ? credentials : nil
        manager.setStoreId(nil)
        return manager
    }
}

// MARK: - SessionManagerProtocol: Testing Methods
//
extension SessionManagerProtocol {
    func setStoreId(_ id: Int64?) {
        UserDefaults(suiteName: "storesManagerTests")!.set(id, forKey: .defaultStoreID)
    }
}


// MARK: - Testing Constants
//
enum SessionSettings {
    static let wpcomCredentials = Credentials(username: "wpcomUsername", authToken: "authToken", siteAddress: "siteAddress")
    static let wporgCredentials = Credentials(username: "wporgUsername", password: "password", siteAddress: "siteAddress")
    static let defaults = UserDefaults(suiteName: "storesManagerTests")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
