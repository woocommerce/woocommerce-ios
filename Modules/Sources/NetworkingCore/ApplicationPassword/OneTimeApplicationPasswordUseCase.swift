import Foundation
import KeychainAccess

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Use case to save application password generated from web view;
/// The password will not be re-generated because no cookie authentication is available.
///
public final class OneTimeApplicationPasswordUseCase: ApplicationPasswordUseCase {
    public let applicationPassword: ApplicationPassword?

    /// Whether the use case is capable of re-generating password
    public var canRegenerateApplicationPassword: Bool { false }

    private let siteAddress: String
    private let session: URLSessionProtocol
    private let storage: ApplicationPasswordStorageType
    private let discovery: (_ siteURL: String) async -> String?

    public init(applicationPassword: ApplicationPassword? = nil,
                siteAddress: String,
                injectedStorage: ApplicationPasswordStorageType? = nil,
                session: URLSessionProtocol = URLSession(configuration: .default),
                discovery: ((_ siteURL: String) async -> String?)? = nil) {
        self.storage = injectedStorage ?? ApplicationPasswordStorage(keychain: Keychain(service: WooConstants.keychainServiceName))
        if let applicationPassword {
            storage.saveApplicationPassword(applicationPassword)
        }
        self.applicationPassword = storage.applicationPassword
        self.siteAddress = siteAddress
        self.session = session
        if let discovery {
            self.discovery = discovery
        } else {
            let wordpressDiscovery = WordPressAPIDiscovery()
            self.discovery = { siteURL in await wordpressDiscovery.discoverRESTAPIRootURL(for: siteURL) }
        }
    }

    public func generateNewPassword() async throws -> ApplicationPassword {
        /// We don't support generating new password for this use case.
        throw ApplicationPasswordUseCaseError.notSupported
    }

    public func deletePassword(locally: Bool) async throws {
        /// Always fetch UUID because the one in storage was generated locally only.
        /// Check `ApplicationPasswordAuthorizationWebViewController` for more details.
        let discoveredRoot = await discovery(siteAddress)
        guard let uuid = try await fetchApplicationPasswordUUID(discoveredRoot: discoveredRoot),
              let url = restAPIURL(for: Path.applicationPasswords + uuid, discoveredRoot: discoveredRoot) else {
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
    func fetchApplicationPasswordUUID(discoveredRoot: String?) async throws -> String? {
        guard let url = restAPIURL(for: Path.introspect, discoveredRoot: discoveredRoot) else {
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

    func restAPIURL(for path: String, discoveredRoot: String?) -> URL? {
        let root = discoveredRoot ?? (siteAddress + Path.root)
        return URL(string: root + path)
    }

    enum Path {
        static let root = "/?rest_route=/"
        static let introspect = "wp/v2/users/me/application-passwords/introspect"
        static let applicationPasswords = "wp/v2/users/me/application-passwords/"
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
