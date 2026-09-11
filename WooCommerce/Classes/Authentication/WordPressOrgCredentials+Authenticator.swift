import Foundation
import WordPressAuthenticator
import Yosemite

/// Authentication endpoints and URL strings derived from WP.org credentials.
///
extension WordPressOrgCredentials {
    /// Records verified endpoints on the credentials, keeping only the ones that differ from the site's defaults.
    ///
    /// Only normalized, verified configuration is carried. Transaction-local values such as a form action or a
    /// redirect target must never reach here.
    ///
    func replacingAuthenticationEndpoints(with endpoints: CookieNonceAuthenticationEndpoints) -> WordPressOrgCredentials {
        let defaults: CookieNonceAuthenticationEndpoints
        do {
            defaults = try CookieNonceAuthenticationEndpoints(siteURL: endpoints.siteURL)
        } catch {
            // The supplied endpoints already validated their canonical site URL, so this indicates an invariant violation.
            DDLogError("⛔️ Failed to derive default authentication endpoints from verified endpoints: \(error)")
            ServiceLocator.crashLogging.logError(error)
            var updatedOptions = options
            updatedOptions[Key.loginURL.rawValue] = [Key.value.rawValue: endpoints.loginEntryURL.absoluteString]
            updatedOptions[Key.adminURL.rawValue] = [Key.value.rawValue: endpoints.adminBaseURL.absoluteString]
            return WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: updatedOptions)
        }
        var updatedOptions = options
        updatedOptions.removeValue(forKey: Key.loginURL.rawValue)
        updatedOptions.removeValue(forKey: Key.adminURL.rawValue)
        if endpoints.loginEntryURL != defaults.loginEntryURL {
            updatedOptions[Key.loginURL.rawValue] = [Key.value.rawValue: endpoints.loginEntryURL.absoluteString]
        }
        if endpoints.adminBaseURL != defaults.adminBaseURL {
            updatedOptions[Key.adminURL.rawValue] = [Key.value.rawValue: endpoints.adminBaseURL.absoluteString]
        }
        return WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: updatedOptions)
    }

    var loginURL: String {
        if let value = optionValue(for: Key.loginURL.rawValue) as? String {
            return value
        }
        return defaultAuthenticationEndpoints?.loginEntryURL.absoluteString ?? siteURL
    }

    var adminURL: String {
        if let value = optionValue(for: Key.adminURL.rawValue) as? String {
            return value
        }
        guard let adminURL = defaultAuthenticationEndpoints?.adminBaseURL.absoluteString else {
            return siteURL
        }
        return adminURL.removingSuffix("/")
    }

    /// Validated, canonical endpoints supplied by site discovery, or safe defaults when options are absent.
    var authenticationEndpoints: CookieNonceAuthenticationEndpoints? {
        do {
            return makeAuthenticationEndpoints(loginEntryURL: try configuredURL(for: .loginURL),
                                               adminBaseURL: try configuredURL(for: .adminURL))
        } catch {
            return nil
        }
    }
}

// MARK: - Private helpers
//
private extension WordPressOrgCredentials {
    var defaultAuthenticationEndpoints: CookieNonceAuthenticationEndpoints? {
        makeAuthenticationEndpoints()
    }

    func makeAuthenticationEndpoints(loginEntryURL: URL? = nil, adminBaseURL: URL? = nil) -> CookieNonceAuthenticationEndpoints? {
        guard let canonicalSiteURL = URL(string: siteURL) else {
            return nil
        }
        do {
            return try CookieNonceAuthenticationEndpoints(siteURL: canonicalSiteURL,
                                                          loginEntryURL: loginEntryURL,
                                                          adminBaseURL: adminBaseURL)
        } catch {
            return nil
        }
    }

    func configuredURL(for key: Key) throws -> URL? {
        guard options[key.rawValue] != nil else {
            return nil
        }
        guard let value = optionValue(for: key.rawValue) as? String,
              value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              let url = URL(string: value) else {
            throw EndpointOptionError.invalidValue
        }
        return url
    }

    /// Returns value for an option given a key.
    ///
    func optionValue(for key: String) -> Any? {
        let option = options[key] as? [String: Any]
        return option?[Key.value.rawValue]
    }
}

private extension WordPressOrgCredentials {
    enum EndpointOptionError: Error {
        case invalidValue
    }

    /// Key for getting value from `options`.
    ///
    enum Key: String {
        case loginURL = "login_url"
        case adminURL = "admin_url"
        case value
    }
}
