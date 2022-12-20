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

final class DefaultApplicationPasswordUseCase: ApplicationPasswordUseCase {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials

    /// SiteID needed when using WPCOM credentials
    ///
    private let siteID: Int64

    /// To generate and delete application password
    ///
    private let network: Network

    /// To store application password
    ///
    private let storage: ApplicationPasswordStorage

    /// Used to name the password in wpadmin.
    ///
    private var applicationPasswordName: String {
        get async {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
            let model = await UIDevice.current.model
            return bundleIdentifier + ".ios-app-client." + model
        }
    }

    init(siteID: Int64,
         networkcredentials: Credentials,
         network: Network? = nil,
         keychain: Keychain = Keychain(service: KeychainServiceName.name)) {
        self.siteID = siteID
        self.credentials = networkcredentials
        self.storage = ApplicationPasswordStorage(keychain: keychain)

        if let network {
            self.network = network
        } else {
            self.network = ApplicationPasswordNetwork(credentials: networkcredentials)
        }
    }

    /// Returns the locally saved ApplicationPassword if available
    ///
    var applicationPassword: ApplicationPassword? {
        storage.applicationPassword
    }

    /// Generates new ApplicationPassword
    ///
    /// When `duplicateName` error occurs this method will delete the password and try generating again
    ///
    /// - Returns: Generated `ApplicationPassword` instance
    ///
    func generateNewPassword() async throws -> ApplicationPassword {
        async let password = try {
            do {
                return try await createApplicationPasswordUsingWPCOMAuthToken()
            } catch ApplicationPasswordUseCaseError.duplicateName {
                try await deletePassword()
                return try await createApplicationPasswordUsingWPCOMAuthToken()
            }
        }()
        async let username = try fetchWPAdminUsername()

        let applicationPassword = try await ApplicationPassword(wpOrgUsername: username, password: Secret(password))
        storage.saveApplicationPassword(applicationPassword)
        return applicationPassword
    }

    /// Deletes the application password
    ///
    ///  Deletes locally and also sends an API request to delete it from the site
    ///
    func deletePassword() async throws {
        try await deleteApplicationPasswordUsingWPCOMAuthToken()
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

    /// Deletes application password using WordPress.com authentication token
    ///
    func deleteApplicationPasswordUsingWPCOMAuthToken() async throws {
        // Remove password from storage
        storage.removeApplicationPassword()

        let passwordName = await applicationPasswordName

        let parameters = [ParameterKey.name: passwordName]
        let request = JetpackRequest(wooApiVersion: .none, method: .delete, siteID: siteID, path: Path.applicationPasswords, parameters: parameters)

        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Constants
//
private extension DefaultApplicationPasswordUseCase {
    enum KeychainServiceName {
        /// Matching `WooConstants.keychainServiceName`
        ///
        static let name = "com.automattic.woocommerce"
    }

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
