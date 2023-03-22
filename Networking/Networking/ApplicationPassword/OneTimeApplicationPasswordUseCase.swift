import Foundation
import KeychainAccess

/// Use case to save application password generated from web view;
/// The password will not be re-generated because no cookie authentication is available.
///
final public class OneTimeApplicationPasswordUseCase: ApplicationPasswordUseCase {
    public let applicationPassword: ApplicationPassword?

    private let siteAddress: String
    private let session: URLSession

    public init(applicationPassword: ApplicationPassword? = nil,
                siteAddress: String,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        let storage = ApplicationPasswordStorage(keychain: keychain)
        if let applicationPassword {
            storage.saveApplicationPassword(applicationPassword)
        }
        self.applicationPassword = storage.applicationPassword
        self.siteAddress = siteAddress
        self.session = URLSession(configuration: .default)
    }

    public func generateNewPassword() async throws -> ApplicationPassword {
        /// We don't support generating new password for this use case.
        throw ApplicationPasswordUseCaseError.notSupported
    }

    public func deletePassword() async throws {
        guard let uuid = try await fetchApplicationPasswordUUID(),
              let url = URL(string: siteAddress + Path.applicationPasswords + uuid) else {
            return
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
        guard let username = applicationPassword?.wpOrgUsername,
              let password = applicationPassword?.password.secretValue else {
            return request
        }
        var authenticatedRequest = request
        authenticatedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticatedRequest.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let loginString = "\(username):\(password)"

        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            authenticatedRequest.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }

        // Cookies from `CookieNonceAuthenticator` should be skipped
        authenticatedRequest.httpShouldHandleCookies = false

        return authenticatedRequest
    }
}

private extension OneTimeApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "/wp-json/wp/v2/users/me/application-passwords/"
        static let introspect = "/wp-json/wp/v2/users/me/application-passwords/introspect"
    }
}
