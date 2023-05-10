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
    static func makeForTesting(authenticated: Bool = false,
                               isWPCom: Bool = true,
                               defaultRoles: [User.Role] = [.administrator],
                               displayName: String? = nil) -> SessionManager {
        let manager = SessionManager(defaults: SessionSettings.defaults, keychainServiceName: SessionSettings.keychainServiceName)
        // Force setting to `nil` if `authenticated` is `false` so that any auto-loaded credentials
        // will be removed.
        let credentials: Credentials = {
            isWPCom ? SessionSettings.wpcomCredentials : SessionSettings.wporgCredentials
        }()
        manager.defaultCredentials = authenticated ? credentials : nil
        manager.setStoreId(nil)
        manager.defaultRoles = defaultRoles
        if let displayName {
            manager.defaultAccount = Account(userID: 123, displayName: displayName, email: "", username: credentials.username, gravatarUrl: nil)
        }
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
    static let wpcomCredentials = Credentials.wpcom(username: "username", authToken: "authToken", siteAddress: "siteAddress")
    static let wporgCredentials = Credentials.wporg(username: "username", password: "password", siteAddress: "siteAddress")
    static let applicationPasswordCredentials = Credentials.applicationPassword(username: "username", password: "password", siteAddress: "siteAddress")
    static let defaults = UserDefaults(suiteName: "storesManagerTests")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
