import Foundation
import WordPressShared
import KeychainAccess

enum ApplicationPasswordUseCaseError: Error {
    case duplicateName
    case applicationPasswordsDisabled
}

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
    /// Creates application password using WordPress.com authentication token
    ///
    /// - Returns: Application password as `String`
    ///
    func createApplicationPasswordUsingWPCOMAuthToken() async throws -> String {
        let passwordName = await applicationPasswordName

        let parameters = [ParameterKey.name: passwordName]
        let request = JetpackRequest(wooApiVersion: .none, method: .post, siteID: siteID, path: Path.applicationPasswords, parameters: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        let mapper = ApplicationPasswordMapper()
                        let password = try mapper.map(response: data)
                        continuation.resume(returning: password)
                    } catch let DotcomError.unknown(code, _) where code == ErrorCode.applicationPasswordsDisabledErrorCode {
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
                    } catch let DotcomError.unknown(code, _) where code == ErrorCode.duplicateNameErrorCode {
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.duplicateName)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Fetches wpadmin username using WordPress.com authentication token
    ///
    /// - Returns: wpadmin username
    ///
    func fetchWPAdminUsername() async throws -> String {
        let parameters = [
            "context": "edit",
            "fields": "id,username,id_wpcom,email,first_name,last_name,nickname,roles"
        ]
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: Path.users, parameters: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        let mapper = UserMapper(siteID: self.siteID)
                        let username =  try mapper.map(response: data).username
                        continuation.resume(returning: username)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Saves application password into keychain
    ///
    /// - Parameter password: `ApplicationPasword` to be saved
    ///
    func saveApplicationPassword(_ password: ApplicationPassword) {
        keychain.applicationPassword = password.wpOrgUsername
        keychain.applicationPasswordUsername = password.password.secretValue
    }
}

// MARK: - Constants
//
private extension DefaultApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
        static let users = "wp/v2/users/me"
    }

    enum ParameterKey {
        static let name = "name"
    }

    enum ErrorCode {
        static let applicationPasswordsDisabledErrorCode = "application_passwords_disabled"
        static let duplicateNameErrorCode = "application_password_duplicate_name"
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
