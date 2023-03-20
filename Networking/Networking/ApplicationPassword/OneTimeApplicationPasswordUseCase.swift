import Foundation
import KeychainAccess

/// Use case to save application password generated from web view;
/// The password will not be re-generated because no cookie authentication is available.
///
final public class OneTimeApplicationPasswordUseCase: ApplicationPasswordUseCase {
    public let applicationPassword: ApplicationPassword?

    private let siteAddress: String
    private let session: URLSession

    public init(applicationPassword: ApplicationPassword?,
                siteAddress: String,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        let storage = ApplicationPasswordStorage(keychain: keychain)
        if let applicationPassword {
            storage.saveApplicationPassword(applicationPassword)
        }
        self.applicationPassword = applicationPassword ?? storage.applicationPassword
        self.siteAddress = siteAddress
        self.session = URLSession(configuration: .default)
    }

    public func generateNewPassword() async throws -> ApplicationPassword {
        /// We don't support generating new password for this use case.
        throw ApplicationPasswordUseCaseError.notSupported
    }

    public func deletePassword() async throws {
        guard let uuid = applicationPassword?.uuid,
              let username = applicationPassword?.wpOrgUsername,
              let password = applicationPassword?.password.secretValue,
              let url = URL(string: siteAddress + Path.applicationPasswords + uuid) else {
            return
        }

        var request = try URLRequest(url: url, method: .delete)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let loginString = "\(username):\(password)"

        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }

        // Cookies from `CookieNonceAuthenticator` should be skipped
        request.httpShouldHandleCookies = false
        _ = try await session.data(for: request)
    }
}

private extension OneTimeApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "/wp-json/wp/v2/users/me/application-passwords/"
    }
}
