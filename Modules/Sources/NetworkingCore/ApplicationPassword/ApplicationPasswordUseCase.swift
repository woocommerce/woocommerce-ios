import Foundation
import enum Alamofire.AFError
import struct Alamofire.HTTPMethod
import KeychainAccess

#if !os(watchOS)
import UIKit
#else
import WatchKit
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
    /// - Parameter locally: Determines whether to remove the password from the local storage
    /// or only sends an API request to delete it from the site.
    ///
    func deletePassword(locally: Bool) async throws
}

final public class DefaultApplicationPasswordUseCase: ApplicationPasswordUseCase {
    /// Authentication type
    ///
    private let authenticationType: AuthenticationType

    /// To generate and delete application password
    ///
    private let network: Network

    /// To store application password
    ///
    private let storage: ApplicationPasswordStorageType

    /// Used to name the password in wpadmin.
    ///
    private let applicationPasswordName: String

    /// Internal initializer (accessible from tests via @testable import).
    init(type: AuthenticationType,
         network: Network,
         passwordName: String? = nil,
         storage: ApplicationPasswordStorageType? = nil) {
        self.authenticationType = type
        self.storage = storage ?? ApplicationPasswordStorage(keychain: Keychain(service: WooConstants.keychainServiceName))
        self.network = network
        self.applicationPasswordName = passwordName ?? Self.createPasswordName()
    }

    /// Public initializer
    public convenience init(type: AuthenticationType,
                            network: Network,
                            passwordName: String? = nil,
                            storage: ApplicationPasswordStorageType? = nil) {
        self.init(type: type, network: network, passwordName: passwordName, storage: storage)
    }

    /// Public initializer for wporg authentication
    public convenience init(username: String,
                            password: String,
                            siteAddress: String,
                            network: Network? = nil,
                            storage: ApplicationPasswordStorageType? = nil) throws {
        let resolvedNetwork: Network
        if let network {
            resolvedNetwork = network
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
            resolvedNetwork = WordPressOrgNetwork(configuration: config)
        }
        self.init(type: .wporg(username: username, password: password, siteAddress: siteAddress),
                  network: resolvedNetwork,
                  passwordName: nil,
                  storage: storage)
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
                    try await deletePassword(locally: true)
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
    public func deletePassword(locally: Bool) async throws {
        // Get the uuid before removing the password from storage
        let uuidFromLocalPassword = locally ? storage.applicationPassword?.uuid : nil

        if locally {
            // Remove password from storage
            storage.removeApplicationPassword()
        }

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
    /// Helper method to create password name from device
    static func createPasswordName() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
        #if !os(watchOS)
        let model = UIDevice.current.model
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return "\(bundleIdentifier).ios-app-client.\(model).\(identifierForVendor)"
        #else
        let model = WKInterfaceDevice.current().model
        let identifierForVendor =
        WKInterfaceDevice.current().identifierForVendor?.uuidString ?? ""
        return "\(bundleIdentifier).watch-app-client.\(model).\(identifierForVendor)"
        #endif
    }

    /// Helper method to construct network requests either directly with the remote site
    /// or through Jetpack proxy.
    func constructRequest(method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> Request {
        switch authenticationType {
        case .wpcom(let siteID):
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
        let wpOrgUsername = try await {
            switch authenticationType {
            case .wporg(let username, _, _):
                return username
            case .wpcom(let siteID):
                return try await fetchWPOrgUsername(siteID: siteID)
            }
        }()

        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let mapper = ApplicationPasswordMapper(wpOrgUsername: wpOrgUsername)
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
                        if let item = list.last(where: { $0.name == passwordName }) {
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

    func fetchWPOrgUsername(siteID: Int64) async throws -> String {
        let parameters = [
            ParameterKey.context: Constants.editValue
        ]
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.userDetails,
                                     parameters: parameters)
        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success(let data):
                    let mapper = UserMapper(siteID: siteID)
                    do {
                        let user = try mapper.map(response: data)
                        continuation.resume(returning: user.username)
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

extension DefaultApplicationPasswordUseCase {
    public enum AuthenticationType {
        case wporg(username: String, password: String, siteAddress: String)
        case wpcom(siteID: Int64)
    }
}

// MARK: - Constants
//
private extension DefaultApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
        static let userDetails = "wp/v2/users/me"
    }

    enum ParameterKey {
        static let name = "name"
        static let context = "context"
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
        static let editValue = "edit"
    }
}
