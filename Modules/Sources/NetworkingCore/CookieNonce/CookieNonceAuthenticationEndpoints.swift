import Foundation

/// Normalized, same-site endpoints trusted by the cookie-nonce authentication flow.
///
/// `loginEntryURL` is durable configuration. A form submission URL is transaction-local and is
/// returned separately by `verifiedLoginFormSubmissionURL(in:documentURL:)`.
public struct CookieNonceAuthenticationEndpoints: Equatable, Sendable {
    public static let maximumRedirectCount = 3

    public let siteURL: URL
    public let loginEntryURL: URL
    public let adminBaseURL: URL

    public init(siteURL: URL, loginEntryURL: URL? = nil, adminBaseURL: URL? = nil) throws {
        let siteURL = try Self.normalized(siteURL, kind: .site)
        let loginEntryURL = loginEntryURL ?? siteURL.appendingPathComponent("wp-login.php")
        let adminBaseURL = adminBaseURL ?? siteURL.appendingPathComponent("wp-admin", isDirectory: true)
        self.siteURL = siteURL
        self.loginEntryURL = try Self.normalized(loginEntryURL, relativeTo: siteURL, kind: .login)
        self.adminBaseURL = try Self.normalized(adminBaseURL, relativeTo: siteURL, kind: .admin)
    }

    /// Resolves a redirect relative to the response URL and enforces the same-site policy.
    public func resolveRedirect(location: String, from previousURL: URL) throws -> URL {
        let previousURL = try Self.normalized(previousURL, relativeTo: siteURL, kind: .login)
        let location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard location.isEmpty == false, let candidate = URL(string: location, relativeTo: previousURL)?.absoluteURL else {
            throw ValidationError.invalidURL
        }
        return try validatedTransactionURL(candidate, after: previousURL)
    }

    /// Resolves a transaction-local form action without changing the configured login entry.
    func resolveFormAction(_ action: String?, documentURL: URL) throws -> URL {
        let documentURL = try Self.normalized(documentURL, relativeTo: siteURL, kind: .login)
        let action = action?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard action.isEmpty == false else {
            return documentURL
        }
        guard let candidate = URL(string: action, relativeTo: documentURL)?.absoluteURL else {
            throw ValidationError.invalidURL
        }
        return try validatedTransactionURL(candidate, after: documentURL)
    }

    /// Returns the submission URL only for one rendered, eligible WordPress credential form.
    public func verifiedLoginFormSubmissionURL(in html: String, documentURL: URL) throws -> URL? {
        guard let form = WordPressLoginHTMLVerifier(html: html).verifiedLoginForm() else {
            return nil
        }
        return try resolveFormAction(form.action, documentURL: documentURL)
    }

    public func isAuthenticatedDashboardHTML(_ html: String) -> Bool {
        WordPressLoginHTMLVerifier(html: html).isAuthenticatedDashboard
    }

    func loginErrorMessage(in html: String) -> String? {
        WordPressLoginHTMLVerifier(html: html).loginErrorMessage
    }

    /// The admin base after a validated login transaction, including default-port HTTP-to-HTTPS promotion.
    public func derivedAdminBaseURL(afterLoginAt finalLoginURL: URL? = nil) throws -> URL {
        let loginURL: URL
        if let finalLoginURL {
            loginURL = try validatedTransactionURL(finalLoginURL, after: loginEntryURL)
        } else {
            loginURL = loginEntryURL
        }
        return try promotedAdminBaseURL(for: loginURL)
    }

    public func nonceURL(afterLoginAt finalLoginURL: URL? = nil) throws -> URL {
        let endpoint = try derivedAdminBaseURL(afterLoginAt: finalLoginURL).appendingPathComponent("admin-ajax.php")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw ValidationError.invalidURL
        }
        components.percentEncodedQuery = "action=rest-nonce"
        guard let url = components.url else {
            throw ValidationError.invalidURL
        }
        return url
    }

    public func isExpectedAdminBaseURL(_ candidate: URL, afterLoginAt finalLoginURL: URL? = nil) -> Bool {
        guard candidate.fragment == nil,
              let normalized = try? Self.normalized(candidate, relativeTo: siteURL, kind: .admin),
              let expected = try? derivedAdminBaseURL(afterLoginAt: finalLoginURL) else {
            return false
        }
        return normalized == expected
    }

    /// Recognizes any structurally exact same-site WordPress REST nonce endpoint.
    func isNonceEndpoint(_ candidate: URL) -> Bool {
        guard candidate.fragment == nil,
              let components = try? Self.trustedComponents(candidate, relativeTo: siteURL) else {
            return false
        }
        return components.percentEncodedPath.hasSuffix("/admin-ajax.php") &&
            components.percentEncodedQuery == "action=rest-nonce"
    }

    public func isExpectedNonceURL(_ candidate: URL, afterLoginAt finalLoginURL: URL? = nil) -> Bool {
        guard isNonceEndpoint(candidate),
              let normalized = try? Self.normalized(candidate, relativeTo: siteURL, kind: .login),
              let expected = try? nonceURL(afterLoginAt: finalLoginURL) else {
            return false
        }
        return normalized == expected
    }

    /// Validates a credential response redirect without promoting its target to a request URL.
    ///
    /// Some login integrations redirect to a structurally valid custom nonce endpoint or the configured admin base
    /// instead of honoring the requested nonce URL. Callers must still fetch the internally derived nonce URL rather
    /// than follow or promote this transaction-local redirect.
    public func isExpectedCredentialRedirect(location: String, from previousURL: URL, afterLoginAt finalLoginURL: URL) -> Bool {
        guard let candidate = try? resolveRedirect(location: location, from: previousURL) else {
            return false
        }
        return isNonceEndpoint(candidate) ||
            isExpectedAdminBaseURL(candidate, afterLoginAt: finalLoginURL)
    }
}

