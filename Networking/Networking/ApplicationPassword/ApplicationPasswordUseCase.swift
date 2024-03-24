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

final public class DefaultApplicationPasswordUseCase: ApplicationPasswordUseCase {
    /// Site Address
    ///
    private let siteAddress: String

    // Add documentation
    private let siteID: Int64

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
            let identifierForVendor = await UIDevice.current.identifierForVendor?.uuidString ?? ""
            return "\(bundleIdentifier).ios-app-client.\(model).\(identifierForVendor)"
        }
    }

    public init(username: String,
                password: String,
                siteAddress: String,
                siteID: Int64? = nil,
                network: Network? = nil,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) throws {
        self.siteID = siteID ?? .zero
        self.siteAddress = siteAddress
        self.username = username
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
                    try await deletePassword() // TEST THIS PATH
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

        let request = JetpackRequest(wooApiVersion: .none, method: .post, siteID: siteID, path: Path.applicationPasswords, parameters: parameters, availableAsRESTRequest: true)
        //let request = RESTRequest(siteURL: siteAddress, method: .post, path: Path.applicationPasswords, parameters: parameters)
        return try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let data):
                    do {
                        let mapper = ApplicationPasswordMapper(wpOrgUsername: self.username, siteURL: siteAddress)
                        let password = try mapper.map(response: data)
                        continuation.resume(returning: password)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):

                    // Extract error code from `AFErrors` or `NetworkErrors`
                    // This is needed because this use case can accept different type of Network objects.
                    let errorCode: Int? = {
                        switch error {
                        case NetworkError.unacceptableStatusCode(let statusCode, _):
                            return statusCode
                        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(let code)):
                            return code
                        default:
                            return nil
                        }
                    }()

                    switch errorCode {
                    case ErrorCode.notFound:
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
                    case ErrorCode.applicationPasswordsDisabledErrorCode:
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
                    case ErrorCode.duplicateNameErrorCode:
                        continuation.resume(throwing: ApplicationPasswordUseCaseError.duplicateName)
                    case ErrorCode.unauthorized:
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
        // TEST THIS PATH
        // CHANGE THIS for a jetpack request
        //let request = RESTRequest(siteURL: siteAddress, method: .get, path: Path.applicationPasswords)
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: Path.applicationPasswords, availableAsRESTRequest: true)

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
        // TEST THIS PATH
        // Change this for a jetpackrequest
        //let request = RESTRequest(siteURL: siteAddress, method: .delete, path: Path.applicationPasswords + "/" + uuid)
        let request = JetpackRequest(wooApiVersion: .none, method: .delete, siteID: siteID, path: Path.applicationPasswords + "/" + uuid, availableAsRESTRequest: true)

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
