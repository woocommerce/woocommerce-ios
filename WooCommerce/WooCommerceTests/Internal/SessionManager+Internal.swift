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
}


// MARK: - Testing Constants
//
enum SessionSettings {
    static let credentials = Credentials(username: "username", authToken: "authToken")
    static let defaults = UserDefaults(suiteName: "storesManagerTests")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
