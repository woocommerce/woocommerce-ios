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
              let url = restAPIURL(for: "/wp/v2/users/me/application-passwords/" + uuid, discoveredRoot: discoveredRoot) else {
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
        guard let url = restAPIURL(for: "/wp/v2/users/me/application-passwords/introspect", discoveredRoot: discoveredRoot) else {
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

    /// Builds the full URL for a WordPress REST API path using the discovered root, or falls back to `?rest_route=`.
    ///
    /// Handles both permalink styles:
    /// - Pretty permalinks: `https://example.com/wp-json/` + `/wp/v2/users/me/...` → `https://example.com/wp-json/wp/v2/users/me/...`
    /// - Default permalinks: `https://example.com/?rest_route=/` → `https://example.com/?rest_route=/wp/v2/users/me/...`
    /// - No discovery: falls back to `siteAddress + /?rest_route=` + path
    ///
    func restAPIURL(for wpPath: String, discoveredRoot: String?) -> URL? {
        let path = wpPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if let root = discoveredRoot, var components = URLComponents(string: root) {
            if components.queryItems?.contains(where: { $0.name == "rest_route" }) == true {
                // ?rest_route=/ style
                components.percentEncodedQueryItems = [URLQueryItem(name: "rest_route", value: "/" + path)]
                return components.url
            } else {
                // wp-json/ style
                let base = root.hasSuffix("/") ? root : root + "/"
                return URL(string: base + path)
            }
        }
        // Fallback to ?rest_route= style
        return URL(string: siteAddress + "/?rest_route=/" + path)
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
