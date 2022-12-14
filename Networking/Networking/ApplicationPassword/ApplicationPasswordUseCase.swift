import Foundation
import WordPressShared
import KeychainAccess

struct ApplicationPassword {
    /// WordPress org username that the application password belongs to
    ///
    let wpOrgUsername: String

    /// Application password
    ///
    let password: Secret<String>
}

protocol ApplicationPasswordUseCase {
    /// Returns the locally saved ApplicationPassword if available
    ///
    var applicationPassword: ApplicationPassword? { get }

    /// Generates new ApplicationPassword
    ///
    /// - Returns: Generated `ApplicationPassword` instance
    ///
    func generateNewPassword() async throws -> ApplicationPassword

    /// Deletes the application password
    ///
    ///  Deletes locally and also sends an API request to delete it from the site
    ///
    func deletePassword() async throws
}

final class DefaultApplicationPasswordUseCase {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials

    /// SiteID needed when using WPCOM credentials
    ///
    private let siteID: Int64

    /// To generate and delete application password
    ///
    private let network: Network

    /// Stores the application password
    ///
    private let keychain: Keychain

    /// Used to name the password in wpadmin.
    ///
    private var applicationPasswordName: String {
        get async {
            await UIDevice.current.model
        }
    }

    init(siteID: Int64,
         networkcredentials: Credentials,
         network: Network? = nil,
         keychain: Keychain = Keychain(service: "com.automattic.woocommerce.applicationpassword")) {
        self.siteID = siteID
        self.credentials = networkcredentials
        self.keychain = keychain

        if let network {
            self.network = network
        } else {
            self.network = ApplicationPasswordNetwork(credentials: networkcredentials)
        }
    }

    /// Returns the locally saved ApplicationPassword if available
    ///
    var applicationPassword: ApplicationPassword? {
        guard let password = keychain.applicationPassword,
              let username = keychain.applicationPasswordUsername else {
            return nil
        }
        return ApplicationPassword(wpOrgUsername: username, password: Secret(password))
    }
}

private extension DefaultApplicationPasswordUseCase {
    /// Saves application password into keychain
    ///
    /// - Parameter password: `ApplicationPasword` to be saved
    ///
    func saveApplicationPassword(_ password: ApplicationPassword) {
        keychain.applicationPassword = password.wpOrgUsername
        keychain.applicationPasswordUsername = password.password.secretValue
    }
}

// MARK: - For storing the application password in keychain
//
private extension Keychain {
    private static let keychainApplicationPassword = "ApplicationPassword"
    private static let keychainApplicationPasswordUsername = "ApplicationPasswordUsername"

    var applicationPassword: String? {
        get { self[Keychain.keychainApplicationPassword] }
        set { self[Keychain.keychainApplicationPassword] = newValue }
    }

    var applicationPasswordUsername: String? {
        get { self[Keychain.keychainApplicationPasswordUsername] }
        set { self[Keychain.keychainApplicationPasswordUsername] = newValue }
    }
}
