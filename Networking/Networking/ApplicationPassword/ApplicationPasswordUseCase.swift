import Foundation
import WordPressShared
import WordPressKit
import enum Alamofire.AFError
import KeychainAccess

public enum ApplicationPasswordUseCaseError: Error {
    case duplicateName
    case applicationPasswordsDisabled
    case failedToConstructLoginOrAdminURLUsingSiteAddress

    var errorDescription: String {
        switch self {
        case .applicationPasswordsDisabled:
            return "application_password_disabled"
        case .duplicateName:
            return "duplicate_name"
        case .failedToConstructLoginOrAdminURLUsingSiteAddress:
            return "application_password_failed_to_construct_login_or_admin_URL"
        }
    }
}

public struct ApplicationPassword {
    /// WordPress org username that the application password belongs to
    ///
    let wpOrgUsername: String

    /// Application password
    ///
    let password: Secret<String>
}

public protocol ApplicationPasswordUseCase {
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

final public class DefaultApplicationPasswordUseCase: ApplicationPasswordUseCase {
    /// Site Address
    ///
    private let siteAddress: String

    /// WPOrg username
    ///
    private let username: String

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

    public init(username: String,
                password: String,
                siteAddress: String,
                network: Network? = nil,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) throws {
        self.siteAddress = siteAddress
        self.username = username
        self.storage = ApplicationPasswordStorage(keychain: keychain)

        if let network {
            self.network = network
        } else {
            guard let loginURL = URL(string: siteAddress + Constants.loginPath),
                  let adminURL = URL(string: siteAddress + Constants.adminPath) else {
                DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(siteAddress)")
                TracksProvider.shared.track(ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress.errorDescription)
                throw ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress
            }
            // Prepares the authenticator with username and password
            let authenticator = CookieNonceAuthenticator(username: username,
                                                         password: password,
                                                         loginURL: loginURL,
                                                         adminURL: adminURL,
                                                         version: Constants.defaultWPVersion,
                                                         nonce: nil)
            self.network = WordPressOrgNetwork(authenticator: authenticator)
        }
    }

    /// Returns the locally saved ApplicationPassword if available
    ///
    public var applicationPassword: ApplicationPassword? {
        storage.applicationPassword
    }

    /// Generates new ApplicationPassword
    ///
    /// When `duplicateName` error occurs this method will delete the password and try generating again
    ///
    /// - Returns: Generated `ApplicationPassword` instance
    ///
    public func generateNewPassword() async throws -> ApplicationPassword {
        async let password = try {
            do {
                return try await createApplicationPassword()
            } catch ApplicationPasswordUseCaseError.duplicateName {
                try await deletePassword()
                return try await createApplicationPassword()
            }
        }()

        let applicationPassword = try await ApplicationPassword(wpOrgUsername: username, password: Secret(password))
        storage.saveApplicationPassword(applicationPassword)
        return applicationPassword
    }

    /// Deletes the application password
    ///
    ///  Deletes locally and also sends an API request to delete it from the site
    ///
    public func deletePassword() async throws {
        try await deleteApplicationPassword()
    }
}

private extension DefaultApplicationPasswordUseCase {
    /// Creates application password using WordPress.com authentication token
    ///
    /// - Returns: Application password as `String`
    ///
    func createApplicationPassword() async throws -> String {
        let passwordName = await applicationPasswordName

        let parameters = [ParameterKey.name: passwordName]
        let request = WordPressOrgRequest(baseURL: siteAddress, method: .post, path: Path.applicationPasswords, parameters: parameters)
        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let mapper = ApplicationPasswordMapper()
                        let password = try mapper.map(response: data)
                        continuation.resume(returning: password)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    guard let error = error as? AFError else {
                        continuation.resume(throwing: error)
                        return
                    }

                    let eventName = "application_password_generation_failed"
                    switch error {
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.notFound)):
                        let error = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
                        TracksProvider.shared.track(eventName, withProperties: ["error": error.errorDescription])
                        continuation.resume(throwing: error)
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.applicationPasswordsDisabledErrorCode)):
                        let error = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
                        TracksProvider.shared.track(eventName, withProperties:  ["error": error.errorDescription])
                        continuation.resume(throwing: error)
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.duplicateNameErrorCode)):
                        let error = ApplicationPasswordUseCaseError.duplicateName
                        TracksProvider.shared.track(eventName, withProperties:  ["error": error.errorDescription])
                        continuation.resume(throwing: error)
                    default:
                        TracksProvider.shared.track(eventName)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Deletes application password using WordPress.com authentication token
    ///
    func deleteApplicationPassword() async throws {
        // Remove password from storage
        storage.removeApplicationPassword()

        let passwordName = await applicationPasswordName
        let parameters = [ParameterKey.name: passwordName]
        let request = WordPressOrgRequest(baseURL: siteAddress, method: .delete, path: Path.applicationPasswords, parameters: parameters)

        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success:
                    TracksProvider.shared.track("application_password_delete_successful")
                    continuation.resume()
                case .failure(let error):
                    TracksProvider.shared.track("application_password_delete_failed")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Constants
//
private extension DefaultApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
    }

    enum ParameterKey {
        static let name = "name"
    }

    enum ErrorCode {
        static let notFound = 404
        static let applicationPasswordsDisabledErrorCode = 501
        static let duplicateNameErrorCode = 409
    }

    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin/"
        static let defaultWPVersion = "5.6.0" // a default version that supports Ajax nonce retrieval
    }
}
