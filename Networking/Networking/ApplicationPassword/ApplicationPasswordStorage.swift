import Foundation
import KeychainAccess
import WordPressShared

struct ApplicationPasswordStorage {
    /// Stores the application password
    ///
    private let keychain: Keychain

    init(keychain: Keychain = Keychain(service: KeychainServiceName.name)) {
        self.keychain = keychain
    }

    /// Returns the saved application password if available
    ///
    var applicationPassword: ApplicationPassword? {
        guard let password = keychain.password,
              let username = keychain.username else {
            return nil
        }
        return ApplicationPassword(wpOrgUsername: username, password: Secret(password))
    }

    /// Saves application password into keychain
    ///
    /// - Parameter password: `ApplicationPasword` to be saved
    ///
    func saveApplicationPassword(_ password: ApplicationPassword) {
        keychain.password = password.wpOrgUsername
        keychain.username = password.password.secretValue
    }

    /// Removes the currently saved password from storage
    ///
    func removeApplicationPassword() {
        // Delete password from keychain
        keychain.password = nil
        keychain.username = nil
    }
}

// MARK: - Constants
//
private extension ApplicationPasswordStorage {
    enum KeychainServiceName {
        /// Matching `WooConstants.keychainServiceName`
        ///
        static let name = "com.automattic.woocommerce"
    }
}

// MARK: - For storing the application password in keychain
//
private extension Keychain {
    private static let keychainApplicationPassword = "ApplicationPassword"
    private static let keychainApplicationPasswordUsername = "ApplicationPasswordUsername"

    var password: String? {
        get { self[Keychain.keychainApplicationPassword] }
        set { self[Keychain.keychainApplicationPassword] = newValue }
    }

    var username: String? {
        get { self[Keychain.keychainApplicationPasswordUsername] }
        set { self[Keychain.keychainApplicationPasswordUsername] = newValue }
    }
}
