import Foundation
import WordPressAuthenticator
import struct Networking.CookieNonceAuthenticatorConfiguration

/// Extension to create cookie nonce authenticator from WP.org credentials.
///
extension WordPressOrgCredentials {
    var loginURL: String {
        let value = optionValue(for: Key.loginURL.rawValue) as? String
        return value ?? siteURL + Strings.loginPath
    }

    var adminURL: String {
        let value = optionValue(for: Key.adminURL.rawValue) as? String
        return value ?? siteURL + Strings.adminPath
    }

    /// Returns a cookie nonce authenticator configuration based on the current credentials
    ///
    func makeCookieNonceAuthenticatorConfig() -> CookieNonceAuthenticatorConfiguration? {
        guard let loginURL = URL(string: loginURL),
              let adminURL = URL(string: adminURL) else {
            return nil
        }
        return CookieNonceAuthenticatorConfiguration(username: username,
                                                     password: password,
                                                     loginURL: loginURL,
                                                     adminURL: adminURL)
    }
}

// MARK: - Private helpers
//
private extension WordPressOrgCredentials {
    /// Returns value for an option given a key.
    ///
    func optionValue(for key: String) -> Any? {
        let option = options[key] as? [String: Any]
        return option?[Key.value.rawValue]
    }
}

private extension WordPressOrgCredentials {
    enum Strings {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
    }

    /// Key for getting value from `options`.
    ///
    enum Key: String {
        case loginURL = "login_url"
        case adminURL = "admin_url"
        case value
    }
}
