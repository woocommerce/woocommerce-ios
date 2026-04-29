import Foundation
import CocoaLumberjackSwift
import NetworkingCore

/// `AssistantJWTProviding` that mints AI JWTs against the merchant's own
/// `<siteURL>/wp-json/jetpack/v4/jetpack-ai-jwt` endpoint with HTTP Basic
/// auth. The harness lives outside the Jetpack tunnel, so the merchant's
/// app password is the only viable credential.
///
/// Caching, single-flight, clock-skew margin, and JWT validation are
/// delegated to `WpComJetpackAIJWTProvider`. Concurrent harnesses with
/// the same `(siteURL, basicAuth)` share one provider via a process-wide
/// cache, so a smoke run firing many parallel scenarios mints once.
public struct URLSessionJetpackAIJWTClient: AssistantJWTProviding {

    public typealias Mint = @Sendable (URL, String, URLSession) async throws -> String

    private let siteURL: URL
    private let blogID: Int64
    private let basicAuthHeader: String
    private let session: URLSession
    private let cacheKey: String
    private let mint: Mint

    public init(siteURL: URL,
                blogID: Int64,
                username: String,
                appPassword: String,
                session: URLSession = .shared) {
        self.init(siteURL: siteURL,
                  blogID: blogID,
                  username: username,
                  appPassword: appPassword,
                  session: session,
                  mint: Self.defaultMint)
    }

    // Internal seam: tests inject a stub mint to exercise the cache without going to the network.
    init(siteURL: URL,
         blogID: Int64,
         username: String,
         appPassword: String,
         session: URLSession = .shared,
         mint: @escaping Mint) {
        self.siteURL = siteURL
        self.blogID = blogID
        self.session = session
        // Strip whitespace from the app password before encoding. The Jetpack mint endpoint
        // rejects spaced "abcd efgh" passwords with a 401 even though wp-admin accepts them.
        let strippedPassword = appPassword.replacingOccurrences(of: " ", with: "")
        let raw = "\(username):\(strippedPassword)"
        let encoded = Data(raw.utf8).base64EncodedString()
        self.basicAuthHeader = "Basic \(encoded)"
        self.cacheKey = "\(siteURL.absoluteString)|\(encoded)"
        self.mint = mint
    }

    public func currentJWT() async throws -> String {
        try await provider().currentJWT()
    }

    public func invalidate() async {
        await provider().invalidate()
    }

    private func provider() async -> WpComJetpackAIJWTProvider {
        let siteURL = self.siteURL
        let header = self.basicAuthHeader
        let session = self.session
        let mint = self.mint
        return await Self.providerCache.providerFor(cacheKey: cacheKey, blogID: blogID) {
            WpComJetpackAIJWTProvider(blogID: $0) { _ in
                try await mint(siteURL, header, session)
            }
        }
    }

    static let defaultMint: Mint = { siteURL, basicAuthHeader, session in
        let endpoint = siteURL.appendingPathComponent("wp-json/jetpack/v4/jetpack-ai-jwt")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AssistantError(kind: .network, message: "Headless JWT mint received a non-HTTP response.")
        }
        if !(200..<300).contains(http.statusCode) {
            let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
            throw AssistantError(kind: .auth,
                                 code: String(http.statusCode),
                                 message: "Headless JWT mint failed (HTTP \(http.statusCode)): \(snippet)")
        }
        struct Envelope: Decodable {
            let token: String?
            let jwt: String?
        }
        do {
            let decoded = try JSONDecoder().decode(Envelope.self, from: data)
            if let token = decoded.token, !token.isEmpty { return token }
            if let jwt = decoded.jwt, !jwt.isEmpty { return jwt }
        } catch {
            DDLogError("URLSessionJetpackAIJWTClient mint envelope decode failed: \(error)")
        }
        let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
        throw AssistantError(kind: .auth,
                             message: "Headless JWT mint expected `token` in response body, got: \(snippet)")
    }

    static let providerCache = ProviderCache()
}

// Process-wide map of `cacheKey → provider`. The provider itself owns the
// in-flight Task / token cache / clock-skew margin from `WpComJetpackAIJWTProvider`.
actor ProviderCache {
    private var providers: [String: WpComJetpackAIJWTProvider] = [:]

    func providerFor(cacheKey: String,
                     blogID: Int64,
                     make: (Int64) -> WpComJetpackAIJWTProvider) -> WpComJetpackAIJWTProvider {
        if let existing = providers[cacheKey] { return existing }
        let provider = make(blogID)
        providers[cacheKey] = provider
        return provider
    }

    func reset() {
        providers.removeAll()
    }

    func cachedProviderCount() -> Int {
        providers.count
    }
}
