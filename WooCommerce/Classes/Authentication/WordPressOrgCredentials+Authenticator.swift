import Foundation
import WordPressKit
import WordPressAuthenticator

/// Extension to create cookie nonce authenticator from WP.org credentials.
///
extension WordPressOrgCredentials {
    /// Returns a cookie nonce authenticator based on the current credentials
    ///
    func makeCookieNonceAuthenticator() -> CookieNonceAuthenticator? {
        guard let loginURL = URL(string: loginURL),
              let adminURL = URL(string: adminURL) else {
            return nil
        }
        return CookieNonceAuthenticator(username: username,
                                        password: password,
                                        loginURL: loginURL,
                                        adminURL: adminURL,
                                        version: version)
    }
}

// MARK: - Private helpers
//
private extension WordPressOrgCredentials {
    var loginURL: String {
        let value = optionValue(for: Strings.loginURLKey) as? String
        return value ?? siteURL + Strings.loginPath
    }

    var adminURL: String {
        let value = optionValue(for: Strings.adminURLKey) as? String
        return value ?? siteURL + Strings.adminPath
    }

    var version: String {
        let value = optionValue(for: Strings.versionKey)
        if let stringValue = value as? String {
            return stringValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        return ""
    }

    /// Returns value for an option given a key.
    ///
    func optionValue(for key: String) -> Any? {
        let option = options[key] as? [String: Any]
        return option?[Strings.valueKey]
    }
}

private extension WordPressOrgCredentials {
    enum Strings {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
        static let loginURLKey = "login_url"
        static let adminURLKey = "admin_url"
        static let versionKey = "software_version"
        static let valueKey = "value"
    }
}
