import Foundation

/// Parses a scanner / deep-link input string into a `QRLoginPayload`.
///
/// The matching is order-sensitive per spec §3 — the first matching variant
/// wins. This type has no dependencies and is fully unit-testable.
struct QRLoginPayloadParser {

    /// Parses `input` (the raw scanner output or inbound URL string) into a
    /// `QRLoginPayload`. Returns `.invalid` for any string that doesn't match
    /// one of the recognised shapes.
    func parse(_ input: String) -> QRLoginPayload {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            return .invalid
        }
        return parse(url)
    }

    /// Parses a pre-built `URL` into a payload. Useful when the caller already
    /// has a `URL` (e.g. an inbound deep-link `URL` from the OS).
    func parse(_ url: URL) -> QRLoginPayload {
        // §3.1 — magic-link is matched on full URL first so a wrong host/path
        // can fall through to the other branches cleanly.
        if let payload = matchMagicLink(url) { return payload }

        // §3.2 — install QR (woocommerce.com/mobile/*).
        if matchesInstallQR(url) { return .installQR }

        // §3.3 — legacy `woocommerce://app-login`.
        if isCustomScheme(url, host: Constants.appLoginHost) {
            return parseAppLogin(url)
        }

        // §3.4 / §3.5 / §3.6 — `woocommerce://qr-login` family.
        if isCustomScheme(url, host: Constants.qrLoginHost) {
            return parseQRLogin(url)
        }

        return .invalid
    }
}

// MARK: - WP.com magic-link

private extension QRLoginPayloadParser {
    func matchMagicLink(_ url: URL) -> QRLoginPayload? {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == Constants.magicLinkHost,
              url.path == Constants.magicLinkPath else {
            return nil
        }
        let params = queryItems(url)
        guard params["action"] == "magic-login",
              params["scheme"] == "woocommerce",
              let token = params["token"], token.isEmpty == false else {
            return nil
        }
        return .magicLink(url: url)
    }
}

// MARK: - Install QR

private extension QRLoginPayloadParser {
    func matchesInstallQR(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == Constants.installQRHost else {
            return false
        }
        // First non-empty path segment must be "mobile".
        let segments = url.pathComponents.filter { $0 != "/" && $0.isEmpty == false }
        return segments.first?.lowercased() == "mobile"
    }
}

// MARK: - `woocommerce://app-login`

private extension QRLoginPayloadParser {
    func parseAppLogin(_ url: URL) -> QRLoginPayload {
        let params = queryItems(url)
        guard let siteURL = params["siteUrl"], siteURL.isEmpty == false,
              isValidAppLoginSiteURL(siteURL) else {
            return .invalid
        }
        // `wpcomEmail` takes precedence over `username` per §3.3.
        if let email = params["wpcomEmail"], email.isEmpty == false {
            return .appLoginWPCom(siteURL: siteURL, email: email)
        }
        if let username = params["username"], username.isEmpty == false {
            return .appLoginUsername(siteURL: siteURL, username: username)
        }
        return .invalid
    }

    /// Legacy app-login accepts http or https (§10.3). No userinfo, query, or
    /// fragment allowed.
    func isValidAppLoginSiteURL(_ raw: String) -> Bool {
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, host.isEmpty == false,
              url.user == nil, url.password == nil,
              (url.query ?? "").isEmpty,
              (url.fragment ?? "").isEmpty else {
            return false
        }
        return true
    }
}

// MARK: - `woocommerce://qr-login`

private extension QRLoginPayloadParser {
    func parseQRLogin(_ url: URL) -> QRLoginPayload {
        let params = queryItems(url)
        let siteURLRaw = params["siteUrl"]
        let hasSiteURL = (siteURLRaw?.isEmpty == false)

        let token = params["token"]
        let encrypted = params["encrypted"]

        // Self-hosted branch is gated on `siteUrl` being present (§3.4 / §3.5),
        // so a wp.com payload that happens to carry `siteUrl` is never silently
        // rerouted to wp.com.
        if hasSiteURL {
            guard let siteURL = normalisedSelfHostedSiteURL(siteURLRaw ?? "") else {
                return .invalid
            }
            if let token, token.isEmpty == false {
                guard isValidSelfHostedToken(token) else {
                    return .invalid
                }
                return .selfHosted(token: token, siteURL: siteURL)
            }
            return .siteURLOnly(siteURL: siteURL)
        }

        // No siteUrl: only the wp.com branch can apply.
        guard let token, isValidWPComToken(token),
              let encrypted, encrypted.isEmpty == false else {
            return .invalid
        }
        return .wpCom(token: token, encrypted: encrypted)
    }

    /// §3.4 — self-hosted `siteUrl` rejects userinfo/query/fragment, lowercases
    /// the host, and strips a trailing slash.
    ///
    /// Release builds are https-only: the `/scan` token and the `/exchange`
    /// Application Password must never travel in cleartext. DEBUG builds also
    /// accept `http` so the flow can be exercised against a local test server.
    func normalisedSelfHostedSiteURL(_ raw: String) -> URL? {
        guard let components = URLComponents(string: raw),
              let scheme = components.scheme?.lowercased(),
              Self.allowedSelfHostedSchemes.contains(scheme),
              let host = components.host, host.isEmpty == false,
              components.user == nil, components.password == nil,
              (components.query ?? "").isEmpty,
              (components.fragment ?? "").isEmpty else {
            return nil
        }
        var normalised = components
        normalised.scheme = scheme
        normalised.host = host.lowercased()
        // Trailing slash strip on the path.
        if normalised.path == "/" {
            normalised.path = ""
        }
        return normalised.url
    }

    /// Schemes accepted for a self-hosted `siteUrl`. `http` is DEBUG-only — see
    /// `normalisedSelfHostedSiteURL`.
    #if DEBUG
    static let allowedSelfHostedSchemes: Set<String> = ["https", "http"]
    #else
    static let allowedSelfHostedSchemes: Set<String> = ["https"]
    #endif

    func isValidSelfHostedToken(_ token: String) -> Bool {
        token.range(of: #"^[A-Za-z0-9]{64,512}$"#, options: .regularExpression) != nil
    }

    func isValidWPComToken(_ token: String) -> Bool {
        token.range(of: #"^[A-Fa-f0-9]{64}:[A-Fa-f0-9]{32}$"#, options: .regularExpression) != nil
    }
}

// MARK: - Helpers

private extension QRLoginPayloadParser {
    /// Returns `true` when `url` is one of our case-insensitive
    /// `woocommerce://<host>` deep links and its path is empty or `/`.
    func isCustomScheme(_ url: URL, host expectedHost: String) -> Bool {
        guard url.scheme?.lowercased() == Constants.customScheme,
              url.host?.lowercased() == expectedHost else {
            return false
        }
        return url.path.isEmpty || url.path == "/"
    }

    func queryItems(_ url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return [:]
        }
        var result: [String: String] = [:]
        for item in items where item.value != nil {
            result[item.name] = item.value
        }
        return result
    }

    enum Constants {
        static let customScheme = "woocommerce"
        static let qrLoginHost = "qr-login"
        static let appLoginHost = "app-login"
        static let magicLinkHost = "wordpress.com"
        static let magicLinkPath = "/wp-login.php"
        static let installQRHost = "woocommerce.com"
    }
}
