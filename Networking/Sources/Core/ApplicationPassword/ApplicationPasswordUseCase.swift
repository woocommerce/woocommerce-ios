import Foundation
import enum Alamofire.AFError
import KeychainAccess

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

/// A wrapper for the `UIDevice` `model` and `identifierForVendor` properties.
///
/// This is necessary because `UIDevice` is part of UIKit which we cannot use when targeting watchOS.
/// So, to keep this package compatible with watchOS, we need to abstract UIKit away and delegate it to the consumers to provide us
/// with the device information.
///
/// This approach is feasible because only the `applicationPasswordName` method in
/// `DefaultApplicationPasswordUseCase` needs access to the information and watchOS does not need to create application
/// passwords. We can therefore pass a `nil` value to it to satisfy the compilation without issues for the user experience.
public struct DeviceModelIdentifierInfo {
    let model: String
    let identifierForVendor: String

    public init(model: String, identifierForVendor: String) {
        self.model = model
        self.identifierForVendor = identifierForVendor
    }
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

    private let deviceModelIdentifierInfo: DeviceModelIdentifierInfo?

    /// Used to name the password in wpadmin.
    ///
    private var applicationPasswordName: String {
        get {
            guard let deviceModelIdentifierInfo else {
                return "" // This is not needed on watchOS as the watch does not create application passwords.
            }

            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
            return "\(bundleIdentifier).ios-app-client.\(deviceModelIdentifierInfo.model).\(deviceModelIdentifierInfo.identifierForVendor)"
        }
    }

    public init(username: String,
                password: String,
                siteAddress: String,
                deviceModelIdentifierInfo: DeviceModelIdentifierInfo? = nil,
                network: Network? = nil,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) throws {
        self.siteAddress = siteAddress
        self.username = username
        self.storage = ApplicationPasswordStorage(keychain: keychain)
        self.deviceModelIdentifierInfo = deviceModelIdentifierInfo

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
                return try await self.fetchUUIDForApplicationPassword(await applicationPasswordName)
            }
        }()
        try await deleteApplicationPassword(uuidToBeDeleted)
    }
}

private extension DefaultApplicationPasswordUseCase {
    /// Creates application password using WordPress.com authentication token
    ///
    /// - Returns: Generated `ApplicationPassword`
    ///
    func createApplicationPassword() async throws -> ApplicationPassword {
        let passwordName = await applicationPasswordName

        let parameters = [ParameterKey.name: passwordName]
        let request = RESTRequest(siteURL: siteAddress, method: .post, path: Path.applicationPasswords, parameters: parameters)
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
        let request = RESTRequest(siteURL: siteAddress, method: .get, path: Path.applicationPasswords)

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
        let request = RESTRequest(siteURL: siteAddress, method: .delete, path: Path.applicationPasswords + "/" + uuid)

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
