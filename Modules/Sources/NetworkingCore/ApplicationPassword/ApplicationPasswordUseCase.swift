import Foundation
import enum Alamofire.AFError
import struct Alamofire.HTTPMethod
import KeychainAccess

#if canImport(UIKit)
import UIKit
#endif

public enum ApplicationPasswordUseCaseError: Error {
    case duplicateName
    case applicationPasswordsDisabled
    case failedToConstructLoginOrAdminURLUsingSiteAddress
    case unauthorizedRequest
    case unableToFindPasswordUUID
    case notSupported
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
    /// Authentication type
    ///
    private let authenticationType: AuthenticationType

    /// WPOrg username
    ///
    private var username: String {
        switch authenticationType {
        case .wporg(let username, _, _):
            return username
        case .wpcom(let wporgUsername, _):
            return wporgUsername
        }
    }

    /// To generate and delete application password
    ///
    private let network: Network

    /// To store application password
    ///
    private let storage: ApplicationPasswordStorage

    /// Used to name the password in wpadmin.
    ///
    private var applicationPasswordName: String {
#if !os(watchOS)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
        let model = UIDevice.current.model
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return "\(bundleIdentifier).ios-app-client.\(model).\(identifierForVendor)"
#else
        fatalError("Unexpected error: Application password should not be generated through watch app")
#endif
    }

    /// Internal initializer
    /// periphery: ignore - used in future PR for WOOMOB-1123
    init(type: AuthenticationType,
         network: Network,
         keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        self.authenticationType = type
        self.storage = ApplicationPasswordStorage(keychain: keychain)
        self.network = network
    }

    /// Public initializer for wporg authentication
    public init(username: String,
                password: String,
                siteAddress: String,
                network: Network? = nil,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) throws {
        self.authenticationType = .wporg(username: username, password: password, siteAddress: siteAddress)
        self.storage = ApplicationPasswordStorage(keychain: keychain)

        if let network {
            self.network = network
        } else {
            guard let loginURL = URL(string: siteAddress + Constants.loginPath),
                  let adminURL = URL(string: siteAddress + Constants.adminPath) else {
                DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(siteAddress)")
                throw ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress
            }
            // Prepares the authenticator with username and password
            let config = CookieNonceAuthenticatorConfiguration(username: username,
                                                               password: password,
                                                               loginURL: loginURL,
                                                               adminURL: adminURL)
            self.network = WordPressOrgNetwork(configuration: config)
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
        let applicationPassword = try await {
            do {
                return try await createApplicationPassword()
            } catch ApplicationPasswordUseCaseError.duplicateName {
                do {
                    try await deletePassword()
                } catch ApplicationPasswordUseCaseError.unableToFindPasswordUUID {
                    // No password found with the `applicationPasswordName`
                    // We can proceed to the creation step
                }
                return try await createApplicationPassword()
            }
        }()

        storage.saveApplicationPassword(applicationPassword)
        return applicationPassword
    }

    /// Deletes the application password
    ///
    ///  Deletes locally and also sends an API request to delete it from the site
    ///
    public func deletePassword() async throws {
        // Get the uuid before removing the password from storage
        let uuidFromLocalPassword = applicationPassword?.uuid

        // Remove password from storage
        storage.removeApplicationPassword()

        let uuidToBeDeleted = try await {
            if let uuidFromLocalPassword {
                return uuidFromLocalPassword
            } else {
                return try await self.fetchUUIDForApplicationPassword(applicationPasswordName)
            }
        }()
        try await deleteApplicationPassword(uuidToBeDeleted)
    }
}

private extension DefaultApplicationPasswordUseCase {
    /// Helper method to construct network requests either directly with the remote site
    /// or through Jetpack proxy.
    func constructRequest(method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> Request {
        switch authenticationType {
        case .wpcom(_, let siteID):
            JetpackRequest(wooApiVersion: .none,
                           method: method,
                           siteID: siteID,
                           path: path,
                           parameters: parameters)
        case .wporg(_, _, let siteAddress):
            RESTRequest(siteURL: siteAddress,
                        method: method,
                        path: path,
                        parameters: parameters)
        }
    }

    /// Creates application password using WordPress.com authentication token
    ///
    /// - Returns: Generated `ApplicationPassword`
    ///
    func createApplicationPassword() async throws -> ApplicationPassword {
        let passwordName = applicationPasswordName

        let parameters = [ParameterKey.name: passwordName]
        let request = constructRequest(method: .post,
                                       path: Path.applicationPasswords,
                                       parameters: parameters)
        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let data):
                    do {
                        let mapper = ApplicationPasswordMapper(wpOrgUsername: self.username)
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

                    switch error {
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.notFound)):
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.applicationPasswordsDisabledErrorCode)):
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.duplicateNameErrorCode)):
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.duplicateName)
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: ErrorCode.unauthorized)):
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.unauthorizedRequest)
                    default:
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Get the UUID of the application password
    ///
    func fetchUUIDForApplicationPassword(_ passwordName: String) async throws -> String {
        let request = constructRequest(method: .get, path: Path.applicationPasswords)

        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let mapper = ApplicationPasswordNameAndUUIDMapper()
                        let list = try mapper.map(response: data)
                        if let item = list.first(where: { $0.name == passwordName }) {
                            continuation.resume(returning: item.uuid)
                        } else {
                            continuation.resume(throwing: ApplicationPasswordUseCaseError.unableToFindPasswordUUID)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Deletes application password using UUID
    ///
    func deleteApplicationPassword(_ uuid: String) async throws {
        let request = constructRequest(method: .delete, path: Path.applicationPasswords + "/" + uuid)

        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension DefaultApplicationPasswordUseCase {
    enum AuthenticationType {
        case wporg(username: String, password: String, siteAddress: String)
        case wpcom(wporgUsername: String, siteID: Int64)
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
        static let unauthorized = 401
    }

    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin/"
    }
}
