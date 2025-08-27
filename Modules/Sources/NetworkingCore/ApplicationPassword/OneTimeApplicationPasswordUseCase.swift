import Foundation
import KeychainAccess

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Use case to save application password generated from web view;
/// The password will not be re-generated because no cookie authentication is available.
///
final public class OneTimeApplicationPasswordUseCase: ApplicationPasswordUseCase {
    public let applicationPassword: ApplicationPassword?

    private let siteAddress: String
    private let session: URLSessionProtocol
    private let storage: ApplicationPasswordStorageType

    public init(applicationPassword: ApplicationPassword? = nil,
                siteAddress: String,
                injectedStorage: ApplicationPasswordStorageType? = nil,
                session: URLSessionProtocol = URLSession(configuration: .default)) {
        self.storage = injectedStorage ?? ApplicationPasswordStorage(keychain: Keychain(service: WooConstants.keychainServiceName))
        if let applicationPassword {
            storage.saveApplicationPassword(applicationPassword)
        }
        self.applicationPassword = storage.applicationPassword
        self.siteAddress = siteAddress
        self.session = session
    }

    public func generateNewPassword() async throws -> ApplicationPassword {
        /// We don't support generating new password for this use case.
        throw ApplicationPasswordUseCaseError.notSupported
    }

    public func deletePassword(locally: Bool) async throws {
        let uuidToBeDeleted: String? = try await {
            if locally, let uuid = storage.applicationPassword?.uuid {
                return uuid
            } else {
                return try await self.fetchApplicationPasswordUUID()
            }
        }()

        guard let uuidToBeDeleted,
              let url = URL(string: siteAddress + Path.applicationPasswords + uuidToBeDeleted) else {
            return
        }

        if locally {
            // Remove password from storage
            storage.removeApplicationPassword()
        }

        let request = try URLRequest(url: url, method: .delete)
        let authenticatedRequest = authenticateRequest(request: request)
        _ = try await session.data(for: authenticatedRequest)
    }
}

private extension OneTimeApplicationPasswordUseCase {
    func fetchApplicationPasswordUUID() async throws -> String? {
        guard let url = URL(string: siteAddress + Path.introspect) else {
            return nil
        }

        let request = try URLRequest(url: url, method: .get)
        let authenticatedRequest = authenticateRequest(request: request)
        let (data, _) = try await session.data(for: authenticatedRequest)

        let decoder = JSONDecoder()
        if let username = applicationPassword?.wpOrgUsername {
            decoder.userInfo = [
                .wpOrgUsername: username
            ]
        }

        let password = try decoder.decode(ApplicationPassword.self, from: data)
        return password.uuid
    }

    func authenticateRequest(request: URLRequest) -> URLRequest {
        guard let applicationPassword else {
            return request
        }
        var authenticatedRequest = request
        authenticatedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticatedRequest.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        if let base64LoginString = ApplicationPasswordEncoder(passwordEnvelope: applicationPassword).encodedPassword() {
            authenticatedRequest.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }

        // Cookies from `CookieNonceAuthenticator` should be skipped
        authenticatedRequest.httpShouldHandleCookies = false

        return authenticatedRequest
    }
}

private extension OneTimeApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "/?rest_route=/wp/v2/users/me/application-passwords/"
        static let introspect = "/?rest_route=/wp/v2/users/me/application-passwords/introspect"
    }
}