public extension CookieNonceAuthenticationEndpoints {
    enum ValidationError: Error, Equatable, Sendable {
        case invalidURL
        case unsupportedScheme
        case missingHost
        case userInfoNotAllowed
        case queryNotAllowed
        case originMismatch
        case insecureDowngrade
    }
}

private extension CookieNonceAuthenticationEndpoints {
    enum EndpointKind {
        case site
        case login
        case admin
    }

    static func normalized(_ url: URL, relativeTo siteURL: URL? = nil, kind: EndpointKind) throws -> URL {
        var components = try trustedComponents(url, relativeTo: siteURL)
        if kind != .login, components.query != nil {
            throw ValidationError.queryNotAllowed
        }
        components.fragment = nil
        if components.port == components.defaultPort {
            components.port = nil
        }
        if kind == .site {
            components.percentEncodedPath = components.percentEncodedPath.trimmingTrailingSlashes
            if components.percentEncodedPath == "/" {
                components.percentEncodedPath = ""
            }
        } else if kind == .admin {
            var path = components.percentEncodedPath.trimmingTrailingSlashes
            if path.lowercased().hasSuffix("/index.php") {
                path.removeLast("/index.php".count)
            }
            components.percentEncodedPath = (path == "/" ? "" : path.trimmingTrailingSlashes) + "/"
        }
        guard let normalized = components.url else {
            throw ValidationError.invalidURL
        }
        return normalized
    }

    static func trustedComponents(_ url: URL, relativeTo siteURL: URL?) throws -> URLComponents {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ValidationError.invalidURL
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        guard components.scheme == "http" || components.scheme == "https" else {
            throw ValidationError.unsupportedScheme
        }
        guard components.host?.isEmpty == false else {
            throw ValidationError.missingHost
        }
        guard components.user == nil, components.password == nil else {
            throw ValidationError.userInfoNotAllowed
        }
        if let siteURL {
            try validateOrigin(components, siteURL: siteURL)
        }
        return components
    }

    static func validateOrigin(_ candidate: URLComponents, siteURL: URL) throws {
        guard let site = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            throw ValidationError.invalidURL
        }
        guard candidate.host?.lowercased() == site.host?.lowercased() else {
            throw ValidationError.originMismatch
        }
        if candidate.scheme == site.scheme, candidate.effectivePort == site.effectivePort {
            return
        }
        guard site.scheme == "http", site.effectivePort == 80,
              candidate.scheme == "https", candidate.effectivePort == 443 else {
            throw ValidationError.originMismatch
        }
    }

    func validatedTransactionURL(_ candidate: URL, after previousURL: URL) throws -> URL {
        let normalized = try Self.normalized(candidate, relativeTo: siteURL, kind: .login)
        if previousURL.scheme == "https", normalized.scheme != "https" {
            throw ValidationError.insecureDowngrade
        }
        return normalized
    }

    func promotedAdminBaseURL(for loginURL: URL) throws -> URL {
        guard adminBaseURL.scheme == "http", loginURL.scheme == "https",
              URLComponents(url: adminBaseURL, resolvingAgainstBaseURL: false)?.effectivePort == 80,
              URLComponents(url: loginURL, resolvingAgainstBaseURL: false)?.effectivePort == 443,
              var components = URLComponents(url: adminBaseURL, resolvingAgainstBaseURL: false) else {
            return adminBaseURL
        }
        components.scheme = "https"
        components.port = nil
        guard let url = components.url else {
            throw ValidationError.invalidURL
        }
        return url
    }
}

private extension URLComponents {
    var defaultPort: Int? {
        if scheme == "http" {
            return 80
        }
        if scheme == "https" {
            return 443
        }
        return nil
    }

    var effectivePort: Int? {
        port ?? defaultPort
    }
}

private extension String {
    var trimmingTrailingSlashes: String {
        var result = self
        while result.count > 1, result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}
