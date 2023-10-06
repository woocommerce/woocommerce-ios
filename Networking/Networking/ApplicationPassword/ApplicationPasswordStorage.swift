import Foundation
import KeychainAccess
import WordPressShared

public struct ApplicationPasswordStorage {
    /// Stores the application password
    ///
    private let keychain: Keychain

    public init(keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        self.keychain = keychain
    }

    /// Returns the saved application password if available
    ///
    var applicationPassword: ApplicationPassword? {
        guard let password = keychain.password,
              let username = keychain.username,
              let uuid = keychain.uuid else {
            return nil
        }
        return ApplicationPassword(wpOrgUsername: username, password: Secret(password), uuid: uuid)
    }

    /// Saves application password into keychain
    ///
    /// - Parameter password: `ApplicationPasword` to be saved
    ///
    public func saveApplicationPassword(_ password: ApplicationPassword) {
        keychain.username = password.wpOrgUsername
        keychain.password = password.password.secretValue
        keychain.uuid = password.uuid
    }

    /// Removes the currently saved password from storage
    ///
    func removeApplicationPassword() {
        // Delete password from keychain
        keychain.username = nil
        keychain.password = nil
        keychain.uuid = nil
    }
}

// MARK: - For storing the application password in keychain
//
private extension Keychain {
    private static let keychainApplicationPassword = "ApplicationPassword"
    private static let keychainApplicationPasswordUsername = "ApplicationPasswordUsername"
    private static let keychainApplicationPasswordUUID = "ApplicationPasswordUUID"

    var password: String? {
        get { self[Keychain.keychainApplicationPassword] }
        set { self[Keychain.keychainApplicationPassword] = newValue }
    }

    var username: String? {
        get { self[Keychain.keychainApplicationPasswordUsername] }
        set { self[Keychain.keychainApplicationPasswordUsername] = newValue }
    }

    var uuid: String? {
        get { self[Keychain.keychainApplicationPasswordUUID] }
        set { self[Keychain.keychainApplicationPasswordUUID] = newValue }
    }
}
